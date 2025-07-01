# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
import json
import time
import os
import base64
import io
from PIL import Image
import requests
import re
import concurrent.futures
import uuid
from datetime import datetime
import logging
from typing import Optional, List, Dict, Any
from utils import (
    get_recipe_logic, 
    encode_image, 
    robust_json_parse, 
    process_ingredient_nutrition_data, 
    get_refrigerator_prompt, 
    get_invoice_prompt, 
    compress_image_for_api,
    MAX_IMAGES,
    MAX_FILE_SIZE,
    INGREDIENT_ANALYSIS_TIMEOUT,
    get_analysis_prompt,
    get_simple_meal_analysis_prompt
)
from firebase_functions.https_fn import Request, Response

# Initialize Firebase app
app = initialize_app()

# Import our custom helper modules
from openai_helper import analyze_image_with_openai, analyze_image_with_openrouter
from mongodb_config import (
    save_validation_error, 
    save_ingredient_to_mongo, 
    save_meal_analysis_to_mongo, 
    validate_nutrition_data
)

# Constants for the new functions
BASE_MODEL_NAME = "google/gemini-2.5-flash-preview"

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MongoDB configuration is now handled in mongodb_config.py

# OpenAI function for analyzing meal images (V1 - Original)
@https_fn.on_request()
def analyze_meal_image_v1(req: https_fn.Request) -> https_fn.Response:
    """Analyze meal image using OpenAI Vision API"""
    try:
        # Get data from request
        data = req.get_json()
        image_url = data.get('image_url')
        image_base64 = data.get('image_base64')
        image_name = data.get('image_name', 'unknown.jpg')
        function_info = data.get('function_info', {})
        
        print(f"Received analysis request for image: {image_name}")
        
        if image_url:
            print(f"Image URL length: {len(image_url)}")
        if image_base64:
            print(f"Image base64 length: {len(image_base64)}")
        
        # Validate that we have either URL or base64
        if not image_url and not image_base64:
            return https_fn.Response(
                json.dumps({'error': 'Either image_url or image_base64 must be provided'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )
            
        # Validate URL format if provided
        if image_url and not image_url.startswith(('http://', 'https://')):
            return https_fn.Response(
                json.dumps({'error': 'Invalid image URL format. Must start with http:// or https://'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )

        if image_url:
            print(f"Processing image URL: {image_url[:50]}...")
        else:
            print(f"Processing base64 image data ({len(image_base64)} characters)")
        
        prompt = get_simple_meal_analysis_prompt()

        try:
            # Using the custom analyze_image_with_openai function from openai_helper
            raw_analysis_output = analyze_image_with_openai(
                image_url=image_url, 
                prompt=prompt, 
                image_base64=image_base64
            )
            
            # Debug: Log what OpenAI actually returned
            print(f"🔍 Raw OpenAI output type: {type(raw_analysis_output)}")
            if isinstance(raw_analysis_output, str):
                print(f"🔍 Raw OpenAI output (first 500 chars): {raw_analysis_output[:500]}")
            else:
                print(f"🔍 Raw OpenAI output: {raw_analysis_output}")
            
            final_json_payload_str: str

            if isinstance(raw_analysis_output, str):
                text_to_parse = raw_analysis_output.strip()

                # Try to remove markdown fences
                if text_to_parse.startswith("```json") and text_to_parse.endswith("```"):
                    # Slice from after "```json" (length 7) to before "```" (length 3 from end)
                    text_to_parse = text_to_parse[len("```json"):-len("```")].strip()
                elif text_to_parse.startswith("```") and text_to_parse.endswith("```"):
                    # Slice from after "```" (length 3) to before "```" (length 3 from end)
                    text_to_parse = text_to_parse[len("```"):-len("```")].strip()

                # After attempting to strip markdown, find the JSON object
                json_start_index = text_to_parse.find('{')
                json_end_index = text_to_parse.rfind('}')

                if json_start_index != -1 and json_end_index != -1 and json_end_index > json_start_index:
                    json_str_candidate = text_to_parse[json_start_index : json_end_index + 1]
                    try:
                        parsed_json = json.loads(json_str_candidate)
                        
                        # Debug: Check if healthiness is in the parsed JSON
                        print(f"🔍 Parsed JSON keys: {list(parsed_json.keys())}")
                        if 'healthiness' in parsed_json:
                            print(f"✅ Found healthiness in parsed JSON: {parsed_json['healthiness']}")
                        else:
                            print("❌ No healthiness field found in parsed JSON")
                            print(f"🔍 Full parsed JSON: {parsed_json}")
                            # Add default healthiness if missing
                            parsed_json['healthiness'] = 'N/A'
                            print("🔧 Added default healthiness: N/A")
                        
                        final_json_payload_str = json.dumps(parsed_json) # Re-serialize for clean output
                    except json.JSONDecodeError as e:
                        error_message = f"Could not parse extracted JSON (from braces) from vision API output. Error: {str(e)}. Candidate snippet: {json_str_candidate[:200]}"
                        print(error_message)
                        raise Exception(error_message) from e
                else:
                    # If no '{...}' found, try to parse the text_to_parse directly
                    try:
                        parsed_json = json.loads(text_to_parse)
                        
                        # Debug: Check if healthiness is in the parsed JSON
                        print(f"🔍 Direct parse JSON keys: {list(parsed_json.keys())}")
                        if 'healthiness' in parsed_json:
                            print(f"✅ Found healthiness in direct parsed JSON: {parsed_json['healthiness']}")
                        else:
                            print("❌ No healthiness field found in direct parsed JSON")
                            print(f"🔍 Full direct parsed JSON: {parsed_json}")
                            # Add default healthiness if missing
                            parsed_json['healthiness'] = 'N/A'
                            print("🔧 Added default healthiness: N/A")
                        
                        final_json_payload_str = json.dumps(parsed_json) 
                    except json.JSONDecodeError as e:
                        error_message = f"Vision API output is not a recognized JSON object (no braces found) and not a simple JSON string after stripping. Error: {str(e)}. Output snippet: {text_to_parse[:200]}"
                        print(error_message)
                        raise Exception(error_message) from e
            elif isinstance(raw_analysis_output, (dict, list)):
                final_json_payload_str = json.dumps(raw_analysis_output)
            else:
                error_message = f"Unexpected data type from image analysis service: {type(raw_analysis_output)}. Output snippet: {str(raw_analysis_output)[:200]}"
                print(error_message)
                raise Exception(error_message)

            # Return the cleaned and validated analysis result
            return https_fn.Response(
                final_json_payload_str,
                status=200,
                headers={'Content-Type': 'application/json'}
            )
        except Exception as vision_error:
            print(f"OpenAI Vision API error: {str(vision_error)}")
            # Return a more helpful error message
            error_response = {
                "error": "Failed to analyze image with OpenAI Vision API",
                "message": str(vision_error),
                "fallback_analysis": {
                    "meal_name": "Unknown meal (analysis failed)",
                    "estimated_calories": 0,
                    "macronutrients": {
                        "proteins": "0g",
                        "carbohydrates": "0g",
                        "fats": "0g"
                    },
                    "ingredients": ["could not analyze image"],
                    "health_assessment": "Analysis failed. Please try again later.",
                    "source": "https://fdc.nal.usda.gov/"
                }
            }
            return https_fn.Response(
                json.dumps(error_response),
                status=200,  # Return 200 with error info instead of 500
                headers={'Content-Type': 'application/json'}
            )
        
    except Exception as e:
        print(f"Error in analyze_meal_image: {str(e)}")
        return https_fn.Response(
            json.dumps({
                "error": "General error occurred",
                "message": str(e),
                "fallback_analysis": {
                    "meal_name": "Error occurred",
                    "estimated_calories": 0,
                    "macronutrients": {
                        "proteins": "0g",
                        "carbohydrates": "0g",
                        "fats": "0g"
                    },
                    "ingredients": ["analysis failed"],
                    "health_assessment": "Error occurred during analysis.",
                    "source": "https://fdc.nal.usda.gov/"
                }
            }),
            status=200,
            headers={'Content-Type': 'application/json'}
        )

# OpenAI function for analyzing meal images (V2 - Enhanced)
@https_fn.on_request()
def analyze_meal_image_v2(req: https_fn.Request) -> https_fn.Response:
    """
    Cloud Function to analyze meal images using OpenAI Vision API (V2)
    Supports both image URLs and base64 encoded images with compression
    """
    # Enable CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response("", status=204, headers=headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    try:
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({"error": "Only POST method is allowed"}),
                status=405,
                headers=headers
            )
        
        # Parse request body
        try:
            request_data = req.get_json()
            if not request_data:
                raise ValueError("No JSON data provided")
        except Exception as e:
            return https_fn.Response(
                json.dumps({"error": f"Invalid JSON data: {str(e)}"}),
                status=400,
                headers=headers
            )
        
        print(f"🔍 Received request data keys: {list(request_data.keys())}")
        
        # Get image data - support both URL and base64
        image_url = request_data.get('image_url')
        image_base64 = request_data.get('image_base64')
        image_name = request_data.get('image_name', 'unknown')
        
        print(f"📸 Processing image: {image_name}")
        print(f"🔗 Has image_url: {bool(image_url)}")
        print(f"📊 Has image_base64: {bool(image_base64)}")
        
        if not image_url and not image_base64:
            return https_fn.Response(
                json.dumps({"error": "Either 'image_url' or 'image_base64' must be provided"}),
                status=400,
                headers=headers
            )
        
        # If base64 image is provided, optionally compress it
        if image_base64:
            try:
                # Decode base64 to check size and potentially compress
                image_bytes = base64.b64decode(image_base64)
                original_size_kb = len(image_bytes) / 1024
                
                print(f"📏 Original base64 image size: {original_size_kb:.1f} KB")
                
                # If image is large, compress it
                if original_size_kb > 400:  # 400KB threshold
                    print(f"🗜️ Compressing large image...")
                    compressed_bytes = compress_image_for_api(image_bytes, max_size_kb=400)
                    image_base64 = base64.b64encode(compressed_bytes).decode('utf-8')
                    new_size_kb = len(compressed_bytes) / 1024
                    print(f"📏 Compressed image size: {new_size_kb:.1f} KB")
                    
            except Exception as e:
                print(f"⚠️ Error processing base64 image: {e}")
                # Continue with original base64 if compression fails
        
        # Analyze the image (single attempt, no retry)
        print(f"🤖 Starting OpenAI analysis...")
        
        analysis_result = analyze_image_with_openrouter(
            image_url=image_url,
            image_base64=image_base64,
            prompt=get_analysis_prompt()
        )
        
        if "error" not in analysis_result:
            print(f"✅ Analysis completed successfully")
            return https_fn.Response(
                json.dumps(analysis_result),
                status=200,
                headers=headers
            )
        else:
            print(f"⚠️ Analysis returned error: {analysis_result.get('error')}")
            return https_fn.Response(
                json.dumps(analysis_result),
                status=500,
                headers=headers
            )
        
    except Exception as e:
        error_msg = f"Unexpected error in analyze_meal_image_v2: {str(e)}"
        print(f"❌ {error_msg}")
        return https_fn.Response(
            json.dumps({"error": error_msg}),
            status=500,
            headers=headers
        )

# Refrigerator Analysis Function
@https_fn.on_request()
def analyze_refrigerator(req: https_fn.Request) -> https_fn.Response:
    """
    Analyze refrigerator images to identify ingredients
    """
    # Enable CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response("", status=204, headers=headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    try:
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({"error": "Only POST method is allowed"}),
                status=405,
                headers=headers
            )
        
        # Parse request body
        try:
            request_data = req.get_json()
            if not request_data:
                raise ValueError("No JSON data provided")
        except Exception as e:
            return https_fn.Response(
                json.dumps({"error": f"Invalid JSON data: {str(e)}"}),
                status=400,
                headers=headers
            )
        
        # Get images from request
        images = request_data.get('images', [])
        if not images:
            return https_fn.Response(
                json.dumps({"error": "No images provided"}),
                status=400,
                headers=headers
            )
        
        if len(images) > MAX_IMAGES:
            return https_fn.Response(
                json.dumps({"error": f"Maximum {MAX_IMAGES} images allowed"}),
                status=400,
                headers=headers
            )
        
        logger.info(f"Processing {len(images)} refrigerator images")
        
        # Process images
        all_ingredients = []
        total_items = 0
        processed_images = 0
        errors = []
        
        # Process each image
        for index, image_data in enumerate(images):
            try:
                image_base64 = image_data.get('image_base64')
                if not image_base64:
                    errors.append(f"Image {index+1}: No base64 data provided")
                    continue
                
                # Analyze image using OpenRouter
                result = analyze_image_with_openrouter(
                    image_base64=image_base64,
                    prompt=get_refrigerator_prompt()
                )
                
                if "error" in result:
                    errors.append(f"Image {index+1}: {result['error']}")
                else:
                    # Process ingredient data
                    if "macronutrients_by_ingredient" in result:
                        process_ingredient_nutrition_data(result)
                    
                    # Collect ingredients
                    if "ingredients" in result:
                        all_ingredients.extend(result["ingredients"])
                    
                    if "total_items" in result:
                        total_items += result["total_items"]
                    
                    processed_images += 1
                    
            except Exception as e:
                error_msg = f"Error processing image {index+1}: {str(e)}"
                errors.append(error_msg)
                logger.error(error_msg)
        
        # Create response
        response_data = {
            "ingredients": all_ingredients,
            "total_items": total_items,
            "images_processed": processed_images,
            "total_images": len(images),
            "unique_ingredients": len(set(ingredient.get("name", "") for ingredient in all_ingredients)),
            "processing_errors": errors if errors else None,
            "analysis_type": "refrigerator_analysis"
        }
        
        return https_fn.Response(
            json.dumps(response_data),
            status=200,
            headers=headers
        )
        
    except Exception as e:
        error_msg = f"Unexpected error in analyze_refrigerator: {str(e)}"
        logger.error(error_msg)
        return https_fn.Response(
            json.dumps({"error": error_msg}),
            status=500,
            headers=headers
        )

# Invoice Analysis Function
@https_fn.on_request()
def analyze_invoice(req: https_fn.Request) -> https_fn.Response:
    """
    Analyze invoice/receipt images to identify ingredients
    """
    # Enable CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response("", status=204, headers=headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    try:
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({"error": "Only POST method is allowed"}),
                status=405,
                headers=headers
            )
        
        # Parse request body
        try:
            request_data = req.get_json()
            if not request_data:
                raise ValueError("No JSON data provided")
        except Exception as e:
            return https_fn.Response(
                json.dumps({"error": f"Invalid JSON data: {str(e)}"}),
                status=400,
                headers=headers
            )
        
        # Get images from request
        images = request_data.get('images', [])
        if not images:
            return https_fn.Response(
                json.dumps({"error": "No images provided"}),
                status=400,
                headers=headers
            )
        
        if len(images) > MAX_IMAGES:
            return https_fn.Response(
                json.dumps({"error": f"Maximum {MAX_IMAGES} images allowed"}),
                status=400,
                headers=headers
            )
        
        logger.info(f"Processing {len(images)} invoice images")
        
        # Process images
        all_ingredients = []
        total_items = 0
        processed_images = 0
        errors = []
        receipt_summaries = []
        
        # Process each image
        for index, image_data in enumerate(images):
            try:
                image_base64 = image_data.get('image_base64')
                if not image_base64:
                    errors.append(f"Image {index+1}: No base64 data provided")
                    continue
                
                # Analyze image using OpenRouter
                result = analyze_image_with_openrouter(
                    image_base64=image_base64,
                    prompt=get_invoice_prompt()
                )
                
                if "error" in result:
                    errors.append(f"Image {index+1}: {result['error']}")
                else:
                    # Process ingredient data
                    if "macronutrients_by_ingredient" in result:
                        process_ingredient_nutrition_data(result)
                    
                    # Collect ingredients
                    if "ingredients" in result:
                        all_ingredients.extend(result["ingredients"])
                    
                    if "total_items" in result:
                        total_items += result["total_items"]
                    
                    if "receipt_summary" in result:
                        receipt_summaries.append(result["receipt_summary"])
                    
                    processed_images += 1
                    
            except Exception as e:
                error_msg = f"Error processing image {index+1}: {str(e)}"
                errors.append(error_msg)
                logger.error(error_msg)
        
        # Create response
        response_data = {
            "ingredients": all_ingredients,
            "total_items": total_items,
            "receipt_summaries": receipt_summaries,
            "images_processed": processed_images,
            "total_images": len(images),
            "unique_ingredients": len(set(ingredient.get("name", "") for ingredient in all_ingredients)),
            "processing_errors": errors if errors else None,
            "analysis_type": "invoice_receipt_analysis"
        }
        
        return https_fn.Response(
            json.dumps(response_data),
            status=200,
            headers=headers
        )
        
    except Exception as e:
        error_msg = f"Unexpected error in analyze_invoice: {str(e)}"
        logger.error(error_msg)
        return https_fn.Response(
            json.dumps({"error": error_msg}),
            status=500,
            headers=headers
        )


@https_fn.on_request()
def get_recipe(req: Request) -> Response:
    params = req.args
    result = get_recipe_logic(params)
    return Response(json.dumps(result), mimetype="application/json")


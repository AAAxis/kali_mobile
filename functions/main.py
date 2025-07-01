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

# Initialize Firebase app
app = initialize_app()

# Import our custom helper module
from openai_helper import analyze_image_with_openai, analyze_image_with_openrouter

def get_analysis_prompt():
    """Get the enhanced analysis prompt for meal image analysis"""
    return """
           As a professional nutritionist, analyze the provided food image and return accurate nutritional data in strict JSON format.

          ANALYSIS INSTRUCTIONS:

          1. IDENTIFY ALL VISIBLE ITEMS:
             - Include partially hidden items, sauces, and items extending beyond the frame
             - Identify the likely cuisine type (e.g., Mediterranean, Asian, American)
             - Account for perspective distortion and lighting variations when estimating size/quantity

          2. ESTIMATE QUANTITIES (WITH IMAGE GEOMETRY AND CAMERA ANGLE):
              - Use known reference objects in the image (e.g. standard fork ≈ 18cm, plate ≈ 27cm diameter) to scale food items
              - Adjust estimates based on camera angle:
                 * If taken from top-down (90°) – use area coverage on plate for volume approximation
                 * If taken from ~45° – apply foreshortening correction to infer height/depth
                 * If taken from low angle (<30°) – estimate vertical volume more accurately but adjust for occlusion
              - Document:
                 * Apparent scaling ratios
                 * Any overlap, stacking, or visual distortion that affects estimation
              - Provide comparison-based estimates such as:
                 * "Meat portion ≈ 2× fork length in width, 1× in thickness"
                 * "Rice occupies ⅓ of the plate area, thickness ~1.5 cm"

          3. PROVIDE COMPLETE NUTRITIONAL BREAKDOWN:
             - Calculate: proteins, carbohydrates, fats in grams
             - Sum total calories: (proteins × 4) + (carbs × 4) + (fats × 9)
             - Include likely ingredients used in preparation (oils, spices) when evident
             - Use USDA FoodData Central or equivalent databases

          4. DOCUMENT ALL ASSUMPTIONS:
             - Size comparisons used
             - Inferences based on shape, shadow, overlap
             - Perspective adjustments made
             - Preparation method assumptions

          Return output in this JSON format:

          {
            "mealName": "English meal name",
            "calories": number (estimated total calories),
            "meal_name": "Descriptive name of the combined meal",
            "cuisine_type": "Mediterranean",
            "macronutrients": {
              "proteins": "40g",
              "carbohydrates": "50g",
              "fats": "30g"
            },
            "macros": {
               "proteins": number (grams),
               "carbs": number (grams),
               "fats": number (grams)
             },
            "estimated_weight": "500g",
            "weight_estimation_details": [
              "Grilled chicken breast × 200g = 200g",
              "Quinoa salad × 300g = 300g"
            ],
            "ingredients": ["chicken breast", "quinoa", "tomatoes", "olive oil", "lemon"],
            "nutrients": {
                "fiber": number (grams),
                "sugar": number (grams),
                "sodium": number (mg),
                "potassium": number (mg),
                "vitamin_c": number (mg),
                "calcium": number (mg),
                "iron": number (mg)
              },
            "cooking_state": "cooked",
            "cooking_method": "grilled|fried|baked|raw|steamed|etc",
            "category": "meat (poultry)",
            "category_cause": "Contains chicken breast",
            "assumptions": [
              "Olive oil used for grilling",
              "Portion sizes estimated based on plate size"
            ],
            "portion_size": "small|medium|large",
            "meal_type": "breakfast|lunch|dinner|snack",
            "allergens": ["gluten", "dairy", "nuts", "etc"],
            "dietary_tags": ["vegetarian", "vegan", "keto", "low-carb","high-protein", "gluten-free", "etc"],
            "part_identification_confidence": {
              "chicken breast": "95%",
              "quinoa": "85%"
            },
            "health_assessment": "healthy",
            "healthiness": "healthy|medium|unhealthy",
            "healthiness_explanation": "English explanation ex: This meal contains lean protein, whole grains, and vegetables with healthy fats",
            "source": "USDA FoodData Central",
            "confidence_level": "high",
            "macronutrients_by_ingredient": {
              "chicken breast": {
                "proteins": "31g",
                "carbohydrates": "0g",
                "fats": "3.6g",
                "calories": "165"
              },
              "quinoa": {
                "proteins": "8g",
                "carbohydrates": "39g",
                "fats": "3.5g",
                "calories": "222"
              }
            },
            "judge": {
              "final_meal_name": "Grilled Chicken with Quinoa Salad",
              "estimated_total_calories": 650,
              "total_macronutrients": {
                "protein_grams": 40,
                "fat_grams": 30,
                "carbohydrate_grams": 50
              },
              "final_ingredients_list": [
                "chicken breast",
                "quinoa",
                "tomatoes",
                "olive oil",
                "lemon"
              ],
              "final_assumptions": [
                "Grilled with 1 tbsp olive oil",
                "Salad is not dressed with sugar-based dressing"
              ],
              "cooking_state": "cooked",
              "category": "meat (poultry)",
              "category_cause": "Dominant ingredient is grilled chicken",
              "source": "USDA FoodData Central",
              "judge_estimation_calories": {
                "total_estimated_calories": 650,
                "ingredient_breakdown": [
                  {
                    "ingredient": "chicken breast",
                    "estimated_weight_grams": 200,
                    "estimated_kcal_per_gram": 0.83,
                    "estimated_calories": 165,
                    "weight_estimation_steps": ["1 medium fillet × 200g = 200g"],
                    "macronutrients": {
                      "protein_grams": 31,
                      "fat_grams": 3.6,
                      "carbohydrate_grams": 0
                    }
                  },
                  {
                    "ingredient": "quinoa",
                    "estimated_weight_grams": 300,
                    "estimated_kcal_per_gram": 0.74,
                    "estimated_calories": 222,
                    "weight_estimation_steps": ["1.5 cup cooked quinoa = 300g"],
                    "macronutrients": {
                      "protein_grams": 8,
                      "fat_grams": 3.5,
                      "carbohydrate_grams": 39
                    }
                  }
                ],
                "calculation_method": "Sum of ingredients based on standard kcal/g values"
              }
            }
          }

          Provide accurate nutritional estimates based on visible ingredients and portion sizes. Be as detailed and accurate as possible. All responses should be in English only.

            🚩 Return only a valid JSON block.
            🚩 Do not include markdown, explanations, or additional text.
            🚩 This is your final expert-level output for visual nutritional analysis.
          """


def compress_image_for_api(image_bytes, max_size_kb=400, quality=85):
    """Compress image for API submission"""
    try:
        # Open image from bytes
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if necessary
        if image.mode in ('RGBA', 'LA', 'P'):
            image = image.convert('RGB')
        
        # Calculate initial compression
        output = io.BytesIO()
        image.save(output, format='JPEG', quality=quality, optimize=True)
        compressed_bytes = output.getvalue()
        
        # If still too large, reduce dimensions
        while len(compressed_bytes) > max_size_kb * 1024 and quality > 10:
            output = io.BytesIO()
            # Reduce quality
            quality -= 10
            image.save(output, format='JPEG', quality=quality, optimize=True)
            compressed_bytes = output.getvalue()
        
        # If still too large, resize image
        if len(compressed_bytes) > max_size_kb * 1024:
            width, height = image.size
            scale_factor = 0.8
            while len(compressed_bytes) > max_size_kb * 1024 and scale_factor > 0.3:
                new_width = int(width * scale_factor)
                new_height = int(height * scale_factor)
                resized_image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
                
                output = io.BytesIO()
                resized_image.save(output, format='JPEG', quality=quality, optimize=True)
                compressed_bytes = output.getvalue()
                scale_factor -= 0.1
        
        print(f"📏 Image compressed from {len(image_bytes)} to {len(compressed_bytes)} bytes")
        return compressed_bytes
        
    except Exception as e:
        print(f"❌ Error compressing image: {e}")
        return image_bytes




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
        
        prompt = """
Analyze this meal image and provide detailed nutritional information in JSON format. Include:
1. Meal identification (in English only)
2. Accurate calorie estimation
3. Detailed macro breakdown (in grams)
4. List of ingredients with estimated weights (in English only)
5. Detailed ingredients with individual nutrition per ingredient
6. A categorical healthiness value (e.g., 'healthy', 'medium', 'unhealthy')
7. Detailed health assessment text
8. Source URL for more information

Format the response as:
{
  'mealName': 'Meal name in English',
  'estimatedCalories': number (e.g., 670),
  'macros': {
    'proteins': 'Xg (e.g., 30g)',
    'carbohydrates': 'Xg (e.g., 50g)',
    'fats': 'Xg (e.g., 40g)'
  },
  'ingredients': ['ingredient1', 'ingredient2', 'ingredient3'],
  'detailedIngredients': [
    {
      'name': 'Ingredient name in English',
      'grams': estimated_weight_in_grams,
      'calories': calories_for_this_ingredient,
      'proteins': proteins_in_grams,
      'carbs': carbs_in_grams,
      'fats': fats_in_grams
    }
  ],
  'healthiness': 'healthy' | 'medium' | 'unhealthy' | 'N/A',
  'health_assessment': 'Detailed health assessment of the meal',
  'source': 'A valid URL (starting with http or https) for more information about this meal'
}

Important:
- Provide realistic calorie and macro values based on visible portions.
- Ensure 'estimatedCalories' is a number.
- Ensure macros (proteins, carbohydrates, fats) are strings ending with 'g'.
- For detailedIngredients, estimate the weight of each visible ingredient in grams.
- Calculate individual nutrition values for each ingredient based on typical nutrition data.
- The sum of all ingredient calories should approximately match estimatedCalories.
- The sum of all ingredient macros should approximately match the main macros.
- The 'healthiness' field should be one of 'healthy', 'medium', 'unhealthy', or 'N/A'.
- Provide a comprehensive 'health_assessment' string.
- The source field MUST be a valid URL, defaulting to https://fdc.nal.usda.gov/ if needed.
- All responses should be in English only - translation will be handled client-side.
- Be as accurate as possible with ingredient weights and nutrition values.
"""

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


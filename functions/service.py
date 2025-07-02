import json
from utils import get_simple_meal_analysis_prompt, get_analysis_prompt, get_refrigerator_prompt, get_invoice_prompt, get_recipe_logic, compress_image_for_api, MAX_IMAGES, process_ingredient_nutrition_data
from openai_helper import analyze_image_with_openai, analyze_image_with_openrouter
import base64
import logging
from firebase_functions.https_fn import Request, Response

logger = logging.getLogger(__name__)

def analyze_meal_image_v1_service(req: Request) -> Response:
    try:
        data = req.get_json()
        image_url = data.get('image_url')
        image_base64 = data.get('image_base64')
        image_name = data.get('image_name', 'unknown.jpg')
        function_info = data.get('function_info', {})
        if not image_url and not image_base64:
            return Response(json.dumps({'error': 'Either image_url or image_base64 must be provided'}), status=400, headers={'Content-Type': 'application/json'})
        if image_url and not image_url.startswith(('http://', 'https://')):
            return Response(json.dumps({'error': 'Invalid image URL format. Must start with http:// or https://'}), status=400, headers={'Content-Type': 'application/json'})
        prompt = get_simple_meal_analysis_prompt()
        try:
            raw_analysis_output = analyze_image_with_openai(
                image_url=image_url, 
                prompt=prompt, 
                image_base64=image_base64
            )
            final_json_payload_str: str
            if isinstance(raw_analysis_output, str):
                text_to_parse = raw_analysis_output.strip()
                if text_to_parse.startswith("```json") and text_to_parse.endswith("```"):
                    text_to_parse = text_to_parse[len("```json"):-len("```")].strip()
                elif text_to_parse.startswith("```") and text_to_parse.endswith("```"):
                    text_to_parse = text_to_parse[len("```"):-len("```")].strip()
                json_start_index = text_to_parse.find('{')
                json_end_index = text_to_parse.rfind('}')
                if json_start_index != -1 and json_end_index != -1 and json_end_index > json_start_index:
                    json_str_candidate = text_to_parse[json_start_index : json_end_index + 1]
                    try:
                        parsed_json = json.loads(json_str_candidate)
                        if 'healthiness' not in parsed_json:
                            parsed_json['healthiness'] = 'N/A'
                        final_json_payload_str = json.dumps(parsed_json)
                    except json.JSONDecodeError as e:
                        error_message = f"Could not parse extracted JSON (from braces) from vision API output. Error: {str(e)}. Candidate snippet: {json_str_candidate[:200]}"
                        raise Exception(error_message) from e
                else:
                    try:
                        parsed_json = json.loads(text_to_parse)
                        if 'healthiness' not in parsed_json:
                            parsed_json['healthiness'] = 'N/A'
                        final_json_payload_str = json.dumps(parsed_json) 
                    except json.JSONDecodeError as e:
                        error_message = f"Vision API output is not a recognized JSON object (no braces found) and not a simple JSON string after stripping. Error: {str(e)}. Output snippet: {text_to_parse[:200]}"
                        raise Exception(error_message) from e
            elif isinstance(raw_analysis_output, (dict, list)):
                final_json_payload_str = json.dumps(raw_analysis_output)
            else:
                error_message = f"Unexpected data type from image analysis service: {type(raw_analysis_output)}. Output snippet: {str(raw_analysis_output)[:200]}"
                raise Exception(error_message)
            return Response(final_json_payload_str, status=200, headers={'Content-Type': 'application/json'})
        except Exception as vision_error:
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
            return Response(json.dumps(error_response), status=200, headers={'Content-Type': 'application/json'})
    except Exception as e:
        return Response(json.dumps({
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
        }), status=200, headers={'Content-Type': 'application/json'})

def analyze_meal_image_v2_service(req: Request) -> Response:
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return Response("", status=204, headers=headers)
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    try:
        if req.method != 'POST':
            return Response(json.dumps({"error": "Only POST method is allowed"}), status=405, headers=headers)
        try:
            request_data = req.get_json()
            if not request_data:
                raise ValueError("No JSON data provided")
        except Exception as e:
            return Response(json.dumps({"error": f"Invalid JSON data: {str(e)}"}), status=400, headers=headers)
        image_url = request_data.get('image_url')
        image_base64 = request_data.get('image_base64')
        image_name = request_data.get('image_name', 'unknown')
        if not image_url and not image_base64:
            return Response(json.dumps({"error": "Either 'image_url' or 'image_base64' must be provided"}), status=400, headers=headers)
        if image_base64:
            try:
                image_bytes = base64.b64decode(image_base64)
                original_size_kb = len(image_bytes) / 1024
                if original_size_kb > 400:
                    compressed_bytes = compress_image_for_api(image_bytes, max_size_kb=400)
                    image_base64 = base64.b64encode(compressed_bytes).decode('utf-8')
            except Exception as e:
                pass
        analysis_result = analyze_image_with_openrouter(
            image_url=image_url,
            image_base64=image_base64,
            prompt=get_analysis_prompt()
        )
        if "error" not in analysis_result:
            return Response(json.dumps(analysis_result), status=200, headers=headers)
        else:
            return Response(json.dumps(analysis_result), status=500, headers=headers)
    except Exception as e:
        error_msg = f"Unexpected error in analyze_meal_image_v2: {str(e)}"
        return Response(json.dumps({"error": error_msg}), status=500, headers=headers)

def analyze_refrigerator_service(req: Request) -> Response:
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return Response("", status=204, headers=headers)
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    try:
        if req.method != 'POST':
            return Response(json.dumps({"error": "Only POST method is allowed"}), status=405, headers=headers)
        try:
            request_data = req.get_json()
            if not request_data:
                raise ValueError("No JSON data provided")
        except Exception as e:
            return Response(json.dumps({"error": f"Invalid JSON data: {str(e)}"}), status=400, headers=headers)
        images = request_data.get('images', [])
        if not images:
            return Response(json.dumps({"error": "No images provided"}), status=400, headers=headers)
        if len(images) > MAX_IMAGES:
            return Response(json.dumps({"error": f"Maximum {MAX_IMAGES} images allowed"}), status=400, headers=headers)
        logger.info(f"Processing {len(images)} refrigerator images")
        all_ingredients = []
        total_items = 0
        processed_images = 0
        errors = []
        for index, image_data in enumerate(images):
            try:
                image_base64 = image_data.get('image_base64')
                if not image_base64:
                    errors.append(f"Image {index+1}: No base64 data provided")
                    continue
                result = analyze_image_with_openrouter(
                    image_base64=image_base64,
                    prompt=get_refrigerator_prompt()
                )
                if "error" in result:
                    errors.append(f"Image {index+1}: {result['error']}")
                else:
                    if "macronutrients_by_ingredient" in result:
                        process_ingredient_nutrition_data(result)
                    if "ingredients" in result:
                        all_ingredients.extend(result["ingredients"])
                    if "total_items" in result:
                        total_items += result["total_items"]
                    processed_images += 1
            except Exception as e:
                error_msg = f"Error processing image {index+1}: {str(e)}"
                errors.append(error_msg)
                logger.error(error_msg)
        response_data = {
            "ingredients": all_ingredients,
            "total_items": total_items,
            "images_processed": processed_images,
            "total_images": len(images),
            "unique_ingredients": len(set(ingredient.get("name", "") for ingredient in all_ingredients)),
            "processing_errors": errors if errors else None,
            "analysis_type": "refrigerator_analysis"
        }
        return Response(json.dumps(response_data), status=200, headers=headers)
    except Exception as e:
        error_msg = f"Unexpected error in analyze_refrigerator: {str(e)}"
        logger.error(error_msg)
        return Response(json.dumps({"error": error_msg}), status=500, headers=headers)

def analyze_invoice_service(req: Request) -> Response:
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return Response("", status=204, headers=headers)
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    try:
        if req.method != 'POST':
            return Response(json.dumps({"error": "Only POST method is allowed"}), status=405, headers=headers)
        try:
            request_data = req.get_json()
            if not request_data:
                raise ValueError("No JSON data provided")
        except Exception as e:
            return Response(json.dumps({"error": f"Invalid JSON data: {str(e)}"}), status=400, headers=headers)
        images = request_data.get('images', [])
        if not images:
            return Response(json.dumps({"error": "No images provided"}), status=400, headers=headers)
        if len(images) > MAX_IMAGES:
            return Response(json.dumps({"error": f"Maximum {MAX_IMAGES} images allowed"}), status=400, headers=headers)
        logger.info(f"Processing {len(images)} invoice images")
        all_ingredients = []
        total_items = 0
        processed_images = 0
        errors = []
        receipt_summaries = []
        for index, image_data in enumerate(images):
            try:
                image_base64 = image_data.get('image_base64')
                if not image_base64:
                    errors.append(f"Image {index+1}: No base64 data provided")
                    continue
                result = analyze_image_with_openrouter(
                    image_base64=image_base64,
                    prompt=get_invoice_prompt()
                )
                if "error" in result:
                    errors.append(f"Image {index+1}: {result['error']}")
                else:
                    if "macronutrients_by_ingredient" in result:
                        process_ingredient_nutrition_data(result)
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
        return Response(json.dumps(response_data), status=200, headers=headers)
    except Exception as e:
        error_msg = f"Unexpected error in analyze_invoice: {str(e)}"
        logger.error(error_msg)
        return Response(json.dumps({"error": error_msg}), status=500, headers=headers)

def get_recipe_service(req: Request) -> Response:
    params = req.args
    result = get_recipe_logic(params)
    return Response(json.dumps(result), mimetype="application/json")


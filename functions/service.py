import json
from utils import get_simple_meal_analysis_prompt, get_analysis_prompt, get_refrigerator_prompt, get_invoice_prompt, get_recipe_logic, compress_image_for_api, MAX_IMAGES, process_ingredient_nutrition_data
from openai_helper import analyze_image_with_openai, analyze_image_with_openrouter
import base64
import logging
import uvicorn

logger = logging.getLogger(__name__)

def analyze_meal_image_v1_service(image_url=None, image_base64=None, image_name='unknown.jpg', function_info=None):
    """
    Service logic for analyzing a meal image using OpenAI Vision API (V1).
    Args:
        image_url (str): URL of the image
        image_base64 (str): Base64-encoded image
        image_name (str): Name of the image
        function_info (dict): Additional function info
    Returns:
        dict: Analysis result or error response
    """
    # Logging and validation
    print(f"[Service] Received analysis request for image: {image_name}")
    if image_url:
        print(f"[Service] Image URL length: {len(image_url)}")
    if image_base64:
        print(f"[Service] Image base64 length: {len(image_base64)}")
    if not image_url and not image_base64:
        return {'error': 'Either image_url or image_base64 must be provided'}
    if image_url and not image_url.startswith(('http://', 'https://')):
        return {'error': 'Invalid image URL format. Must start with http:// or https://'}
    # Prepare prompt
    prompt = get_simple_meal_analysis_prompt()
    # Call OpenAI helper
    try:
        raw_analysis_output = analyze_image_with_openai(
            image_url=image_url,
            prompt=prompt,
            image_base64=image_base64
        )
        # Post-process and clean the output
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
                    print(error_message)
                    return {'error': error_message}
            else:
                try:
                    parsed_json = json.loads(text_to_parse)
                    if 'healthiness' not in parsed_json:
                        parsed_json['healthiness'] = 'N/A'
                    final_json_payload_str = json.dumps(parsed_json)
                except json.JSONDecodeError as e:
                    error_message = f"Vision API output is not a recognized JSON object (no braces found) and not a simple JSON string after stripping. Error: {str(e)}. Output snippet: {text_to_parse[:200]}"
                    print(error_message)
                    return {'error': error_message}
        elif isinstance(raw_analysis_output, (dict, list)):
            final_json_payload_str = json.dumps(raw_analysis_output)
        else:
            error_message = f"Unexpected data type from image analysis service: {type(raw_analysis_output)}. Output snippet: {str(raw_analysis_output)[:200]}"
            print(error_message)
            return {'error': error_message}
        return {'result': final_json_payload_str}
    except Exception as e:
        print(f"[Service] OpenAI Vision API error: {str(e)}")
        return {'error': str(e)}

def analyze_meal_image_v2_service(image_url=None, image_base64=None, image_name='unknown'):
    logger.info(f"[Service] V2: Processing image: {image_name}")
    if not image_url and not image_base64:
        return {'error': "Either 'image_url' or 'image_base64' must be provided"}
    if image_base64:
        try:
            image_bytes = base64.b64decode(image_base64)
            original_size_kb = len(image_bytes) / 1024
            logger.info(f"[Service] V2: Original base64 image size: {original_size_kb:.1f} KB")
            if original_size_kb > 400:
                logger.info(f"[Service] V2: Compressing large image...")
                compressed_bytes = compress_image_for_api(image_bytes, max_size_kb=400)
                image_base64 = base64.b64encode(compressed_bytes).decode('utf-8')
        except Exception as e:
            logger.warning(f"[Service] V2: Error processing base64 image: {e}")
    try:
        analysis_result = analyze_image_with_openrouter(
            image_url=image_url,
            image_base64=image_base64,
            prompt=get_analysis_prompt()
        )
        if "error" not in analysis_result:
            logger.info(f"[Service] V2: Analysis completed successfully")
            return {'result': analysis_result}
        else:
            logger.warning(f"[Service] V2: Analysis returned error: {analysis_result.get('error')}")
            return {'error': analysis_result.get('error')}
    except Exception as e:
        logger.error(f"[Service] V2: Unexpected error: {str(e)}")
        return {'error': str(e)}

def analyze_refrigerator_service(images):
    if not images:
        return {'error': "No images provided"}
    if len(images) > MAX_IMAGES:
        return {'error': f"Maximum {MAX_IMAGES} images allowed"}
    logger.info(f"[Service] Refrigerator: Processing {len(images)} images")
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
    return {'result': response_data}

def analyze_invoice_service(images):
    if not images:
        return {'error': "No images provided"}
    if len(images) > MAX_IMAGES:
        return {'error': f"Maximum {MAX_IMAGES} images allowed"}
    logger.info(f"[Service] Invoice: Processing {len(images)} images")
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
    return {'result': response_data}

def get_recipe_service(params):
    logger.info(f"[Service] get_recipe called with params: {params}")
    try:
        result = get_recipe_logic(params)
        logger.info(f"[Service] get_recipe result: {type(result)}")
        return {'result': result}
    except Exception as e:
        logger.error(f"[Service] get_recipe error: {str(e)}")
        return {'error': str(e)}

if __name__ == "__main__":
    uvicorn.run(
        "functions.fastapi_app:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    ) 
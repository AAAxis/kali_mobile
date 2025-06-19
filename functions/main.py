# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
import json
import base64
import io
from PIL import Image
import requests
import os

# Initialize Firebase app
app = initialize_app()

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
           "mealName": {
              "en": "English meal name",
              "ru": "Russian meal name",
              "he": "Hebrew meal name"
            },
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
            "ingredients": {
               "en": ["ingredient1", "ingredient2", ...],
               "ru": ["ингредиент1", "ингредиент2", ...],
               "he": ["רכיב1", "רכיב2", ...]
             },
            "ingredients_multilingual": {
              "en": ["chicken breast", "quinoa", "tomatoes", "olive oil", "lemon"],
              "ru": ["куриная грудка", "киноа", "помидоры", "оливковое масло", "лимон"],
              "he": ["חזה עוף", "קינואה", "עגבניות", "שמן זית", "לימון"]
            },
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

              "dietary_tags": ["vegetarian", "vegan", "keto", "low-carb","high-protein", "gluten-free", "etc"]

            "part_identification_confidence": {
              "chicken breast": "95%",
              "quinoa": "85%"
            },
            "health_assessment": "healthy",

             "healthiness": "healthy|medium|unhealthy",
             "healthiness_explanation": {
               "en": "English explanation ex: This meal contains lean protein, whole grains, and vegetables with healthy fats",
               "ru": "Russian explanation",
               "he": "Hebrew explanation"
             },


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

          Provide accurate nutritional estimates based on visible ingredients and portion sizes. Be as detailed and accurate as possible. Make sure to provide translations in Hebrew (he), English (en), and Russian (ru) for all multilingual fields.
          """


def analyze_image_with_openai(image_url=None, image_base64=None, prompt=None):
    """
    Analyze an image using OpenAI's Vision capabilities
    """
    try:
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise Exception("OpenAI API key not configured")
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        
        # Prepare image content
        if image_url:
            image_content = {"type": "image_url", "image_url": {"url": image_url}}
        elif image_base64:
            image_content = {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}}
        else:
            raise Exception("Either image_url or image_base64 must be provided")
        
        payload = {
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt or get_analysis_prompt()},
                        image_content
                    ]
                }
            ],
            "max_tokens": 1500,
            "response_format": {"type": "json_object"}
        }
        
        print(f"🤖 Making OpenAI API request...")
        response = requests.post("https://api.openai.com/v1/chat/completions", 
                               headers=headers, 
                               json=payload,
                               timeout=60)
        
        print(f"🤖 OpenAI API response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content']
            
            try:
                analysis_result = json.loads(content)
                print(f"✅ Successfully parsed OpenAI response")
                return analysis_result
            except json.JSONDecodeError as e:
                print(f"❌ Error parsing OpenAI JSON response: {e}")
                print(f"Raw content: {content}")
                return {"error": "Failed to parse OpenAI response as JSON", "raw_content": content}
        else:
            error_msg = f"OpenAI API error: {response.status_code} - {response.text}"
            print(f"❌ {error_msg}")
            return {"error": error_msg}
            
    except Exception as e:
        error_msg = f"Error calling OpenAI API: {str(e)}"
        print(f"❌ {error_msg}")
        return {"error": error_msg}

@https_fn.on_request()
def analyze_meal_image(req: https_fn.Request) -> https_fn.Response:
    """
    Cloud Function to analyze meal images using OpenAI Vision API
    Supports both image URLs and base64 encoded images
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
        
        analysis_result = analyze_image_with_openai(
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
        error_msg = f"Unexpected error in analyze_meal_image: {str(e)}"
        print(f"❌ {error_msg}")
        return https_fn.Response(
            json.dumps({"error": error_msg}),
            status=500,
            headers=headers
        )

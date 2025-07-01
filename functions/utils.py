import json, time, logging
from typing import Optional, List, Dict, Any, Tuple
import base64
import io
import os
from pathlib import Path
from PIL import Image
from dotenv import load_dotenv
from urllib.parse import quote_plus
from datetime import datetime
import asyncio
import requests
from fastapi import HTTPException, UploadFile

# Import your backend and model utilities as needed
# from backend.app_recipe.utils.base.mongo_client import recipes_collection, ingredient_names_collection, \
#     ingredient_categories_collection, gpt_recipes_collection, ingredients_nutrition_collection
# from backend.app_recipe.utils.model_common_util import execute_call
# from backend.app_recipe.utils.mongo_handler_utils import *

logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
BASE_MODEL_NAME = 'google/gemini-2.5-flash-preview'
MODEL_NAMES = ['openai/gpt-4o-mini', 'meta-llama/llama-4-maverick:free']
FINAL_MODEL = 'openai/gpt-4o'

# Constants for the functions
MAX_IMAGES = 3
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
INGREDIENT_ANALYSIS_TIMEOUT = 60

# --- Common utility functions moved from main.py ---

def encode_image(file_path: str) -> str:
    """Encode image file to base64"""
    try:
        with open(file_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')
    except Exception as e:
        logger.error(f"Error encoding image {file_path}: {str(e)}")
        return None

def robust_json_parse(json_str: str) -> dict:
    """Robustly parse JSON string, handling common formatting issues"""
    try:
        # Try direct parsing first
        return json.loads(json_str)
    except json.JSONDecodeError:
        try:
            # Try to clean up common issues
            cleaned = json_str.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()
            return json.loads(cleaned)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON after cleaning: {e}")
            return None

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

def process_ingredient_nutrition_data(result: dict) -> None:
    """Process and validate ingredient nutrition data"""
    try:
        if "macronutrients_by_ingredient" in result:
            for ingredient_name, data in result["macronutrients_by_ingredient"].items():
                # Ensure all required fields exist
                required_fields = ["category", "proteins", "carbohydrates", "fats", "calories"]
                for field in required_fields:
                    if field not in data:
                        data[field] = "0g" if field != "category" else "Other"
                
                # Calculate per 100g values if weight is available
                if "weight" in data and data["weight"]:
                    try:
                        weight_str = data["weight"].lower().replace("g", "").replace("ml", "")
                        weight = float(weight_str)
                        if weight > 0:
                            # Extract numeric values
                            proteins = float(data["proteins"].replace("g", ""))
                            carbs = float(data["carbohydrates"].replace("g", ""))
                            fats = float(data["fats"].replace("g", ""))
                            calories = float(data["calories"].replace("kcal", ""))
                            
                            # Calculate per 100g
                            data["proteins_per_100g"] = round((proteins / weight) * 100, 2)
                            data["carbohydrates_per_100g"] = round((carbs / weight) * 100, 2)
                            data["fats_per_100g"] = round((fats / weight) * 100, 2)
                            data["calories_per_100g"] = round((calories / weight) * 100, 2)
                    except (ValueError, AttributeError):
                        data["proteins_per_100g"] = 0.0
                        data["carbohydrates_per_100g"] = 0.0
                        data["fats_per_100g"] = 0.0
                        data["calories_per_100g"] = 0.0
                
                # Validate nutrition data
                is_valid, error_details = validate_nutrition_data(ingredient_name, data)
                
                if not is_valid:
                    # Save validation error to MongoDB
                    save_validation_error(ingredient_name, error_details, data)
                    logger.warning(f"⚠️ Validation failed for {ingredient_name}: {error_details['errors']}")
                else:
                    # Save valid ingredient data to MongoDB
                    ingredient_data = {
                        "name": ingredient_name,
                        "nutrition_data": data,
                        "source": "meal_analysis",
                        "analysis_timestamp": datetime.utcnow()
                    }
                    save_ingredient_to_mongo(ingredient_data)
                    logger.info(f"✅ Validated and saved {ingredient_name} to MongoDB")
        
        # Save complete meal analysis to MongoDB
        if result:
            meal_analysis_data = {
                "analysis_type": "meal_image_analysis",
                "result_data": result,
                "analysis_timestamp": datetime.utcnow()
            }
            save_meal_analysis_to_mongo(meal_analysis_data)
            logger.info("✅ Meal analysis saved to MongoDB")
            
    except Exception as e:
        logger.error(f"Error processing ingredient nutrition data: {str(e)}")

def get_refrigerator_prompt():
    """Get the prompt for refrigerator analysis"""
    return """
    You are a food analysis agent.

    Your task is to:
    1. Analyze the image and extract a list of all detected ingredients.
    2. Normalize each ingredient into its base product name (e.g., "Tomatoes on the Vine" → "Tomato", "Greek Style Yogurt" → "Yogurt").
    3. Avoid duplication of similar ingredients by mapping variations to a common base name.
    4. For each unique normalized base ingredient name, return a structured nutrition object as follows:
    5. possible_measurement - means if the ingredient was in this measurement what will be the value at 1 gram. (if it fruit/vegetable try to fill the avg_raw,small_raw,medium and large , also eggs and co.)  

    "macronutrients_by_ingredient": {
        "base_ingredient_name - (add the type, e.g., Apple (Granny Smith))": {
            "category": "[Fruits, Other, Eggs, Grains, Legumes, Dairy, Vegetables/Fruits, Fish, Fat And Oils, Vegetables, Meat, Herb, Leafy Green, Fruit Juice, Nut, Mushroom, Soy, Alcoholic, Fortified Wine, Nut Recipes, Seed, Dried Fruit, Spice, Citrus, Dairy Alternatives, Sweeteners, Condiment, Root Vegetable, Shellfish, Seafood, Liqueur, Alcohol, Poultry, Olive, Nuts and Seeds, Herbs and Spices, Berry, Tree Nut, Fruit And Oils, Sauces, Liquor, Beverages]",
            "possible_measurement": {
                "cup":  "",
                "tbsp":  "",
                "tsp":  "",
                "g": 1,
                "ml": 1,
                "avg_raw": "",
                "small_raw": "",
                "medium_raw": "",
                "large_raw": ""
            },
            "base_ingredient_name": ["base name in singular and plural, lowercase (e.g., 'apple', 'apples')"],
            "names": {
                "english": {
                    "name": { "singular": "English name", "plural": "English names" },
                    "synonyms": ["synonym1", "synonym2"]
                },
                "russian": { ... },
                "spanish": { ... },
                "hebrew": { ... }
            },
            "data_source": "source name (e.g., USDA, Tesco)",
            "weight": "actual weight in grams or ml (e.g., '100g')",
            "proteins": "actual value in grams (e.g., '5.2g')",
            "carbohydrates": "actual value in grams (e.g., '18.1g')",
            "fats": "actual value in grams (e.g., '1.3g')",
            "calories": "actual value in kcal (e.g., '90.4kcal')",
            "average_weight": "serving size weight (e.g., '120g')",
            "proteins_per_100g": 0.0,
            "carbohydrates_per_100g": 0.0,
            "fats_per_100g": 0.0,
            "calories_per_100g": 0.0
        }
    }
    """

def get_invoice_prompt():
    """Get the prompt for invoice analysis"""
    return """
    You are a food analysis agent.

    Your task is to:
    1. Analyze the uploaded image(s) and extract all visible or OCR-detected food products.
    2. Normalize each product name to a clean base ingredient name with specific type formatting. Example: 
       - "Greek Style Yogurt" → "Yogurt (Greek Style)"
       - "Tomatoes on the Vine" → "Tomato (On the Vine)"
       - "Magnum Almond Ice Cream" → "Ice Cream (Almond)"
    3. Avoid duplication by mapping variations to the same normalized base name.
    4. For each **unique normalized base ingredient**, return a structured object inside a dictionary called `"macronutrients_by_ingredient"`.
    5. possible_measurement - means if the ingredient was in this measurement what will be the value at 1 gram. (if it fruit/vegetable try to fill the avg_raw,small_raw,medium and large , also eggs and co.)  

    The structure should follow this format:

    ```json
    "macronutrients_by_ingredient": {
      "Base Ingredient Name (Type)": {
        "category": "[Fruits, Other, Eggs, Grains, Legumes, Dairy, Vegetables/Fruits, Fish, Fat And Oils, Vegetables, Meat, Herb, Leafy Green, Fruit Juice, Nut, Mushroom, Soy, Alcoholic, Fortified Wine, Nut Recipes, Seed, Dried Fruit, Spice, Citrus, Dairy Alternatives, Sweeteners, Condiment, Root Vegetable, Shellfish, Seafood, Liqueur, Alcohol, Poultry, Olive, Nuts and Seeds, Herbs and Spices, Berry, Tree Nut, Fruit And Oils, Sauces, Liquor, Beverages]",
        "possible_measurement": {
          "cup": "",
          "tbsp": "",
          "tsp": "",
          "g": 1,
          "ml": 1,
          "avg_raw": "",
          "small_raw": "",
          "medium_raw": "",
          "large_raw": ""
        },
        "base_ingredient_name": ["singular form", "plural form"],
        "names": {
          "english": {
            "name": { "singular": "English name", "plural": "English names" },
            "synonyms": ["alternative1", "alternative2"]
          },
          "russian": {
            "name": { "singular": "", "plural": "" },
            "synonyms": []
          },
          "spanish": {
            "name": { "singular": "", "plural": "" },
            "synonyms": []
          },
          "hebrew": {
            "name": { "singular": "", "plural": "" },
            "synonyms": []
          }
        },
        "data_source": "USDA, Tesco, or other trusted source",
        "weight": "total product weight (e.g., '500g', '1000ml')",
        "proteins": "calculated total (e.g., '7.5g')",
        "carbohydrates": "calculated total (e.g., '22.1g')",
        "fats": "calculated total (e.g., '3.2g')",
        "calories": "total kcal (e.g., '145.5kcal')",
        "average_weight": "e.g., '120g', '1 cup'",
        "proteins_per_100g": float,
        "carbohydrates_per_100g": float,
        "fats_per_100g": float,
        "calories_per_100g": float
      }
    }
    ```
    """


def get_recipe_logic(params: dict) -> dict:
    # Extract and robustly convert parameters
    def to_int(val, default=None):
        try:
            return int(val)
        except (TypeError, ValueError):
            return default
    def to_float(val, default=None):
        try:
            return float(val)
        except (TypeError, ValueError):
            return default

    lang = params.get('lang')
    difficulty = params.get('difficulty')
    ingredients = params.get('ingredients')
    diet_type = params.get('diet_type')
    min_calories = to_int(params.get('min_calories'))
    max_calories = to_int(params.get('max_calories'))
    min_proteins = to_float(params.get('min_proteins'))
    max_proteins = to_float(params.get('max_proteins'))
    max_prep_time = to_int(params.get('max_prep_time'))
    min_carbs = to_float(params.get('min_carbs'))
    max_carbs = to_float(params.get('max_carbs'))
    min_fats = to_float(params.get('min_fats'))
    max_fats = to_float(params.get('max_fats'))
    limit = to_int(params.get('limit'), 10)
    skip = to_int(params.get('skip'), 0)

    ingredients_list = None
    if ingredients:
        # If already a JSON array, don't double encode
        try:
            parsed = json.loads(ingredients)
            if isinstance(parsed, list):
                ingredients_list = ingredients
            else:
                ingredient_items = [i.strip() for i in ingredients.split(",") if i.strip()]
                ingredients_list = json.dumps([{"name": item, "quantity": ""} for item in ingredient_items])
        except Exception:
            ingredient_items = [i.strip() for i in ingredients.split(",") if i.strip()]
            ingredients_list = json.dumps([{"name": item, "quantity": ""} for item in ingredient_items])

    try:
        logger.info(f"/get_recipe called with lang={lang}, difficulty={difficulty}, ingredients={ingredients}, diet_type={diet_type}, min_calories={min_calories}, max_calories={max_calories}, min_proteins={min_proteins}, max_proteins={max_proteins}, max_prep_time={max_prep_time}, min_carbs={min_carbs}, max_carbs={max_carbs}, min_fats={min_fats}, max_fats={max_fats}, limit={limit}, skip={skip}")
        overall_start_time = time.time()
        logger.info(f"=== Starting AI recipe generation ===")
        # Step 1: Input validation
        validation_start_time = time.time()
        logger.info(f"Step 1: Starting input validation...")
        DynamicRecipeValidator.validate_nutritional_ranges(
            min_calories, max_calories, min_proteins, max_proteins,
            min_carbs, max_carbs, min_fats, max_fats
        )
        DynamicRecipeValidator.validate_difficulty(difficulty)
        validation_time = time.time() - validation_start_time
        logger.info(f"Step 1: Input validation completed in {validation_time:.3f} seconds")
        # Step 2: Parse ingredients list
        ingredients_parse_start_time = time.time()
        logger.info(f"Step 2: Starting ingredients list parsing...")
        manual_ingredients = IngredientParser.parse_ingredients_list(ingredients_list)
        ingredients_parse_time = time.time() - ingredients_parse_start_time
        logger.info(f"Step 2: Ingredients list parsing completed in {ingredients_parse_time:.3f} seconds (found {len(manual_ingredients)} manual ingredients)")
        # Step 3: Use available ingredients (from parsed ingredients_list)
        available_ingredients = manual_ingredients
        # Check if no ingredients are available
        if not available_ingredients:
            logger.info("Step 3: No ingredients found - returning empty recipe")
            empty_response = ResponseBuilder.build_empty_response()
            overall_time = time.time() - overall_start_time
            logger.info(f"=== AI recipe generation completed in {overall_time:.3f} seconds (no ingredients found) ===")
            return empty_response
        # Step 4: Clean up old files
        cleanup_start_time = time.time()
        logger.info(f"Step 4: Starting file cleanup...")
        # TODO: Make this path configurable
        FileManager.cleanup_old_files("/home/data/kaila/uploads/recipe")
        cleanup_time = time.time() - cleanup_start_time
        logger.info(f"Step 4: File cleanup completed in {cleanup_time:.3f} seconds")
        # Step 5: Build prompt
        prompt_build_start_time = time.time()
        logger.info(f"Step 5: Starting prompt building...")
        prompt = PromptBuilder.build_recipe_prompt(
            available_ingredients, min_calories, max_calories,
            min_proteins, max_proteins, min_carbs, max_carbs,
            min_fats, max_fats, diet_type, None, difficulty
        )
        logger.info(f" Prompt = {prompt}")
        prompt_build_time = time.time() - prompt_build_start_time
        logger.info(f"Step 5: Prompt building completed in {prompt_build_time:.3f} seconds")
        # Step 6: Generate recipe with AI
        api_call_start_time = time.time()
        logger.info(f"Step 6: Starting OpenRouter API call for recipe generation...")
        try:
            # NOTE: If called from an async context, replace asyncio.run with await
            result = asyncio.run(RecipeGenerator.generate_recipe_with_ai(prompt, []))
            api_call_time = time.time() - api_call_start_time
            logger.info(f"Step 6: OpenRouter API call completed in {api_call_time:.3f} seconds")
        except Exception as e:
            api_call_time = time.time() - api_call_start_time
            logger.error(f"Step 6: API call failed after {api_call_time:.3f} seconds: {str(e)}")
            if "Network error" in str(e) or "Timeout" in str(e):
                fallback_response = ResponseBuilder.build_error_response(
                    "network_error", f"Network error: {str(e)}", available_ingredients
                )
            else:
                fallback_response = ResponseBuilder.build_error_response(
                    "api_error", f"API error: {str(e)}", available_ingredients
                )
            overall_time = time.time() - overall_start_time
            logger.info(f"=== AI recipe generation completed with error fallback in {overall_time:.3f} seconds ===")
            return fallback_response
        # Step 7: Parse response
        parsing_start_time = time.time()
        logger.info(f"Step 7: Starting response parsing...")
        try:
            result_json = parse_ai_json_response(result)
            parsing_time = time.time() - parsing_start_time
            logger.info(f"Step 7: Response parsing completed in {parsing_time:.3f} seconds")
            # Step 8: Add metadata and save response
            metadata_start_time = time.time()
            logger.info(f"Step 8: Starting metadata addition...")
            result_json = ResponseBuilder.add_metadata_to_response(result_json, available_ingredients)
            FileManager.save_response_to_mock(result_json)
            metadata_time = time.time() - metadata_start_time
            logger.info(f"Step 8: Metadata addition completed in {metadata_time:.3f} seconds")
            overall_time = time.time() - overall_start_time
            logger.info(f"Successfully generated dynamic recipes with {len(available_ingredients)} available ingredients")
            logger.info(f"=== AI recipe generation completed in {overall_time:.3f} seconds ===")
            logger.info("SUCCESS!!!!")
            print(json.dumps(result_json, indent=4))
            return result_json
        except json.JSONDecodeError as e:
            parsing_time = time.time() - parsing_start_time
            logger.error(f"Step 7: Response parsing failed after {parsing_time:.3f} seconds: {str(e)}")
            fallback_response = ResponseBuilder.build_error_response(
                "parsing_error", "JSON parsing failed", available_ingredients
            )
            overall_time = time.time() - overall_start_time
            logger.info(f"=== AI recipe generation completed with fallback in {overall_time:.3f} seconds ===")
            return fallback_response
    except Exception as e:
        logger.error(f"Exception in /get_recipe: {str(e)}")
        return {"error": f"Error searching recipes: {str(e)}"}

# --- MongoDB and recipe processing functions ---

def save_recipe_to_mongodb(recipe, recipe_info):
    """
    Save a recipe to the gpt_recipes collection and extract ingredient nutrition data
    with flattened structure
    """
    try:
        # Flatten the recipe data
        flattened_recipe = {
            'name': recipe.get('name'),
            'original_recipe_name': recipe_info['name'],
            'ingredients': recipe.get('ingredients', []),
            'base_ingredient_name': recipe.get('base_ingredient_name', []),
            'instructions': recipe.get('instructions', []),
            'allergens': recipe.get('allergens', []),
            'allergen_free': recipe.get('allergen_free', []),
            'prep_time': recipe.get('prep_time'),
            'cook_time': recipe.get('cook_time'),
            'difficulty': recipe.get('difficulty'),
            'servings': recipe.get('servings'),
            'cusine': recipe.get('cusine'),
            'course': recipe.get('course'),
            'created_at': datetime.utcnow(),
            'last_updated': datetime.utcnow(),
            'source_model': recipe.get('source_model'),
            'input_ingredients': recipe.get('input_ingredients', []),
            'macronutrients_by_ingredient': recipe.get('macronutrients_by_ingredient'),
            'kosher': recipe.get('kosher'),
            'halal': recipe.get('halal'),
            'gluten_free': recipe.get('gluten_free'),
            'dairy_free': recipe.get('dairy_free'),
            'low_carb': recipe.get('low_carb'),
            'diabetic_friendly': recipe.get('diabetic_friendly'),
            'heart_healthy': recipe.get('heart_healthy'),
            'health_rank': recipe.get('health_rank'),
            'tasty_rank': recipe.get('tasty_rank'),
        }
        # Add macronutrients
        if 'macronutrients' in recipe:
            macronutrients = recipe['macronutrients']
            flattened_recipe.update({
                'total_proteins': macronutrients.get('proteins', '0g'),
                'total_carbohydrates': macronutrients.get('carbohydrates', '0g'),
                'total_fats': macronutrients.get('fats', '0g'),
                'total_calories': macronutrients.get('calories', '0kcal')
            })
        if ('macronutrients_per_for_this_meal_100g' in recipe):
            base_name = 'macronutrients_per_for_this_meal_100g'
        else:
            base_name = 'macronutrients_per_100g'
        # Add per 100g macronutrients
        if base_name in recipe:
            per_100g = recipe[base_name]
            flattened_recipe.update({
                'proteins': per_100g.get('proteins', '0g'),
                'carbohydrates': per_100g.get('carbohydrates', '0g'),
                'fats': per_100g.get('fats', '0g'),
                'calories': per_100g.get('calories', '0kcal')
            })
        # Add health recommendations
        if 'health_recommendations' in recipe:
            health = recipe['health_recommendations']
            flattened_recipe.update({
                'health_benefits': health.get('benefits', []),
                'health_considerations': health.get('considerations', []),
                'suitable_diets': health.get('suitable_for', []),
                'unsuitable_diets': health.get('not_suitable_for', [])
            })
        try:
            # Save the flattened recipe
            recipe_id = gpt_recipes_collection.insert_one(flattened_recipe).inserted_id
        except Exception as exp:
            print(exp)
        # Extract and save ingredient data
        process_ingredient_nutrition_data(recipe)
        return recipe_id
    except Exception as e:
        print(f"Error saving recipe to MongoDB: {str(e)}")
        return None


async def update_recipe(model: str, recipe: Dict) -> List[Dict]:
    """
    Generate a new recipe variation based on an existing recipe.
    
    Args:
        model (str): The model to use for recipe generation
        recipe (Dict): The original recipe to base the variation on
        
    Returns:
        List[Dict]: List of generated recipe variations
    """
    try:
        # Extract key information from the original recipe
        recipe_info = {
            'name': recipe.get('title', ''),
            'ingredients': recipe.get('ingredients', []),
            'instructions': recipe.get('directions', []),
            'source': recipe.get('source', ''),
            'tags': recipe.get('tags', ''),
            'url': recipe.get('url', ''),
        }

        # Build the prompt with proper string formatting
        base_prompt = f"""Given these recipes: {recipe_info}
                        Complete the data and return a new recipe based on the following structure:                        
                        For each recipe, provide:
                        Return the new recipe in the following structure:
                        IMPORTANT: Your response must be valid JSON - do not include any explanatory text before or after the JSON
                        IMPORTANT: take calroy data from https://www.fatsecret.com/calories-nutrition/usda or https://fdc.nal.usda.gov/ other but write me the source
                        IMPORTANT: take possible_measurement from https://www.fatsecret.com/calories-nutrition/usda or https://fdc.nal.usda.gov/ other but write me the source and the weight

                        {{
                            "name": "New recipe name",
                            "ingredients": ["List of ingredients"],
                            "base_ingredient_name": ["List of all base ingredients without any modifications / counts, singular and plural for this ingredient write in english (add the type example Apple (Granny_Smith)) "],                            
                            "instructions": ["Step by step instructions"],
                            "prep_time": "Preparation time in minutes",
                            "cook_time": "Cooking time in minutes",
                            "difficulty": "One of [Easy, Medium, Hard]",
                            "servings": "Number of servings",
                            "cusine": "ex: Amirican / Asian / French",
                            "course": "One of [Breakfast, Lunch, Dinner, Snack, Any]",
                            "macronutrients": {{     
                                "data_source": "site name",                           
                                "weight: "gr/ml",                              
                                "proteins": "protein content in grams (e.g., '15.2g')",
                                "carbohydrates": "carbohydrate content in grams (e.g., '45.2g')",
                                "fats": "fat content in grams (e.g., '12.2g')",
                                "calories": "calorie content (e.g., '350.2kcal')"
                            }},
                            "macronutrients_by_ingredient": {{
                                "base_ingredient_name -  (add the type example Apple (Granny_Smith)) , must apper at base_ingredient_name": {{
                                    "category": "one of the list [Fruits,Other,Eggs,Grains,Legumes,Dairy,Vegetables/Fruits,Fish,Fat And Oils,Vegetables,Meat,Herb,Leafy Green,Fruit Juice,Nut,Mushroom,Soy,Alcoholic,Fortified Wine,Nut Recipes,Seed,Dried Fruit,Spice,Citrus,Dairy Alternatives,Sweeteners,Condiment,Root Vegetable,Shellfish,Seafood,Liqueur,Alcohol,Poultry,Olive,Nuts and Seeds,Herbs and Spices,Berry,Tree Nut,Fruit And Oils,Sauces,Liquor,Beverages]",
                                     "possible_measurement": {{ e.g --->
                                        "cup": None,
                                        "tbsp": None,
                                        "tsp": None,
                                        "g": 1,
                                        "ml": 1,
                                        "avg_raw" : "",
                                        "small_raw" : "",
                                        "medium_raw" : "",
                                        "large_raw" : "", etc.
                                        
                                    }},                             
                                    "possible_measurement": ["e.g., g, ml, tbsp, tsp, cup, etc."],
                                    "base_ingredient_name": ["List of base ingredients without any modifications / counts, singular and plural for this ingredientwrite in english "],
                                    "names": {{
                                        "english": {{
                                            "name": {{
                                                "singular": "english name",
                                                "plural": "english names"
                                            }},
                                            "synonyms": ["english synonym 1", "english synonym 2"]
                                        }},
                                        "russian": {{
                                            "name": {{
                                                "singular": "russian name",
                                                "plural": "russian names"
                                            }},
                                            "synonyms": ["russian synonym 1", "russian synonym 2"]
                                        }},
                                        "spanish": {{
                                            "name": {{
                                                "singular": "spanish name",
                                                "plural": "spanish names"
                                            }},
                                            "synonyms": ["spanish synonym 1", "spanish synonym 2"]
                                        }},
                                        "hebrew": {{
                                            "name": {{
                                                "singular": "hebrew name",
                                                "plural": "hebrew names"
                                            }},
                                            "synonyms": ["hebrew synonym 1", "hebrew synonym 2"]
                                        }}
                                    }},
                                    "data_source": "site name",
                                    "weight": "Actual weight in grams or milliliters (e.g., '100.2g' or '250ml')",
                                    "proteins": "Calculate actual protein content in grams (e.g., '5.3g')",
                                    "carbohydrates": "Calculate actual carbohydrate content in grams (e.g., '20.2g')",
                                    "fats": "Calculate actual fat content in grams (e.g., '3.2g')",
                                    "calories": "Calculate actual calorie content (e.g., '120.2kcal')",
                                    "average_weight": "Standard serving size in grams or milliliters",
                                    "proteins_per_100g": "Calculate protein content per 100g (e.g., '5.3g') - must be a float number and must filled",
                                    "carbohydrates_per_100g": "Calculate carbohydrate content per 100g (e.g., '20.1g') - must be a float number and must filled",
                                    "fats_per_100g": "Calculate fat content per 100g (e.g., '3.1g') - must be a float number and must filled",
                                    "calories_per_100g": "Calculate calories per 100g (e.g., '120.2kcal') - must be a float number and must filled"
                                }}
                            }},
                            "macronutrients_per_for_this_meal_100g": {{                                
                                "proteins": "Calculate total protein content per 100g of the final dish - must be a float number and must filled",
                                "carbohydrates": "Calculate total carbohydrate content per 100g of the final dish - must be a float number and must filled",
                                "fats": "Calculate total fat content per 100g of the final dish - must be a float number and must filled",
                                "calories": "Calculate total calories per 100g of the final dish - must be a float number and must filled"
                            }},
                            "kosher": {{
                                "is_kosher": "Yes/No",
                                "why": "description-exp milk and meat, prey meat -Meat is not kosher"
                            }},
                            "halal": {{
                                "is_halal": "Yes/No",
                                "why": "description-exp"
                            }},
                            "gluten_free": {{
                                "is_gluten_free": "Yes/No",
                                "why": "description-exp"
                            }},
                            "dairy_free": {{
                                "is_dairy_free": "Yes/No",
                                "why": "description-exp"
                            }},
                            "low_carb": {{
                                "is_low_carb": "Yes/No",
                                "why": "description-exp"
                            }},
                            "diabetic_friendly": {{
                                "is_diabetic_friendly": "Yes/No",
                                "why": "description-exp"
                            }},
                            "heart_healthy": {{
                                "is_heart_healthy": "Yes/No",
                                "why": "description-exp"
                            }},
                            "health_rank": "number between 1-100",
                            "tasty_rank": "number between 1-100",
                            "health_recommendations": {{
                                "benefits": ["List of health benefits"],
                                "considerations": ["List of health considerations or warnings"],
                                "suitable_for": [
                                   "List of dietary types or health conditions this recipe is suitable for, e.g., vegan, vegetarian, keto, paleo, kosher, halal, gluten-free, dairy-free, low-carb, diabetic-friendly, heart-healthy, weight loss, anti-inflammatory, low-sodium"
                                ],
                                "not_suitable_for": [
                                   "List of dietary types or health conditions this recipe is not suitable for, e.g., not kosher, not vegetarian, not gluten-free, not halal, contains pork, high cholesterol, hypertension, diabetes, IBS, kidney disease"
                                ]
                            }},
                            "allergens": ["List of potential allergens"],
                            "allergen_free": ["List of allergens this recipe is free from"]
                        }}
                        
                        Return the response as a JSON object."""

        # model = "google/gemini-2.5-flash-preview"
        model = "google/gemini-flash-1.5"
        # model = "deepseek/deepseek-prover-v2:free"
        # Prepare the API request
        body = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": base_prompt
                        },
                    ]
                }
            ],
            "temperature": 0,  # Increased for more variation
            "response_format": {"type": "json_object"}
        }

        # Make the API call
        openrouter_response = await execute_call(body, model)

        if not openrouter_response or not hasattr(openrouter_response, 'json'):
            print("Error: Invalid response from API")
            return []

        try:
            response_json = openrouter_response.json()
            message_content = response_json["choices"][0]["message"]["content"]
            message_content = message_content.replace("json","")
            message_content = message_content.replace("```", "")
            # Convert the JSON string inside "content" to a Python dict
            new_recipe = json.loads(message_content)

            # Add metadata
            new_recipe['created_at'] = datetime.utcnow()
            new_recipe['source_model'] = model
            new_recipe['original_recipe_id'] = recipe.get('_id')
            if (new_recipe['name'] != recipe_info['name']):
                new_recipe['original_recipe_name'] = recipe_info['name']

            # Save to MongoDB
            recipe_id = save_recipe_to_mongodb(new_recipe, recipe_info)
            if recipe_id:
                new_recipe['_id'] = recipe_id

                # Print recipe details
                print(f"\nGenerated new recipe variation:")
                print(f"Name: {new_recipe.get('name', 'N/A')}")
                print(f"Course: {new_recipe.get('course', 'Any')}")
                print(f"Ingredients: {', '.join(new_recipe.get('ingredients', []))}")
                print(f"Prep Time: {new_recipe.get('prep_time', 'N/A')} mins")
                print(f"Cook Time: {new_recipe.get('cook_time', 'N/A')} mins")
                print(f"Difficulty: {new_recipe.get('difficulty', 'N/A')}")
                print(f"Servings: {new_recipe.get('servings', 'N/A')}")
                if 'macronutrients' in new_recipe:
                    print(f"Calories: {new_recipe['macronutrients'].get('calories', 'N/A')}")
                print("\nInstructions:")
                for step in new_recipe.get('instructions', []):
                    print(f"- {step}")
                print("-" * 80)

                return [new_recipe]
            else:
                print("Failed to save new recipe to database")
                return []

        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON response: {str(e)}")
            print(f"Raw response content: {message_content}")
            return []
        except Exception as e:
            print(f"Error processing response: {str(e)}")
            return []

    except Exception as e:
        print(f"Error in update_recipe: {str(e)}")
        return []



async def process_recipe(recipe: Dict, model: str = "anthropic/claude-3-opus-20240229") -> bool:
    """
    Process a single recipe to generate new variations.
    
    Args:
        recipe (Dict): The recipe to process
        model (str): The model to use for generation
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Double check: skip if recipe already exists
        if gpt_recipes_collection.find_one({'name': recipe.get('title', '')}):
            print(f"[Double Check] Skipping existing recipe: {recipe.get('title', 'Unknown')}")
            return False

        print(f"\nProcessing recipe: {recipe.get('name', 'Unknown')}")
        print(f"Course: {recipe.get('course', 'Any')}")
        print(f"Ingredients: {', '.join(recipe.get('ingredients', []))}")

        # Generate new recipe variation
        new_recipes = await update_recipe(model=model, recipe=recipe)

        if new_recipes:
            print(f"Generated {len(new_recipes)} new recipe variations")
            return True
        else:
            print("No new recipes generated")
            return False

    except Exception as e:
        print(f"Error processing recipe: {str(e)}")
        return False


async def check_recipe_exists(title: str) -> bool:
    """
    Check if a recipe with the given title already exists in the database.
    
    Args:
        title (str): The recipe title to check
        
    Returns:
        bool: True if recipe exists, False otherwise
    """
    try:
        existing_recipe = gpt_recipes_collection.find_one({'name': title})
        return existing_recipe is not None
    except Exception as e:
        print(f"Error checking recipe existence: {str(e)}")
        return False


async def process_recipe_batch(recipes: List[Dict], model: str) -> Tuple[int, int]:
    """
    Process a batch of recipes in parallel, skipping those that already exist.
    
    Args:
        recipes (List[Dict]): List of recipes to process
        model (str): The model to use for generation
        
    Returns:
        Tuple[int, int]: Number of processed and successful recipes
    """
    tasks = []
    for recipe in recipes:
        # Check if recipe already exists by title
        if await check_recipe_exists(recipe.get('title', '')):
            print(f"Skipping existing recipe: {recipe.get('title', 'Unknown')}")
            continue

        task = asyncio.create_task(process_recipe(recipe, model))
        tasks.append(task)

    if not tasks:
        print("No new recipes to process in this batch")
        return 0, 0

    results = await asyncio.gather(*tasks, return_exceptions=True)

    processed = len(tasks)
    successful = sum(1 for result in results if result is True)

    return processed, successful


def get_random_recipe_sample(sample_size: int = 1000) -> List[Dict]:
    """
    Get a random sample of recipes from the database.
    
    Args:
        sample_size (int): Number of recipes to sample (default: 1000)
        
    Returns:
        List[Dict]: List of randomly sampled recipes
    """
    try:
        # Use MongoDB's $sample aggregation to get random documents
        pipeline = [
            {"$sample": {"size": sample_size}}
        ]

        # Execute the aggregation
        sampled_recipes = list(recipes_collection.aggregate(pipeline))

        print(f"Successfully sampled {len(sampled_recipes)} recipes")
        return sampled_recipes

    except Exception as e:
        print(f"Error sampling recipes: {str(e)}")
        return []

async def generate_recipe_variations(batch_size: int = 10, model: str = "deepseek/deepseek-prover-v2:free",
                                     max_concurrent: int = 10):
    """
    Generate variations of existing recipes using parallel processing.
    
    Args:
        batch_size (int): Number of recipes to process in each batch
        model (str): The model to use for generation
        max_concurrent (int): Maximum number of concurrent tasks
    """
    try:
        # Get total count of recipes
        total_recipes = recipes_collection.count_documents({})
        print(f"Found {total_recipes} recipes in database")

        # Process recipes in batches
        processed = 0
        successful = 0
        skipped = 0
        batch_number = 1

        while processed < total_recipes:
            # Get batch of recipes
            cursor = recipes_collection.find({}).skip(processed).limit(batch_size)
            recipes = list(cursor)

            if not recipes:
                break

            print(f"\nProcessing batch {batch_number} ({len(recipes)} recipes)")

            # Get all recipe titles in the batch
            recipe_titles = [recipe.get('title', '') for recipe in recipes]

            # Check which recipes already exist
            existing_status = await check_recipes_exist(recipe_titles)

            # Filter out existing recipes
            new_recipes = [recipe for recipe in recipes if not existing_status.get(recipe.get('title', ''), False)]

            if not new_recipes:
                print("All recipes in this batch already exist")
                processed += len(recipes)
                skipped += len(recipes)
                batch_number += 1
                continue

            # Process the batch
            batch_processed, batch_successful = await process_recipe_batch(new_recipes, model)

            # Update statistics
            processed += len(recipes)
            successful += batch_successful
            skipped += len(recipes) - len(new_recipes)

            print(f"\nProgress: {processed}/{total_recipes} recipes processed")
            print(f"Successfully generated variations for {successful} recipes")
            print(f"Skipped {skipped} existing recipes")

            # Calculate success rate only if we've processed any recipes
            if processed > 0:
                success_rate = (successful / processed) * 100
                print(f"Current success rate: {success_rate:.2f}%")
            else:
                print("No recipes processed yet")

            # Add a small delay between batches to avoid rate limits
            await asyncio.sleep(2)
            batch_number += 1

            # Print a summary every 1000 recipes
            if processed % 1000 == 0:
                print(f"\n=== Progress Summary at {processed} recipes ===")
                print(f"Total processed: {processed}/{total_recipes} ({(processed / total_recipes) * 100:.2f}%)")
                print(f"Successfully generated: {successful}")
                print(f"Skipped: {skipped}")
                if processed > 0:
                    print(f"Success rate: {(successful / processed) * 100:.2f}%")
                print("=" * 40)

        print("\nFinal Statistics:")
        print(f"Total recipes processed: {processed}")
        print(f"Successfully generated variations: {successful}")
        print(f"Skipped existing recipes: {skipped}")

        # Calculate final success rate only if we've processed any recipes
        if processed > 0:
            final_success_rate = (successful / processed) * 100
            print(f"Overall success rate: {final_success_rate:.2f}%")
        else:
            print("No recipes were processed")

    except Exception as e:
        print(f"Error in generate_recipe_variations: {str(e)}")
    finally:
        print("MongoDB connection closed")


def save_validation_error(ingredient_name: str, error_message: str, nutrition_data: Dict, category: str = None):
    """
    Save validation error to a collection for manual review.
    
    Args:
        ingredient_name (str): Name of the ingredient
        error_message (str): Validation error message
        nutrition_data (Dict): The nutrition data that failed validation
        category (str): Category of the ingredient
    """
    try:
        error_doc = {
            'ingredient_name': ingredient_name,
            'error_message': error_message,
            'nutrition_data': nutrition_data,
            'category': category,
            'should_check': True,
            'created_at': datetime.utcnow(),
            'last_updated': datetime.utcnow(),
            'status': 'pending'  # pending, reviewed, fixed, ignored
        }

        # Create or get the validation_errors collection
        validation_errors_collection = recipes_collection.database['validation_errors']

        # Insert the error document
        validation_errors_collection.insert_one(error_doc)

    except Exception as e:
        print(f"Error saving validation error: {str(e)}")


def validate_nutritional_values(nutrition_data: Dict, category: str = None, ingredient_name: str = None) -> Tuple[bool, str]:
    """
    Validate nutritional values for an ingredient.
    
    Args:
        nutrition_data (Dict): Dictionary containing nutritional values
        category (str): Category of the ingredient (e.g., 'Alcoholic', 'Beverages')
        ingredient_name (str): Name of the ingredient
        
    Returns:
        Tuple[bool, str]: (is_valid, error_message)
    """
    try:
        # Extract values and convert to float
        def extract_float(value: str) -> float:
            if isinstance(value, (int, float)):
                return float(value)
            # Remove units and convert to float
            return float(str(value).replace('g', '').replace('kcal', '').strip())

        # Get values
        proteins = extract_float(nutrition_data.get('proteins_per_100g', '0'))
        carbs = extract_float(nutrition_data.get('carbohydrates_per_100g', '0'))
        fats = extract_float(nutrition_data.get('fats_per_100g', '0'))
        calories = extract_float(nutrition_data.get('calories_per_100g', '0'))

        # Check if this is an alcoholic beverage
        is_alcoholic = category in ['Alcoholic', 'Alcohol', 'Liquor', 'Fortified Wine', 'Liqueur'] or \
                       any(alcohol_term in str(category).lower() for alcohol_term in
                           ['wine', 'beer', 'spirit', 'liquor'])

        if is_alcoholic:
            # Special validation for alcoholic beverages
            if not (0 <= proteins <= 5):
                error_msg = f"Invalid protein value for alcoholic beverage: {proteins}g (should be between 0-5g)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg
            if not (0 <= carbs <= 30):
                error_msg = f"Invalid carbohydrate value for alcoholic beverage: {carbs}g (should be between 0-30g)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg
            if not (0 <= fats <= 5):
                error_msg = f"Invalid fat value for alcoholic beverage: {fats}g (should be between 0-5g)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg
            if not (0 <= calories <= 350):
                error_msg = f"Invalid calorie value for alcoholic beverage: {calories}kcal (should be between 0-350kcal)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg

        else:
            # Regular food validation
            if not (0 <= proteins <= 100):
                error_msg = f"Invalid protein value: {proteins}g (should be between 0-100g)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg
            if not (0 <= carbs <= 100):
                error_msg = f"Invalid carbohydrate value: {carbs}g (should be between 0-100g)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg
            if not (0 <= fats <= 100):
                error_msg = f"Invalid fat value: {fats}g (should be between 0-100g)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg
            if not (0 <= calories <= 900):
                error_msg = f"Invalid calorie value: {calories}kcal (should be between 0-900kcal)"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg

            # Validate total macronutrients don't exceed 100g
            total_macros = proteins + carbs + fats
            if total_macros > 100:
                error_msg = f"Total macronutrients ({total_macros}g) exceed 100g"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg

            # Validate calories match macronutrients (roughly)
            calculated_calories = (proteins * 4) + (carbs * 4) + (fats * 9)
            if abs(calculated_calories - calories) > 50:
                error_msg = f"Calorie calculation mismatch: calculated {calculated_calories}kcal vs provided {calories}kcal"
                save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                                      error_message=error_msg,
                                      nutrition_data=nutrition_data,
                                      category=category)
                return False, error_msg

        return True, "Valid nutritional values"

    except (ValueError, TypeError) as e:
        error_msg = f"Error converting values: {str(e)}"
        save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                              error_message=error_msg,
                              nutrition_data=nutrition_data,
                              category=category)
        return False, error_msg
    except Exception as e:
        error_msg = f"Validation error: {str(e)}"
        save_validation_error(ingredient_name=ingredient_name if ingredient_name else "Unknown",
                              error_message=error_msg,
                              nutrition_data=nutrition_data,
                              category=category)
        return False, error_msg


# --- Recipe-related classes and functions ---

class DynamicRecipeValidator:
    """Utility class for validating dynamic recipe parameters"""
    
    @staticmethod
    def validate_nutritional_ranges(
        calorie_min: Optional[int], calorie_max: Optional[int],
        protein_min: Optional[float], protein_max: Optional[float],
        carbs_min: Optional[float], carbs_max: Optional[float],
        fat_min: Optional[float], fat_max: Optional[float]
    ) -> None:
        """Validate nutritional range parameters"""
        # Check for negative minimum values
        if calorie_min is not None and calorie_min < 0:
            raise HTTPException(status_code=400, detail="calorie_min cannot be negative")
        
        if protein_min is not None and protein_min < 0:
            raise HTTPException(status_code=400, detail="protein_min cannot be negative")
        
        if carbs_min is not None and carbs_min < 0:
            raise HTTPException(status_code=400, detail="carbs_min cannot be negative")
        
        if fat_min is not None and fat_min < 0:
            raise HTTPException(status_code=400, detail="fat_min cannot be negative")
        
        # Check for negative maximum values
        if calorie_max is not None and calorie_max < 0:
            raise HTTPException(status_code=400, detail="calorie_max cannot be negative")
        
        if protein_max is not None and protein_max < 0:
            raise HTTPException(status_code=400, detail="protein_max cannot be negative")
        
        if carbs_max is not None and carbs_max < 0:
            raise HTTPException(status_code=400, detail="carbs_max cannot be negative")
        
        if fat_max is not None and fat_max < 0:
            raise HTTPException(status_code=400, detail="fat_max cannot be negative")
        
        # Check that min is not greater than max
        if calorie_min is not None and calorie_max is not None and calorie_min > calorie_max:
            raise HTTPException(status_code=400, detail="calorie_min cannot be greater than calorie_max")
        
        if protein_min is not None and protein_max is not None and protein_min > protein_max:
            raise HTTPException(status_code=400, detail="protein_min cannot be greater than protein_max")
        
        if carbs_min is not None and carbs_max is not None and carbs_min > carbs_max:
            raise HTTPException(status_code=400, detail="carbs_min cannot be greater than carbs_max")
        
        if fat_min is not None and fat_max is not None and fat_min > fat_max:
            raise HTTPException(status_code=400, detail="fat_min cannot be greater than fat_max")
    
    @staticmethod
    def validate_difficulty(difficulty: Optional[str]) -> None:
        """Validate preparation difficulty parameter"""
        if difficulty and difficulty not in ["Easy", "Medium", "Hard"]:
            raise HTTPException(status_code=400, detail="preparation_difficulty must be Easy, Medium, or Hard")
    
    @staticmethod
    def validate_images(images: Optional[List[UploadFile]]) -> None:
        """Validate uploaded images"""
        if images and len(images) > 3:
            raise HTTPException(status_code=400, detail="Maximum 3 images allowed")


class IngredientParser:
    """Utility class for parsing and processing ingredients"""
    
    @staticmethod
    def parse_ingredients_list(ingredients_list: Optional[str]) -> List[Dict[str, Any]]:
        """Parse ingredients list from JSON string"""
        manual_ingredients = []
        if ingredients_list:
            try:
                parsed_ingredients = json.loads(ingredients_list)
                if isinstance(parsed_ingredients, list):
                    for ingredient in parsed_ingredients:
                        if isinstance(ingredient, dict) and "name" in ingredient:
                            manual_ingredients.append({
                                "name": ingredient.get("name", ""),
                                "quantity": ingredient.get("quantity", ""),
                                "confidence": ingredient.get("confidence", 100)
                            })
                        else:
                            logger.warning(f"Invalid ingredient format: {ingredient}")
                else:
                    logger.warning("ingredients_list should be a JSON array")
            except json.JSONDecodeError as e:
                raise HTTPException(status_code=400, detail=f"Invalid JSON format for ingredients_list: {str(e)}")
        
        return manual_ingredients
    
    @staticmethod
    def deduplicate_ingredients(ingredients: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Remove duplicate ingredients based on name (case-insensitive)"""
        seen_names = set()
        unique_ingredients = []
        for ingredient in ingredients:
            name_lower = ingredient["name"].lower().strip()
            if name_lower not in seen_names:
                seen_names.add(name_lower)
                unique_ingredients.append(ingredient)
        return unique_ingredients
    
    
class PromptBuilder:
    """Utility class for building recipe generation prompts"""
    
    @staticmethod
    def build_recipe_prompt(
        available_ingredients: List[Dict[str, Any]],
        min_calories: Optional[int], max_calories: Optional[int],
        min_proteins: Optional[float], max_proteins: Optional[float],
        min_carbs: Optional[float], max_carbs: Optional[float],
        min_fats: Optional[float], max_fats: Optional[float],
        diet_type: Optional[str],
        recipe_description: Optional[str],
        difficulty: Optional[str],
        limit: int = 5,
        lang: str = "en",
        max_prep_time: Optional[int] = None
    ) -> str:
        """Build the complete prompt for recipe generation"""
        prompt_parts = []
        constraint_parts = []
        
        # Add available ingredients if found
        if available_ingredients:
            ingredient_list = []
            for ingredient in available_ingredients:
                source = "manual" if ingredient.get("confidence", 0) == 100 else "image"
                ingredient_list.append(f"- {ingredient['name']} ({ingredient['quantity']}) [from {source}]")
            ingredients_text = "\n".join(ingredient_list)
            prompt_parts.append(f"Available ingredients:\n{ingredients_text}")
            prompt_parts.append("Please use these ingredients in the recipes when possible (ignore spices), please not use ingredient that not in the list, you can ignore spices (not must to be in the list) but can be within the recipe.")
        
        # Nutritional requirements with default ranges
        def adjust_min_max(min_val, max_val, is_float=False):
            if (min_val is None or min_val == 0) and max_val is not None:
                adj_min = round(max_val * 0.9, 1) if is_float else int(max_val * 0.9)
                return adj_min, max_val
            return min_val if min_val is not None else 0, max_val

        calorie_min_val, calorie_max_val = adjust_min_max(min_calories, max_calories)
        # Only add calories to prompt if at least one is nonzero
        if not (calorie_min_val == 0 and calorie_max_val == 0):
            if calorie_min_val == 0:
                constraint_parts.append(f"Calories: max {calorie_max_val} calories (aim to be close to this value)")
            elif calorie_min_val != calorie_max_val:
                constraint_parts.append(f"Calories: {calorie_min_val}-{calorie_max_val} calories (aim to be close to the upper bound)")
            else:
                constraint_parts.append(f"Calories: {calorie_max_val} calories")

        protein_min_val, protein_max_val = adjust_min_max(min_proteins, max_proteins, is_float=True)
        if protein_min_val == 0:
            constraint_parts.append(f"Protein: max {protein_max_val}g (aim to be close to this value)")
        elif protein_min_val != protein_max_val:
            constraint_parts.append(f"Protein: {protein_min_val}-{protein_max_val}g (aim to be close to the upper bound)")
        else:
            constraint_parts.append(f"Protein: {protein_max_val}g")

        # carbs_min_val, carbs_max_val = adjust_min_max(min_carbs, max_carbs, is_float=True)
        # if carbs_min_val == 0:
        #     constraint_parts.append(f"Carbohydrates: max {carbs_max_val}g (aim to be close to this value)")
        # elif carbs_min_val != carbs_max_val:
        #     constraint_parts.append(f"Carbohydrates: {carbs_min_val}-{carbs_max_val}g (aim to be close to the upper bound)")
        # else:
        #     constraint_parts.append(f"Carbohydrates: {carbs_max_val}g")
        #
        # fat_min_val, fat_max_val = adjust_min_max(min_fats, max_fats, is_float=True)
        # if fat_min_val == 0:
        #     constraint_parts.append(f"Fat: max {fat_max_val}g (aim to be close to this value)")
        # elif fat_min_val != fat_max_val:
        #     constraint_parts.append(f"Fat: {fat_min_val}-{fat_max_val}g (aim to be close to the upper bound)")
        # else:
        #     constraint_parts.append(f"Fat: {fat_max_val}g")
        
        # Dietary preference
        if diet_type:
            constraint_parts.append(f"Dietary preference: {diet_type}")
        else:
            constraint_parts.append("Dietary preference: flexible (any diet type allowed)")
        
        # Recipe description
        if recipe_description:
            constraint_parts.append(f"Recipe description: {recipe_description}")
        else:
            constraint_parts.append("Recipe description: Create a delicious and nutritious meal")
        
        # Preparation difficulty
        if difficulty:
            constraint_parts.append(f"Preparation difficulty: {difficulty}")
        else:
            constraint_parts.append("Preparation difficulty: Any level (Easy, Medium, or Hard)")
        
        # Maximum preparation time
        if max_prep_time:
            constraint_parts.append(f"Maximum preparation time: {max_prep_time} minutes")
        
        # Number of recipes to generate
        prompt_parts.append(f"Generate {limit} recipe(s)")
        
        # Language instruction
        if lang.lower() == "he":
            prompt_parts.append("IMPORTANT: Generate the recipe in Hebrew language. All text should be in Hebrew.")
        elif lang.lower() != "en":
            prompt_parts.append(f"IMPORTANT: Generate the recipe in {lang} language.")
        
        # --- Protein constraint clarification logic ---
        protein_constraint_text = ""
        if protein_min_val and protein_max_val:
            protein_constraint_text = (
                f"Protein: Must be between {protein_min_val}–{protein_max_val}g regardless of calorie level. "
                "This takes precedence over other calculations. Do not adjust downward based on calorie estimate.\n"
                f"Do not reduce protein target below {protein_min_val}g. If necessary, increase calories to accommodate.\n"
                "If available ingredients are insufficient to meet protein target, explain that and fallback to highest possible protein using listed ingredients.\n"
            )
        elif protein_max_val:
            protein_constraint_text = (
                f"Protein: Must be at least {protein_max_val}g regardless of calorie level. "
                "This takes precedence over other calculations. Do not adjust downward based on calorie estimate.\n"
                f"Do not reduce protein target below {protein_max_val}g. If necessary, increase calories to accommodate.\n"
                "If available ingredients are insufficient to meet protein target, explain that and fallback to highest possible protein using listed ingredients.\n"
            )
        # --- End protein constraint clarification logic ---

        # Build the complete prompt
        constraint_text = "\n".join(constraint_parts) if constraint_parts else "No specific requirements"
        requirements_text = "\n".join(prompt_parts) if prompt_parts else "No specific requirements"

        final_prompt =  f"""
        Generate 5 nutritious and delicious recipes using only the provided list of ingredients.  
        If no ingredients are provided — generate a free-form recipe.
        
        ✅ Water and spices may be used optionally even if not listed.  
        ✅ Macronutrients must be aligned and calculated from valid nutritional databases (see below).
        
        ⚠️ Constraints and Rules:
        
        - If "calories" is provided by the user, automatically calculate a suitable protein range (typically 15–30% of total kcal).
        - If "protein" is provided and "calories" is missing, estimate the total calories based on standard macros (4 kcal per gram protein).
        - If both "calories" and "protein" are missing, use a default balanced nutritional profile (e.g., 500–700 kcal, 20–30g protein).
        
        {protein_constraint_text}
        {constraint_text}         
        
        {requirements_text}
        
        
          The dietary preference is flexible (any type of diet is allowed).
          Any preparation difficulty (easy, medium, hard) is acceptable.
          
          \n\n
          Each recipe must include:\n
          1. A title\n
          2. A short description\n
          3. A list of used ingredients with amounts and measurement units\n
          4. Detailed preparation steps\n
          5. Nutrition facts: calories, protein, carbs, fat\n
          6. The source used for nutritional values (e.g., https://www.fatsecret.com/calories-nutrition/usda or https://fdc.nal.usda.gov/)\n
          7. The source used for possible measurements (same as above or other valid nutritional databases)\n\n
          
          - Do not include markdown formatting, explanations, or text outside the JSON object.\n
          - Each nutritional value must include a source.\n
          - Each measurement used for an ingredient must include a source.\n
          - No other text is allowed in the response."
               
        
            IMPORTANT: take calorie data from https://www.fatsecret.com/calories-nutrition/usda or https://fdc.nal.usda.gov/ other but write me the source
            IMPORTANT: take possible_measurement from https://www.fatsecret.com/calories-nutrition/usda or https://fdc.nal.usda.gov/ other but write me the source and the weight

                        Return a JSON object with the following structure:
                        {{
                            "recipes": [
                                {{
                                    "name": "Recipe Name",
                                    "description": "Brief description",
                                    "ingredients": [
                                        {{
                                            "name": "ingredient name",
                                            "amount": "quantity",
                                            "unit": "measurement unit",
                                            "calories": 400, (per amount)
                                            "protein": 20, (per amount)
                                            "carbohydrates": 30, (per amount)
                                            "fat": 15, (per amount)
                                            "fiber": 5, (per amount)
                                        }}
                                    ],
                                       "base_ingredient_name": ["List of all base ingredients without any modifications / counts, singular and plural for this ingredient write in english (add the type example Apple (Granny_Smith)) "],                            

                                    "instructions": [
                                        "step 1",
                                        "step 2",
                                        "step 3"
                                    ],
                                    "nutritional_info": {{
                                        "calories": 400,
                                        "protein": 20,
                                        "carbohydrates": 30,
                                        "fat": 15,
                                        "fiber": 5
                                    }},
                                     "macronutrients": {{     
                                "data_source": "site name",                           
                                "weight: "gr/ml",                              
                                "proteins": "protein content in grams (e.g., '15.2g')",
                                "carbohydrates": "carbohydrate content in grams (e.g., '45.2g')",
                                "fats": "fat content in grams (e.g., '12.2g')",
                                "calories": "calorie content (e.g., '350.2kcal')"
                            }},
                            
                            "macronutrients_per_for_this_meal_100g": {{                                
                                "proteins": "Calculate total protein content per 100g of the final dish - must be a float number and must filled",
                                "carbohydrates": "Calculate total carbohydrate content per 100g of the final dish - must be a float number and must filled",
                                "fats": "Calculate total fat content per 100g of the final dish - must be a float number and must filled",
                                "calories": "Calculate total calories per 100g of the final dish - must be a float number and must filled"
                            }},
                                    "preparation_time": "30 minutes",
                                    "cooking_time": "45 minutes",
                                    "difficulty": "Easy",
                                    "servings": 4,
                                     "cusine": "ex: Amirican / Asian / French",
                                    "course": "One of [Breakfast, Lunch, Dinner, Snack, Any]",                                                                
                                    "dietary_tags": ["vegetarian", "gluten-free"],
                                     "health_rank": "number between 1-100",
                                    "tasty_rank": "number between 1-100",
                                    "health_recommendations": {{
                                        "benefits": ["List of health benefits"],
                                        "considerations": ["List of health considerations or warnings"],
                                        "suitable_for": [
                                           "List of dietary types or health conditions this recipe is suitable for, e.g., vegan, vegetarian, keto, paleo, kosher, halal, gluten-free, dairy-free, low-carb, diabetic-friendly, heart-healthy, weight loss, anti-inflammatory, low-sodium"
                                        ],
                                        "not_suitable_for": [
                                           "List of dietary types or health conditions this recipe is not suitable for, e.g., not kosher, not vegetarian, not gluten-free, not halal, contains pork, high cholesterol, hypertension, diabetes, IBS, kidney disease"
                                        ]
                                    }},
                                    "allergens": ["List of potential allergens"],
                                    "allergen_free": ["List of allergens this recipe is free from"]
                                }}
                            ],
                            "total_recipes": {limit},
                            "recommendations": ["suggestion 1", "suggestion 2"],
                            "available_ingredients_used": ["ingredient1", "ingredient2"]
                        }}
                        
                        serving size always for one persian, please adjust the recipe as needed!
                        Generate {limit} recipe(s) that meet(s) the specified requirements. Ensure all JSON is properly formatted with correct quotes, commas, and brackets."""

        return final_prompt

class RecipeGenerator:
    """Utility class for generating recipes using AI"""
    
    @staticmethod
    async def generate_recipe_with_ai(prompt: str, image_urls: List[str]) -> Dict[str, Any]:
        """Generate recipe using OpenRouter API"""
        content = [{"type": "text", "text": prompt}]
        
        # Add images if provided
        for image_url in image_urls:
            local_path = image_url.replace(f"https://{MY_SERVER_NAME}/api/uploads/", "/home/data/kaila/uploads/recipe/")
            encode_data = ImageProcessor.encode_image(local_path)
            encoded_image_url = f"data:image/jpeg;base64,{encode_data}"
            
            content.append({
                "type": "image_url",
                "image_url": {
                    "url": encoded_image_url,
                    "detail": "high"
                }
            })

        max_retries = 2
        for retry_attempt in range(max_retries + 1):
            try:
                async with httpx.AsyncClient(timeout=httpx.Timeout(30.0, connect=10.0)) as client:
                    body = {
                        "model": BASE_MODEL_NAME,
                        "messages": [
                            {
                                "role": "user",
                                "content": content
                            }
                        ],
                        "temperature": 0.7,
                        "response_format": {"type": "json_object"}
                    }
                    
                    response = await client.post(
                        "https://openrouter.ai/api/v1/chat/completions",
                        headers={"Authorization": f"Bearer {OPENROUTER_API_KEY}", "Content-Type": "application/json"},
                        json=body,
                        timeout=RECIPE_GENERATION_TIMEOUT
                    )
                    
                    if response.status_code == 200:
                        response_data = response.json()
                        return response_data["choices"][0]["message"]["content"]
                    elif response.status_code == 429 and retry_attempt < max_retries:
                        wait_time = 2 ** retry_attempt
                        await asyncio.sleep(wait_time)
                        continue
                    elif response.status_code >= 500 and retry_attempt < max_retries:
                        wait_time = 1 * (retry_attempt + 1)
                        await asyncio.sleep(wait_time)
                        continue
                    else:
                        break
                        
            except (httpx.TimeoutException, httpx.ConnectError) as e:
                if retry_attempt < max_retries:
                    wait_time = 1 * (retry_attempt + 1)
                    await asyncio.sleep(wait_time)
                    continue
                else:
                    raise e
        
        raise HTTPException(status_code=500, detail="Failed to generate recipe after multiple attempts")



class ResponseBuilder:
    """Utility class for building response objects"""
    
    @staticmethod
    def build_empty_response() -> Dict[str, Any]:
        """Build empty response when no ingredients are found"""
        return {
            "recipes": [
                {
                    "name": "No Ingredients Available",
                    "description": "No ingredients were found in the images or provided in the ingredients list. Please provide ingredients or upload images with visible food items.",
                    "ingredients": [],
                    "instructions": [
                        "Please provide ingredients using one of the following methods:",
                        "1. Upload images containing visible food items",
                        "2. Use the ingredients_list parameter to specify available ingredients",
                        "3. Try with different images or ingredient combinations"
                    ],
                    "nutritional_info": {
                        "calories": 0,
                        "protein": 0,
                        "carbohydrates": 0,
                        "fat": 0,
                        "fiber": 0
                    },
                    "preparation_time": "N/A",
                    "cooking_time": "N/A",
                    "difficulty": "N/A",
                    "servings": 0,
                    "dietary_tags": ["no-ingredients"]
                }
            ],
            "total_recipes": 1,
            "recommendations": [
                "Upload clear images of your refrigerator or pantry",
                "Provide a list of available ingredients using the ingredients_list parameter",
                "Ensure images contain visible food items",
                "Try with different dietary preferences or nutritional requirements"
            ],
            "available_ingredients": [],
            "total_ingredients_found": 0,
            "ingredients_from_images": 0,
            "ingredients_from_manual": 0,
            "comment": "No ingredients found in images or provided in ingredients list. Please provide ingredients to generate recipes.",
            "status": "no_ingredients"
        }
    
    @staticmethod
    def build_error_response(error_type: str, error_message: str, available_ingredients: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Build error response for various error scenarios"""
        error_templates = {
            "network_error": {
                "name": "Network Error",
                "description": "Unable to connect to recipe generation service. Please check your internet connection.",
                "instructions": [
                    "Check your internet connection",
                    "Try again in a few minutes",
                    "Contact support if the problem persists"
                ],
                "dietary_tags": ["network_error"]
            },
            "api_error": {
                "name": "API Service Unavailable",
                "description": "Recipe generation service is temporarily unavailable. Please try again later.",
                "instructions": [
                    "Please try again in a few minutes",
                    "If the problem persists, contact support",
                    "Consider using manual ingredient input"
                ],
                "dietary_tags": ["service_unavailable"]
            },
            "parsing_error": {
                "name": "Recipe Generation Error",
                "description": "Unable to generate recipes due to technical issues. Please try again.",
                "instructions": [
                    "Please try the request again",
                    "If the problem persists, try with different parameters",
                    "Consider using fewer ingredients or simpler requirements"
                ],
                "dietary_tags": ["error"]
            }
        }
        
        template = error_templates.get(error_type, error_templates["parsing_error"])
        
        return {
            "recipes": [
                {
                    "name": template["name"],
                    "description": template["description"],
                    "ingredients": [
                        {
                            "name": "Available ingredients",
                            "amount": "As needed",
                            "unit": "pieces"
                        }
                    ],
                    "instructions": template["instructions"],
                    "nutritional_info": {
                        "calories": 0,
                        "protein": 0,
                        "carbohydrates": 0,
                        "fat": 0,
                        "fiber": 0
                    },
                    "preparation_time": "N/A",
                    "cooking_time": "N/A",
                    "difficulty": "N/A",
                    "servings": 0,
                    "dietary_tags": template["dietary_tags"]
                }
            ],
            "total_recipes": 1,
            "recommendations": [
                "Try again in a few minutes",
                "Check your internet connection",
                "Contact support if the issue persists"
            ],
            "error": error_message,
            "available_ingredients": available_ingredients,
            "total_ingredients_found": len(available_ingredients)
        }
    
    @staticmethod
    def add_metadata_to_response(response: Dict[str, Any], available_ingredients: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Add metadata to the response"""
        if available_ingredients:
            response["available_ingredients"] = available_ingredients
            response["total_ingredients_found"] = len(available_ingredients)
            response["ingredients_from_images"] = len([i for i in available_ingredients if i.get("confidence", 0) != 100])
            response["ingredients_from_manual"] = len([i for i in available_ingredients if i.get("confidence", 0) == 100])
        return response



class FileManager:
    """Utility class for file management operations"""
    
    @staticmethod
    def cleanup_old_files(folder_path: str, max_files: int = 1000) -> None:
        """Clean up old files, keeping only the most recent ones"""
        try:
            files = [(f, os.path.getmtime(os.path.join(folder_path, f))) 
                    for f in os.listdir(folder_path) 
                    if os.path.isfile(os.path.join(folder_path, f))]
            files.sort(key=lambda x: x[1])
            
            while len(files) > max_files:
                oldest_file = files.pop(0)
                os.remove(os.path.join(folder_path, oldest_file[0]))
                logger.info(f"Removed old file: {oldest_file[0]}")
        except Exception as e:
            logger.error(f"Error cleaning up folder {folder_path}: {str(e)}")
    
    @staticmethod
    def save_response_to_mock(response: Dict[str, Any], filename: str = 'get_dynamic_get_recipe.json') -> None:
        """Save response to mock folder for testing"""
        try:
            os.makedirs(MOCK_FOLDER, exist_ok=True)
            response_file_path = os.path.join(MOCK_FOLDER, filename)
            if not os.path.exists(response_file_path):
                with open(response_file_path, 'w') as f:
                    json.dump(response, f, indent=2)
                logger.info(f"Response saved to {response_file_path}")
            else:
                logger.info(f"Mock file already exists: {response_file_path}")
        except Exception as e:
            logger.error(f"Failed to save response to mock file: {str(e)}")
            # Don't raise the exception to avoid breaking the main flow



def parse_ai_json_response(result: str) -> Dict[str, Any]:
    """Parse AI JSON response with error handling and JSON repair"""
    try:
        return json.loads(result)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse AI response: {str(e)}")
        logger.error(f"Raw response: {result[:500]}...")
        
        # Try smart repair first (uses error position for targeted fixes)
        try:
            smart_repaired = smart_json_repair(result, e.pos)
            return json.loads(smart_repaired)
        except Exception as smart_error:
            logger.error(f"Smart JSON repair failed: {str(smart_error)}")
            
            # Try comprehensive repair
            try:
                comprehensive_repaired = comprehensive_json_repair(result, e.pos)
                return json.loads(comprehensive_repaired)
            except Exception as comprehensive_error:
                logger.error(f"Comprehensive JSON repair failed: {str(comprehensive_error)}")
                
                # Try the original repair functions as fallback
                try:
                    repaired_json = repair_json_response(result, e.pos)
                    return json.loads(repaired_json)
                except Exception as repair_error:
                    logger.error(f"Basic JSON repair failed: {str(repair_error)}")
                    
                    # Try aggressive repair as last resort
                    try:
                        aggressive_repaired = aggressive_json_repair(result)
                        return json.loads(aggressive_repaired)
                    except Exception as aggressive_error:
                        logger.error(f"Aggressive JSON repair also failed: {str(aggressive_error)}")
                        raise e

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

def get_simple_meal_analysis_prompt():
    """Get the simple meal image analysis prompt for OpenAI V1 (used for basic meal nutrition extraction)."""
    return """
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


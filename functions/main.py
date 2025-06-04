# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
from datetime import datetime, timedelta
import json
import random
import smtplib
import os

# Initialize Firebase app
app = initialize_app()

def calculate_bmr(weight, height, age, gender):
    """Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation"""
    if gender.lower() == 'male':
        return (10 * weight) + (6.25 * height) - (5 * age) + 5
    else:
        return (10 * weight) + (6.25 * height) - (5 * age) - 161

def calculate_daily_needs(bmr, activity_level, goal):
    """Calculate daily caloric needs based on activity and goal"""
    activity_multipliers = {
        'sedentary': 1.2,
        'light': 1.375,
        'moderate': 1.55,
        'active': 1.725,
        'very_active': 1.9
    }
    
    tdee = bmr * activity_multipliers.get(activity_level, 1.2)
    
    goal_adjustments = {
        'lose_weight': -500,    # Caloric deficit for weight loss
        'gain_weight': 500,     # Caloric surplus for weight gain
        'maintain_weight': 0,   # No adjustment for maintenance
        'build_muscle': 300,    # Slight surplus for muscle gain
    }
    
    daily_calories = tdee + goal_adjustments.get(goal, 0)
    return max(1200, daily_calories)  # Ensure minimum healthy calories

def calculate_macros(daily_calories, goal):
    """Calculate macronutrient distribution based on goal"""
    if goal == 'build_muscle':
        protein_pct = 0.30
        fat_pct = 0.25
        carbs_pct = 0.45
    elif goal == 'lose_weight':
        protein_pct = 0.35
        fat_pct = 0.30
        carbs_pct = 0.35
    else:  # maintain_weight or gain_weight
        protein_pct = 0.25
        fat_pct = 0.25
        carbs_pct = 0.50
    
    protein_cals = daily_calories * protein_pct
    fat_cals = daily_calories * fat_pct
    carbs_cals = daily_calories * carbs_pct
    
    return {
        'protein_g': round(protein_cals / 4),  # 4 calories per gram of protein
        'fats_g': round(fat_cals / 9),         # 9 calories per gram of fat
        'carbs_g': round(carbs_cals / 4)       # 4 calories per gram of carbs
    }

@https_fn.on_request()
def calculate_nutrition_plan(req: https_fn.Request) -> https_fn.Response:
    """Handle nutrition plan calculation request"""
    try:
        # Get data from request
        data = req.get_json()
        
        # Extract required parameters
        weight = float(data.get('weight', 70))  # in kg
        height = float(data.get('height', 170))  # in cm
        age = int(data.get('age', 25))
        gender = data.get('gender', 'male')
        activity_level = data.get('activity_level', 'moderate')
        goal = data.get('goal', 'maintain_weight')
        target_weight = float(data.get('target_weight', weight))
        
        # Calculate BMR
        bmr = calculate_bmr(weight, height, age, gender)
        
        # Calculate daily caloric needs
        daily_calories = calculate_daily_needs(bmr, activity_level, goal)
        
        # Calculate macronutrient distribution
        macros = calculate_macros(daily_calories, goal)
        
        # Calculate weight change timeline
        weight_diff = abs(target_weight - weight)
        weekly_change = 0.5 if goal in ['lose_weight', 'gain_weight'] else 0
        weeks_to_goal = round(weight_diff / weekly_change) if weekly_change > 0 else 0
        target_date = datetime.now() + timedelta(weeks=weeks_to_goal)
        
        # Calculate BMI
        bmi = weight / ((height/100) ** 2)
        
        response_data = {
            'daily_calories': round(daily_calories),
            'protein_g': macros['protein_g'],
            'carbs_g': macros['carbs_g'],
            'fats_g': macros['fats_g'],
            'bmr': round(bmr),
            'bmi': round(bmi, 1),
            'target_date': target_date.strftime('%Y-%m-%d'),
            'weeks_to_goal': weeks_to_goal
        }
        
        return https_fn.Response(
            json.dumps(response_data),
            status=200,
            headers={'Content-Type': 'application/json'}
        )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=400,
            headers={'Content-Type': 'application/json'}
        )

# Import our custom helper module
from openai_helper import analyze_image_with_vision

# OpenAI function for analyzing meal images
@https_fn.on_request()
def analyze_meal_image(req: https_fn.Request) -> https_fn.Response:
    """Analyze meal image using OpenAI Vision API"""
    try:
        # Get data from request
        data = req.get_json()
        image_url = data.get('image_url')
        image_name = data.get('image_name', 'unknown.jpg')
        function_info = data.get('function_info', {})
        
        print(f"Received analysis request for image: {image_name}")
        print(f"Image URL length: {len(image_url) if image_url else 0}")
        
        if not image_url:
            return https_fn.Response(
                json.dumps({'error': 'No image URL provided'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )
            
        if not image_url.startswith(('http://', 'https://')):
            return https_fn.Response(
                json.dumps({'error': 'Invalid image URL format. Must start with http:// or https://'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )

        print(f"Processing image URL: {image_url[:50]}...")
        
        prompt = """
Analyze this meal image and provide detailed nutritional information in JSON format. Include:
1. Meal identification
2. Accurate calorie estimation
3. Detailed macro breakdown (in grams)
4. List of ingredients
5. A categorical healthiness value (e.g., 'healthy', 'medium', 'unhealthy')
6. Detailed health assessment text
7. Source URL for more information

Additionally, return the meal name and the list of ingredients in three languages: English, Hebrew, and Russian.

Format the response as:
{
  'mealName': {'en': '...', 'he': '...', 'ru': '...'},
  'estimatedCalories': number (e.g., 670),
  'macros': {
    'proteins': 'Xg (e.g., 30g)',
    'carbohydrates': 'Xg (e.g., 50g)',
    'fats': 'Xg (e.g., 40g)'
  },
  'ingredients': {
    'en': ['...', '...'],
    'he': ['...', '...'],
    'ru': ['...', '...']
  },
  'healthiness': 'healthy' | 'medium' | 'unhealthy' | 'N/A',
  'health_assessment': 'Detailed health assessment of the meal',
  'source': 'A valid URL (starting with http or https) for more information about this meal'
}

Important:
- Provide realistic calorie and macro values based on visible portions.
- Ensure 'estimatedCalories' is a number.
- Ensure macros (proteins, carbohydrates, fats) are strings ending with 'g'.
- The 'healthiness' field should be one of 'healthy', 'medium', 'unhealthy', or 'N/A'.
- Provide a comprehensive 'health_assessment' string.
- The source field MUST be a valid URL, defaulting to https://fdc.nal.usda.gov/ if needed.
- All translations must be accurate and contextually appropriate for food.
"""

        try:
            # Using the custom analyze_image_with_vision function from openai_helper
            raw_analysis_output = analyze_image_with_vision(image_url, prompt)
            
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
                        final_json_payload_str = json.dumps(parsed_json) # Re-serialize for clean output
                    except json.JSONDecodeError as e:
                        error_message = f"Could not parse extracted JSON (from braces) from vision API output. Error: {str(e)}. Candidate snippet: {json_str_candidate[:200]}"
                        print(error_message)
                        raise Exception(error_message) from e
                else:
                    # If no '{...}' found, try to parse the text_to_parse directly
                    try:
                        parsed_json = json.loads(text_to_parse)
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
        print(f"Error in analyze_meal_image function: {str(e)}")
        import traceback
        traceback_str = traceback.format_exc()
        print(f"Full traceback: {traceback_str}")
        
        return https_fn.Response(
            json.dumps({
                'error': str(e),
                'traceback': traceback_str,
                'fallback_analysis': {
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
            }),
            status=200,  # Return 200 with error info instead of 500
            headers={'Content-Type': 'application/json'}
        )

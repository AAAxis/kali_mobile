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
from service import (
    analyze_meal_image_v1_service,
    analyze_meal_image_v2_service,
    analyze_refrigerator_service,
    analyze_invoice_service,
    get_recipe_service
)

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
def analyze_meal_image_v1(req: Request) -> Response:
    return analyze_meal_image_v1_service(req)

# OpenAI function for analyzing meal images (V2 - Enhanced)
@https_fn.on_request()
def analyze_meal_image_v2(req: Request) -> Response:
    return analyze_meal_image_v2_service(req)

# Refrigerator Analysis Function
@https_fn.on_request()
def analyze_refrigerator(req: Request) -> Response:
    return analyze_refrigerator_service(req)

# Invoice Analysis Function
@https_fn.on_request()
def analyze_invoice(req: Request) -> Response:
    return analyze_invoice_service(req)

@https_fn.on_request()
def get_recipe(req: Request) -> Response:
    return get_recipe_service(req)


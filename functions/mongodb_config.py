#!/usr/bin/env python3
"""
MongoDB configuration and helper functions for the Kali Mobile Firebase Functions
"""

import os
import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any

# Configure logging
logger = logging.getLogger(__name__)

# MongoDB Configuration
try:
    from pymongo import MongoClient
    from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
    from dotenv import load_dotenv
    
    # Load environment variables from .env file
    load_dotenv()
    
    # Get MongoDB credentials and connection parameters
    username = os.environ.get("MONGO_INITDB_ROOT_USERNAME")
    password = os.environ.get("MONGO_INITDB_ROOT_PASSWORD")
    host = os.environ.get("MONGO_HOST", "localhost")
    port = os.environ.get("MONGO_PORT", "27017")
    db_name = os.environ.get("MONGO_DB_NAME", "admin")
    MONGODB_DB = os.environ.get("MONGODB_DB", "kali_mobile")
    
    # Check if credentials are available
    if not username or not password:
        logger.warning("MongoDB credentials not found. Using default localhost connection without authentication.")
        MONGODB_URI = f"mongodb://{host}:{port}/"
    else:
        # Import quote_plus for URL encoding
        from urllib.parse import quote_plus
        
        # Encode credentials
        username_quoted = quote_plus(str(username))
        password_quoted = quote_plus(str(password))
        
        # Build MongoDB URI
        MONGODB_URI = f"mongodb://{username_quoted}:{password_quoted}@{host}:{port}/{db_name}?authSource=admin"
        logger.info(f"🔐 MongoDB authentication enabled for user: {username}")
    
    # Additional MongoDB configuration (optional)
    MONGODB_AUTH_MECHANISM = os.environ.get("MONGODB_AUTH_MECHANISM", "SCRAM-SHA-1")
    
    # Connection timeout settings
    CONNECT_TIMEOUT_MS = int(os.environ.get("MONGODB_CONNECT_TIMEOUT_MS", "5000"))
    SERVER_SELECTION_TIMEOUT_MS = int(os.environ.get("MONGODB_SERVER_SELECTION_TIMEOUT_MS", "5000"))
    SOCKET_TIMEOUT_MS = int(os.environ.get("MONGODB_SOCKET_TIMEOUT_MS", "20000"))
    MAX_POOL_SIZE = int(os.environ.get("MONGODB_MAX_POOL_SIZE", "10"))
    MIN_POOL_SIZE = int(os.environ.get("MONGODB_MIN_POOL_SIZE", "1"))
    
    # Build connection options
    connection_options = {
        "serverSelectionTimeoutMS": SERVER_SELECTION_TIMEOUT_MS,
        "connectTimeoutMS": CONNECT_TIMEOUT_MS,
        "socketTimeoutMS": SOCKET_TIMEOUT_MS,
        "maxPoolSize": MAX_POOL_SIZE,
        "minPoolSize": MIN_POOL_SIZE
    }
    
    # Authentication is now handled in the URI, so we don't need separate auth options
    if username and password:
        logger.info(f"🔐 MongoDB authentication configured via URI for user: {username}")
    else:
        logger.info("🔓 MongoDB connection without authentication")
    
    # Initialize MongoDB client
    client = MongoClient(MONGODB_URI, **connection_options)
    db = client[MONGODB_DB]
    
    # Test connection
    client.admin.command('ping')
    logger.info(f"✅ MongoDB connection established successfully to {MONGODB_URI}")
    logger.info(f"📊 Database: {MONGODB_DB}")
    
    # Get collection names from environment variables with defaults
    INGREDIENTS_COLLECTION = os.environ.get("MONGODB_INGREDIENTS_COLLECTION", "ingredients")
    VALIDATION_ERRORS_COLLECTION = os.environ.get("MONGODB_VALIDATION_ERRORS_COLLECTION", "validation_errors")
    MEAL_ANALYSIS_COLLECTION = os.environ.get("MONGODB_MEAL_ANALYSIS_COLLECTION", "meal_analysis")
    INGREDIENT_NAMES_COLLECTION = os.environ.get("MONGODB_INGREDIENT_NAMES_COLLECTION", "ingredient_names_v5")
    NORMALIZED_INGREDIENTS_COLLECTION = os.environ.get("MONGODB_NORMALIZED_INGREDIENTS_COLLECTION", "normalized_ingredients_v5")
    INGREDIENTS_NUTRITION_COLLECTION = os.environ.get("MONGODB_INGREDIENTS_NUTRITION_COLLECTION", "ingredients_nutrition_v5")
    INGREDIENT_CATEGORIES_COLLECTION = os.environ.get("MONGODB_INGREDIENT_CATEGORIES_COLLECTION", "ingredient_categories_v5")
    
    # Define collections
    ingredients_collection = db[INGREDIENTS_COLLECTION]
    validation_errors_collection = db[VALIDATION_ERRORS_COLLECTION]
    meal_analysis_collection = db[MEAL_ANALYSIS_COLLECTION]
    ingredient_names_collection = db[INGREDIENT_NAMES_COLLECTION]
    normalized_ingredients_collection = db[NORMALIZED_INGREDIENTS_COLLECTION]
    ingredients_nutrition_collection = db[INGREDIENTS_NUTRITION_COLLECTION]
    ingredient_categories_collection = db[INGREDIENT_CATEGORIES_COLLECTION]
    
    logger.info(f"📁 Collections configured: {INGREDIENTS_COLLECTION}, {VALIDATION_ERRORS_COLLECTION}, {MEAL_ANALYSIS_COLLECTION}")
    
except Exception as e:
    logger.error(f"❌ MongoDB connection failed: {str(e)}")
    client = None
    db = None
    ingredients_collection = None
    validation_errors_collection = None
    meal_analysis_collection = None
    ingredient_names_collection = None
    normalized_ingredients_collection = None
    ingredients_nutrition_collection = None
    ingredient_categories_collection = None

def save_validation_error(ingredient_name: str, error_details: dict, original_data: dict = None) -> bool:
    """
    Save validation errors to MongoDB for manual review
    
    Args:
        ingredient_name: Name of the ingredient that failed validation
        error_details: Dictionary containing validation error details
        original_data: Original data that caused the validation error
        
    Returns:
        bool: True if saved successfully, False otherwise
    """
    try:
        if validation_errors_collection is None:
            logger.warning("MongoDB validation_errors collection not available")
            return False
            
        error_document = {
            "ingredient_name": ingredient_name,
            "error_details": error_details,
            "original_data": original_data,
            "timestamp": datetime.utcnow(),
            "status": "pending_review"
        }
        
        result = validation_errors_collection.insert_one(error_document)
        logger.info(f"✅ Validation error saved for {ingredient_name} with ID: {result.inserted_id}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to save validation error for {ingredient_name}: {str(e)}")
        return False

def save_ingredient_to_mongo(ingredient_data: dict) -> bool:
    """
    Save ingredient data to MongoDB
    
    Args:
        ingredient_data: Dictionary containing ingredient information
        
    Returns:
        bool: True if saved successfully, False otherwise
    """
    try:
        if ingredients_collection is None:
            logger.warning("MongoDB ingredients collection not available")
            return False
            
        # Add timestamp
        ingredient_data["created_at"] = datetime.utcnow()
        ingredient_data["updated_at"] = datetime.utcnow()
        
        result = ingredients_collection.insert_one(ingredient_data)
        logger.info(f"✅ Ingredient saved to MongoDB with ID: {result.inserted_id}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to save ingredient to MongoDB: {str(e)}")
        return False

def save_meal_analysis_to_mongo(analysis_data: dict) -> bool:
    """
    Save meal analysis data to MongoDB
    
    Args:
        analysis_data: Dictionary containing meal analysis information
        
    Returns:
        bool: True if saved successfully, False otherwise
    """
    try:
        if meal_analysis_collection is None:
            logger.warning("MongoDB meal_analysis collection not available")
            return False
            
        # Add timestamp
        analysis_data["created_at"] = datetime.utcnow()
        
        result = meal_analysis_collection.insert_one(analysis_data)
        logger.info(f"✅ Meal analysis saved to MongoDB with ID: {result.inserted_id}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to save meal analysis to MongoDB: {str(e)}")
        return False

def validate_nutrition_data(ingredient_name: str, nutrition_data: dict) -> Tuple[bool, dict]:
    """
    Validate nutrition data for an ingredient
    
    Args:
        ingredient_name: Name of the ingredient
        nutrition_data: Dictionary containing nutrition information
        
    Returns:
        tuple: (is_valid, error_details)
    """
    errors = []
    
    try:
        # Check required fields
        required_fields = ["proteins", "carbohydrates", "fats", "calories"]
        for field in required_fields:
            if field not in nutrition_data:
                errors.append(f"Missing required field: {field}")
            elif not nutrition_data[field]:
                errors.append(f"Empty value for required field: {field}")
        
        # Validate numeric values
        numeric_fields = ["proteins", "carbohydrates", "fats", "calories"]
        for field in numeric_fields:
            if field in nutrition_data and nutrition_data[field]:
                try:
                    value = float(str(nutrition_data[field]).replace("g", "").replace("kcal", ""))
                    if value < 0:
                        errors.append(f"Negative value for {field}: {value}")
                    if value > 10000:  # Reasonable upper limit
                        errors.append(f"Unrealistically high value for {field}: {value}")
                except ValueError:
                    errors.append(f"Invalid numeric value for {field}: {nutrition_data[field]}")
        
        # Special validation for alcoholic beverages
        if "category" in nutrition_data and "alcoholic" in nutrition_data["category"].lower():
            if "calories" in nutrition_data:
                try:
                    calories = float(str(nutrition_data["calories"]).replace("kcal", ""))
                    if calories < 50:  # Alcoholic beverages typically have higher calories
                        errors.append(f"Alcoholic beverage has unusually low calories: {calories}")
                except ValueError:
                    pass
        
        # Validate per 100g values if present
        per_100g_fields = ["proteins_per_100g", "carbohydrates_per_100g", "fats_per_100g", "calories_per_100g"]
        for field in per_100g_fields:
            if field in nutrition_data and nutrition_data[field] is not None:
                try:
                    value = float(nutrition_data[field])
                    if value < 0:
                        errors.append(f"Negative value for {field}: {value}")
                    if value > 1000:  # Reasonable upper limit for per 100g
                        errors.append(f"Unrealistically high value for {field}: {value}")
                except ValueError:
                    errors.append(f"Invalid numeric value for {field}: {nutrition_data[field]}")
        
        is_valid = len(errors) == 0
        error_details = {
            "ingredient_name": ingredient_name,
            "errors": errors,
            "validation_timestamp": datetime.utcnow().isoformat()
        }
        
        return is_valid, error_details
        
    except Exception as e:
        error_details = {
            "ingredient_name": ingredient_name,
            "errors": [f"Validation error: {str(e)}"],
            "validation_timestamp": datetime.utcnow().isoformat()
        }
        return False, error_details

def find_ingredient(query: str, search_type: str = "partial", limit: int = 10, language: str = "en") -> List[Dict]:
    """
    Find ingredients in the database
    
    Args:
        query: Search query
        search_type: Type of search (exact, partial, fuzzy, multilingual)
        limit: Maximum number of results
        language: Language for multilingual search
        
    Returns:
        List of matching ingredients
    """
    try:
        if ingredient_names_collection is None:
            logger.warning("MongoDB ingredient_names collection not available")
            return []
        
        if search_type == "exact":
            # Exact match
            results = list(ingredient_names_collection.find(
                {"name": query},
                {"_id": 0}
            ).limit(limit))
            
        elif search_type == "partial":
            # Partial match using regex
            results = list(ingredient_names_collection.find(
                {"name": {"$regex": query, "$options": "i"}},
                {"_id": 0}
            ).limit(limit))
            
        elif search_type == "fuzzy":
            # Fuzzy search using text index
            results = list(ingredient_names_collection.find(
                {"$text": {"$search": query}},
                {"_id": 0, "score": {"$meta": "textScore"}}
            ).sort([("score", {"$meta": "textScore"})]).limit(limit))
            
        elif search_type == "multilingual":
            # Multilingual search
            results = list(ingredient_names_collection.find(
                {f"names.{language}.name.singular": {"$regex": query, "$options": "i"}},
                {"_id": 0}
            ).limit(limit))
            
        else:
            logger.warning(f"Unknown search type: {search_type}")
            return []
        
        return results
        
    except Exception as e:
        logger.error(f"❌ Error finding ingredients: {str(e)}")
        return []

def find_ingredient_by_category(category: str, limit: int = 10) -> List[Dict]:
    """
    Find ingredients by category
    
    Args:
        category: Category to search for
        limit: Maximum number of results
        
    Returns:
        List of ingredients in the category
    """
    try:
        if ingredient_categories_collection is None:
            logger.warning("MongoDB ingredient_categories collection not available")
            return []
        
        results = list(ingredient_categories_collection.find(
            {"category": {"$regex": category, "$options": "i"}},
            {"_id": 0}
        ).limit(limit))
        
        return results
        
    except Exception as e:
        logger.error(f"❌ Error finding ingredients by category: {str(e)}")
        return []

def find_ingredient_nutrition(ingredient_name: str) -> Optional[Dict]:
    """
    Find nutrition information for an ingredient
    
    Args:
        ingredient_name: Name of the ingredient
        
    Returns:
        Nutrition data or None if not found
    """
    try:
        if ingredients_nutrition_collection is None:
            logger.warning("MongoDB ingredients_nutrition collection not available")
            return None
        
        result = ingredients_nutrition_collection.find_one(
            {"name": {"$regex": ingredient_name, "$options": "i"}},
            {"_id": 0}
        )
        
        return result
        
    except Exception as e:
        logger.error(f"❌ Error finding ingredient nutrition: {str(e)}")
        return None

def find_similar_ingredients(ingredient_name: str, limit: int = 5) -> List[Dict]:
    """
    Find similar ingredients
    
    Args:
        ingredient_name: Name of the ingredient
        limit: Maximum number of results
        
    Returns:
        List of similar ingredients
    """
    try:
        if normalized_ingredients_collection is None:
            logger.warning("MongoDB normalized_ingredients collection not available")
            return []
        
        # Find the base ingredient first
        base_ingredient = normalized_ingredients_collection.find_one(
            {"base_ingredient_name": {"$regex": ingredient_name, "$options": "i"}},
            {"_id": 0}
        )
        
        if base_ingredient:
            # Find similar ingredients in the same category
            category = base_ingredient.get("category", "")
            results = list(normalized_ingredients_collection.find(
                {"category": category, "base_ingredient_name": {"$ne": ingredient_name}},
                {"_id": 0}
            ).limit(limit))
            
            return results
        else:
            return []
        
    except Exception as e:
        logger.error(f"❌ Error finding similar ingredients: {str(e)}")
        return [] 
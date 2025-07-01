#!/usr/bin/env python3
"""
Test script for MongoDB functionality
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_mongodb_connection():
    """Test MongoDB connection and basic operations"""
    print("🧪 Testing MongoDB connection...")
    
    try:
        from mongodb_config import (
            save_validation_error,
            save_ingredient_to_mongo,
            save_meal_analysis_to_mongo,
            validate_nutrition_data
        )
        
        print("✅ MongoDB functions imported successfully")
        
        # Test validation function
        print("\n🧪 Testing nutrition validation...")
        test_data = {
            "proteins": "25g",
            "carbohydrates": "30g",
            "fats": "15g",
            "calories": "355kcal",
            "category": "meat"
        }
        
        is_valid, error_details = validate_nutrition_data("chicken breast", test_data)
        print(f"   Validation result: {'✅ Valid' if is_valid else '❌ Invalid'}")
        if not is_valid:
            print(f"   Errors: {error_details['errors']}")
        
        # Test with invalid data
        invalid_data = {
            "proteins": "-5g",  # Negative value
            "carbohydrates": "invalid",  # Non-numeric
            "fats": "15g",
            "calories": "355kcal"
        }
        
        is_valid, error_details = validate_nutrition_data("invalid_ingredient", invalid_data)
        print(f"   Invalid data validation: {'✅ Valid' if is_valid else '❌ Invalid'}")
        if not is_valid:
            print(f"   Errors: {error_details['errors']}")
        
        # Test saving functions (these will only work if MongoDB is connected)
        print("\n🧪 Testing save functions...")
        
        # Test ingredient save
        ingredient_data = {
            "name": "test_chicken_breast",
            "nutrition_data": test_data,
            "source": "test"
        }
        
        save_result = save_ingredient_to_mongo(ingredient_data)
        print(f"   Ingredient save: {'✅ Success' if save_result else '⚠️ Failed (expected if no MongoDB)'}")
        
        # Test validation error save
        error_save_result = save_validation_error("test_ingredient", error_details, invalid_data)
        print(f"   Validation error save: {'✅ Success' if error_save_result else '⚠️ Failed (expected if no MongoDB)'}")
        
        # Test meal analysis save
        meal_data = {
            "analysis_type": "test_analysis",
            "result_data": {"test": "data"},
            "test": True
        }
        
        meal_save_result = save_meal_analysis_to_mongo(meal_data)
        print(f"   Meal analysis save: {'✅ Success' if meal_save_result else '⚠️ Failed (expected if no MongoDB)'}")
        
        print("\n✅ MongoDB functionality test completed!")
        
    except ImportError as e:
        print(f"❌ Failed to import MongoDB functions: {e}")
        print("   Make sure mongodb_config.py exists and has no syntax errors")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()

def test_environment_variables():
    """Test if required environment variables are set"""
    print("🧪 Testing environment variables...")
    
    # Test required variables
    required_vars = [
        "OPENAI_API_KEY",
        "OPENROUTER_API_KEY"
    ]
    
    for var in required_vars:
        value = os.environ.get(var)
        if value:
            print(f"   ✅ {var}: {'Set' if len(value) > 10 else 'Too short'}")
        else:
            print(f"   ❌ {var}: Not set")
    
    # Test MongoDB variables
    mongodb_vars = [
        "MONGO_INITDB_ROOT_USERNAME",
        "MONGO_INITDB_ROOT_PASSWORD",
        "MONGO_HOST",
        "MONGO_PORT",
        "MONGO_DB_NAME",
        "MONGODB_DB",
        "MONGODB_AUTH_MECHANISM"
    ]
    
    print("\n   📊 MongoDB Configuration:")
    for var in mongodb_vars:
        value = os.environ.get(var)
        if value:
            if "PASSWORD" in var:
                print(f"   ✅ {var}: {'Set' if len(value) > 0 else 'Empty'}")
            else:
                print(f"   ✅ {var}: {value}")
        else:
            print(f"   ⚠️  {var}: Not set (will use default)")
    
    # Test collection variables
    collection_vars = [
        "MONGODB_INGREDIENTS_COLLECTION",
        "MONGODB_VALIDATION_ERRORS_COLLECTION",
        "MONGODB_MEAL_ANALYSIS_COLLECTION"
    ]
    
    print("\n   📁 Collection Configuration:")
    for var in collection_vars:
        value = os.environ.get(var)
        if value:
            print(f"   ✅ {var}: {value}")
        else:
            print(f"   ⚠️  {var}: Not set (will use default)")
    
    # Test connection settings
    connection_vars = [
        "MONGODB_CONNECT_TIMEOUT_MS",
        "MONGODB_SERVER_SELECTION_TIMEOUT_MS",
        "MONGODB_SOCKET_TIMEOUT_MS",
        "MONGODB_MAX_POOL_SIZE",
        "MONGODB_MIN_POOL_SIZE"
    ]
    
    print("\n   ⚙️  Connection Settings:")
    for var in connection_vars:
        value = os.environ.get(var)
        if value:
            print(f"   ✅ {var}: {value}")
        else:
            print(f"   ⚠️  {var}: Not set (will use default)")

def main():
    """Run all tests"""
    print("🚀 Starting MongoDB functionality tests...")
    print("=" * 50)
    
    test_environment_variables()
    test_mongodb_connection()
    
    print("\n" + "=" * 50)
    print("✅ All tests completed!")

if __name__ == "__main__":
    main() 
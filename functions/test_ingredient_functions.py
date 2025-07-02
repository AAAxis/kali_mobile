#!/usr/bin/env python3
"""
Test script for ingredient-related MongoDB functions
"""

import sys
import os
from mongodb_config import (
    find_ingredient, 
    find_ingredient_by_category, 
    find_ingredient_nutrition, 
    find_similar_ingredients,
    db
)

def test_find_ingredient():
    """Test the main find_ingredient function with different search types"""
    print("🧪 Testing find_ingredient function...")
    
    # Test exact search
    print("\n1. Testing EXACT search:")
    results = find_ingredient("tomato", search_type="exact", limit=3)
    print(f"   Found {len(results)} exact matches for 'tomato'")
    for i, result in enumerate(results[:2], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")
    
    # Test partial search
    print("\n2. Testing PARTIAL search:")
    results = find_ingredient("chicken", search_type="partial", limit=3)
    print(f"   Found {len(results)} partial matches for 'chicken'")
    for i, result in enumerate(results[:2], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")
    
    # Test fuzzy search
    print("\n3. Testing FUZZY search:")
    results = find_ingredient("tomat", search_type="fuzzy", limit=3)
    print(f"   Found {len(results)} fuzzy matches for 'tomat'")
    for i, result in enumerate(results[:2], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")
    
    # Test multilingual search
    print("\n4. Testing MULTILINGUAL search:")
    results = find_ingredient("tomate", search_type="multilingual", language="es", limit=3)
    print(f"   Found {len(results)} multilingual matches for 'tomate' (Spanish)")
    for i, result in enumerate(results[:2], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")

def test_find_ingredient_by_category():
    """Test finding ingredients by category"""
    print("\n🧪 Testing find_ingredient_by_category function...")
    
    # Test with a common category
    print("\n1. Testing category search:")
    results = find_ingredient_by_category("vegetables", limit=5)
    print(f"   Found {len(results)} vegetables")
    for i, result in enumerate(results[:3], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")
    
    # Test with another category
    print("\n2. Testing another category:")
    results = find_ingredient_by_category("fruits", limit=5)
    print(f"   Found {len(results)} fruits")
    for i, result in enumerate(results[:3], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")

def test_find_ingredient_nutrition():
    """Test finding nutrition information for ingredients"""
    print("\n🧪 Testing find_ingredient_nutrition function...")
    
    # Test with a common ingredient
    print("\n1. Testing nutrition for 'chicken breast':")
    nutrition = find_ingredient_nutrition("chicken breast")
    if nutrition:
        print(f"   Found nutrition data for chicken breast")
        print(f"   Calories: {nutrition.get('calories', 'N/A')}")
        print(f"   Protein: {nutrition.get('protein', 'N/A')}g")
        print(f"   Carbs: {nutrition.get('carbs', 'N/A')}g")
        print(f"   Fat: {nutrition.get('fat', 'N/A')}g")
    else:
        print("   No nutrition data found for chicken breast")
    
    # Test with another ingredient
    print("\n2. Testing nutrition for 'apple':")
    nutrition = find_ingredient_nutrition("apple")
    if nutrition:
        print(f"   Found nutrition data for apple")
        print(f"   Calories: {nutrition.get('calories', 'N/A')}")
        print(f"   Protein: {nutrition.get('protein', 'N/A')}g")
        print(f"   Carbs: {nutrition.get('carbs', 'N/A')}g")
        print(f"   Fat: {nutrition.get('fat', 'N/A')}g")
    else:
        print("   No nutrition data found for apple")

def test_find_similar_ingredients():
    """Test finding similar ingredients"""
    print("\n🧪 Testing find_similar_ingredients function...")
    
    # Test with a common ingredient
    print("\n1. Testing similar ingredients for 'apple':")
    similar = find_similar_ingredients("apple", limit=5)
    print(f"   Found {len(similar)} similar ingredients to 'apple'")
    for i, result in enumerate(similar[:3], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")
    
    # Test with another ingredient
    print("\n2. Testing similar ingredients for 'tomato':")
    similar = find_similar_ingredients("tomato", limit=5)
    print(f"   Found {len(similar)} similar ingredients to 'tomato'")
    for i, result in enumerate(similar[:3], 1):
        print(f"   {i}. {result.get('name', result.get('ingredient_name', 'Unknown'))}")

def test_collection_info():
    """Test and display information about the collections"""
    print("\n🧪 Testing collection information...")
    
    collections_to_check = [
        'ingredient_names_v5',
        'normalized_ingredients_v5', 
        'ingredients_nutrition_v5',
        'ingredient_categories_v5'
    ]
    
    for collection_name in collections_to_check:
        try:
            collection = db[collection_name]
            count = collection.count_documents({})
            print(f"   {collection_name}: {count} documents")
            
            # Show a sample document structure
            sample = collection.find_one()
            if sample:
                print(f"     Sample fields: {list(sample.keys())[:5]}...")
        except Exception as e:
            print(f"   {collection_name}: Error - {e}")

def test_error_handling():
    """Test error handling with invalid inputs"""
    print("\n🧪 Testing error handling...")
    
    # Test with empty string
    print("\n1. Testing with empty string:")
    results = find_ingredient("", search_type="exact")
    print(f"   Empty string search returned {len(results)} results")
    
    # Test with very long string
    print("\n2. Testing with very long string:")
    long_string = "a" * 1000
    results = find_ingredient(long_string, search_type="exact")
    print(f"   Long string search returned {len(results)} results")
    
    # Test with special characters
    print("\n3. Testing with special characters:")
    results = find_ingredient("tom@to!", search_type="exact")
    print(f"   Special characters search returned {len(results)} results")

def main():
    """Run all tests"""
    print("🚀 Starting ingredient function tests...")
    print("=" * 50)
    
    try:
        # Test collection information first
        test_collection_info()
        
        # Test main functions
        test_find_ingredient()
        test_find_ingredient_by_category()
        test_find_ingredient_nutrition()
        test_find_similar_ingredients()
        
        # Test error handling
        test_error_handling()
        
        print("\n" + "=" * 50)
        print("✅ All tests completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 
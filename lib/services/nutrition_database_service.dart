import 'dart:convert';

class NutritionDatabaseService {
  static bool _initialized = false;
  static Map<String, Map<String, double>> _nutritionDatabase = {};
  
  /// Initialize the nutrition database with common ingredients
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Basic nutrition database (per 100g)
    _nutritionDatabase = {
      // Proteins
      'Chicken breast': {'calories': 165, 'proteins': 31, 'carbs': 0, 'fats': 3.6},
      'Chicken thigh': {'calories': 209, 'proteins': 26, 'carbs': 0, 'fats': 10.9},
      'Salmon': {'calories': 208, 'proteins': 20, 'carbs': 0, 'fats': 13},
      'Beef': {'calories': 250, 'proteins': 26, 'carbs': 0, 'fats': 15},
      'Pork': {'calories': 242, 'proteins': 27, 'carbs': 0, 'fats': 14},
      'Tuna': {'calories': 132, 'proteins': 28, 'carbs': 0, 'fats': 1},
      'Eggs': {'calories': 155, 'proteins': 13, 'carbs': 1.1, 'fats': 11},
      'Tofu': {'calories': 76, 'proteins': 8, 'carbs': 1.9, 'fats': 4.8},
      
      // Dairy
      'Greek yogurt': {'calories': 59, 'proteins': 10, 'carbs': 3.6, 'fats': 0.4},
      'Milk': {'calories': 42, 'proteins': 3.4, 'carbs': 5, 'fats': 1},
      'Cheese cheddar': {'calories': 402, 'proteins': 25, 'carbs': 1.3, 'fats': 33},
      'Mozzarella': {'calories': 300, 'proteins': 22, 'carbs': 2.2, 'fats': 22},
      'Butter': {'calories': 717, 'proteins': 0.9, 'carbs': 0.1, 'fats': 81},
      
      // Grains & Carbs
      'Rice': {'calories': 130, 'proteins': 2.7, 'carbs': 28, 'fats': 0.3},
      'Pasta': {'calories': 131, 'proteins': 5, 'carbs': 25, 'fats': 1.1},
      'Bread': {'calories': 265, 'proteins': 9, 'carbs': 49, 'fats': 3.2},
      'Oats': {'calories': 389, 'proteins': 17, 'carbs': 66, 'fats': 6.9},
      'Quinoa': {'calories': 120, 'proteins': 4.4, 'carbs': 22, 'fats': 1.9},
      
      // Vegetables
      'Potato': {'calories': 77, 'proteins': 2, 'carbs': 17, 'fats': 0.1},
      'Sweet potato': {'calories': 86, 'proteins': 1.6, 'carbs': 20, 'fats': 0.1},
      'Broccoli': {'calories': 34, 'proteins': 2.8, 'carbs': 7, 'fats': 0.4},
      'Spinach': {'calories': 23, 'proteins': 2.9, 'carbs': 3.6, 'fats': 0.4},
      'Tomato': {'calories': 18, 'proteins': 0.9, 'carbs': 3.9, 'fats': 0.2},
      'Cucumber': {'calories': 16, 'proteins': 0.7, 'carbs': 4, 'fats': 0.1},
      'Carrots': {'calories': 41, 'proteins': 0.9, 'carbs': 10, 'fats': 0.2},
      'Bell pepper': {'calories': 31, 'proteins': 1, 'carbs': 7, 'fats': 0.3},
      'Onion': {'calories': 40, 'proteins': 1.1, 'carbs': 9.3, 'fats': 0.1},
      'Garlic': {'calories': 149, 'proteins': 6.4, 'carbs': 33, 'fats': 0.5},
      
      // Fruits
      'Banana': {'calories': 89, 'proteins': 1.1, 'carbs': 23, 'fats': 0.3},
      'Apple': {'calories': 52, 'proteins': 0.3, 'carbs': 14, 'fats': 0.2},
      'Orange': {'calories': 47, 'proteins': 0.9, 'carbs': 12, 'fats': 0.1},
      'Strawberry': {'calories': 32, 'proteins': 0.7, 'carbs': 8, 'fats': 0.3},
      'Blueberry': {'calories': 57, 'proteins': 0.7, 'carbs': 14, 'fats': 0.3},
      'Avocado': {'calories': 160, 'proteins': 2, 'carbs': 9, 'fats': 15},
      
      // Nuts & Seeds
      'Nuts mixed': {'calories': 607, 'proteins': 20, 'carbs': 13, 'fats': 54},
      'Almonds': {'calories': 579, 'proteins': 21, 'carbs': 22, 'fats': 50},
      'Walnuts': {'calories': 654, 'proteins': 15, 'carbs': 14, 'fats': 65},
      'Peanuts': {'calories': 567, 'proteins': 26, 'carbs': 16, 'fats': 49},
      'Sunflower seeds': {'calories': 584, 'proteins': 21, 'carbs': 20, 'fats': 51},
      
      // Legumes
      'Lentils': {'calories': 116, 'proteins': 9, 'carbs': 20, 'fats': 0.4},
      'Chickpeas': {'calories': 164, 'proteins': 8.9, 'carbs': 27, 'fats': 2.6},
      'Black beans': {'calories': 132, 'proteins': 8.9, 'carbs': 23, 'fats': 0.5},
      'Kidney beans': {'calories': 127, 'proteins': 8.7, 'carbs': 23, 'fats': 0.5},
      
      // Oils & Fats
      'Olive oil': {'calories': 884, 'proteins': 0, 'carbs': 0, 'fats': 100},
      'Coconut oil': {'calories': 862, 'proteins': 0, 'carbs': 0, 'fats': 100},
      'Vegetable oil': {'calories': 884, 'proteins': 0, 'carbs': 0, 'fats': 100},
      
      // Condiments & Spices
      'Salt': {'calories': 0, 'proteins': 0, 'carbs': 0, 'fats': 0},
      'Black pepper': {'calories': 251, 'proteins': 10, 'carbs': 64, 'fats': 3.3},
      'Paprika': {'calories': 282, 'proteins': 14, 'carbs': 54, 'fats': 13},
      'Cumin': {'calories': 375, 'proteins': 18, 'carbs': 44, 'fats': 22},
      'Oregano': {'calories': 265, 'proteins': 9, 'carbs': 69, 'fats': 4.3},
      'Basil': {'calories': 22, 'proteins': 3.2, 'carbs': 2.6, 'fats': 0.6},
      
      // Beverages (per 100ml)
      'Water': {'calories': 0, 'proteins': 0, 'carbs': 0, 'fats': 0},
      'Orange juice': {'calories': 45, 'proteins': 0.7, 'carbs': 10, 'fats': 0.2},
      'Apple juice': {'calories': 46, 'proteins': 0.1, 'carbs': 11, 'fats': 0.1},
      'Coffee': {'calories': 2, 'proteins': 0.3, 'carbs': 0, 'fats': 0},
      'Tea': {'calories': 1, 'proteins': 0, 'carbs': 0.3, 'fats': 0},
    };
    
    _initialized = true;
    print('✅ NutritionDatabaseService initialized with ${_nutritionDatabase.length} ingredients');
  }
  
  /// Get nutrition information for a specific ingredient and weight
  static Map<String, double> calculateNutrition(String ingredientName, double grams) {
    if (!_initialized) {
      print('⚠️ NutritionDatabaseService not initialized, using defaults');
      return {'calories': 100.0, 'proteins': 5.0, 'carbs': 15.0, 'fats': 3.0};
    }
    
    // Try exact match first
    if (_nutritionDatabase.containsKey(ingredientName)) {
      final baseNutrition = _nutritionDatabase[ingredientName]!;
      return _scaleNutrition(baseNutrition, grams);
    }
    
    // Try case-insensitive match
    final lowerName = ingredientName.toLowerCase();
    for (final entry in _nutritionDatabase.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return _scaleNutrition(entry.value, grams);
      }
    }
    
    // Try partial match
    for (final entry in _nutritionDatabase.entries) {
      if (entry.key.toLowerCase().contains(lowerName) || 
          lowerName.contains(entry.key.toLowerCase())) {
        return _scaleNutrition(entry.value, grams);
      }
    }
    
    // Default values if no match found
    print('⚠️ No nutrition data found for: $ingredientName, using estimated values');
    return _scaleNutrition({
      'calories': 100.0,
      'proteins': 5.0,
      'carbs': 15.0,
      'fats': 3.0,
    }, grams);
  }
  
  /// Scale nutrition values from 100g base to actual grams
  static Map<String, double> _scaleNutrition(Map<String, double> baseNutrition, double grams) {
    final scale = grams / 100.0;
    return {
      'calories': (baseNutrition['calories'] ?? 0) * scale,
      'proteins': (baseNutrition['proteins'] ?? 0) * scale,
      'carbs': (baseNutrition['carbs'] ?? 0) * scale,
      'fats': (baseNutrition['fats'] ?? 0) * scale,
    };
  }
  
  /// Get ingredient suggestions based on search query
  static List<String> getSuggestions(String query) {
    if (!_initialized) {
      return [];
    }
    
    if (query.isEmpty) {
      return _nutritionDatabase.keys.toList()..sort();
    }
    
    final lowerQuery = query.toLowerCase();
    final suggestions = _nutritionDatabase.keys
        .where((ingredient) => ingredient.toLowerCase().contains(lowerQuery))
        .toList();
    
    suggestions.sort();
    return suggestions;
  }
  
  /// Check if an ingredient exists in the database
  static bool hasIngredient(String ingredientName) {
    if (!_initialized) return false;
    
    // Try exact match first
    if (_nutritionDatabase.containsKey(ingredientName)) {
      return true;
    }
    
    // Try case-insensitive match
    final lowerName = ingredientName.toLowerCase();
    return _nutritionDatabase.keys.any((key) => key.toLowerCase() == lowerName);
  }
  
  /// Add a custom ingredient to the database
  static void addCustomIngredient(String name, Map<String, double> nutrition) {
    _nutritionDatabase[name] = Map<String, double>.from(nutrition);
    print('✅ Added custom ingredient: $name');
  }
  
  /// Get all available ingredient names
  static List<String> getAllIngredients() {
    if (!_initialized) return [];
    return _nutritionDatabase.keys.toList()..sort();
  }
} 
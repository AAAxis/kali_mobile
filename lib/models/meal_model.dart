import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Ingredient {
  final String name;
  final double grams;
  final double calories;
  final double proteins;
  final double carbs;
  final double fats;

  const Ingredient({
    required this.name,
    required this.grams,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
  });

  /// Create from JSON
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      grams: (json['grams'] ?? 0).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      proteins: (json['proteins'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fats: (json['fats'] ?? 0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': grams,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
    };
  }

  /// Create a copy with updated values
  Ingredient copyWith({
    String? name,
    double? grams,
    double? calories,
    double? proteins,
    double? carbs,
    double? fats,
  }) {
    return Ingredient(
      name: name ?? this.name,
      grams: grams ?? this.grams,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }
}

class Meal {
  final String id;
  final String? imageUrl;
  final String? localImagePath;
  final DateTime timestamp;
  final double calories;
  final Map<String, double> macros;
  final dynamic mealName; // Can be String (new format) or Map (old format)
  final String? name; // Fallback for simple string names
  final dynamic ingredients; // Can be List<String> (new format) or Map (old format)
  final Map<String, dynamic>? nutrients;
  final String? healthiness;
  final dynamic healthinessExplanation; // Can be String (new format) or Map (old format)
  final String? portionSize;
  final String? mealType;
  final String? cookingMethod;
  final List<String>? allergens;
  final List<String>? dietaryTags;
  final List<Ingredient>? detailedIngredients;
  final bool isFavorite;
  final bool isAnalyzing;
  final bool analysisFailed;
  final String? userId;

  const Meal({
    required this.id,
    this.imageUrl,
    this.localImagePath,
    required this.timestamp,
    required this.calories,
    required this.macros,
    this.mealName,
    this.name,
    this.ingredients,
    this.nutrients,
    this.healthiness,
    this.healthinessExplanation,
    this.portionSize,
    this.mealType,
    this.cookingMethod,
    this.allergens,
    this.dietaryTags,
    this.detailedIngredients,
    this.isFavorite = false,
    this.isAnalyzing = false,
    this.analysisFailed = false,
    this.userId,
  });

  /// Create a meal with analyzing state (used when starting analysis)
  factory Meal.analyzing({
    required String imageUrl,
    String? localImagePath,
    String? userId,
  }) {
    return Meal(
      id: const Uuid().v4(),
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      timestamp: DateTime.now(),
      calories: 0,
      macros: {'proteins': 0, 'carbs': 0, 'fats': 0},
      isAnalyzing: true,
      userId: userId,
    );
  }

  /// Create a meal with failed analysis state
  factory Meal.failed({
    required String id,
    required String imageUrl,
    String? localImagePath,
    String? userId,
  }) {
    return Meal(
      id: id,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      timestamp: DateTime.now(),
      calories: 0,
      macros: {'proteins': 0, 'carbs': 0, 'fats': 0},
      analysisFailed: true,
      userId: userId,
    );
  }

  /// Create a meal from OpenAI analysis result
  factory Meal.fromAnalysis({
    required String id,
    required String imageUrl,
    String? localImagePath,
    required Map<String, dynamic> analysisData,
    String? userId,
  }) {
    // Extract macros with fallback
    final macros = <String, double>{};
    if (analysisData['macros'] is Map) {
      final macrosData = analysisData['macros'] as Map<String, dynamic>;
      macros['proteins'] = (macrosData['proteins'] ?? 0).toDouble();
      macros['carbs'] = (macrosData['carbs'] ?? 0).toDouble();
      macros['fats'] = (macrosData['fats'] ?? 0).toDouble();
    } else {
      macros['proteins'] = 0;
      macros['carbs'] = 0;
      macros['fats'] = 0;
    }

    // Extract allergens and dietary tags
    List<String>? allergens;
    if (analysisData['allergens'] is List) {
      allergens = List<String>.from(analysisData['allergens']);
    }

    List<String>? dietaryTags;
    if (analysisData['dietary_tags'] is List) {
      dietaryTags = List<String>.from(analysisData['dietary_tags']);
    }

    // Extract detailed ingredients
    List<Ingredient>? detailedIngredients;
    if (analysisData['detailedIngredients'] is List) {
      detailedIngredients = (analysisData['detailedIngredients'] as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Ingredient.fromJson(item);
            }
            return null;
          })
          .where((item) => item != null)
          .cast<Ingredient>()
          .toList();
    }

    return Meal(
      id: id,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      timestamp: DateTime.now(),
      calories: (analysisData['calories'] ?? 0).toDouble(),
      macros: macros,
      mealName: analysisData['mealName'],
      ingredients: analysisData['ingredients'],
      nutrients: analysisData['nutrients'],
      healthiness: analysisData['healthiness'],
      healthinessExplanation: analysisData['healthiness_explanation'],
      portionSize: analysisData['portion_size'],
      mealType: analysisData['meal_type'],
      cookingMethod: analysisData['cooking_method'],
      allergens: allergens,
      dietaryTags: dietaryTags,
      detailedIngredients: detailedIngredients,
      userId: userId,
    );
  }

  /// Create a copy of this meal with updated values
  Meal copyWith({
    String? id,
    String? imageUrl,
    String? localImagePath,
    DateTime? timestamp,
    double? calories,
    Map<String, double>? macros,
    dynamic mealName,
    String? name,
    dynamic ingredients,
    Map<String, dynamic>? nutrients,
    String? healthiness,
    dynamic healthinessExplanation,
    String? portionSize,
    String? mealType,
    String? cookingMethod,
    List<String>? allergens,
    List<String>? dietaryTags,
    List<Ingredient>? detailedIngredients,
    bool? isFavorite,
    bool? isAnalyzing,
    bool? analysisFailed,
    String? userId,
  }) {
    return Meal(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      timestamp: timestamp ?? this.timestamp,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      mealName: mealName ?? this.mealName,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      nutrients: nutrients ?? this.nutrients,
      healthiness: healthiness ?? this.healthiness,
      healthinessExplanation: healthinessExplanation ?? this.healthinessExplanation,
      portionSize: portionSize ?? this.portionSize,
      mealType: mealType ?? this.mealType,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      allergens: allergens ?? this.allergens,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      detailedIngredients: detailedIngredients ?? this.detailedIngredients,
      isFavorite: isFavorite ?? this.isFavorite,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisFailed: analysisFailed ?? this.analysisFailed,
      userId: userId ?? this.userId,
    );
  }

  /// Get meal name based on locale (with frontend translation)
  String getMealName(String locale) {
    // Handle new format: direct English string
    if (mealName is String) {
      final englishName = mealName as String;
      if (locale == 'en') {
        return englishName;
      }
      // Import will be handled by the calling code to avoid circular dependency
      // TranslationService.translateText(englishName, locale) should be called by the UI
      return englishName; // Return English for now, UI will translate
    }
    
    // Handle old format: multilingual map (backward compatibility)
    if (mealName is Map) {
      final nameMap = mealName as Map<String, dynamic>;
      return nameMap[locale] ?? nameMap['en'] ?? name ?? 'Unknown Meal';
    }
    
    return name ?? 'Unknown Meal';
  }

  /// Get ingredients list based on locale (with frontend translation)
  List<String> getIngredients(String locale) {
    // Handle new format: direct English list
    if (ingredients is List) {
      final englishIngredients = List<String>.from(ingredients);
      if (locale == 'en') {
        return englishIngredients;
      }
      // Return English for now, UI will translate using TranslationService
      return englishIngredients;
    }
    
    // Handle old format: multilingual map (backward compatibility)
    if (ingredients is Map) {
      final ingredientsMap = ingredients as Map<String, dynamic>;
      final localeIngredients = ingredientsMap[locale];
      if (localeIngredients is List) {
        return List<String>.from(localeIngredients);
      }
      // Fallback to English
      final englishIngredients = ingredientsMap['en'];
      if (englishIngredients is List) {
        return List<String>.from(englishIngredients);
      }
    }
    
    return [];
  }

  /// Get healthiness explanation based on locale (with frontend translation)
  String getHealthinessExplanation(String locale) {
    // Handle new format: direct English string
    if (healthinessExplanation is String) {
      final englishExplanation = healthinessExplanation as String;
      if (locale == 'en') {
        return englishExplanation;
      }
      // Return English for now, UI will translate using TranslationService
      return englishExplanation;
    }
    
    // Handle old format: multilingual map (backward compatibility)
    if (healthinessExplanation is Map) {
      final explanationMap = healthinessExplanation as Map<String, dynamic>;
      return explanationMap[locale] ?? explanationMap['en'] ?? '';
    }
    
    return '';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'timestamp': timestamp.toIso8601String(),
      'calories': calories,
      'macros': macros,
      'mealName': mealName,
      'name': name,
      'ingredients': ingredients,
      'nutrients': nutrients,
      'healthiness': healthiness,
      'healthiness_explanation': healthinessExplanation,
      'portion_size': portionSize,
      'meal_type': mealType,
      'cooking_method': cookingMethod,
      'allergens': allergens,
      'dietary_tags': dietaryTags,
      'detailedIngredients': detailedIngredients?.map((i) => i.toJson()).toList(),
      'isFavorite': isFavorite,
      'isAnalyzing': isAnalyzing,
      'analysisFailed': analysisFailed,
      'userId': userId,
    };
  }

  /// Create from JSON
  factory Meal.fromJson(Map<String, dynamic> json) {
    // Parse macros with proper type handling
    final macros = <String, double>{};
    if (json['macros'] is Map) {
      final macrosData = json['macros'] as Map<String, dynamic>;
      macros['proteins'] = (macrosData['proteins'] ?? 0).toDouble();
      macros['carbs'] = (macrosData['carbs'] ?? 0).toDouble();
      macros['fats'] = (macrosData['fats'] ?? 0).toDouble();
    }

    // Parse timestamp
    DateTime timestamp;
    if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp']);
    } else {
      timestamp = DateTime.now();
    }

    // Parse allergens and dietary tags
    List<String>? allergens;
    if (json['allergens'] is List) {
      allergens = List<String>.from(json['allergens']);
    }

    List<String>? dietaryTags;
    if (json['dietary_tags'] is List) {
      dietaryTags = List<String>.from(json['dietary_tags']);
    }

    // Parse detailed ingredients
    List<Ingredient>? detailedIngredients;
    if (json['detailedIngredients'] is List) {
      detailedIngredients = (json['detailedIngredients'] as List)
          .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Meal(
      id: json['id'] ?? const Uuid().v4(),
      imageUrl: json['imageUrl'],
      localImagePath: json['localImagePath'],
      timestamp: timestamp,
      calories: (json['calories'] ?? 0).toDouble(),
      macros: macros,
      mealName: json['mealName'],
      name: json['name'],
      ingredients: json['ingredients'],
      nutrients: json['nutrients'],
      healthiness: json['healthiness'],
      healthinessExplanation: json['healthiness_explanation'],
      portionSize: json['portion_size'],
      mealType: json['meal_type'],
      cookingMethod: json['cooking_method'],
      allergens: allergens,
      dietaryTags: dietaryTags,
      detailedIngredients: detailedIngredients,
      isFavorite: json['isFavorite'] ?? false,
      isAnalyzing: json['isAnalyzing'] ?? false,
      analysisFailed: json['analysisFailed'] ?? false,
      userId: json['userId'],
    );
  }

  /// Create from Map (alias for fromJson for Firestore compatibility)
  factory Meal.fromMap(Map<String, dynamic> map, String documentId) {
    map['id'] = documentId; // Use document ID as meal ID
    return Meal.fromJson(map);
  }

  /// Save meals to local storage
  static Future<void> saveToLocalStorage(List<Meal> meals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = meals.map((meal) => jsonEncode(meal.toJson())).toList();
      await prefs.setStringList('local_meals', mealsJson);
      print('✅ Saved ${meals.length} meals to local storage');
    } catch (e) {
      print('❌ Error saving meals to local storage: $e');
      rethrow;
    }
  }

  /// Load meals from local storage
  static Future<List<Meal>> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = prefs.getStringList('local_meals') ?? [];
      
      final meals = mealsJson.map((mealJson) {
        final mealData = jsonDecode(mealJson) as Map<String, dynamic>;
        return Meal.fromJson(mealData);
      }).toList();
      
      print('✅ Loaded ${meals.length} meals from local storage');
      return meals;
    } catch (e) {
      print('❌ Error loading meals from local storage: $e');
      return [];
    }
  }

  /// Delete a specific meal from local storage
  static Future<void> deleteFromLocalStorage(String mealId) async {
    try {
      final meals = await loadFromLocalStorage();
      final updatedMeals = meals.where((meal) => meal.id != mealId).toList();
      await saveToLocalStorage(updatedMeals);
      print('✅ Deleted meal $mealId from local storage');
    } catch (e) {
      print('❌ Error deleting meal from local storage: $e');
      rethrow;
    }
  }

  /// Add or update a meal in local storage
  static Future<void> addOrUpdateInLocalStorage(Meal meal) async {
    try {
      final meals = await loadFromLocalStorage();
      final existingIndex = meals.indexWhere((m) => m.id == meal.id);
      
      if (existingIndex >= 0) {
        meals[existingIndex] = meal;
      } else {
        meals.add(meal);
      }
      
      await saveToLocalStorage(meals);
      print('✅ Added/updated meal ${meal.id} in local storage');
    } catch (e) {
      print('❌ Error adding/updating meal in local storage: $e');
      rethrow;
    }
  }

  /// Clear all meals from local storage
  static Future<void> clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_meals');
      print('✅ Cleared all meals from local storage');
    } catch (e) {
      print('❌ Error clearing meals from local storage: $e');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: ${getMealName("en")}, calories: $calories, isAnalyzing: $isAnalyzing, analysisFailed: $analysisFailed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
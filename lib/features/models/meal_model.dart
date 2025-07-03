import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Ingredient {
  final String name;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const Ingredient({
    required this.name,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Create from JSON
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      grams: (json['grams'] ?? 0).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  /// Create a copy with updated values
  Ingredient copyWith({
    String? name,
    double? grams,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return Ingredient(
      name: name ?? this.name,
      grams: grams ?? this.grams,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}

class Meal {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isAnalyzing;
  final bool analysisFailed;
  final Map<String, dynamic> macros;
  final String? localImagePath;
  final dynamic mealName; // Can be String (new format) or Map (old format)
  final String? fallbackName; // Fallback for simple string names
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
  final String? userId;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    required this.timestamp,
    this.isAnalyzing = false,
    this.analysisFailed = false,
    Map<String, dynamic>? macros,
    this.localImagePath,
    this.mealName,
    this.fallbackName,
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
    this.userId,
  }) : this.macros = macros ?? {
          'proteins': protein,
          'carbs': carbs,
          'fats': fat,
        };

  /// Create a meal with analyzing state (used when starting analysis)
  factory Meal.analyzing({
    required String imageUrl,
    String? localImagePath,
    String? userId,
  }) {
    return Meal(
      id: const Uuid().v4(),
      name: '',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      isAnalyzing: true,
      analysisFailed: false,
      localImagePath: localImagePath,
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
      name: '',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      isAnalyzing: false,
      analysisFailed: true,
      localImagePath: localImagePath,
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
      name: analysisData['mealName']?.toString() ?? '',
      calories: (analysisData['calories'] ?? 0).toDouble(),
      protein: macros['proteins'] ?? 0,
      carbs: macros['carbs'] ?? 0,
      fat: macros['fats'] ?? 0,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      isAnalyzing: false,
      analysisFailed: false,
      macros: macros,
      localImagePath: localImagePath,
      mealName: analysisData['mealName'],
      fallbackName: analysisData['mealName']?.toString(),
      ingredients: analysisData['ingredients'],
      nutrients: analysisData['nutrients'] as Map<String, dynamic>?,
      healthiness: analysisData['healthiness']?.toString(),
      healthinessExplanation: analysisData['healthiness_explanation'],
      portionSize: analysisData['portionSize']?.toString(),
      mealType: analysisData['mealType']?.toString(),
      cookingMethod: analysisData['cookingMethod']?.toString(),
      allergens: allergens,
      dietaryTags: dietaryTags,
      detailedIngredients: detailedIngredients,
      isFavorite: false,
      userId: userId,
    );
  }

  /// Create from Firestore document
  factory Meal.fromMap(Map<String, dynamic> data, String id) {
    // Handle timestamp conversion
    DateTime timestamp = DateTime.now();
    if (data['timestamp'] != null) {
      if (data['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      } else if (data['timestamp'].toString().isNotEmpty) {
        try {
          timestamp = DateTime.parse(data['timestamp'].toString());
        } catch (e) {
          print('Error parsing timestamp: $e');
        }
      }
    }

    // Handle macros
    Map<String, double> macros = {'proteins': 0, 'carbs': 0, 'fats': 0};
    if (data['macros'] is Map) {
      final macrosData = data['macros'] as Map<String, dynamic>;
      macros['proteins'] = (macrosData['proteins'] ?? 0).toDouble();
      macros['carbs'] = (macrosData['carbs'] ?? 0).toDouble();
      macros['fats'] = (macrosData['fats'] ?? 0).toDouble();
    }

    // Handle allergens
    List<String>? allergens;
    if (data['allergens'] is List) {
      allergens = List<String>.from(data['allergens']);
    }

    // Handle dietary tags
    List<String>? dietaryTags;
    if (data['dietary_tags'] is List) {
      dietaryTags = List<String>.from(data['dietary_tags']);
    }

    // Handle detailed ingredients
    List<Ingredient>? detailedIngredients;
    if (data['detailedIngredients'] is List) {
      detailedIngredients = (data['detailedIngredients'] as List)
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
      name: data['name']?.toString() ?? '',
      calories: (data['calories'] ?? 0).toDouble(),
      protein: macros['proteins'] ?? 0,
      carbs: macros['carbs'] ?? 0,
      fat: macros['fats'] ?? 0,
      imageUrl: data['imageUrl']?.toString(),
      timestamp: timestamp,
      isAnalyzing: data['isAnalyzing'] ?? false,
      analysisFailed: data['analysisFailed'] ?? false,
      macros: macros,
      localImagePath: data['localImagePath']?.toString(),
      mealName: data['mealName'],
      fallbackName: data['name']?.toString(),
      ingredients: data['ingredients'],
      nutrients: data['nutrients'] as Map<String, dynamic>?,
      healthiness: data['healthiness']?.toString(),
      healthinessExplanation: data['healthiness_explanation'],
      portionSize: data['portionSize']?.toString(),
      mealType: data['mealType']?.toString(),
      cookingMethod: data['cookingMethod']?.toString(),
      allergens: allergens,
      dietaryTags: dietaryTags,
      detailedIngredients: detailedIngredients,
      isFavorite: data['isFavorite'] ?? false,
      userId: data['userId']?.toString(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'calories': calories,
      'macros': macros,
      'mealName': mealName,
      'name': name,
      'ingredients': ingredients,
      'nutrients': nutrients,
      'healthiness': healthiness,
      'healthiness_explanation': healthinessExplanation,
      'portionSize': portionSize,
      'mealType': mealType,
      'cookingMethod': cookingMethod,
      'allergens': allergens,
      'dietary_tags': dietaryTags,
      'detailedIngredients': detailedIngredients?.map((i) => i.toJson()).toList(),
      'isFavorite': isFavorite,
      'isAnalyzing': isAnalyzing,
      'analysisFailed': analysisFailed,
      'userId': userId,
    };
  }

  /// Convert to JSON for local storage
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
      'portionSize': portionSize,
      'mealType': mealType,
      'cookingMethod': cookingMethod,
      'allergens': allergens,
      'dietary_tags': dietaryTags,
      'detailedIngredients': detailedIngredients?.map((i) => i.toJson()).toList(),
      'isFavorite': isFavorite,
      'isAnalyzing': isAnalyzing,
      'analysisFailed': analysisFailed,
      'userId': userId,
    };
  }

  /// Create from JSON (local storage)
  factory Meal.fromJson(Map<String, dynamic> json) {
    // Handle detailed ingredients
    List<Ingredient>? detailedIngredients;
    if (json['detailedIngredients'] is List) {
      detailedIngredients = (json['detailedIngredients'] as List)
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['macros'] ?? {'proteins': 0})['proteins'] ?? 0,
      carbs: (json['macros'] ?? {'carbs': 0})['carbs'] ?? 0,
      fat: (json['macros'] ?? {'fats': 0})['fats'] ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isAnalyzing: json['isAnalyzing'] ?? false,
      analysisFailed: json['analysisFailed'] ?? false,
      macros: Map<String, double>.from(json['macros'] ?? {'proteins': 0, 'carbs': 0, 'fats': 0}),
      localImagePath: json['localImagePath']?.toString(),
      mealName: json['mealName'],
      fallbackName: json['name']?.toString(),
      ingredients: json['ingredients'],
      nutrients: json['nutrients'] as Map<String, dynamic>?,
      healthiness: json['healthiness']?.toString(),
      healthinessExplanation: json['healthiness_explanation'],
      portionSize: json['portionSize']?.toString(),
      mealType: json['mealType']?.toString(),
      cookingMethod: json['cookingMethod']?.toString(),
      allergens: json['allergens'] != null ? List<String>.from(json['allergens']) : null,
      dietaryTags: json['dietary_tags'] != null ? List<String>.from(json['dietary_tags']) : null,
      detailedIngredients: detailedIngredients,
      isFavorite: json['isFavorite'] ?? false,
      userId: json['userId']?.toString(),
    );
  }

  /// Create a copy with updated values
  Meal copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? imageUrl,
    DateTime? timestamp,
    bool? isAnalyzing,
    bool? analysisFailed,
    Map<String, double>? macros,
    String? localImagePath,
    dynamic mealName,
    String? fallbackName,
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
    String? userId,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisFailed: analysisFailed ?? this.analysisFailed,
      macros: macros ?? this.macros,
      localImagePath: localImagePath ?? this.localImagePath,
      mealName: mealName ?? this.mealName,
      fallbackName: fallbackName ?? this.fallbackName,
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
      userId: userId ?? this.userId,
    );
  }

  /// Get display name based on current locale
  String getDisplayName([String locale = 'en']) {
    if (mealName is Map) {
      final nameMap = mealName as Map<String, dynamic>;
      return nameMap[locale]?.toString() ?? nameMap['en']?.toString() ?? fallbackName ?? 'Unknown Meal';
    } else if (mealName is String) {
      return mealName.toString();
    } else if (fallbackName != null) {
      return fallbackName!;
    }
    return 'Unknown Meal';
  }

  /// Get display ingredients based on current locale
  List<String> getDisplayIngredients([String locale = 'en']) {
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
    } else if (ingredients is List) {
      return List<String>.from(ingredients);
    }
    return [];
  }

  /// Get display healthiness explanation based on current locale
  String getDisplayHealthinessExplanation([String locale = 'en']) {
    if (healthinessExplanation is Map) {
      final explanationMap = healthinessExplanation as Map<String, dynamic>;
      return explanationMap[locale]?.toString() ?? 
             explanationMap['en']?.toString() ?? 
             'No explanation available';
    } else if (healthinessExplanation is String) {
      return healthinessExplanation.toString();
    }
    return 'No explanation available';
  }

  /// Static methods for local storage management
  static Future<List<Meal>> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = prefs.getString('local_meals');
      if (mealsJson != null) {
        final List<dynamic> mealsList = jsonDecode(mealsJson);
        return mealsList.map((json) => Meal.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading meals from local storage: $e');
    }
    return [];
  }

  static Future<void> saveToLocalStorage(List<Meal> meals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = jsonEncode(meals.map((meal) => meal.toJson()).toList());
      await prefs.setString('local_meals', mealsJson);
    } catch (e) {
      print('Error saving meals to local storage: $e');
    }
  }

  static Future<void> addToLocalStorage(Meal meal) async {
    final meals = await loadFromLocalStorage();
    meals.insert(0, meal); // Add to beginning of list
    await saveToLocalStorage(meals);
  }

  static Future<void> updateInLocalStorage(Meal updatedMeal) async {
    final meals = await loadFromLocalStorage();
    final index = meals.indexWhere((meal) => meal.id == updatedMeal.id);
    if (index != -1) {
      meals[index] = updatedMeal;
      await saveToLocalStorage(meals);
    }
  }

  static Future<void> removeFromLocalStorage(String mealId) async {
    final meals = await loadFromLocalStorage();
    meals.removeWhere((meal) => meal.id == mealId);
    await saveToLocalStorage(meals);
  }

  List<String> getIngredients(String locale) {
    // Default implementation returns empty list
    // Override in subclass if needed
    return [];
  }

  String getMealName(String locale) {
    if (mealName is Map) {
      final nameMap = mealName as Map<String, dynamic>;
      return nameMap[locale]?.toString()
          ?? nameMap['en']?.toString()
          ?? (fallbackName != null && fallbackName!.isNotEmpty
              ? fallbackName!
              : (name.isNotEmpty ? name : 'Unknown Meal'));
    } else if (mealName is String && mealName.toString().isNotEmpty) {
      return mealName.toString();
    } else if (fallbackName != null && fallbackName!.isNotEmpty) {
      return fallbackName!;
    } else if (name.isNotEmpty) {
      return name;
    }
    return 'Unknown Meal';
  }

  static Future<void> deleteFromLocalStorage(String mealId) async {
    final prefs = await SharedPreferences.getInstance();
    final mealsJson = prefs.getString('meals');
    if (mealsJson == null) return;

    final List<dynamic> decoded = jsonDecode(mealsJson);
    final meals = decoded.map((json) => Meal.fromJson(json)).toList();
    meals.removeWhere((meal) => meal.id == mealId);
    
    await prefs.setString('meals', jsonEncode(meals.map((m) => m.toJson()).toList()));
  }
} 
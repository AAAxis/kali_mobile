import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

import 'ingridients_edit.dart';
import 'nutrions_edit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/meal_model.dart';
import '../../../core/services/nutrition_database_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/image_cache_service.dart';


class AnalysisDetailsScreen extends StatefulWidget {
  final String analysisId;

  const AnalysisDetailsScreen({Key? key, required this.analysisId})
    : super(key: key);

  @override
  State<AnalysisDetailsScreen> createState() => _AnalysisDetailsScreenState();
}

class _AnalysisDetailsScreenState extends State<AnalysisDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  String? _error;
  List<String> _notes = [];

  Color _getThemeAwareColor(
    BuildContext context,
    Color lightColor,
    Color darkColor,
  ) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkColor
        : lightColor;
  }

  Color getThemeAwareColor(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkColor : Colors.white;
  }

  Color _getHealthinessBackgroundColor(bool isDark) {
    String healthiness =
        (_analysisData?['healthiness'] ?? '').toString().toLowerCase();
    double opacity = isDark ? 0.15 : 0.1;

    if (healthiness.contains('healthy')) {
      return Colors.green.withOpacity(opacity);
    } else if (healthiness.contains('medium')) {
      return Colors.amber.withOpacity(opacity);
    } else if (healthiness.contains('unhealthy')) {
      return Colors.red.withOpacity(opacity);
    } else {
      return Colors.red.withOpacity(opacity);
    }
  }

  IconData _getHealthinessIcon() {
    String healthiness =
        (_analysisData?['healthiness'] ?? '').toString().toLowerCase();

    if (healthiness.contains('healthy')) {
      return Icons.check_circle;
    } else if (healthiness.contains('medium')) {
      return Icons.info;
    } else if (healthiness.contains('unhealthy')) {
      return Icons.warning;
    } else {
      return Icons.warning;
    }
  }

  Color _getHealthinessIconColor() {
    String healthiness =
        (_analysisData?['healthiness'] ?? '').toString().toLowerCase();

    if (healthiness.contains('healthy')) {
      return Colors.green;
    } else if (healthiness.contains('medium')) {
      return Colors.amber;
    } else if (healthiness.contains('unhealthy')) {
      return Colors.red;
    } else {
      return Colors.red;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadAnalysisFromLocal().then((_) {
      // Only fetch from network if we don't have cached data
      if (_analysisData == null) {
        _fetchAnalysisDetails().then((_) {
                  _loadNotes(); // Load notes after analysis data is fetched
        _preloadImage(); // Preload image for better caching
        });
      } else {
        // We have cached data, just load notes and preload image
        _loadNotes();
        _preloadImage();
        // Try to fetch fresh data in background without showing loading
        _fetchAnalysisDetails();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await ImageCacheService.initialize();
  }

  Future<void> _preloadImage() async {
    if (_analysisData?['imageUrl'] != null) {
      final imageUrl = _analysisData!['imageUrl'] as String;
      if (imageUrl.isNotEmpty) {
        // Check if image is already cached, if not, trigger download
        final isInMemory = ImageCacheService.getFromMemoryCache(imageUrl) != null;
        final isInDisk = await ImageCacheService.isInDiskCache(imageUrl);
        
        if (!isInMemory && !isInDisk) {
          print('🔄 Preloading image for faster display: $imageUrl');
          // This will trigger the download and cache the image
          ImageCacheService.getCachedImage(imageUrl);
        } else {
          print('✅ Image already cached: $imageUrl');
        }
      }
    }
  }

  Future<void> _loadAnalysisFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('analysis_${widget.analysisId}');
      if (cached != null) {
        setState(() {
          _analysisData = json.decode(cached);
          _isLoading = false; // Stop loading if we have cached data
        });
      }
    } catch (e) {
      print('Error loading analysis from local: $e');
    }
  }

  Future<void> _saveAnalysisToLocal(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert all Timestamp objects to strings before encoding
      final cleanedData = _convertTimestampsToStrings(data);
      await prefs.setString('analysis_${widget.analysisId}', json.encode(cleanedData));
    } catch (e) {
      print('Error saving analysis to local: $e');
      print('Analysis data in UI: ${data.keys.join(', ')}');
    }
  }

  /// Recursively convert all Timestamp objects to ISO8601 strings
  dynamic _convertTimestampsToStrings(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map<String, dynamic>) {
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        result[key] = _convertTimestampsToStrings(value);
      });
      return result;
    } else if (data is List) {
      return data.map((item) => _convertTimestampsToStrings(item)).toList();
    } else {
      return data;
    }
  }

  Future<void> _fetchAnalysisDetails() async {
    try {
      // Only show loading if we don't have any data yet
      if (_analysisData == null) {
        setState(() => _isLoading = true);
      }
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is authenticated - try to load from Firebase
        print('🔥 Loading meal details from Firebase for user: ${user.uid}');
        final doc = await FirebaseFirestore.instance
            .collection('analyzed_meals')
            .doc(widget.analysisId)
            .get();

        if (doc.exists && doc.data()?['userId'] == user.uid) {
          final data = doc.data()!;
          print("✅ Firebase data loaded: $data");

          setState(() {
            _analysisData = data;
            _isLoading = false;
          });
          await _saveAnalysisToLocal(data);
          return;
        }
      }
      
      // User is not authenticated or meal not found in Firebase - try local storage
      print('📱 Loading meal details from local storage');
      final localMeals = await Meal.loadFromLocalStorage();
      final localMealIndex = localMeals.indexWhere(
        (meal) => meal.id == widget.analysisId,
      );
      
      if (localMealIndex == -1) {
        throw Exception('Meal not found in local storage');
      }
      
      final localMeal = localMeals[localMealIndex];
      
      // Convert Meal to analysis data format
      final data = localMeal.toJson();
      print("✅ Local storage data loaded: $data");
      
      setState(() {
        _analysisData = data;
        _isLoading = false;
      });
      await _saveAnalysisToLocal(data);
      
    } catch (e) {
      print('❌ Error fetching analysis details: $e');
      setState(() {
        _error = 'Failed to fetch analysis details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('meal_notes_${widget.analysisId}');
      List<String> loadedNotes = [];

      if (notesJson != null) {
        final decoded = json.decode(notesJson);
        if (decoded is List) {
          loadedNotes = List<String>.from(decoded);
        } else if (decoded is Map) {
          // If notes were accidentally saved as a Map, take the values
          loadedNotes = decoded.values.map((e) => e.toString()).toList();
        }
      }

      // Add ingredients to notes if they exist and aren't already in notes
      if (_analysisData != null) {
        // Handle ingredients more safely based on the data structure
        List<String> ingredients = [];
        
        if (_analysisData!['ingredients'] != null) {
          final ingredientsData = _analysisData!['ingredients'];
          
          if (ingredientsData is List) {
            // If ingredients is a list, convert to strings
            ingredients = ingredientsData.map((e) => e.toString()).toList();
          } else if (ingredientsData is Map) {
            // If ingredients is a map (multilingual), get current language or default
            final locale = 'en'; // Default to English, or get from context if available
            final Map<String, dynamic> ingMap = Map<String, dynamic>.from(ingredientsData);
            
            if (ingMap[locale] is List) {
              ingredients = List<String>.from(ingMap[locale]);
            } else if (ingMap['en'] is List) {
              ingredients = List<String>.from(ingMap['en']);
            } else {
              // If no proper list found, try to extract values
              final allValues = <String>[];
              ingMap.forEach((key, value) {
                if (value is List) {
                  allValues.addAll(value.map((e) => e.toString()));
                } else if (value is String) {
                  allValues.add(value);
                }
              });
              ingredients = allValues;
            }
          } else if (ingredientsData is String) {
            // If it's a single string, split by common delimiters
            ingredients = ingredientsData.split(RegExp(r'[,|;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }
        
        // Add ingredients to notes
        for (var ingredient in ingredients) {
          final ingredientNote = 'Ingredient: $ingredient';
          if (!loadedNotes.contains(ingredientNote)) {
            loadedNotes.add(ingredientNote);
          }
        }
      }

      setState(() {
        _notes = loadedNotes;
      });

      // Save the updated notes
      await _saveNotes();
    } catch (e) {
      print('Error loading notes: $e');
      // Set empty notes on error to prevent crashes
      setState(() {
        _notes = [];
      });
    }
  }

  // Add a new method to refresh notes when analysis data changes
  void _refreshNotes() {
    if (_analysisData != null) {
      _loadNotes();
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'meal_notes_${widget.analysisId}',
        json.encode(_notes),
      );
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        return DateFormat('MMMM dd, yyyy').format(DateTime.parse(date));
      } catch (e) {
        return 'Unknown date';
      }
    }
    return 'Unknown date';
  }

  String _translateValue(String key, String value) {
    // Define translation mappings
    final Map<String, Map<String, String>> translations = {
      'healthiness': {
        'healthy': 'details.healthiness.healthy',
        'medium': 'details.healthiness.medium',
        'unhealthy': 'details.healthiness.unhealthy',
      },
      'benefits': {
        'high in protein': 'details.benefits.high_protein',
        'low in fat': 'details.benefits.low_fat',
        'good source of fiber': 'details.benefits.good_fiber',
        // Add more benefit translations as needed
      },
      'nutrients': {
        'protein': 'details.nutrients.protein',
        'fiber': 'details.nutrients.fiber',
        'vitamin c': 'details.nutrients.vitamin_c',
        // Add more nutrient translations as needed
      },
    };

    // Try to find and translate the value
    if (translations.containsKey(key)) {
      final translationMap = translations[key]!;
      final lowercaseValue = value.toLowerCase();

      // Try exact match first
      if (translationMap.containsKey(lowercaseValue)) {
        return translationMap[lowercaseValue]!.tr();
      }

      // If no exact match, try partial matches
      for (var entry in translationMap.entries) {
        if (lowercaseValue.contains(entry.key)) {
          return entry.value.tr();
        }
      }
    }

    // Return original value if no translation found
    return value;
  }

  void _showEditNameDialog() {
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String currentName = 'Unknown';
    if (_analysisData?['mealName'] is Map) {
      currentName = _analysisData?['mealName'][locale] ?? _analysisData?['mealName']['en'] ?? 'Unknown';
    } else {
      currentName = _analysisData?['name'] ?? _analysisData?['mealName'] ?? 'Unknown';
    }
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? Colors.grey[800] : Colors.white,
            title: Text(
              'details.edit_name'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            content: TextField(
              controller: nameController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'details.meal_name'.tr(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[700] : Colors.grey[50],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'common.cancel'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    // Update only the current language in the mealName map
                    Map<String, dynamic> mealNameMap = {};
                    if (_analysisData?['mealName'] is Map) {
                      mealNameMap = Map<String, dynamic>.from(_analysisData?['mealName']);
                    } else if (_analysisData?['mealName'] is String) {
                      mealNameMap['en'] = _analysisData?['mealName'];
                    } else if (_analysisData?['name'] is String) {
                      mealNameMap['en'] = _analysisData?['name'];
                    }
                    mealNameMap[locale] = nameController.text.trim();
                    await _updateMealDetails({
                      'mealName': mealNameMap,
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(
                  'common.save'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _updateMealDetails(Map<String, dynamic> updatedData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is authenticated - update in Firebase
        print('🔥 Updating meal details in Firebase');
        final docRef = FirebaseFirestore.instance
            .collection('analyzed_meals')
            .doc(widget.analysisId);

        final Map<String, dynamic> firestoreData = {};
        if (updatedData.containsKey('calories')) {
          firestoreData['calories'] = updatedData['calories'];
        }
        if (updatedData.containsKey('macros')) {
          firestoreData['macros'] = updatedData['macros'];
        }
        if (updatedData.containsKey('name')) {
          firestoreData['name'] = updatedData['name'];
        }
        if (updatedData.containsKey('mealName')) {
          firestoreData['mealName'] = updatedData['mealName'];
        }
        if (updatedData.containsKey('healthiness')) {
          firestoreData['healthiness'] = updatedData['healthiness'];
        }
        if (updatedData.containsKey('imageUrl')) {
          firestoreData['imageUrl'] = updatedData['imageUrl'];
        }
        if (updatedData.containsKey('date')) {
          firestoreData['date'] = updatedData['date'];
        }
        if (updatedData.containsKey('ingredients')) {
          firestoreData['ingredients'] = updatedData['ingredients'];
        }
        if (updatedData.containsKey('detailedIngredients')) {
          firestoreData['detailedIngredients'] = updatedData['detailedIngredients'];
        }
        if (updatedData.containsKey('nutrients')) {
          firestoreData['nutrients'] = updatedData['nutrients'];
        }

        await docRef.update(firestoreData);
        final doc = await docRef.get();

        if (mounted) {
          setState(() {
            _analysisData = doc.data();
          });
        }
        print('✅ Meal updated in Firebase');
      } else {
        // User is not authenticated - update in local storage
        print('📱 Updating meal details in local storage');
        
        // Update the current analysis data
        if (_analysisData != null) {
          _analysisData!.addAll(updatedData);
          
          // Update the meal in local storage
          final localMeals = await Meal.loadFromLocalStorage();
          final updatedMeals = localMeals.map((meal) {
            if (meal.id == widget.analysisId) {
              return Meal.fromJson(_analysisData!);
            }
            return meal;
          }).toList();
          
          // Save updated meals back to local storage
          final prefs = await SharedPreferences.getInstance();
          final mealsJson = updatedMeals.map((meal) => jsonEncode(meal.toJson())).toList();
          await prefs.setStringList('local_meals', mealsJson);
          
          if (mounted) {
            setState(() {
              // _analysisData is already updated above
            });
          }
          print('✅ Meal updated in local storage');
        }
      }

      if (_analysisData != null) {
        await _saveAnalysisToLocal(_analysisData!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('details.meal_updated'.tr())),
        );
      }
    } catch (e) {
      print('❌ Error updating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'details.update_error'.tr()}: ${e.toString()}')),
        );
      }
    }
  }

  // Add method to edit ingredients
  Future<void> _editIngredients() async {
    if (_analysisData == null) return;
    
    // Get current detailed ingredients or convert from legacy format
    List<Ingredient> currentDetailedIngredients = [];
    
    if (_analysisData?['detailedIngredients'] is List) {
      // Use existing detailed ingredients
      currentDetailedIngredients = (_analysisData!['detailedIngredients'] as List)
          .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Convert legacy ingredients to detailed format with estimated nutrition
      final String currentLocale = Localizations.localeOf(context).languageCode;
      List<String> legacyIngredients = [];
      
      if (_analysisData?['ingredients'] is Map) {
        final Map<String, dynamic> ingMap = Map<String, dynamic>.from(_analysisData?['ingredients']);
        legacyIngredients = List<String>.from(
          ingMap[currentLocale] ?? ingMap['en'] ?? [],
        );
      } else if (_analysisData?['ingredients'] is List) {
        legacyIngredients = List<String>.from(_analysisData?['ingredients'] ?? []);
      }
      
      // Convert to detailed ingredients using nutrition database
      final totalCalories = (_analysisData?['calories'] ?? 0.0).toDouble();
      final totalProteins = (_analysisData?['macros']?['proteins'] ?? 0.0).toDouble();
      final totalCarbs = (_analysisData?['macros']?['carbs'] ?? 0.0).toDouble();
      final totalFats = (_analysisData?['macros']?['fats'] ?? 0.0).toDouble();
      
      final ingredientCount = legacyIngredients.length;
      if (ingredientCount > 0) {
        // Initialize nutrition database
        await NutritionDatabaseService.initialize();
        
        currentDetailedIngredients = legacyIngredients.map((name) {
          // Try to get nutrition from database, otherwise use averages
          final nutrition = NutritionDatabaseService.calculateNutrition(name, 100.0);
          
          // If database has good data, use it; otherwise distribute evenly
          if (nutrition['calories']! > 0) {
            return Ingredient(
              name: name,
              grams: 100.0,
              calories: nutrition['calories']!,
              protein: nutrition['proteins']!,
              carbs: nutrition['carbs']!,
              fat: nutrition['fats']!,
            );
          } else {
            // Fallback to even distribution
            return Ingredient(
              name: name,
              grams: 100.0,
              calories: totalCalories / ingredientCount,
              protein: totalProteins / ingredientCount,
              carbs: totalCarbs / ingredientCount,
              fat: totalFats / ingredientCount,
            );
          }
        }).toList();
      }
    }

    final updatedIngredients = await Navigator.push<List<Ingredient>>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientsEditScreen(
          detailedIngredients: currentDetailedIngredients,
          mealId: widget.analysisId,
          language: Localizations.localeOf(context).languageCode,
        ),
      ),
    );

    if (updatedIngredients != null) {
      // Calculate new nutrition totals from ingredients
      double newCalories = 0.0;
      double newProteins = 0.0;
      double newCarbs = 0.0;
      double newFats = 0.0;
      
      for (final ingredient in updatedIngredients) {
        newCalories += ingredient.calories;
        newProteins += ingredient.protein;
        newCarbs += ingredient.carbs;
        newFats += ingredient.fat;
      }
      
      // Update the analysis data with new nutrition values
      final updatedData = {
        'detailedIngredients': updatedIngredients.map((i) => i.toJson()).toList(),
        'calories': newCalories,
        'macros': {
          'proteins': newProteins,
          'carbs': newCarbs,
          'fats': newFats,
        },
      };
      
      await _updateMealDetails(updatedData);
    }
  }
  
  // Add method to edit nutrition
  Future<void> _editNutrition() async {
    if (_analysisData == null) return;
    
    final calories = (_analysisData?['calories'] ?? 0.0).toDouble();
    final proteins = (_analysisData?['macros']?['proteins'] ?? 0.0).toDouble();
    final carbs = (_analysisData?['macros']?['carbs'] ?? 0.0).toDouble();
    final fats = (_analysisData?['macros']?['fats'] ?? 0.0).toDouble();
    
    // Get meal name for display
    final locale = Localizations.localeOf(context).languageCode;
    String mealName = 'Unknown';
    if (_analysisData?['mealName'] is Map) {
      mealName = _analysisData?['mealName']['en'] ?? _analysisData?['name'] ?? 'Unknown';
    } else {
      mealName = _analysisData?['mealName'] ?? _analysisData?['name'] ?? 'Unknown';
    }
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MealNutritionEditScreen(
          initialCalories: calories,
          initialProteins: proteins,
          initialCarbs: carbs,
          initialFats: fats,
          mealName: mealName,
        ),
      ),
    );
    
    if (result != null) {
      final updatedData = {
        'calories': result['calories'],
        'macros': {
          'proteins': result['proteins'],
          'carbs': result['carbs'],
          'fats': result['fats'],
        },
      };
      
      await _updateMealDetails(updatedData);
    }
  }

  // Helper method to safely get translated text with fallback
  String _safeTranslate(String key, [String? fallback]) {
    // For now, just return the fallback or generate from key to avoid localization errors
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    
    // Generate readable text from the key
    return key.split('.').last.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
  }







  @override
  Widget build(BuildContext context) {
    // Debug print for analysis data
    print('Analysis data in UI: ${_analysisData?.keys}');

    final locale = Localizations.localeOf(context).languageCode;
    
    // Get English meal name and translate on frontend
    String englishMealName;
    if (_analysisData?['mealName'] is Map) {
      // Handle old multilingual format (backward compatibility)
      englishMealName = _analysisData?['mealName']['en'] ?? _analysisData?['name'] ?? 'Unknown';
    } else {
      // Handle new English-only format
      englishMealName = _analysisData?['mealName'] ?? _analysisData?['name'] ?? 'Unknown';
    }
    
    // Translate meal name on frontend
    final mealName = (locale == 'en') 
        ? englishMealName 
        : TranslationService.translateIngredientStatic(englishMealName, locale);
    
    // Get English ingredients and translate on frontend
    List<String> englishIngredients = [];
    if (_analysisData?['ingredients'] is Map) {
      // Handle old multilingual format (backward compatibility)
      final Map<String, dynamic> ingMap = Map<String, dynamic>.from(_analysisData?['ingredients']);
      englishIngredients = List<String>.from(ingMap['en'] ?? []);
    } else if (_analysisData?['ingredients'] is List) {
      // Handle new English-only format
      englishIngredients = List<String>.from(_analysisData?['ingredients'] ?? []);
    }
    
    // Translate ingredients on frontend
    final ingredients = (locale == 'en') 
        ? englishIngredients 
        : englishIngredients.map((ingredient) => 
            TranslationService.translateIngredientStatic(ingredient, locale)
          ).toList();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(color: Colors.red[300]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: ClampingScrollPhysics(), // Prevent over-scrolling
        slivers: [
          // Image header that can scroll away
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.4,
            floating: false,
            pinned: false,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _showEditNameDialog,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                ),
                child: _analysisData?['imageUrl'] != null
                    ? ImageCacheService.getCachedImage(
                        _analysisData!['imageUrl'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        errorWidget: Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
            ),
          ),
          
          // Main content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // White content section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            // Meal Name
                            GestureDetector(
                              onTap: _showEditNameDialog,
                              child: Text(
                                mealName,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Calories and Benefits Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department, 
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                      size: 24
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${(_analysisData?['calories'] ?? 0.0).toStringAsFixed(0)} ${'common.calories'.tr()}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((_analysisData?['benefits'] as List?)?.isNotEmpty == true)
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${'details.rich_in'.tr()}\n',
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _translateValue('benefits', 
                                            List<String>.from(_analysisData?['benefits'] ?? []).first),
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Macros Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildNutrientItem(
                                  'common.protein'.tr(),
                                  '${(_analysisData?['macros']?['proteins'] ?? 0.0).toStringAsFixed(0)}g',
                                  'images/meat.png',
                                ),
                                _buildNutrientItem(
                                  'common.carbs'.tr(),
                                  '${(_analysisData?['macros']?['carbs'] ?? 0.0).toStringAsFixed(0)}g',
                                  'images/carbs.png',
                                ),
                                _buildNutrientItem(
                                  'common.fats'.tr(),
                                  '${(_analysisData?['macros']?['fats'] ?? 0.0).toStringAsFixed(0)}g',
                                  'images/fats.png',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Healthiness Row
                            if ((_analysisData?['healthiness'] ?? '').isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    _getHealthinessIcon(),
                                    color: _getHealthinessIconColor(),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _translateValue('healthiness', _analysisData?['healthiness'] ?? 'Unknown'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),

                            // Benefits description
                            if ((_analysisData?['benefits'] as List?)?.isNotEmpty == true)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${'details.meal_contains_nutrients'.tr()} ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'details.stay_healthy'.tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    ],
                  ),
                ),

                // Black section for ingredients and nutrients
                Container(
                  width: double.infinity,
                  color: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                // Nutrients Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${'details.nutrients'.tr()}:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.white70, size: 20),
                                      onPressed: _editNutrition,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${'common.protein'.tr()}: ${(_analysisData?['macros']?['proteins'] ?? 0.0).toStringAsFixed(1)}g | '
                                  '${'common.carbs'.tr()}: ${(_analysisData?['macros']?['carbs'] ?? 0.0).toStringAsFixed(1)}g | '
                                  '${'common.fats'.tr()}: ${(_analysisData?['macros']?['fats'] ?? 0.0).toStringAsFixed(1)}g',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Ingredients Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${'details.ingredients'.tr()}:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.white70, size: 20),
                                      onPressed: _editIngredients,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ingredients.isNotEmpty 
                                    ? ingredients.join(' | ')
                                    : 'details.no_ingredients'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),

                                // Source Section
                                if (_analysisData?['source'] != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    '${'details.source'.tr()}:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () async {
                                      final source = _analysisData?['source'];
                                      if (source != null && source.toString().startsWith('http')) {
                                        final uri = Uri.parse(source.toString());
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      }
                                    },
                                    child: Text(
                                      _analysisData?['source']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _analysisData?['source']?.toString()?.startsWith('http') ?? false
                                            ? Colors.blue[300]
                                            : Colors.white70,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                      ],
                      
                      // Bottom padding to ensure content is fully visible and account for safe area
                      SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(String label, String value, String? imagePath) {
    return Column(
      children: [
        if (imagePath != null)
          imagePath.contains('meat.png')
            ? ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.blue[400]!,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  imagePath,
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.restaurant, size: 28, color: Colors.grey[600]),
                ),
              )
            : Image.asset(
                imagePath,
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.restaurant, size: 28, color: Colors.grey[600]),
              )
        else
          Icon(Icons.restaurant, size: 28, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

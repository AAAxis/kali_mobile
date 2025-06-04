import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'ingridients_edit.dart';
import 'nutrition_edit_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../meal_analysis.dart';
import '../services/image_cache_service.dart';

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
    _loadAnalysisFromLocal().then((_) {
      _fetchAnalysisDetails().then((_) {
        _loadNotes(); // Load notes after analysis data is fetched
      });
    });
  }

  Future<void> _loadAnalysisFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('analysis_${widget.analysisId}');
      if (cached != null) {
        setState(() {
          _analysisData = json.decode(cached);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analysis from local: $e');
    }
  }

  Future<void> _saveAnalysisToLocal(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('analysis_${widget.analysisId}', json.encode(data));
    } catch (e) {
      print('Error saving analysis to local: $e');
    }
  }

  Future<void> _fetchAnalysisDetails() async {
    try {
      setState(() => _isLoading = true);
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

          // Convert Timestamp to ISO8601 string before saving to local
          if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
            data['timestamp'] =
                (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }

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
      final localMeal = localMeals.firstWhere(
        (meal) => meal.id == widget.analysisId,
        orElse: () => throw Exception('Meal not found in local storage'),
      );
      
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
        return _safeTranslate(translationMap[lowercaseValue]!, value);
      }

      // If no exact match, try partial matches
      for (var entry in translationMap.entries) {
        if (lowercaseValue.contains(entry.key)) {
          return _safeTranslate(entry.value, value);
        }
      }
    }

    // Return original value if no translation found
    return value;
  }

  void _showEditNameDialog() {
    final locale = Localizations.localeOf(context).languageCode;
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
            title: Text(_safeTranslate('details.edit_name', 'Edit Name')),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: _safeTranslate('details.meal_name', 'Meal Name')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_safeTranslate('dashboard.cancel', 'Cancel')),
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
                child: Text(_safeTranslate('dashboard.save', 'Save')),
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
          const SnackBar(content: Text('Meal details updated successfully')),
        );
      }
    } catch (e) {
      print('❌ Error updating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update meal: ${e.toString()}')),
        );
      }
    }
  }

  // Add method to edit ingredients
  Future<void> _editIngredients() async {
    if (_analysisData == null) return;
    // Only edit the current language's list if ingredients is a map
    final String currentLocale = Localizations.localeOf(context).languageCode;
    List<String> currentIngredients = [];
    if (_analysisData?['ingredients'] is Map) {
      final Map<String, dynamic> ingMap = Map<String, dynamic>.from(_analysisData?['ingredients']);
      currentIngredients = List<String>.from(
        ingMap[currentLocale] ?? ingMap['en'] ?? [],
      );
    } else if (_analysisData?['ingredients'] is List) {
      currentIngredients = List<String>.from(_analysisData?['ingredients'] ?? []);
    }

    final updatedIngredients = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientsEditScreen(
          ingredients: currentIngredients,
          mealId: widget.analysisId,
          language: currentLocale,
        ),
      ),
    );

    if (updatedIngredients != null) {
      setState(() {
        if (_analysisData != null) {
          if (_analysisData!['ingredients'] is Map) {
            final Map<String, dynamic> ingMap = Map<String, dynamic>.from(_analysisData!['ingredients']);
            ingMap[currentLocale] = updatedIngredients;
            _analysisData!['ingredients'] = ingMap;
          } else {
            _analysisData!['ingredients'] = updatedIngredients;
          }
        }
      });
      await _saveAnalysisToLocal(_analysisData!);
    }
  }
  
  // Add method to edit nutrition
  Future<void> _editNutrition() async {
    if (_analysisData == null) return;
    
    final calories = (_analysisData?['calories'] ?? 0.0).toDouble();
    final proteins = (_analysisData?['macros']?['proteins'] ?? 0.0).toDouble();
    final carbs = (_analysisData?['macros']?['carbs'] ?? 0.0).toDouble();
    final fats = (_analysisData?['macros']?['fats'] ?? 0.0).toDouble();
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionEditScreen(
          initialCalories: calories,
          initialProteins: proteins,
          initialCarbs: carbs,
          initialFats: fats,
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
    final mealName =
        (_analysisData?['mealName'] is Map)
            ? (_analysisData?['mealName'][locale] ?? _analysisData?['mealName']['en'] ?? 'Unknown')
            : (_analysisData?['name'] ?? _analysisData?['mealName'] ?? 'Unknown');
    // Multilingual ingredients support
    List<String> ingredients = [];
    if (_analysisData?['ingredients'] is Map) {
      final Map<String, dynamic> ingMap = Map<String, dynamic>.from(_analysisData?['ingredients']);
      ingredients = List<String>.from(
        ingMap[locale] ?? ingMap['en'] ?? [],
      );
    } else if (_analysisData?['ingredients'] is List) {
      ingredients = List<String>.from(_analysisData?['ingredients'] ?? []);
    }

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
      body: Stack(
        children: [
          // Main image - covers entire screen including status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
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
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

          // SafeArea for buttons and content
          SafeArea(
            child: Stack(
              children: [
                // Back Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // Edit Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _showEditNameDialog,
                    ),
                  ),
                ),

                // Main Content positioned relative to SafeArea
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.35 - MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      // White content section
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.r),
                            topRight: Radius.circular(30.r),
                          ),
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
                                  fontSize: 32.sp,
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
                                    Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${(_analysisData?['calories'] ?? 0.0).toStringAsFixed(0)} calories',
                                      style: TextStyle(
                                        fontSize: 24.sp,
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
                                          text: 'Rich in\n',
                                          style: TextStyle(
                                            fontSize: 17.sp,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _translateValue('benefits', 
                                            List<String>.from(_analysisData?['benefits'] ?? []).first),
                                          style: TextStyle(
                                            fontSize: 24.sp,
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
                                  _safeTranslate('details.protein', 'Protein'),
                                  '${(_analysisData?['macros']?['proteins'] ?? 0.0).toStringAsFixed(0)}g',
                                  'assets/Protein.png',
                                ),
                                _buildNutrientItem(
                                  _safeTranslate('details.carbs', 'Carbs'),
                                  '${(_analysisData?['macros']?['carbs'] ?? 0.0).toStringAsFixed(0)}g',
                                  'assets/Carb.png',
                                ),
                                _buildNutrientItem(
                                  _safeTranslate('details.fats', 'Fats'),
                                  '${(_analysisData?['macros']?['fats'] ?? 0.0).toStringAsFixed(0)}g',
                                  'assets/Fat.png',
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
                                      fontSize: 15.sp,
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
                                      text: 'This meal contains beneficial nutrients that will help you ',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Stay Healthy!',
                                      style: TextStyle(
                                        fontSize: 14.sp,
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
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nutrients Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _safeTranslate('details.nutrients', 'Nutrients') + ':',
                                      style: TextStyle(
                                        fontSize: 16.sp,
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
                                  'Protein: ${(_analysisData?['macros']?['proteins'] ?? 0.0).toStringAsFixed(1)}g | '
                                  'Carbs: ${(_analysisData?['macros']?['carbs'] ?? 0.0).toStringAsFixed(1)}g | '
                                  'Fats: ${(_analysisData?['macros']?['fats'] ?? 0.0).toStringAsFixed(1)}g',
                                  style: TextStyle(
                                    fontSize: 14.sp,
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
                                      _safeTranslate('details.ingredients', 'Ingredients') + ':',
                                      style: TextStyle(
                                        fontSize: 16.sp,
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
                                    : 'No ingredients available',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),

                                // Source Section
                                if (_analysisData?['source'] != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _safeTranslate('details.source', 'Source') + ':',
                                    style: TextStyle(
                                      fontSize: 16.sp,
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
                                        fontSize: 14.sp,
                                        color: _analysisData?['source']?.toString()?.startsWith('http') ?? false
                                            ? Colors.blue[300]
                                            : Colors.white70,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
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
          Image.asset(
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

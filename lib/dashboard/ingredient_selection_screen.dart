import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/meal_model.dart';
import '../services/nutrition_database_service.dart';
import '../services/translation_service.dart';

class IngredientSelectionScreen extends StatefulWidget {
  const IngredientSelectionScreen({Key? key}) : super(key: key);

  @override
  State<IngredientSelectionScreen> createState() => _IngredientSelectionScreenState();
}

class _IngredientSelectionScreenState extends State<IngredientSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allIngredients = [];
  List<String> _filteredIngredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeIngredients();
  }

  Future<void> _initializeIngredients() async {
    await NutritionDatabaseService.initialize();
    setState(() {
      _allIngredients = NutritionDatabaseService.getAllIngredients();
      _filteredIngredients = List.from(_allIngredients);
      _isLoading = false;
    });
  }

  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = List.from(_allIngredients);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredIngredients = _allIngredients.where((ingredient) {
          // Search in English (original name)
          if (ingredient.toLowerCase().contains(lowerQuery)) {
            return true;
          }
          
          // Search in current language (translated name)
          final translatedName = TranslationService.translateIngredientStatic(
            ingredient, 
            context.locale.languageCode
          ).toLowerCase();
          if (translatedName.contains(lowerQuery)) {
            return true;
          }
          
          // Search in all supported languages for better coverage
          final hebrewName = TranslationService.translateIngredientStatic(ingredient, 'he').toLowerCase();
          final russianName = TranslationService.translateIngredientStatic(ingredient, 'ru').toLowerCase();
          
          return hebrewName.contains(lowerQuery) || russianName.contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _selectIngredient(String ingredientName) {
    _showGramDialog(ingredientName);
  }

  // Get appropriate icon for ingredient category
  IconData _getIngredientIcon(String ingredientName) {
    final name = ingredientName.toLowerCase();
    
    // Fruits
    if (name.contains('apple') || name.contains('banana') || name.contains('orange') || 
        name.contains('berry') || name.contains('grape') || name.contains('lemon') ||
        name.contains('lime') || name.contains('fruit') || name.contains('cherry') ||
        name.contains('peach') || name.contains('pear') || name.contains('mango') ||
        name.contains('pineapple') || name.contains('kiwi') || name.contains('melon')) {
      return Icons.apple;
    }
    
    // Vegetables
    if (name.contains('tomato') || name.contains('onion') || name.contains('carrot') ||
        name.contains('potato') || name.contains('pepper') || name.contains('lettuce') ||
        name.contains('spinach') || name.contains('broccoli') || name.contains('cucumber') ||
        name.contains('mushroom') || name.contains('garlic') || name.contains('celery') ||
        name.contains('cabbage') || name.contains('vegetable')) {
      return Icons.eco;
    }
    
    // Proteins/Meat
    if (name.contains('chicken') || name.contains('beef') || name.contains('pork') ||
        name.contains('meat') || name.contains('fish') || name.contains('salmon') ||
        name.contains('tuna') || name.contains('egg') || name.contains('turkey') ||
        name.contains('bacon') || name.contains('ham') || name.contains('protein')) {
      return Icons.restaurant;
    }
    
    // Dairy
    if (name.contains('milk') || name.contains('cheese') || name.contains('yogurt') ||
        name.contains('butter') || name.contains('cream') || name.contains('dairy')) {
      return Icons.local_drink;
    }
    
    // Grains/Carbs
    if (name.contains('rice') || name.contains('bread') || name.contains('pasta') ||
        name.contains('flour') || name.contains('oats') || name.contains('quinoa') ||
        name.contains('barley') || name.contains('wheat') || name.contains('grain') ||
        name.contains('cereal') || name.contains('noodle')) {
      return Icons.grain;
    }
    
    // Nuts/Seeds
    if (name.contains('nut') || name.contains('seed') || name.contains('almond') ||
        name.contains('walnut') || name.contains('cashew') || name.contains('peanut') ||
        name.contains('sunflower') || name.contains('chia') || name.contains('flax')) {
      return Icons.scatter_plot;
    }
    
    // Oils/Fats
    if (name.contains('oil') || name.contains('olive') || name.contains('coconut oil') ||
        name.contains('avocado') || name.contains('fat')) {
      return Icons.opacity;
    }
    
    // Spices/Herbs
    if (name.contains('salt') || name.contains('pepper') || name.contains('herb') ||
        name.contains('spice') || name.contains('basil') || name.contains('oregano') ||
        name.contains('thyme') || name.contains('rosemary') || name.contains('parsley') ||
        name.contains('cinnamon') || name.contains('paprika') || name.contains('cumin')) {
      return Icons.grass;
    }
    
    // Default food icon
    return Icons.fastfood;
  }

  void _showGramDialog(String ingredientName) {
    final TextEditingController gramsController = TextEditingController(text: '100');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        title: Text(
          'ingredient_selection.add_ingredient'.tr(namedArgs: {'ingredient': TranslationService.translateIngredientStatic(ingredientName, context.locale.languageCode)}),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ingredient_selection.how_many_grams'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: gramsController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'ingredient_selection.weight'.tr(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                suffixText: 'g',
                suffixStyle: TextStyle(
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
              autofocus: true,
            ),
          ],
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
            onPressed: () {
              final grams = double.tryParse(gramsController.text) ?? 100.0;
              final nutrition = NutritionDatabaseService.calculateNutrition(ingredientName, grams);
              
              final ingredient = Ingredient(
                name: ingredientName,
                grams: grams,
                calories: nutrition['calories'] ?? 0.0,
                proteins: nutrition['proteins'] ?? 0.0,
                carbs: nutrition['carbs'] ?? 0.0,
                fats: nutrition['fats'] ?? 0.0,
              );

              Navigator.pop(context); // Close dialog
              Navigator.pop(context, ingredient); // Return to previous screen
            },
            child: Text(
              'common.add'.tr(),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          'ingredient_selection.title'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'ingredient_selection.search_placeholder'.tr(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
              ),
              onChanged: _filterIngredients,
            ),
          ),
          
          // Ingredients List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIngredients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ingredient_selection.no_ingredients_found'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ingredient_selection.try_different_search'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredientName = _filteredIngredients[index];
                          final nutrition = NutritionDatabaseService.calculateNutrition(ingredientName, 100);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isDark ? Colors.grey[800] : Colors.white,
                            child: ListTile(
                              onTap: () => _selectIngredient(ingredientName),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIngredientIcon(ingredientName),
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                TranslationService.translateIngredientStatic(ingredientName, context.locale.languageCode),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${'ingredient_selection.per_100g'.tr()}: ${nutrition['calories']?.toStringAsFixed(0) ?? '0'} ${'ingredient_selection.kcal_unit'.tr()} • '
                                  '${'ingredient_selection.protein'.tr()}: ${nutrition['proteins']?.toStringAsFixed(1) ?? '0'}${'ingredient_selection.grams_unit'.tr()} • '
                                  '${'ingredient_selection.carbs'.tr()}: ${nutrition['carbs']?.toStringAsFixed(1) ?? '0'}${'ingredient_selection.grams_unit'.tr()} • '
                                  '${'ingredient_selection.fats'.tr()}: ${nutrition['fats']?.toStringAsFixed(1) ?? '0'}${'ingredient_selection.grams_unit'.tr()}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 
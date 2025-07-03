import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/nutrition_database_service.dart';
import '../../../core/services/translation_service.dart';
import '../../models/meal_model.dart';
import 'ingridients_add.dart';

class IngredientsEditScreen extends StatefulWidget {
  final List<Ingredient> detailedIngredients;
  final String mealId;
  final String language;
  final Function(List<Ingredient>)? onSave;
  
  const IngredientsEditScreen({
    Key? key,
    required this.mealId,
    required this.detailedIngredients,
    required this.language,
    this.onSave,
  }) : super(key: key);

  @override
  State<IngredientsEditScreen> createState() => _IngredientsEditScreenState();
}

class _IngredientsEditScreenState extends State<IngredientsEditScreen> {
  late List<Ingredient> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = List<Ingredient>.from(widget.detailedIngredients);
    // Initialize the nutrition database
    NutritionDatabaseService.initialize();
    
    // If no detailed ingredients provided, show message
    if (_ingredients.isEmpty) {
      print('🔍 No detailed ingredients provided, user can add manually');
    } else {
      print('✅ Loaded ${_ingredients.length} detailed ingredients from OpenAI');
        }
  }

  void _addIngredient() async {
    final result = await Navigator.push<Ingredient>(
      context,
      MaterialPageRoute(
        builder: (context) => const IngredientSelectionScreen(),
      ),
    );
    if (result != null) {
      setState(() {
        _ingredients.add(result);
      });
    }
  }

  void _editIngredient(int index) async {
    final result = await _showEditIngredientDialog(_ingredients[index]);
    if (result != null) {
      setState(() {
        _ingredients[index] = result;
      });
    }
  }

  void _deleteIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  // Get appropriate icon for ingredient category (same logic as ingredient selection screen)
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

  Future<Ingredient?> _showEditIngredientDialog(Ingredient ingredient) async {
    final gramsController = TextEditingController(
      text: ingredient.grams.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double calories = 0.0;
    double proteins = 0.0;
    double carbs = 0.0;
    double fats = 0.0;

    void _updateNutrition() {
      final grams = double.tryParse(gramsController.text) ?? 100.0;
      final nutrition = NutritionDatabaseService.calculateNutrition(ingredient.name, grams);
      
      calories = nutrition['calories'] ?? 0.0;
      proteins = nutrition['proteins'] ?? 0.0;
      carbs = nutrition['carbs'] ?? 0.0;
      fats = nutrition['fats'] ?? 0.0;
    }

    // Initialize with current values
    _updateNutrition();

    return await showDialog<Ingredient>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          title: Text(
            'ingredient_selection.edit_ingredient'.tr(namedArgs: {'ingredient': TranslationService.translateIngredientStatic(ingredient.name, context.locale.languageCode)}),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gramsController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'ingredient_selection.weight_grams'.tr(),
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
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _updateNutrition();
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'ingredient_selection.nutrition_information'.tr()}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'ingredient_selection.calories'.tr()}: ${calories.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${'ingredient_selection.protein'.tr()}: ${proteins.toStringAsFixed(1)}g',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'ingredient_selection.carbs'.tr()}: ${carbs.toStringAsFixed(1)}g',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${'ingredient_selection.fats'.tr()}: ${fats.toStringAsFixed(1)}g',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

                final updatedIngredient = Ingredient(
                  name: ingredient.name,
                  grams: grams,
                  calories: calories,
                  protein: proteins,
                  carbs: carbs,
                  fat: fats,
                );

                Navigator.pop(context, updatedIngredient);
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
      ),
    );
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.mealId.isNotEmpty) {
      try {
        // Update Firebase with detailed ingredients
        await FirebaseFirestore.instance
            .collection('analyzed_meals')
            .doc(widget.mealId)
            .update({
          'detailedIngredients': _ingredients.map((i) => i.toJson()).toList(),
        });
      } catch (e) {
        print('Error updating ingredients in Firebase: $e');
      }
    }
    
    if (widget.onSave != null) {
      widget.onSave!(_ingredients);
    }
    Navigator.pop(context, _ingredients);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'ingredients_edit.title'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _submit,
        ),
      ),
      body: _ingredients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ingredients_edit.no_ingredients'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ingredients_edit.tap_add_ingredients'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                return Dismissible(
                  key: Key('${ingredient.name}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text(
                          'Delete Ingredient',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'ingredients_edit.remove_ingredient'.tr(namedArgs: {'ingredient': TranslationService.translateIngredientStatic(ingredient.name, context.locale.languageCode)}),
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'common.cancel'.tr(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'ingredients_edit.delete'.tr(),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    _deleteIngredient(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${TranslationService.translateIngredientStatic(ingredient.name, context.locale.languageCode)} ${'common.removed'.tr()}'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    child: ListTile(
                      onTap: () => _editIngredient(index),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIngredientIcon(ingredient.name),
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        TranslationService.translateIngredientStatic(ingredient.name, context.locale.languageCode),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'ingredient_selection.weight'.tr()}: ${ingredient.grams.toStringAsFixed(0)}g',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${ingredient.calories.toStringAsFixed(0)} ${'ingredient_selection.kcal_unit'.tr()} • '
                            '${'ingredient_selection.protein'.tr()}: ${ingredient.protein.toStringAsFixed(1)}${'ingredient_selection.grams_unit'.tr()} • '
                            '${'ingredient_selection.carbs'.tr()}: ${ingredient.carbs.toStringAsFixed(1)}${'ingredient_selection.grams_unit'.tr()} • '
                            '${'ingredient_selection.fats'.tr()}: ${ingredient.fat.toStringAsFixed(1)}${'ingredient_selection.grams_unit'.tr()}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredient,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

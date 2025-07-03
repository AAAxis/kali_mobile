import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MealNutritionEditScreen extends StatefulWidget {
  final double initialCalories;
  final double initialProteins;
  final double initialCarbs;
  final double initialFats;
  final String mealName;

  const MealNutritionEditScreen({
    Key? key,
    required this.initialCalories,
    required this.initialProteins,
    required this.initialCarbs,
    required this.initialFats,
    required this.mealName,
  }) : super(key: key);

  @override
  State<MealNutritionEditScreen> createState() => _MealNutritionEditScreenState();
}

class _MealNutritionEditScreenState extends State<MealNutritionEditScreen> {
  late double calories;
  late double proteins;
  late double carbs;
  late double fats;

  @override
  void initState() {
    super.initState();
    calories = widget.initialCalories;
    proteins = widget.initialProteins;
    carbs = widget.initialCarbs;
    fats = widget.initialFats;
  }

  void _saveChanges() {
    print('✅ Meal nutrition updated:');
    print('  - Meal: ${widget.mealName}');
    print('  - Calories: ${calories.round()}');
    print('  - Protein: ${proteins.round()}g');
    print('  - Carbs: ${carbs.round()}g');
    print('  - Fats: ${fats.round()}g');
    
    Navigator.pop(context, {
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveChanges();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'meal_nutrition_edit.title'.tr(),
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
            onPressed: () => _saveChanges(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'meal_nutrition_edit.meal_nutrition_info'.tr(),
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.mealName,
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSlider(
                      'meal_nutrition_edit.calories',
                      calories,
                      0,
                      2000,
                      Colors.black,
                      (v) => setState(() => calories = v),
                      unitKey: 'meal_nutrition_edit.kcal',
                    ),
                    _buildSlider(
                      'meal_nutrition_edit.protein',
                      proteins,
                      0,
                      100,
                      Colors.red[400]!,
                      (v) => setState(() => proteins = v),
                      unitKey: 'meal_nutrition_edit.grams',
                    ),
                    _buildSlider(
                      'meal_nutrition_edit.carbs',
                      carbs,
                      0,
                      300,
                      Colors.orange[400]!,
                      (v) => setState(() => carbs = v),
                      unitKey: 'meal_nutrition_edit.grams',
                    ),
                    _buildSlider(
                      'meal_nutrition_edit.fats',
                      fats,
                      0,
                      100,
                      Colors.blue[400]!,
                      (v) => setState(() => fats = v),
                      unitKey: 'meal_nutrition_edit.grams',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String labelKey, double value, double min, double max, Color color, Function(double) onChanged, {String? unitKey}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEditDialog(labelKey, value, min, max, color, onChanged, unitKey),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labelKey.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  '${value.round()}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unitKey?.tr() ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String labelKey, double currentValue, double min, double max, Color color, Function(double) onChanged, String? unitKey) {
    final controller = TextEditingController(text: currentValue.round().toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'common.edit'.tr() + ' ${labelKey.tr()}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: '${labelKey.tr()} (${unitKey?.tr() ?? ''})',
                labelStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                suffixText: unitKey?.tr() ?? '',
                suffixStyle: const TextStyle(color: Colors.black54),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'common.range'.tr() + ': ${min.round()} - ${max.round()} ${unitKey?.tr() ?? ''}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null && newValue >= min && newValue <= max) {
                onChanged(newValue);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
} 
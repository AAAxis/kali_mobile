import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class NutritionGoalsEditScreen extends StatefulWidget {
  final double initialCalories;
  final double initialProteins;
  final double initialCarbs;
  final double initialFats;

  const NutritionGoalsEditScreen({
    Key? key,
    required this.initialCalories,
    required this.initialProteins,
    required this.initialCarbs,
    required this.initialFats,
  }) : super(key: key);

  @override
  State<NutritionGoalsEditScreen> createState() => _NutritionGoalsEditScreenState();
}

class _NutritionGoalsEditScreenState extends State<NutritionGoalsEditScreen> {
  late double calories;
  late double proteins;
  late double carbs;
  late double fats;

  @override
  void initState() {
    super.initState();
    calories = widget.initialCalories;
    proteins = widget.initialProteins.clamp(0, 100);
    carbs = widget.initialCarbs.clamp(0, 300);
    fats = widget.initialFats.clamp(0, 100);
  }

  void _saveChanges() async {
    try {
      // Save to SharedPreferences using both key sets for consistency
      final prefs = await SharedPreferences.getInstance();
      
      // Save to wizard keys (daily_*)
      await prefs.setDouble('daily_calories', calories);
      await prefs.setDouble('daily_protein', proteins);
      await prefs.setDouble('daily_carbs', carbs);
      await prefs.setDouble('daily_fats', fats);
      
      // Save to dashboard keys (nutrition_goal_*)
      await prefs.setDouble('nutrition_goal_calories', calories);
      await prefs.setDouble('nutrition_goal_protein', proteins);
      await prefs.setDouble('nutrition_goal_carbs', carbs);
      await prefs.setDouble('nutrition_goal_fats', fats);
      
      // Also set a flag to indicate goals have been set
      await prefs.setBool('nutrition_goals_set', true);
      
      print('✅ Daily nutrition goals saved to both key sets:');
      print('  - Calories: ${calories.round()}');
      print('  - Protein: ${proteins.round()}g');
      print('  - Carbs: ${carbs.round()}g');
      print('  - Fats: ${fats.round()}g');
      
    } catch (e) {
      print('❌ Error saving nutrition goals: $e');
    }
    
    Navigator.pop(context, {
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    return WillPopScope(
      onWillPop: () async {
        _saveChanges();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('nutrition_goals_edit.title'.tr()),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
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
                    // Header explaining this is for daily goals
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'nutrition_goals_edit.daily_targets_info'.tr(),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSlider(
                      'nutrition_goals_edit.daily_calories',
                      calories,
                      0,
                      4000,
                      isDark ? Colors.white : Colors.black,
                      (v) => setState(() => calories = v),
                      unitKey: 'nutrition_goals_edit.kcal',
                    ),
                    _buildSlider(
                      'nutrition_goals_edit.daily_protein',
                      proteins,
                      0,
                      100,
                      Colors.red[400]!,
                      (v) => setState(() => proteins = v),
                      unitKey: 'nutrition_goals_edit.grams',
                    ),
                    _buildSlider(
                      'nutrition_goals_edit.daily_carbs',
                      carbs,
                      0,
                      300,
                      Colors.orange[400]!,
                      (v) => setState(() => carbs = v),
                      unitKey: 'nutrition_goals_edit.grams',
                    ),
                    _buildSlider(
                      'nutrition_goals_edit.daily_fats',
                      fats,
                      0,
                      100,
                      Colors.blue[400]!,
                      (v) => setState(() => fats = v),
                      unitKey: 'nutrition_goals_edit.grams',
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
                  borderSide: const BorderSide(color: Colors.blue),
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
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null && newValue >= min && newValue <= max) {
                _adjustValues(labelKey, newValue, onChanged);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _adjustValues(String changedLabel, double newValue, Function(double) onChanged) {
    final oldValue = _getCurrentValue(changedLabel);
    final difference = newValue - oldValue;
    
    // Apply the change to the selected value
    onChanged(newValue);
    
    // Adjust other values based on the change
    if (changedLabel == 'nutrition_goals_edit.daily_calories') {
      // When calories change, adjust macronutrients proportionally
      final totalMacros = proteins + carbs + fats;
      if (totalMacros > 0) {
        final proteinRatio = proteins / totalMacros;
        final carbsRatio = carbs / totalMacros;
        final fatsRatio = fats / totalMacros;
        
        // Adjust based on calorie change (rough approximation)
        final calorieDiff = difference * 4; // 4 calories per gram of protein/carbs
        final macroAdjustment = calorieDiff / 4; // Distribute across macros
        
        setState(() {
          proteins = (proteins + macroAdjustment * proteinRatio).clamp(0, 100);
          carbs = (carbs + macroAdjustment * carbsRatio).clamp(0, 300);
          fats = (fats + macroAdjustment * fatsRatio).clamp(0, 100);
        });
      }
    } else if (changedLabel == 'nutrition_goals_edit.daily_protein') {
      // When protein increases, decrease carbs (protein is more satiating)
      final carbsReduction = difference * 0.5; // Reduce carbs by half the protein increase
      setState(() {
        carbs = (carbs - carbsReduction).clamp(0, 300);
      });
    } else if (changedLabel == 'nutrition_goals_edit.daily_carbs') {
      // When carbs increase, decrease fats (carbs and fats are energy sources)
      final fatsReduction = difference * 0.3; // Reduce fats by 30% of carbs increase
      setState(() {
        fats = (fats - fatsReduction).clamp(0, 100);
      });
    } else if (changedLabel == 'nutrition_goals_edit.daily_fats') {
      // When fats increase, decrease carbs
      final carbsReduction = difference * 0.4; // Reduce carbs by 40% of fats increase
      setState(() {
        carbs = (carbs - carbsReduction).clamp(0, 300);
      });
    }
  }

  double _getCurrentValue(String label) {
    switch (label) {
      case 'nutrition_goals_edit.daily_calories':
        return calories;
      case 'nutrition_goals_edit.daily_protein':
        return proteins;
      case 'nutrition_goals_edit.daily_carbs':
        return carbs;
      case 'nutrition_goals_edit.daily_fats':
        return fats;
      default:
        return 0;
    }
  }
}

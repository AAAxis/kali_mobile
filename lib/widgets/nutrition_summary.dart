import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../meal_analysis.dart';

class NutritionSummary extends StatefulWidget {
  final List<Meal> meals;
  final Function(DateTime)? onDateChanged;

  const NutritionSummary({
    Key? key,
    required this.meals,
    this.onDateChanged,
  }) : super(key: key);

  @override
  State<NutritionSummary> createState() => _NutritionSummaryState();
}

class _NutritionSummaryState extends State<NutritionSummary> {
  DateTime selectedDate = DateTime.now();
  bool _goalsSet = false;
  double _caloriesGoal = 2000;
  double _proteinGoal = 150;
  double _carbsGoal = 300;
  double _fatsGoal = 65;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
    // Set initial selected date to today and notify parent
    final today = DateTime.now();
    selectedDate = DateTime(today.year, today.month, today.day);
    // Notify parent about the initial date selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateChanged?.call(selectedDate);
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 365));
    final todayIndex = today.difference(startDate).inDays;
    
    // Each day takes about 50 pixels (40 width + 10 margin)
    final scrollPosition = (todayIndex * 50.0) - (MediaQuery.of(context).size.width / 2) + 25;
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load from both key sets for consistency
      final caloriesGoal = prefs.getDouble('nutrition_goal_calories') ?? 
                          prefs.getDouble('daily_calories') ?? 2000;
      final proteinGoal = prefs.getDouble('nutrition_goal_protein') ?? 
                         prefs.getDouble('daily_protein') ?? 150;
      final carbsGoal = prefs.getDouble('nutrition_goal_carbs') ?? 
                       prefs.getDouble('daily_carbs') ?? 300;
      final fatsGoal = prefs.getDouble('nutrition_goal_fats') ?? 
                      prefs.getDouble('daily_fats') ?? 65;
      
      setState(() {
        _goalsSet = prefs.getBool('nutrition_goals_set') ?? false;
        _caloriesGoal = caloriesGoal;
        _proteinGoal = proteinGoal;
        _carbsGoal = carbsGoal;
        _fatsGoal = fatsGoal;
      });
      
      print('📊 Nutrition Summary - Loaded Goals:');
      print('  - Goals Set: $_goalsSet');
      print('  - Calories: ${_caloriesGoal.round()}');
      print('  - Protein: ${_proteinGoal.round()}g');
      print('  - Carbs: ${_carbsGoal.round()}g');
      print('  - Fats: ${_fatsGoal.round()}g');
      
    } catch (e) {
      print('❌ Error loading nutrition goals: $e');
    }
  }

  Widget _buildCalendarStrip() {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 365));
    final endDate = today.add(const Duration(days: 365));
    final totalDays = endDate.difference(startDate).inDays;
    
    return Container(
      height: 60,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final isSelected = normalizedDate == selectedDate;
          final isToday = normalizedDate == DateTime(today.year, today.month, today.day);
          
          // Check if this date has meals
          final hasMeals = widget.meals.any((meal) {
            final mealDate = DateTime(meal.timestamp.year, meal.timestamp.month, meal.timestamp.day);
            return mealDate == normalizedDate && !meal.isAnalyzing && !meal.analysisFailed;
          });
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = normalizedDate;
              });
              widget.onDateChanged?.call(normalizedDate);
            },
            child: Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : (isToday 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      border: isToday && !isSelected
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : (isToday 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface),
                              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasMeals && !isSelected)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _calculateNutritionForDate(DateTime date) {
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Filter meals for the selected day only
    final dayMeals = widget.meals.where((meal) =>
        meal.timestamp.isAfter(startOfDay) &&
        meal.timestamp.isBefore(endOfDay) &&
        !meal.isAnalyzing &&
        !meal.analysisFailed
    ).toList();

    for (final meal in dayMeals) {
      totalCalories += meal.calories;
      totalProteins += meal.macros['proteins'] ?? 0.0;
      totalCarbs += meal.macros['carbs'] ?? 0.0;
      totalFats += meal.macros['fats'] ?? 0.0;
    }

    return {
      'calories': totalCalories,
      'proteins': totalProteins,
      'carbs': totalCarbs,
      'fats': totalFats,
    };
  }

  String _formatNutritionValue(double value) {
    // If the value is a whole number (or very close to it), show without decimals
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    // Otherwise, show one decimal place
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = _calculateNutritionForDate(selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      children: [
        // Calendar strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildCalendarStrip(),
        ),
        const SizedBox(height: 12),
        // Wide calories card on top
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildCaloriesCard(
            nutrition['calories']!,
            _caloriesGoal,
            textColor,
            subTextColor,
          ),
        ),
        const SizedBox(height: 12),
        // 3 macro cards in a row below
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildNutritionCardWithImageAndProgress(
                'nutrition.protein_left',
                '${(_proteinGoal - nutrition['proteins']!).clamp(0, double.infinity).round()}g',
                '',
                'images/meat.png',
                Colors.blue[400]!,
                textColor,
                subTextColor,
                nutrition['proteins']!,
                _proteinGoal,
              ),
              const SizedBox(width: 12),
              _buildNutritionCardWithImageAndProgress(
                'nutrition.carbs_left',
                '${(_carbsGoal - nutrition['carbs']!).clamp(0, double.infinity).round()}g',
                '',
                'images/carbs.png',
                Colors.orange[400]!,
                textColor,
                subTextColor,
                nutrition['carbs']!,
                _carbsGoal,
              ),
              const SizedBox(width: 12),
              _buildNutritionCardWithImageAndProgress(
                'nutrition.fats_left',
                '${(_fatsGoal - nutrition['fats']!).clamp(0, double.infinity).round()}g',
                '',
                'images/fats.png',
                Colors.green[400]!,
                textColor,
                subTextColor,
                nutrition['fats']!,
                _fatsGoal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    Color textColor,
    Color? subTextColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCardWithImage(
    String label,
    String value,
    String unit,
    String imagePath,
    Color color,
    Color textColor,
    Color? subTextColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: 18,
              height: 18,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCardWithProgress(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    Color textColor,
    Color? subTextColor,
    double currentValue,
    double goalValue,
  ) {
    final progress = (currentValue / goalValue).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark 
                  ? Colors.white.withOpacity(0.9)
                  : textColor,
              size: 18,
            ),
            const SizedBox(height: 8),
            // Progress bar with percentage inside
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
               
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value$unit',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesCard(
    double currentCalories,
    double goalCalories,
    Color textColor,
    Color? subTextColor,
  ) {
    final caloriesLeft = (goalCalories - currentCalories).clamp(0, double.infinity);
    final progress = (currentCalories / goalCalories).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.transparent, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flame icon with circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.red.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caloriesLeft.round().toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'nutrition.calories_left'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCardWithImageAndProgress(
    String labelKey,
    String value,
    String unit,
    String imagePath,
    Color color,
    Color textColor,
    Color? subTextColor,
    double currentValue,
    double goalValue,
  ) {
    final progress = (currentValue / goalValue).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? Colors.transparent, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon with circular progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: imagePath.contains('meat.png')
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.blue[400]!,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            imagePath,
                            width: 16,
                            height: 16,
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          width: 16,
                          height: 16,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Value and unit
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Translated label
            Text(
              labelKey.tr(),
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_animations.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/services/calculation_service.dart';
import 'wizard18.dart';  // Add import for Wizard18
import '../../../core/custom_widgets/calorie_gauage.dart';

class Wizard11 extends StatefulWidget {
  const Wizard11({super.key});

  @override
  State<Wizard11> createState() => _Wizard11State();
}

class _Wizard11State extends State<Wizard11> {
  double calories = 2000;
  double proteins = 150;
  double carbs = 300;
  double fats = 65;

  @override
  void initState() {
    super.initState();
    _calculateAndLoadNutritionGoals();
  }

  Future<void> _calculateAndLoadNutritionGoals() async {
    try {
      // Calculate nutrition goals based on wizard data
      final calculatedGoals = await CalculationService.calculateNutritionGoals();
      
      setState(() {
        calories = calculatedGoals['calories']!;
        proteins = calculatedGoals['protein']!;
        carbs = calculatedGoals['carbs']!;
        fats = calculatedGoals['fats']!;
      });
    } catch (e) {
      print('Error calculating nutrition goals: $e');
      // Fallback to default values
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        calories = prefs.getDouble('nutrition_goal_calories') ?? 2000;
        proteins = prefs.getDouble('nutrition_goal_protein') ?? 150;
        carbs = prefs.getDouble('nutrition_goal_carbs') ?? 300;
        fats = prefs.getDouble('nutrition_goal_fats') ?? 65;
      });
    }
  }

  Future<void> _saveNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('nutrition_goal_calories', calories);
    await prefs.setDouble('nutrition_goal_protein', proteins);
    await prefs.setDouble('nutrition_goal_carbs', carbs);
    await prefs.setDouble('nutrition_goal_fats', fats);
  }

  Future<Map<String, dynamic>> _calculateTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final currentWeight = prefs.getDouble('wizard_weight') ?? 70.0;
    final targetWeight = prefs.getDouble('wizard_target_weight') ?? 65.0;
    final goal = prefs.getInt('wizard_goal') ?? 0;
    final goalSpeed = prefs.getDouble('wizard_goal_speed') ?? 0.8;
    final isMetric = prefs.getBool('wizard_is_metric') ?? true;
    
    // Debug print
    print('🔍 Timeline Calculation Debug:');
    print('  - Current Weight: $currentWeight kg');
    print('  - Target Weight: $targetWeight kg');
    print('  - Weight Difference: ${(targetWeight - currentWeight).abs()} kg');
    print('  - Goal Speed: $goalSpeed kg/week');
    print('  - Goal: $goal (0=lose, 1=maintain, 2=gain)');
    
    // For maintain weight, no timeline needed
    if (goal == 1) {
      return {
        'goal': goal,
        'weightDifference': 0.0,
        'targetDate': DateTime.now(),
      };
    }
    
    // For lose/gain weight, use the actual target weight from wizard
    final timeline = CalculationService.calculateTimeline(
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      goalSpeed: goalSpeed,
      isMetric: isMetric,
    );
    
    // Debug print timeline results
    print('  - Weeks to Goal: ${timeline['weeksToGoal']}');
    print('  - Days to Goal: ${timeline['daysToGoal']}');
    print('  - Target Date: ${timeline['targetDate']}');
    
    return {
      ...timeline,
      'goal': goal,
    };
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _showEditDialog(String title, double currentValue, Function(double) onSave) async {
    final controller = TextEditingController(text: currentValue.toStringAsFixed(0));
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Edit $title',
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
                labelText: title,
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
                suffixText: title == 'Calories' ? 'kcal' : 'g',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null && newValue > 0) {
                onSave(newValue);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  SizedBox(height: Constants.beforeIcon),
                  Center(child: Image.asset(AppIcons.kali, color: colorScheme.primary)),
                  SizedBox(height: Constants.afterIcon),

                  Center(
                    child: Image.asset(
                      AppAnimations.cloud,
                      height: 180.h,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
                      cacheWidth: (ScreenUtil().screenWidth * 0.6).toInt(),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Center(
                    child: Text(
                      "Congratulations!!",
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: Text(
                      "Your custom plan is all set!",
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 18.h),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _calculateTimeline(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final timeline = snapshot.data!;
                        final goal = timeline['goal'] as int;
                        final weightDifference = timeline['weightDifference'] as double;
                        final targetDate = timeline['targetDate'] as DateTime;
                        final goalText = goal == 0 ? 'lose' : goal == 1 ? 'maintain' : 'gain';
                        
                        return Column(
                          children: [
                            Text(
                              "You should $goalText:",
                              style: AppTextStyles.bodyLarge.copyWith(
                                  color: colorScheme.onSurface, fontSize: 20),
                            ),
                            SizedBox(height: 5.h),
                            Card(
                              margin: EdgeInsets.symmetric(horizontal: 70.sp),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.r)),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${weightDifference.toStringAsFixed(1)} kg by ${_formatDate(targetDate)}",
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        "(${(timeline['weeksToGoal'] as double).toStringAsFixed(1)} weeks)",
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Text(
                              "Calculating your goal...",
                              style: AppTextStyles.bodyLarge.copyWith(
                                  color: colorScheme.onSurface, fontSize: 20),
                            ),
                            SizedBox(height: 5.h),
                            const CircularProgressIndicator(),
                          ],
                        );
                      }
                    },
                  ),

                  SizedBox(height: 28.h),

                  // Recommendations Section
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily recommendations",
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "You can edit this anytime",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color:
                                  colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // 2x2 Nutrition Cards Grid
                          Column(
                            children: [
                              // Row 1: Calories and Proteins
                              Row(
                                children: [
                                  Expanded(
                                    child: CalorieGauge(
                                      title: 'Calories',
                                      icon: Icon(Icons.local_fire_department_rounded, color: Colors.redAccent),
                                      unit: 'kcal',
                                      currentValue: calories,
                                      maxValue: 3000,
                                      filledColor: Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: CalorieGauge(
                                      title: 'Protein',
                                      icon: Icon(Icons.fitness_center, color: Colors.green),
                                      unit: 'g',
                                      currentValue: proteins,
                                      maxValue: 300,
                                      filledColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              // Row 2: Carbs and Fats
                              Row(
                                children: [
                                  Expanded(
                                    child: CalorieGauge(
                                      title: 'Carbs',
                                      icon: Icon(Icons.bakery_dining, color: Colors.amber),
                                      unit: 'g',
                                      currentValue: carbs,
                                      maxValue: 500,
                                      filledColor: Colors.amber,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: CalorieGauge(
                                      title: 'Fats',
                                      icon: Icon(Icons.opacity, color: Colors.red),
                                      unit: 'g',
                                      currentValue: fats,
                                      maxValue: 200,
                                      filledColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Goals section
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r)),
                    elevation: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 16.w),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "How to reach your goals:",
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _GoalRow(
                              icon: AppIcons.goal1,
                              color: Colors.green[600]!,
                              text: "Use health scores to improve your routine",
                            ),
                            SizedBox(height: 8.h),
                            _GoalRow(
                              icon: AppIcons.goal2,
                              color: Colors.indigo,
                              text: "Follow your daily calorie recommendations",
                            ),
                            SizedBox(height: 8.h),
                            _GoalRow(
                              icon: AppIcons.goal3,
                              color: Colors.redAccent,
                              text: "Track your food",
                            ),
                            SizedBox(height: 8.h),
                            _GoalRow(
                              icon: AppIcons.goal4,
                              color: Colors.teal,
                              text: "Balance your carbs, proteins and fats.",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Continue Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
                    child: WizardButton(
                      label: 'Continue',
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const Wizard18(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 300),
                          ),
                        );
                      },
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String icon;
  final Color color;
  final String text;

  const _GoalRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        height: 50.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 240),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.only(left: 4.sp),
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Image.asset(
                icon,
                height: 18.h,
                width: 18.w,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

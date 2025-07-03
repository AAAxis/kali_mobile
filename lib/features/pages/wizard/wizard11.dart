import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_animations.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/calorie_gauage.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import 'wizard18.dart';  // Add import for Wizard18

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
    _loadNutritionGoals();
  }

  Future<void> _loadNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      calories = prefs.getDouble('nutrition_goal_calories') ?? 2000;
      proteins = prefs.getDouble('nutrition_goal_protein') ?? 150;
      carbs = prefs.getDouble('nutrition_goal_carbs') ?? 300;
      fats = prefs.getDouble('nutrition_goal_fats') ?? 65;
    });
  }

  Future<void> _saveNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('nutrition_goal_calories', calories);
    await prefs.setDouble('nutrition_goal_protein', proteins);
    await prefs.setDouble('nutrition_goal_carbs', carbs);
    await prefs.setDouble('nutrition_goal_fats', fats);
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
                  Column(
                    children: [
                      Text(
                        "You should lose:",
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
                            child: Text(
                              "10.0 Kgs by July 31",
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

                          // 2x2 CalorieGauge Grid
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 16.h,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.1,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await _showEditDialog('Calories', calories, (value) {
                                    setState(() => calories = value);
                                    _saveNutritionGoals();
                                  });
                                },
                                child: CalorieGauge(
                                  currentValue: proteins,
                                  maxValue: 200,
                                  filledColor: Colors.black87,
                                  unfilledColor: Colors.grey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _showEditDialog('Proteins', proteins, (value) {
                                    setState(() => proteins = value);
                                    _saveNutritionGoals();
                                  });
                                },
                                child: CalorieGauge(
                                  currentValue: proteins,
                                  maxValue: 200,
                                  filledColor: Colors.green,
                                  unfilledColor: Colors.grey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _showEditDialog('Carbs', carbs, (value) {
                                    setState(() => carbs = value);
                                    _saveNutritionGoals();
                                  });
                                },
                                child: CalorieGauge(
                                  currentValue: carbs,
                                  maxValue: 100,
                                  filledColor: Colors.amber,
                                  unfilledColor: Colors.grey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _showEditDialog('Fats', fats, (value) {
                                    setState(() => fats = value);
                                    _saveNutritionGoals();
                                  });
                                },
                                child: CalorieGauge(
                                  currentValue: fats,
                                  maxValue: 150,
                                  filledColor: Colors.red,
                                  unfilledColor: Colors.grey,
                                ),
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

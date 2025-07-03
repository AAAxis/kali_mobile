import 'package:flutter/material.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_text_styles.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      Provider.of<LoadingProvider>(context, listen: false).startLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = context.watch<LoadingProvider>().progress;
    final provider = Provider.of<WizardProvider>(context, listen: false);

    final items = ['Calories', 'Carbohydrates', 'Fats', 'Proteins'];
    final checkedCount = (progress ~/ 25).clamp(0, 4);
    final isCompleted = progress >= 100;

    return AbsorbPointer(
      absorbing: !isCompleted,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                Image.asset(AppIcons.kali, color: colorScheme.primary),
                SizedBox(height: 60.h),

                // Percentage
                Text(
                  '${progress.toInt()}%',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 64.sp,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Building your personalized\nnutrition guide',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 30.h),

                // Gradient progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Stack(
                    children: [
                      Container(
                        height: 8.h,
                        width: double.infinity,
                        color: colorScheme.outlineVariant,
                      ),
                      Container(
                        height: 8.h,
                        width: MediaQuery.of(context).size.width *
                            (progress / 100),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00E3FF), // cyan
                              Color(0xFF3870FF), // blue
                              Color(0xFF00B4D8), // light blue
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),
                Text(
                  'Optimizing results just for you...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 40.h),

                // Info Card
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: 20.h, horizontal: 18.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Recommendations',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...List.generate(items.length, (index) {
                        final checked = index < checkedCount;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '- ${items[index]}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (checked)
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 18.sp,
                                ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 6.h),
                      Text(
                        'Goal Instructions',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                if (isCompleted) ...[
                  WizardButton(
                    label: 'Continue',
                    onPressed: () => provider.nextPage(),
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                  ),
                  SizedBox(height: 24.h),
                ],
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

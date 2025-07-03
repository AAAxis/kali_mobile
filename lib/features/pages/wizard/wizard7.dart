import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';

class Wizard7 extends StatelessWidget {
  const Wizard7({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WizardProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final isKg = provider.isKg;
    final weight = provider.weight;
    final min = isKg ? 40.0 : 90.0;
    final max = isKg ? 150.0 : 330.0;
    final step = 0.1;
    final itemCount = ((max - min) / step).floor() + 1;
    final itemExtent = isKg ? 20.w : 26.w;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: Constants.beforeIcon),
            Image.asset(AppIcons.kali, color: colorScheme.primary),
            SizedBox(height: Constants.afterIcon),
            Text(
              "What's your dream\nweight?",
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),

            /// Toggle KG/Lbs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitToggleButton(
                  label: "Lbs",
                  isActive: !isKg,
                  onTap: () => provider.toggleUnit(false),
                ),
                SizedBox(width: 18.w),
                _UnitToggleButton(
                  label: "KGs",
                  isActive: isKg,
                  onTap: () => provider.toggleUnit(true),
                ),
              ],
            ),
            SizedBox(height: 80.h),

            /// Weight Display
            Text(
              '${weight.toStringAsFixed(1)} ${isKg ? "Kg" : "Lb"}',
              style: AppTextStyles.headingLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 40.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 30.h,
            ),

            /// Ruler Picker
            SizedBox(
              height: 100.h,
              child: RotatedBox(
                quarterTurns: -1,
                child: ListWheelScrollView.useDelegate(
                  controller: provider.scrollController,
                  itemExtent: itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    final value = min + (index * step);
                    provider.setWeight(value);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: itemCount,
                    builder: (context, idx) {
                      final value = min + idx * step;
                      final isSelected = (value.toStringAsFixed(1) ==
                          weight.toStringAsFixed(1));
                      final isWholeUnit = (value * 10) % 10 == 0;

                      double height;
                      if (isSelected) {
                        height = 55.h; // tallest line
                      } else if (isWholeUnit) {
                        height = 40.h; // medium line
                      } else {
                        height = 25.h; // short line
                      }

                      return RotatedBox(
                        quarterTurns: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isSelected ? 3.5.w : 2.w,
                              height: height,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            if (isWholeUnit)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    value.toStringAsFixed(0),
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const Spacer(),

            WizardButton(
              label: 'Continue',
              onPressed: () => provider.nextPage(),
              padding: EdgeInsets.symmetric(vertical: 18.h),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _UnitToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _UnitToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.w,
        height: 42.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.7),
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }
}

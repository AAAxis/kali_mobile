import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';

class Wizard3 extends StatelessWidget {
  const Wizard3({super.key});

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
    final initialIndex = ((weight - min) / step).round();
    final controller = FixedExtentScrollController(initialItem: initialIndex);
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
              "What's your current\nweight right now?",
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),

            /// Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitToggleButton(
                  label: "Lbs",
                  isActive: !isKg,
                  onTap: () async {
                    provider.toggleUnit(false);
                    await provider.saveAllWizardData();
                  },
                ),
                SizedBox(width: 18.w),
                _UnitToggleButton(
                  label: "KGs",
                  isActive: isKg,
                  onTap: () async {
                    provider.toggleUnit(true);
                    await provider.saveAllWizardData();
                  },
                ),
              ],
            ),
            SizedBox(height: 100.h),

            /// Display Weight
            Text(
              '${weight.toStringAsFixed(1)} ${isKg ? "Kg" : "Lb"}',
              style: AppTextStyles.headingLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 40.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),

            /// Ruler Picker
            SizedBox(
              height: 100.h,
              child: RotatedBox(
                quarterTurns: -1,
                child: ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) async {
                    final value = min + (index * step);
                    provider.setWeight(value);
                    await provider.saveAllWizardData();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: itemCount,
                    builder: (context, idx) {
                      final value = min + idx * step;
                      final isSelected = (value.toStringAsFixed(1) == weight.toStringAsFixed(1));
                      final isWholeUnit = (value * 10) % 10 == 0;

                      double height;
                      if (isSelected) {
                        height = 55.h;
                      } else if (isWholeUnit) {
                        height = 40.h;
                      } else {
                        height = 25.h;
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
                                    : colorScheme.onSurface.withAlpha(100),
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

            /// Continue Button
            WizardButton(
              label: 'Continue',
              onPressed: () {
                Provider.of<WizardProvider>(context, listen: false).nextPage();
              },
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
                : colorScheme.outline.withAlpha(150),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}

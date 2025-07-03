import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';

class Wizard2 extends StatelessWidget {
  const Wizard2({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WizardProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final isCm = provider.isCm;
    final height = provider.height;

    final minCm = 140;
    final maxCm = 210;
    final minInch = 55;
    final maxInch = 83;

    final min = isCm ? minCm : minInch;
    final max = isCm ? maxCm : maxInch;
    final count = max - min + 1;
    final initialIndex = height - min;

    final controller = FixedExtentScrollController(initialItem: initialIndex);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Constants.beforeIcon),
            Image.asset(AppIcons.kali, color: colorScheme.primary),
            SizedBox(height: Constants.afterIcon),
            Text(
              "What's your current\nheight right now?",
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 22.h),

            /// Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitToggleButton(
                  label: "Inches",
                  isActive: !isCm,
                  onTap: () => provider.toggleHeightUnit(false),
                ),
                SizedBox(width: 18.w),
                _UnitToggleButton(
                  label: "Cm",
                  isActive: isCm,
                  onTap: () => provider.toggleHeightUnit(true),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            /// Picker
            SizedBox(
              height: 400.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ListWheelScrollView.useDelegate(
                    itemExtent: 50.h,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    controller: controller,
                    onSelectedItemChanged: (i) {
                      final selectedHeight = min + i;
                      provider.setHeight(selectedHeight);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: count,
                      builder: (context, i) {
                        final value = min + i;
                        final isSelected = value == height;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              Icon(Icons.play_arrow_rounded,
                                  color: colorScheme.primary, size: 28.sp),
                            SizedBox(width: isSelected ? 4.w : 32.w),
                            Text(
                              '$value',
                              style: AppTextStyles.headingLarge.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface
                                        .withValues(alpha: 90),
                                fontSize: isSelected ? 32.sp : 22.sp,
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: EdgeInsets.only(left: 4.w),
                                child: Text(
                                  isCm ? "cm" : "in",
                                  style: AppTextStyles.headingMedium.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  /// Underlines
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 24.h),
                          height: 2,
                          width: 150.w,
                          color: colorScheme.onSurface.withValues(alpha: 50),
                        ),
                        SizedBox(height: 41.h),
                        Container(
                          margin: EdgeInsets.only(bottom: 24.h),
                          height: 2,
                          width: 150.w,
                          color: colorScheme.onSurface.withValues(alpha: 50),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            /// Continue
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

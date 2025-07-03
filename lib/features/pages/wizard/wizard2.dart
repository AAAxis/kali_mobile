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
    final isMetric = provider.isMetric;

    const minCm = 140;
    const maxCm = 220;
    const minInch = 48;
    const maxInch = 84;

    final min = isMetric ? minCm : minInch;
    final max = isMetric ? maxCm : maxInch;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 38.h),
              // App Title
              Image.asset(
                AppIcons.kali,
                color: colorScheme.primary,
              ),
              SizedBox(height: 20.h),
              Text(
                "What's your current height right now?",
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              
              // Unit Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _UnitToggleButton(
                    label: 'Inches',
                    isActive: !isMetric,
                    onTap: () => provider.toggleMetric(false),
                  ),
                  SizedBox(width: 16.w),
                  _UnitToggleButton(
                    label: 'Cm',
                    isActive: isMetric,
                    onTap: () => provider.toggleMetric(true),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              // Height Display
              Text(
                '${provider.height}${isMetric ? "cm" : "in"}',
                style: AppTextStyles.headingLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 40.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              
              // Height Ruler
              SizedBox(
                height: 100.h,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: ListWheelScrollView.useDelegate(
                    controller: provider.scrollController,
                    itemExtent: 20.w,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      final value = min + index;
                      provider.setHeight(value);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: max - min + 1,
                      builder: (context, idx) {
                        final value = min + idx;
                        final isSelected = value == provider.height;
                        final isWholeUnit = value % 5 == 0;

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
                                      : colorScheme.onSurface.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              if (isWholeUnit)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      value.toString(),
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
              
              // Continue Button
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: WizardButton(
                  label: 'Continue',
                  onPressed: () {
                    Provider.of<WizardProvider>(context, listen: false).nextPage();
                  },
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                ),
              ),
            ],
          ),
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

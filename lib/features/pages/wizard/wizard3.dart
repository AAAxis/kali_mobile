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
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<WizardProvider>(context);

    final isKg = provider.isKg;
    final weight = provider.weight;

    final min = isKg ? 40.0 : 90.0;
    final max = isKg ? 150.0 : 330.0;
    final step = 0.1;
    final itemCount = ((max - min) / step).floor() + 1;

    final itemExtent = isKg ? 20.w : 26.w;

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
                    isActive: !provider.isMetric,
                    onTap: () => provider.toggleMetric(false),
                  ),
                  SizedBox(width: 16.w),
                  _UnitToggleButton(
                    label: 'Cm',
                    isActive: provider.isMetric,
                    onTap: () => provider.toggleMetric(true),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              // Height Picker
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 400.h),
                  child: ListWheelScrollView(
                    controller: provider.scrollController,
                    itemExtent: 50.h,
                    diameterRatio: 4,
                    useMagnifier: true,
                    magnification: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      final height = provider.isMetric ? 
                        (index + 140) : // cm
                        (index + 48);   // inches
                      provider.setHeight(height);
                    },
                    children: List.generate(
                      provider.isMetric ? 81 : 37, // 140-220 cm or 4'-7' feet
                      (index) {
                        final height = provider.isMetric ? 
                          (index + 140) : // cm
                          (index + 48);   // inches
                        final isSelected = height == provider.height;
                        return Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            decoration: isSelected ? BoxDecoration(
                              border: Border(
                                top: BorderSide(color: colorScheme.onSurface, width: 1),
                                bottom: BorderSide(color: colorScheme.onSurface, width: 1),
                              ),
                            ) : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$height${provider.isMetric ? ' cm' : ''}',
                                  style: TextStyle(
                                    fontSize: isSelected ? 24.sp : 20.sp,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? 
                                      colorScheme.onSurface : 
                                      colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
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

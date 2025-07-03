import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';

class Wizard4 extends StatelessWidget {
  const Wizard4({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<WizardProvider>(context);
    final selectedGender = provider.selectedGender;

    final genders = [
      {
        'label': 'Male',
        'icon': AppIcons.male,
      },
      {
        'label': 'Female',
        'icon': AppIcons.female,
      },
      {
        'label': 'Other',
        'icon': AppIcons.others,
      },
    ];

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
              "What's your gender?",
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 32,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 100.h),

            /// Gender options
            ...List.generate(genders.length, (i) {
              final isSelected = selectedGender == i;
              return Padding(
                padding: EdgeInsets.only(bottom: 18.h),
                child: GestureDetector(
                  onTap: () => provider.selectGender(i),
                  child: Container(
                    height: 66.h,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 18.w),
                        Image.asset(
                          genders[i]['icon']!,
                          width: 36.w,
                          height: 36.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 22.w),
                        Text(
                          genders[i]['label']!,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 19.sp,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          margin: EdgeInsets.only(right: 16.w),
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: 2,
                            ),
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surface,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 13.w,
                                    height: 13.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            /// Continue Button
            WizardButton(
              label: 'Continue',
              onPressed: () {
                Provider.of<WizardProvider>(context, listen: false).nextPage();
              },
              isEnabled: selectedGender != null,
              padding: EdgeInsets.symmetric(vertical: 18.h),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

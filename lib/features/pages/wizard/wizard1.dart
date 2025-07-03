import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';

class Wizard1 extends StatelessWidget {
  const Wizard1({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<WizardProvider>(context);
    final selectedAge = provider.age;

    final controller =
        FixedExtentScrollController(initialItem: selectedAge - 10);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: Constants.beforeIcon),
            Image.asset(AppIcons.kali, color: colorScheme.primary),
            SizedBox(height: Constants.afterIcon),
            Text(
              "What's your Age?",
              style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 32),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 36.h),
            SizedBox(
              height: 350.h,
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 100.h,
                diameterRatio: 1.15,
                perspective: 0.004,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) async {
                  provider.setAge(index + 10);
                  await provider.saveAllWizardData();
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 70,
                  builder: (context, i) {
                    final age = i + 10;
                    final isSelected = age == selectedAge;
                    return Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 7.h),
                        decoration: isSelected
                            ? BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.66),
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        child: Text(
                          '$age',
                          style: AppTextStyles.headingLarge.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: isSelected ? 60.sp : 48.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
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

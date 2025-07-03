import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';

class Wizard15 extends StatelessWidget {
  const Wizard15({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<WizardProvider>(context);
    final selectedSocialMedia = provider.selectedSocialMedia;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: Constants.beforeIcon),
                  // App Title
                  Image.asset(
                    AppIcons.kali,
                    color: colorScheme.primary,
                  ),
                  SizedBox(height: Constants.afterIcon),
                  // Title
                  Text(
                    "Where did you hear about us?",
                    style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 50.h),
                  // Options (buttons with icons)
                  _OptionButton(
                    label: 'Instagram',
                    icon: AppIcons.insta,
                    isSelected: selectedSocialMedia == 0,
                    onTap: () async {
                      provider.selectSocialMedia(0);
                      await provider.saveAllWizardData();
                    },
                  ),
                  SizedBox(height: 14.h),
                  _OptionButton(
                    label: 'Facebook',
                    icon: AppIcons.fb,
                    isSelected: selectedSocialMedia == 1,
                    onTap: () async {
                      provider.selectSocialMedia(1);
                      await provider.saveAllWizardData();
                    },
                  ),
                  SizedBox(height: 14.h),
                  _OptionButton(
                    label: 'Website',
                    icon: AppIcons.web,
                    isSelected: selectedSocialMedia == 2,
                    onTap: () async {
                      provider.selectSocialMedia(2);
                      await provider.saveAllWizardData();
                    },
                  ),
                  SizedBox(height: 14.h),
                  _OptionButton(
                    label: 'Tiktok',
                    icon: AppIcons.tiktok,
                    isSelected: selectedSocialMedia == 3,
                    onTap: () async {
                      provider.selectSocialMedia(3);
                      await provider.saveAllWizardData();
                    },
                  ),
                ],
              ),
            ),
            // Fixed Continue Button
            Spacer(),
            WizardButton(
              label: 'Continue',
              onPressed: () {
                // Your action here
                Provider.of<WizardProvider>(context, listen: false).nextPage();
              },
              isEnabled: selectedSocialMedia != null,
              padding: EdgeInsets.symmetric(
                  vertical: 18.h), // Adjust padding if necessary
            ),
          ],
        ),
      ),
    );
  }
}

// Option Button Widget (for Instagram, Facebook, etc.)
class _OptionButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary
                : colorScheme.primary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              icon,
              height: 32.h,
              width: 32.w,
              // Removed the color so it takes the default icon color
            ),
            SizedBox(width: 75.w),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected 
                    ? colorScheme.primary
                    : colorScheme.onSurface, 
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}

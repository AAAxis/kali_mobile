import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/app_images.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';

class Wizard18 extends StatelessWidget {
  const Wizard18({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final TextEditingController referralController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // X Button on top
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: GestureDetector(
                      onTap: () {
                        Provider.of<WizardProvider>(context, listen: false).nextPage();
                      },
                      child: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: colorScheme.onSurface,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: Constants.beforeIcon),

                // Logo
                Image.asset(
                  AppIcons.kali,
                  color: colorScheme.primary,
                ),

                SizedBox(height: Constants.beforeIcon),

                // Image
                Image.asset(
                  AppImages.referralCode,
                  width: 358.w,
                  height: 202.h,
                  fit: BoxFit.cover,
                ),

                SizedBox(height: 20.h),

                // Heading
                Text(
                  "Referral Code",
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 10.h),

                Text(
                  "Please enter your 6 digit referral code here",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 40.h),

                // Referral Code Input Field
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Stack(
                      children: [
                        TextField(
                          controller: referralController,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 20.w,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.r),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.r),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),

                        // Floating Label
                        Positioned(
                          left: 20.w,
                          top: -4.h,
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Text(
                              'Referral Code',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.18),

                // Submit
                WizardButton(
                  label: 'Submit',
                  onPressed: () {
                    final code = referralController.text.trim();
                    if (code.isNotEmpty) {
                      Provider.of<WizardProvider>(context, listen: false)
                          .nextPage();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

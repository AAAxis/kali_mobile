import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/app_images.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'wizard12.dart';
import 'dart:io';
import 'apple_health.dart';
import 'google_fit.dart';

class Wizard18 extends StatelessWidget {
  const Wizard18({super.key});

  void _navigateToNextScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Wizard12()),
    );
  }

  void _navigateToHealthScreen(BuildContext context) {
    if (Platform.isIOS) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wizard20()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wizard21()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<WizardProvider>(context);
    final TextEditingController referralController = TextEditingController();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 38.h),
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => _navigateToHealthScreen(context),
                  ),
                ),
                
                // App Title
                Image.asset(
                  AppIcons.kali,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 20.h),
                
                // Referral Image
                Image.asset(
                  AppImages.referralCode,
                  width: 358.w,
                  height: 202.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 24.h),
                
                // Referral Code Input
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: referralController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter referral code',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      counterText: "", // Hide the character counter
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                
                SizedBox(height: 24.h),
                
                // Submit Button
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: WizardButton(
                    label: 'Submit',
                    onPressed: () {
                      final code = referralController.text.trim();
                      if (code.length == 6) {
                        // Save referral code
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setString('referral_code', code);
                          prefs.setBool('has_used_referral_code', true);
                        });
                        _navigateToNextScreen(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid 6-digit code'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

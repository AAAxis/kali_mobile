import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constant/app_images.dart';
import '../../../core/constant/app_routes.dart';
import '../../../core/custom_widgets/primary_button.dart';
import '../../../core/custom_widgets/scanner_frame.dart';
import '../../../core/custom_widgets/skip_button.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background food image
          Positioned.fill(
            child: Image.asset(AppImages.steak, fit: BoxFit.cover),
          ),
          // Overlay (use theme background with alpha)
          Positioned.fill(
            child: Container(
              color: colorScheme.primary.withAlpha(
                51,
              ), // Semi-transparent overlay
            ),
          ),
          // Skip button
          Positioned(
            top: 70.h,
            right: 20.w,
            child: SkipButton(
              onTap: () => context.go(AppRoutes.onboarding3),
            ),
          ),

          // Scanning text
          Positioned(
            top: 80.h,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scanning ...',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          // Focus rectangle
          Padding(
            padding: EdgeInsets.only(bottom: 80.sp),
            child: Center(
              child: ScannerFrame(
                size: 240, // your size.w
                color: Theme.of(context).colorScheme.onPrimary,
                cornerRadius: 14, // Try 10~16 for a subtle round
                cornerLength: 32,
                thickness: 4,
              ),
            ),
          ),
          // Bottom content
          Positioned(
            left: 0,
            right: 0,
            bottom: 32.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(200),
                  borderRadius: BorderRadius.circular(28.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Effortless Calorie Tracking",
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Snap your meal and we’ll handle the rest – calorie tracking!",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    PrimaryButton(
                      label: 'Continue',
                      onPressed: () => context.go(AppRoutes.onboarding2),
                    ),
                    SizedBox(height: 10.h),
                    // Indicator (•••)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First wider dot (active)
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 24.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                        ),
                        SizedBox(width: 6.w),

                        // Second dot
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),

                        // Third dot
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

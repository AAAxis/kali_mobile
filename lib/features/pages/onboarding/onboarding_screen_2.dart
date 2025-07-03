import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constant/app_images.dart';
import '../../../core/constant/app_routes.dart';
import '../../../core/custom_widgets/primary_button.dart';
import '../../../core/custom_widgets/scanner_frame.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background image (replace with your constant from app_images.dart if needed)
          Positioned.fill(
            child: Image.asset(AppImages.steak, fit: BoxFit.cover),
          ),
          // Overlay using theme background with alpha
          Positioned.fill(
            child: Container(
              color: colorScheme.primary.withAlpha(51), // ~47% opacity
            ),
          ),
          // Skip button
          Positioned(
            top: 70.h,
            right: 20.w,
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.onboarding3),
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.onPrimary
                      .withAlpha(50), // Slightly transparent, for soft overlay
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onPrimary
                          .withAlpha(80), // Soft glow using theme color
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.onPrimary
                        .withAlpha(50), // Soft border for clarity
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Skip',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary, // Always readable
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
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
          // White scanner box
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
          // Bottom card with info and macros
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rib Eye Steak",
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "246 Kcal",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withAlpha(180),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _MacrosRow(
                      macros: [
                        MacroData('Protein', 26, 100, Colors.green),
                        MacroData('Fats', 5, 100, Colors.red),
                        MacroData('Carbs', 16, 100, Colors.amber),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Center(
                      child: PrimaryButton(
                        label: 'Continue',
                        onPressed: () => context.go(AppRoutes.onboarding3),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Indicator (•••)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First wider dot (active)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),

                        // Second dot
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

// Custom MacroBar widget for Onboarding2
class _MacrosRow extends StatelessWidget {
  final List<MacroData> macros;

  const _MacrosRow({required this.macros});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: macros.map((macro) {
        double percent = macro.max == 0 ? 1 : macro.value / macro.max;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  macro.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  minHeight: 5.h,
                  backgroundColor: Colors.white,
                  color: macro.barColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${macro.value}g',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MacroData {
  final String label;
  final int value;
  final int max;
  final Color barColor;
  MacroData(this.label, this.value, this.max, this.barColor);
}

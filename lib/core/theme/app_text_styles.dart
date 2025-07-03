import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

class AppTextStyle extends TextStyle {
  const AppTextStyle({
    required double super.fontSize,
    double? height,
    double? letterSpacing,
    super.fontWeight,
    super.fontFamily,
    super.fontStyle,
    super.color,
  }) : super(
          height: height == null ? null : height / fontSize,
          letterSpacing:
              letterSpacing == null ? null : letterSpacing / fontSize,
        );
}

class AppTextStyles {
  static const TextStyle headingLarge = AppTextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w800,
    fontFamily: FontFamily.inter,
    color: AppColors.primary,
  );

  static const TextStyle headingMedium = AppTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: FontFamily.inter,
    color: AppColors.primary,
  );

  static const TextStyle bodyLarge = AppTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: FontFamily.inter,
    color: AppColors.primary,
  );

  static const TextStyle bodyMedium = AppTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: FontFamily.inter,
    color: AppColors.secondaryDark,
  );

  static const TextStyle bodySmall = AppTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: FontFamily.inter,
    color: AppColors.secondaryDark,
  );

  static const TextStyle buttonText = AppTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: FontFamily.inter,
    color: AppColors.primary,
  );

  // Optionally, you can add more styles for special use cases:
  static const TextStyle error = AppTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: FontFamily.inter,
    color: AppColors.supportRed,
  );

  static const TextStyle success = AppTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: FontFamily.inter,
    color: AppColors.supportGreen,
  );

  static const TextStyle warning = AppTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: FontFamily.inter,
    color: AppColors.supportYellow,
  );
}

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'app_text_styles.dart';

final base = ThemeData(
  brightness: Brightness.light,
  fontFamily: FontFamily.inter,
);

final lightTheme = base.copyWith(
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.background,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.background,
    tertiary: AppColors.secondaryGrey,
    surface: AppColors.background,
    outline: AppColors.secondaryGrey,
    onError: AppColors.supportRed,
    onSurface: AppColors.primary,
  ),
  textTheme: TextTheme(
    headlineLarge: AppTextStyles.headingLarge,
    headlineMedium: AppTextStyles.headingMedium,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    labelLarge: AppTextStyles.buttonText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.background,
    iconTheme: IconThemeData(color: AppColors.background),
    elevation: 0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.supportRed,
    foregroundColor: AppColors.background,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.background,
      textStyle: AppTextStyles.buttonText,
    ),
  ),
  scaffoldBackgroundColor: AppColors.background,
);

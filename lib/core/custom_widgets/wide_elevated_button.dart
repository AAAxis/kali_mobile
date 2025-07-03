import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';

class WideElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final double elevation;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const WideElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderRadius = 22,
    this.fontSize = 18,
    this.fontWeight = FontWeight.bold,
    this.elevation = 8,
    this.backgroundColor,
    this.textColor,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width * 0.50,
      margin: margin ?? EdgeInsets.zero,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colorScheme.primary,
          foregroundColor: textColor ?? colorScheme.onPrimary,
          elevation: elevation,
          shadowColor: backgroundColor?.withAlpha(80) ??
              colorScheme.primary.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          padding: padding ?? EdgeInsets.symmetric(vertical: 16.h),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: textColor ?? colorScheme.onPrimary,
            fontWeight: fontWeight,
            fontSize: fontSize.sp,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

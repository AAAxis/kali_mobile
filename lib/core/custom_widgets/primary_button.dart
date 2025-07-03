import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderRadius = 22,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: 32.w,
              vertical: 10.h,
            ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: textStyle ??
            textTheme.labelLarge?.copyWith(
              color: textColor ?? colorScheme.primary,
              fontWeight: fontWeight ?? FontWeight.bold,
              fontSize: fontSize?.sp,
            ),
      ),
    );
  }
}

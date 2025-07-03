import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final double size;
  final double borderWidth;
  final double fontSize;

  const SkipButton({
    super.key,
    required this.onTap,
    this.label = 'Skip',
    this.size = 48,
    this.borderWidth = 2,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.onPrimary.withAlpha(50),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onPrimary.withAlpha(80),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: colorScheme.onPrimary.withAlpha(50),
            width: borderWidth,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: fontSize.sp,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final String assetPath;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;

  const SocialButton({
    super.key,
    required this.label,
    required this.assetPath,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isEnabled = onPressed != null;

    final Color effectiveBorderColor = isEnabled 
        ? (borderColor ?? colorScheme.outline)
        : colorScheme.outline.withValues(alpha: 0.3);
    final Color effectiveTextColor = isEnabled 
        ? (textColor ?? colorScheme.onSurface)
        : colorScheme.onSurface.withValues(alpha: 0.4);
    final Color effectiveBackgroundColor = isEnabled
        ? (backgroundColor ?? colorScheme.surface)
        : colorScheme.surface.withValues(alpha: 0.5);

    return SizedBox(
      height: 54.h,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          side: BorderSide(color: effectiveBorderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              assetPath,
              width: 26.w,
              height: 26.w,
              color: isEnabled ? null : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(width: 50.w),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: effectiveTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

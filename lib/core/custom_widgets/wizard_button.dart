import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';

class WizardButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool isEnabled;

  const WizardButton({
    required this.label,
    required this.onPressed,
    this.borderRadius = 20.0,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.bold,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.elevation = 8.0,
    this.isEnabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme; // Get the color scheme from the theme

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.065,
      width: MediaQuery.of(context).size.width *
          0.50, // Ensures the button takes full width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? colorScheme.primary 
              : colorScheme.onSurface.withValues(alpha: 0.12), // Using theme's primary color
          elevation: isEnabled ? elevation : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          padding: padding,
        ),
        onPressed: isEnabled ? onPressed : null,
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: isEnabled 
                ? colorScheme.onPrimary 
                : colorScheme.onSurface.withValues(alpha: 0.38), // Text color from theme
            fontWeight: fontWeight,
            fontSize: fontSize.sp,
          ),
        ),
      ),
    );
  }
}

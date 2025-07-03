import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkWizardCompletion();
  }

  void _checkWizardCompletion() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        // Get the appropriate route based on auth state
        final route = AuthService.getInitialRoute();
        context.go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Text(
          'KALI',
          style:
              textTheme.headlineLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ) ??
              AppTextStyles.headingLarge.copyWith(
                color: colorScheme.onPrimary,
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
        ),
      ),
    );
  }
}

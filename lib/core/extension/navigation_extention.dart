// lib/core/extensions/navigation_extensions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constant/app_routes.dart';

extension NavigationExtensions on BuildContext {
  // Navigation methods
  void goToSplash() => go(AppRoutes.splash);
  //onboarding screens
  void goToOnBoarding1() => go(AppRoutes.onboarding1);
  void goToOnBoarding2() => go(AppRoutes.onboarding2);
  void goToOnBoarding3() => go(AppRoutes.onboarding3);
  //auth screens
  void goToLogin() => go(AppRoutes.login);
  void goToSignup() => go(AppRoutes.signup);
  //wizard screens
  void goToWizardPager() => go(AppRoutes.wizardPager);
  void goToWizard1() => go(AppRoutes.wizard1);
  void goToWizard2() => go(AppRoutes.wizard2);
  void goToWizard3() => go(AppRoutes.wizard3);
  void goToWizard4() => go(AppRoutes.wizard4);
  void goToWizard5() => go(AppRoutes.wizard5);
  void goToWizard6() => go(AppRoutes.wizard6);
  void goToWizard7() => go(AppRoutes.wizard7);
  void goToWizard8() => go(AppRoutes.wizard8);
  void goToWizard9() => go(AppRoutes.wizard9);
  void goToWizard10() => go(AppRoutes.wizard10);
  void goToWizard11() => go(AppRoutes.wizard11);
  void goToWizard12() => go(AppRoutes.wizard12);
  void goToWizard13() => go(AppRoutes.wizard13);
  void goToWizard14() => go(AppRoutes.wizard14);
  void goToWizard15() => go(AppRoutes.wizard15);
  void goToAppleHealth() => go(AppRoutes.appleHealth);
  void goToGoogleFit() => go(AppRoutes.googleFit);
  void goToLoadingPage() => go(AppRoutes.loadingPage);

  // Push methods (adds to stack)
  void pushToLogin() => push(AppRoutes.login);
  void pushToSignup() => push(AppRoutes.signup);
  void pushToAppleHealth() => push(AppRoutes.appleHealth);
  void pushToGoogleFit() => push(AppRoutes.googleFit);
  void pushToLoadingPage() => push(AppRoutes.loadingPage);

  // Replace methods (replaces current route)
  // void replaceWithOnboarding() => pushReplacement(AppRoutes.onboarding);
  // Back navigation
  void goBack() {
    if (canPop()) {
      pop();
    } else {
      go(AppRoutes.splash);
    }
  }

  // Check if can pop
  bool canGoBack() => canPop();
}

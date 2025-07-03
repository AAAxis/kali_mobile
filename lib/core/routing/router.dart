// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constant/app_routes.dart';

// Import all your screen widgets here:
import '../../features/pages/splash/splash_screen.dart';
import '../../features/pages/onboarding/onboarding_screen_1.dart';
import '../../features/pages/onboarding/onboarding_screen_2.dart';
import '../../features/pages/onboarding/onboarding_screen_3.dart';

// Import auth screens
import '../../features/pages/auth/login_screen.dart';
import '../../features/pages/auth/signup_screen.dart';
import '../../features/pages/dashboard/dashboard_screen.dart';
import '../../features/pages/auth/email_otp_screen.dart';
import '../../features/pages/wizard/apple_health.dart';
import '../../features/pages/wizard/google_fit.dart';
import '../../features/pages/wizard/loading_page.dart';
import '../../features/pages/wizard/wizard1.dart';
import '../../features/pages/wizard/wizard10.dart';
import '../../features/pages/wizard/wizard11.dart';
import '../../features/pages/wizard/wizard12.dart';
import '../../features/pages/wizard/wizard13.dart';
import '../../features/pages/wizard/wizard14.dart';
import '../../features/pages/wizard/wizard15.dart';
import '../../features/pages/wizard/wizard2.dart';
import '../../features/pages/wizard/wizard3.dart';
import '../../features/pages/wizard/wizard4.dart';
import '../../features/pages/wizard/wizard5.dart';
import '../../features/pages/wizard/wizard6.dart';
import '../../features/pages/wizard/wizard7.dart';
import '../../features/pages/wizard/wizard8.dart';
import '../../features/pages/wizard/wizard9.dart';
import '../../features/pages/wizard/wizard_pager.dart';
import '../../features/providers/loading_provider.dart';
import 'package:provider/provider.dart';

// Import wizard screens (add your real widgets)

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.initial,
        name: 'initial',
        redirect: (context, state) => AppRoutes.splash,
      ),
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding screens
      GoRoute(
        path: AppRoutes.onboarding1,
        name: 'onboarding1',
        builder: (context, state) => const OnboardingScreen1(),
      ),
      GoRoute(
        path: AppRoutes.onboarding2,
        name: 'onboarding2',
        builder: (context, state) => const OnboardingScreen2(),
      ),
      GoRoute(
        path: AppRoutes.onboarding3,
        name: 'onboarding3',
        builder: (context, state) => const OnboardingScreen3(),
      ),

      // Auth screens
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Wizard screens
      GoRoute(
        path: AppRoutes.wizardPager,
        name: 'wizard_pager',
        builder: (context, state) => const WizardPager(),
      ),
      GoRoute(
        path: AppRoutes.wizard1,
        name: 'wizard1',
        builder: (context, state) => const Wizard1(),
      ),
      GoRoute(
        path: AppRoutes.wizard2,
        name: 'wizard2',
        builder: (context, state) => const Wizard2(),
      ),
      GoRoute(
        path: AppRoutes.wizard3,
        name: 'wizard3',
        builder: (context, state) => const Wizard3(),
      ),
      GoRoute(
        path: AppRoutes.wizard4,
        name: 'wizard4',
        builder: (context, state) => const Wizard4(),
      ),
      GoRoute(
        path: AppRoutes.wizard5,
        name: 'wizard5',
        builder: (context, state) => const Wizard5(),
      ),
      GoRoute(
        path: AppRoutes.wizard6,
        name: 'wizard6',
        builder: (context, state) => const Wizard6(),
      ),
      GoRoute(
        path: AppRoutes.wizard7,
        name: 'wizard7',
        builder: (context, state) => const Wizard7(),
      ),
      GoRoute(
        path: AppRoutes.wizard8,
        name: 'wizard8',
        builder: (context, state) => Wizard8(isGain: true, kgs: 17),
      ),
      GoRoute(
        path: AppRoutes.wizard9,
        name: 'wizard9',
        builder: (context, state) => const Wizard9(),
      ),
      GoRoute(
        path: AppRoutes.wizard10,
        name: 'wizard10',
        builder: (context, state) => const Wizard10(),
      ),
      GoRoute(
        path: AppRoutes.wizard11,
        name: 'wizard11',
        builder: (context, state) => const Wizard11(),
      ),
      GoRoute(
        path: AppRoutes.wizard12,
        name: 'wizard12',
        builder: (context, state) => const Wizard12(),
      ),
      GoRoute(
        path: AppRoutes.wizard13,
        name: 'wizard13',
        builder: (context, state) => const Wizard13(),
      ),
      GoRoute(
        path: AppRoutes.wizard14,
        name: 'wizard14',
        builder: (context, state) => const Wizard14(),
      ),
      GoRoute(
        path: AppRoutes.wizard15,
        name: 'wizard15',
        builder: (context, state) => const Wizard15(),
      ),
      GoRoute(
        path: AppRoutes.appleHealth,
        name: 'apple_health',
        builder: (context, state) => const Wizard20(),
      ),
      GoRoute(
        path: AppRoutes.googleFit,
        name: 'google_fit',
        builder: (context, state) => const Wizard21(),
      ),
      GoRoute(
        path: AppRoutes.loadingPage,
        name: 'loading_page',
        builder: (context, state) {
          return ChangeNotifierProvider(
            create: (_) {
              final provider = LoadingProvider();
              provider.startLoading(); // start auto-progress
              return provider;
            },
            child: const LoadingPage(),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.toString()}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go to Splash'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      // Add your auth or intro logic here if needed
      return null;
    },
  );

  static GoRouter get router => _router;
}

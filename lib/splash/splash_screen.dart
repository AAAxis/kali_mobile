import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../wizard/wizard_flow.dart';
import '../dashboard/dashboard.dart';
import '../services/paywall_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasCompletedWizard = prefs.getBool('wizard_completed') ?? false;

    if (!hasCompletedWizard) {
      await context.setLocale(const Locale('en'));
    }

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    bool hasCompletedWizard = prefs.getBool('wizard_completed') ?? false;

    if (!hasCompletedWizard) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WizardController()),
      );
      return;
    }

    // Check authentication state
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isLoggedInPrefs = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getString('user_id');
    
    print('🔍 Auth check: Firebase user: ${firebaseUser?.uid}, SharedPrefs isLoggedIn: $isLoggedInPrefs, userId: $userId');
    
    if (firebaseUser != null && isLoggedInPrefs && userId != null && userId.isNotEmpty && firebaseUser.uid == userId) {
      try {
        await PaywallService.loginUser(userId);
        print('✅ User logged into RevenueCat on app start: $userId');
      } catch (e) {
        print('❌ Error logging user into RevenueCat on app start: $e');
      }
    } else {
      print('🧹 Clearing inconsistent auth state');
      await _clearAuthState();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => DashboardScreen(dashboardKey: globalDashboardKey))
    );
  }

  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('isLoggedIn');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_display_name');
      
      await FirebaseAuth.instance.signOut();
      await PaywallService.logoutUser();
      
      print('✅ Cleared all authentication state');
    } catch (e) {
      print('❌ Error clearing auth state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 370,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 3.5,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              size: 48,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to\nKali Fit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'loading'.tr(),
                    style: TextStyle(
                      color: Colors.grey[600]!,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
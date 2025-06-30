import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'wizard/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/meal_model.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/paywall_service.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'dashboard/dashboard.dart';
import 'dashboard/notifications_screen.dart';
import 'wizard/wizard_flow.dart';

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global key to access dashboard state
final GlobalKey<DashboardScreenState> dashboardKey = GlobalKey<DashboardScreenState>();

// Helper function to handle dashboard auth state changes
Future<void> handleDashboardAuthStateChange() async {
  try {
    if (dashboardKey.currentState != null) {
      await dashboardKey.currentState!.handleAuthStateChange();
    } else {
      print('Dashboard state not available');
    }
  } catch (e) {
    print('Error handling dashboard auth state change: $e');
  }
}



Future<bool> _checkIfUserHasUsedFreeScan() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    
    // Check referral free scans first (applies to both authenticated and non-authenticated users)
    final hasUsedReferralCode = prefs.getBool('has_used_referral_code') ?? false;
    if (hasUsedReferralCode) {
      final referralFreeScans = prefs.getInt('referral_free_scans') ?? 0;
      final usedReferralScans = prefs.getInt('used_referral_scans') ?? 0;
      
      if (usedReferralScans < referralFreeScans) {
        print('🎁 User has ${referralFreeScans - usedReferralScans} referral free scans remaining');
        return false; // Still has referral scans available
      }
    }
    
    if (user == null) {
      // For non-authenticated users, only check local storage
      print('🔍 Checking free scan usage for non-authenticated user (local storage only)');
      final localMeals = await Meal.loadFromLocalStorage();
      final hasUsedFreeScan = localMeals.length >= 2;
      print('🔍 Non-authenticated user free scan check: hasUsed=$hasUsedFreeScan (${localMeals.length}/2 local meals)');
      return hasUsedFreeScan;
    } else {
      // For authenticated users, check Firebase
      print('🔍 Checking free scan usage for authenticated user: ${user.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('analyzed_meals')
          .where('userId', isEqualTo: user.uid)
          .limit(2)
          .get();

      final hasUsedFreeScan = snapshot.docs.length >= 2;
      print('🔍 Authenticated user free scan check: hasUsed=$hasUsedFreeScan (${snapshot.docs.length}/2 Firebase meals)');
      return hasUsedFreeScan;
    }
  } catch (e) {
    print('❌ Error checking free scan usage: $e');
    // On error, assume they haven't used it (better UX)
    print('⚠️ Assuming free scan available due to error (better UX)');
    return false;
  }
}

// Helper function to ensure clean state for non-authenticated users
Future<void> _ensureCleanStateForNonAuthenticatedUser() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User is not authenticated, ensure RevenueCat is in anonymous mode
      print('🔄 Ensuring clean RevenueCat state for non-authenticated user...');
      
      // Check if we have a RevenueCat anonymous user that might be causing issues
      final customerInfo = await Purchases.getCustomerInfo();
      final isAnonymous = customerInfo.originalAppUserId.startsWith('\$RCAnonymousID:');
      
      if (isAnonymous) {
        print('🔍 Found RevenueCat anonymous user: ${customerInfo.originalAppUserId}');
        
        // Check if this anonymous user has any entitlements (which shouldn't happen for new users)
        final hasAnyEntitlements = customerInfo.entitlements.all.isNotEmpty;
        if (hasAnyEntitlements) {
          print('⚠️ Anonymous user has entitlements, this might cause issues. Resetting...');
          
          // Reset RevenueCat data to start fresh
          await PaywallService.logoutUser();
          print('✅ RevenueCat data reset for clean non-authenticated state');
        } else {
          print('✅ Anonymous user has no entitlements, state is clean');
        }
      }
    }
  } catch (e) {
    print('❌ Error ensuring clean state for non-authenticated user: $e');
    // Don't block the flow, just log the error
  }
}



// Helper function to detect if this is truly a fresh app install
Future<bool> _isTrueFreshInstall() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have an install timestamp
    final installTimestamp = prefs.getInt('app_install_timestamp');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (installTimestamp == null) {
      // No install timestamp means this could be a fresh install
      print('🔍 No install timestamp found - checking other indicators...');
      
      // Set install timestamp for future reference
      await prefs.setInt('app_install_timestamp', now);
      
      // Check if we have any cached user data that shouldn't exist on fresh install
      final hasUserEmail = prefs.getString('user_email') != null;
      final hasUserName = prefs.getString('user_display_name') != null;
      final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
      final hasLocalMeals = (await Meal.loadFromLocalStorage()).isNotEmpty;
      
      if (hasUserEmail || hasUserName || hasSeenWelcome || hasLocalMeals) {
        print('⚠️ Found cached data on "fresh" install - iOS app data persistence detected');
        print('📧 Has email: $hasUserEmail');
        print('👤 Has name: $hasUserName'); 
        print('👋 Has seen welcome: $hasSeenWelcome');
        print('🍕 Has local meals: $hasLocalMeals');
        
        // This is likely iOS data persistence, offer to clear it
        return false; // Not a true fresh install
      } else {
        print('✅ No cached data found - this appears to be a genuine fresh install');
        return true;
      }
    } else {
      // We have an install timestamp, check how old it is
      final hoursSinceInstall = (now - installTimestamp) / (1000 * 60 * 60);
      print('🕐 App was installed ${hoursSinceInstall.toStringAsFixed(1)} hours ago');
      
      if (hoursSinceInstall > 24) {
        // App was installed over 24 hours ago, this is not a fresh install
        return false;
      } else {
        // Recent install, might be fresh
        return true;
      }
    }
  } catch (e) {
    print('❌ Error checking fresh install: $e');
    return true; // Default to fresh install on error
  }
}

// Helper function to clear all cached app data
Future<void> _clearAllAppData() async {
  try {
    print('🧹 Clearing all cached app data...');
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Clear local meals
    await Meal.saveToLocalStorage([]);
    
    // Reset RevenueCat
    await PaywallService.logoutUser();
    
    // Set fresh install markers
    await prefs.setBool('has_seen_welcome', false);
    await prefs.setBool('wizard_completed', false);
    await prefs.setInt('app_install_timestamp', DateTime.now().millisecondsSinceEpoch);
    
    print('✅ All app data cleared successfully');
  } catch (e) {
    print('❌ Error clearing app data: $e');
  }
}

// Helper function to reset wizard completion (for testing)
Future<void> _resetWizardCompletion() async {
  try {
    print('🔄 Resetting wizard completion...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', false);
    await prefs.setBool('wizard_completed', false);
    print('✅ Wizard completion reset successfully');
  } catch (e) {
    print('❌ Error resetting wizard completion: $e');
  }
}

// Helper function to check the app's initial state
Future<Map<String, dynamic>> _checkAppInitialState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFreshInstall = await _isTrueFreshInstall();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    final wizardCompleted = prefs.getBool('wizard_completed') ?? false;
    
    // Check for cached data indicators
    final hasUserEmail = prefs.getString('user_email') != null;
    final hasUserName = prefs.getString('user_display_name') != null;
    final hasLocalMeals = (await Meal.loadFromLocalStorage()).isNotEmpty;
    final hasCachedData = hasUserEmail || hasUserName || hasLocalMeals;
    
    // Wizard should be shown if user hasn't seen welcome OR wizard isn't completed
    final shouldShowWizard = !hasSeenWelcome || !wizardCompleted;
    
    print('🔍 App Initial State Check:');
    print('  - Is Fresh Install: $isFreshInstall');
    print('  - Has Seen Welcome: $hasSeenWelcome');
    print('  - Wizard Completed: $wizardCompleted');
    print('  - Should Show Wizard: $shouldShowWizard');
    print('  - Has Cached Data: $hasCachedData');
    print('  - Has User Email: $hasUserEmail');
    print('  - Has User Name: $hasUserName');
    print('  - Has Local Meals: $hasLocalMeals');
    
    return {
      'isFreshInstall': isFreshInstall,
      'hasSeenWelcome': hasSeenWelcome,
      'wizardCompleted': wizardCompleted,
      'shouldShowWizard': shouldShowWizard,
      'hasCachedData': hasCachedData,
    };
  } catch (e) {
    print('❌ Error checking app initial state: $e');
    return {
      'isFreshInstall': true,
      'hasSeenWelcome': false,
      'wizardCompleted': false,
      'shouldShowWizard': true,
      'hasCachedData': false,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureRevenueCat();
  


  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('he'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      assetLoader: const RootBundleAssetLoader(),
      child: const MyApp(),
    ),
  );
}



Future<void> _configureRevenueCat() async {
  await Purchases.setDebugLogsEnabled(true);

  PurchasesConfiguration configuration;
  
  if (Platform.isAndroid) {
    const buildingForAmazon = bool.fromEnvironment("AMAZON");
    if (buildingForAmazon) {
      configuration = AmazonConfiguration(PaywallService.amazonApiKey);
    } else {
      configuration = PurchasesConfiguration(PaywallService.googleApiKey);
    }
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration(PaywallService.appleApiKey);
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(configuration);
  
  // Clear any cached anonymous user data if this is a fresh install
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;
    
    if (isFirstRun) {
      print('🔄 First run detected - clearing RevenueCat anonymous user cache');
      await Purchases.logOut();
      await prefs.setBool('is_first_run', false);
      print('✅ RevenueCat cache cleared for fresh install');
    }
  } catch (e) {
    print('⚠️ Error clearing RevenueCat cache: $e');
  }
  
  print('✅ RevenueCat configured successfully for ${Platform.isIOS ? 'iOS' : 'Android'}');
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: FutureBuilder<Map<String, dynamic>>(
              future: _checkAppInitialState(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data!;
                final isFreshInstall = data['isFreshInstall'] as bool;
                final hasSeenWelcome = data['hasSeenWelcome'] as bool;
                final wizardCompleted = data['wizardCompleted'] as bool;
                final shouldShowWizard = data['shouldShowWizard'] as bool;
                final hasCachedData = data['hasCachedData'] as bool;
                
                // If we detected cached data on a "fresh" install, show welcome with option to clear
                if (!isFreshInstall && hasCachedData && shouldShowWizard) {
                  return const WizardController();
                }
                
                return shouldShowWizard ? const WizardController() : MainTabScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  void _onCategoryTabChange(int index, {String? categoryId, String? categoryName}) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(
      key: dashboardKey,
      isAnalyzing: false,
      onTabChange: _onCategoryTabChange,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dashboard/dashboard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'wizard/wizard_flow.dart';
import 'dashboard/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'meal_analysis.dart';
import 'dart:io';
import 'auth/login.dart';
import 'dashboard/upload_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/revenue_cat_config.dart';
import 'services/paywall_service.dart';
import 'camera/camera_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<DashboardScreenState> dashboardKey =
    GlobalKey<DashboardScreenState>();

// Function to capture image from custom camera
Future<File?> captureImageFromCustomCamera(BuildContext context) async {
  final File? capturedImage = await Navigator.of(context).push<File>(
    MaterialPageRoute(builder: (context) => const CameraScreen()),
  );
  return capturedImage;
}

// Global function to trigger camera access from anywhere in the app
Future<void> triggerCameraAccess(BuildContext context) async {
  // Check if this is a free scan usage (for restore purchases flow)
  final hasActiveSubscription = await PaywallService.hasActiveSubscription();
  if (!hasActiveSubscription) {
    // Free scan will be marked as used when meal is saved
    print('📱 Free scan will be marked as used when meal is saved');
  }

  // Get meals and updateMeals from dashboard
  final dashboardState = dashboardKey.currentState;
  if (dashboardState != null) {
    final meals = dashboardState.meals;
    final updateMeals = dashboardState.updateMeals;
    
    // Trigger analyzing animation on dashboard
    dashboardState.setAnalyzingState(true);
    
    // Go directly to custom camera
    final capturedImage = await captureImageFromCustomCamera(context);
    if (capturedImage != null) {
      await analyzeImageFile(
        imageFile: capturedImage,
        meals: meals,
        updateMeals: updateMeals,
        context: context,
        source: ImageSource.camera,
      );
    }
    
    // Reset analyzing animation
    dashboardState.setAnalyzingState(false);
  }
  dashboardKey.currentState?.refreshDashboard();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️  Warning: Could not load .env file: $e');
    print('💡 Make sure to create a .env file from env.example');
  }
  
  // Initialize Firebase with the generated options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize RevenueCat
  await _configureRevenueCat();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('he'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'), // Force English as default
      useOnlyLangCode: true,
      assetLoader: const RootBundleAssetLoader(),
      child: const MyApp(),
    ),
  );
}

Future<void> _configureRevenueCat() async {
  // Enable debug logs before calling `configure`.
  await Purchases.setDebugLogsEnabled(true);

  PurchasesConfiguration configuration;
  
  if (Platform.isAndroid) {
    // Check if building for Amazon (use --dart-define=AMAZON=true)
    const buildingForAmazon = bool.fromEnvironment("AMAZON");
    if (buildingForAmazon) {
      configuration = AmazonConfiguration(amazonApiKey);
    } else {
      configuration = PurchasesConfiguration(googleApiKey);
    }
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration(appleApiKey);
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(configuration);
  print('✅ RevenueCat configured successfully for ${Platform.isIOS ? 'iOS' : 'Android'}');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  // Check if user has used their free scan by looking in Firebase or local storage
  Future<bool> _checkIfUserHasUsedFreeScan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If user is not logged in, check local storage for any meals
        final localMeals = await Meal.loadFromLocalStorage();
        final hasUsedFreeScan = localMeals.isNotEmpty;
        print('🔍 Free scan check for non-authenticated user: hasUsed=$hasUsedFreeScan (${localMeals.length} local meals)');
        return hasUsedFreeScan;
      }

      // Check Firebase for logged-in users
      final snapshot = await FirebaseFirestore.instance
          .collection('analyzed_meals')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final hasUsedFreeScan = snapshot.docs.isNotEmpty;
      print('🔍 Free scan check for user ${user.uid}: hasUsed=$hasUsedFreeScan');
      return hasUsedFreeScan;
    } catch (e) {
      print('❌ Error checking free scan usage: $e');
      // If there's an error, assume they haven't used it to be generous
      return false;
    }
  }

  // Mark that user has used their free scan
  Future<void> _markFreeScanAsUsed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // For non-authenticated users, the scan will be automatically recorded in local storage
        // when they analyze a meal, so no additional marking needed
        print('📱 Free scan will be marked as used when meal is saved to local storage');
      } else {
        // For logged-in users, the scan will be automatically recorded in Firebase
        // when they analyze a meal, so no additional marking needed
        print('👤 Free scan will be marked as used when meal is saved to Firebase');
      }
    } catch (e) {
      print('❌ Error marking free scan as used: $e');
    }
  }

  void _onTabTapped(int index) async {
    if (index == 1) {
      // Check subscription before allowing camera access
      try {
        final hasActiveSubscription = await PaywallService.hasActiveSubscription();
        if (!hasActiveSubscription) {
          // Check if user has used their free scan
          final hasUsedFreeScan = await _checkIfUserHasUsedFreeScan();
          if (hasUsedFreeScan) {
            print('🔒 No active subscription and free scan already used, showing paywall...');
            // First try the default "Sale" offering
            final purchased = await PaywallService.showPaywall(context, forceCloseOnRestore: true);
            if (!purchased) {
              // User cancelled the Sale paywall, show Offer paywall as fallback
              print('💡 User closed Sale paywall, showing Offer paywall as fallback...');
              final purchasedOffer = await PaywallService.showPaywall(
                context, 
                offeringId: 'Offer',
                forceCloseOnRestore: true,
              );
              if (!purchasedOffer) {
                // User cancelled both paywalls, stay on dashboard (index 0)
                setState(() {
                  _currentIndex = 0;
                });
                return;
              }
            }
          } else {
            print('✅ No subscription but free scan available, allowing camera access...');
          }
        }
      } catch (e) {
        print('❌ Error checking subscription status: $e');
        // If there's an error checking subscription, still allow camera access
      }
      
      // Check if this is a free scan usage
      final hasActiveSubscription = await PaywallService.hasActiveSubscription();
      if (!hasActiveSubscription) {
        await _markFreeScanAsUsed();
      }

      // Get meals and updateMeals from dashboard
      final dashboardState = dashboardKey.currentState;
      if (dashboardState != null) {
        final meals = dashboardState.meals;
        final updateMeals = dashboardState.updateMeals;
        
        // Set analyzing state to show animation
        setState(() {
          _isAnalyzing = true;
        });
        
        // Go directly to custom camera
        final capturedImage = await captureImageFromCustomCamera(context);
        if (capturedImage != null) {
          await analyzeImageFile(
            imageFile: capturedImage,
            meals: meals,
            updateMeals: updateMeals,
            context: context,
            source: ImageSource.camera,
          );
        }
        
        // Reset analyzing state
        setState(() {
          _isAnalyzing = false;
        });
      }
      dashboardKey.currentState?.refreshDashboard();
      
      // Always reset to dashboard after camera flow
      setState(() {
        _currentIndex = 0;
      });
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_currentIndex == 0) {
      body = DashboardScreen(key: dashboardKey, isAnalyzing: _isAnalyzing);
    } else if (_currentIndex == 2) {
      body = const NotificationsScreen();
    } else {
      body = Container(); // Placeholder for camera
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
          unselectedItemColor: Colors.grey[600],
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'navbar.dashboard'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'navbar.scan'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'navbar.notifications'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // Set defaults if wizard not completed
    final prefs = await SharedPreferences.getInstance();
    bool hasCompletedWizard = prefs.getBool('wizard_completed') ?? false;

    if (!hasCompletedWizard) {
      // Force English locale
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

    // Check BOTH Firebase Auth and SharedPreferences for authentication
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isLoggedInPrefs = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getString('user_id');
    
    print('🔍 Auth check: Firebase user: ${firebaseUser?.uid}, SharedPrefs isLoggedIn: $isLoggedInPrefs, userId: $userId');
    
    // User is truly authenticated only if BOTH conditions are met
    if (firebaseUser != null && isLoggedInPrefs && userId != null && userId.isNotEmpty && firebaseUser.uid == userId) {
      try {
        // Login user to RevenueCat to ensure subscription status is current
        await PaywallService.loginUser(userId);
        print('✅ User logged into RevenueCat on app start: $userId');
      } catch (e) {
        print('❌ Error logging user into RevenueCat on app start: $e');
      }
    } else {
      // Clear inconsistent auth state
      print('🧹 Clearing inconsistent auth state');
      await _clearAuthState();
    }

    // Always go to MainTabScreen after wizard, regardless of subscription
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => MainTabScreen()));
  }

  // Helper method to clear all authentication state
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear SharedPreferences auth data
      await prefs.remove('isLoggedIn');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_display_name');
      
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
      
      // Logout from RevenueCat
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

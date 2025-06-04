import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/paywall_service.dart';
import 'services/image_cache_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'splash/splash_screen.dart';
import 'app_theme.dart';
import 'dart:io';
import 'dashboard/dashboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

// Global dashboard key that can be accessed from anywhere in the app
final GlobalKey<DashboardScreenState> globalDashboardKey = GlobalKey<DashboardScreenState>();

// Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Initialize local notifications
  await _initializeNotifications();
  
  // Initialize image cache service
  await ImageCacheService.initialize();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️  Warning: Could not load .env file: $e');
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

Future<void> _initializeNotifications() async {
  // Android initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS initialization
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      // Handle notification tap
      print('Notification tapped: ${details.payload}');
    },
  );

  print('✅ Local notifications initialized');
}

Future<void> _configureRevenueCat() async {
  // Enable debug logs before calling `configure`.
  await Purchases.setDebugLogsEnabled(true);

  PurchasesConfiguration configuration;
  
  if (Platform.isAndroid) {
    // Check if building for Amazon (use --dart-define=AMAZON=true)
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Hardcoded to light for now
      home: SplashScreen(),
    );
  }
}

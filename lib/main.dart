import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/paywall_service.dart';
import 'services/image_cache_service.dart';
import 'splash/splash_screen.dart';
import 'app_theme.dart';
import 'dart:io';
import 'dashboard/dashboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// Global dashboard key that can be accessed from anywhere in the app
final GlobalKey<DashboardScreenState> globalDashboardKey = GlobalKey<DashboardScreenState>();

// Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Global theme notifier for immediate theme changes
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Initialize local notifications
  await _initializeNotifications();
  
  // Initialize image cache service
  await ImageCacheService.initialize();
  
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkTheme') ?? false;
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
      home: SplashScreen(),
        );
      },
    );
  }
}

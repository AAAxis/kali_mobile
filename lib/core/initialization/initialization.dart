import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../firebase_options.dart';
import '../store/shared_pref.dart';

Future<void> initializeApp({
  required VoidCallback onSuccess,
  void Function(Object error, StackTrace stackTrace)? onError,
}) async {
  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize RevenueCat
    await _initializeRevenueCat();
    
    // Initialize SharedPreferences
    await SharedPref.init();

    onSuccess();
  } catch (error, stackTrace) {
    onError?.call(error, stackTrace);
    rethrow; // Re-throw to be caught by main's try-catch
  }
}

Future<void> _initializeRevenueCat() async {
  try {
    // Set log level for debugging
    await Purchases.setLogLevel(LogLevel.debug);
    
    // Configure RevenueCat with your API keys
    PurchasesConfiguration configuration;
    
    // Replace with your actual RevenueCat API keys
    const String appleApiKey = "your_apple_api_key_here";
    const String googleApiKey = "your_google_api_key_here";
    
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration(appleApiKey);
    } else {
      configuration = PurchasesConfiguration(googleApiKey);
    }
    
    await Purchases.configure(configuration);
    print('✅ RevenueCat initialized successfully');
  } catch (e) {
    print('❌ Error initializing RevenueCat: $e');
    // Don't throw error, just log it - app should still work without RevenueCat
  }
}

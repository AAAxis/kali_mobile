import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/runners/app_runner.dart';
import 'core/initialization/initialization.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    
    // Initialize app services
    await initializeApp(
      onSuccess: () {
        print('✅ App initialized successfully');
      },
      onError: (error, stackTrace) {
        print('❌ App initialization failed: $error');
        print(stackTrace.toString());
      },
    );
    
    // Run app with localization support
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'), // English
          Locale('he'), // Hebrew
          Locale('ru'), // Russian
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const AppRunner(),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ Fatal error during app initialization: $e');
    print(stackTrace);
    rethrow;
  }
}

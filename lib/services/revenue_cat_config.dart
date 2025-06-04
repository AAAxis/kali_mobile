import 'package:flutter_dotenv/flutter_dotenv.dart';

//TO DO: add the entitlement ID from the RevenueCat dashboard that is activated upon successful in-app purchase for the duration of the purchase.
String get entitlementID => dotenv.env['ENTITLEMENT_ID'] ?? 'Premium';

// Your configured offering ID from RevenueCat dashboard
String get defaultOfferingId => dotenv.env['DEFAULT_OFFERING_ID'] ?? 'Sale';
String get discountOfferingId => dotenv.env['DISCOUNT_OFFERING_ID'] ?? 'Offer';

//TO DO: add your subscription terms and conditions
const footerText =
    """Don't forget to add your subscription terms and conditions. 

Read more about this here: https://www.revenuecat.com/blog/schedule-2-section-3-8-b""";

//TO DO: add the Apple API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
String get appleApiKey => dotenv.env['REVENUECAT_APPLE_API_KEY'] ?? '';

//TO DO: add the Google API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
String get googleApiKey => dotenv.env['REVENUECAT_GOOGLE_API_KEY'] ?? '';

//TO DO: add the Amazon API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
String get amazonApiKey => dotenv.env['REVENUECAT_AMAZON_API_KEY'] ?? '';

// App Data Singleton for managing subscription state
class AppData {
  static final AppData _appData = AppData._internal();

  bool entitlementIsActive = false;
  String appUserID = '';

  factory AppData() {
    return _appData;
  }
  AppData._internal();
}

final appData = AppData(); 
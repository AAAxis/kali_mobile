# RevenueCat Cross-Platform Paywall Integration

This document explains how the RevenueCat paywall integration works in your Kali Fit app.

## Files Added/Modified

### New Files Created:
- `lib/services/store_config.dart` - Store configuration for different platforms
- `lib/services/revenue_cat_constants.dart` - API keys and configuration constants
- `lib/services/app_data.dart` - Singleton for managing subscription state
- `lib/services/paywall_service.dart` - Service for handling paywall operations
- `lib/dashboard/paywall_screen.dart` - UI screen for displaying subscription options

### Modified Files:
- `lib/main.dart` - Added RevenueCat initialization
- `lib/settings.dart` - Added subscription management options
- `lib/auth/login.dart` - Added RevenueCat user login integration

## Setup Instructions

### 1. Configure API Keys
Edit `lib/services/revenue_cat_constants.dart` and replace the placeholder API keys with your actual RevenueCat API keys:

```dart
const appleApiKey = 'your_apple_api_key_here';
const googleApiKey = 'your_google_api_key_here';
const amazonApiKey = 'your_amazon_api_key_here';
```

### 2. Configure Entitlement ID
Update the entitlement ID to match your RevenueCat dashboard configuration:

```dart
const entitlementID = 'your_entitlement_id_here';
```

### 3. Update Offering ID
In `lib/services/paywall_service.dart`, update the offering ID in the `showKaliProOffering` method:

```dart
static Future<bool> showKaliProOffering(BuildContext context) async {
  return showPaywall(context, offeringId: 'your_offering_id_here');
}
```

## How It Works

### Initialization
RevenueCat is initialized in `main.dart` when the app starts. It automatically detects the platform and uses the appropriate API key.

### User Authentication
When a user logs in, they are automatically logged into RevenueCat using their Firebase UID. This allows for cross-platform subscription management.

### Paywall Display
The paywall can be shown from anywhere in the app by calling:

```dart
await PaywallService.showPaywall(context);
```

### Subscription Status
Check if a user has an active subscription:

```dart
bool hasSubscription = await PaywallService.hasActiveSubscription();
```

### Restore Purchases
Users can restore their purchases:

```dart
bool restored = await PaywallService.restorePurchases();
```

## Features

- ✅ Cross-platform support (iOS, Android)
- ✅ User authentication integration
- ✅ Beautiful paywall UI
- ✅ Purchase restoration
- ✅ Subscription status checking
- ✅ Automatic transaction handling

## Usage in Settings

The settings screen now includes:
- "Upgrade to Premium" - Shows the paywall
- "Restore Purchases" - Restores previous purchases
- "Subscriptions" - Opens platform-specific subscription management

## Testing

1. Make sure you have valid API keys from RevenueCat
2. Configure your products in the RevenueCat dashboard
3. Test on both iOS and Android devices
4. Test purchase flow and restoration

## Important Notes

- Replace all placeholder API keys with real ones before production
- Test thoroughly on both platforms
- Make sure your RevenueCat dashboard is properly configured
- Update the terms and conditions text in `revenue_cat_constants.dart` 
# SwiftUI Paywall Setup Guide

This guide explains how to set up the native SwiftUI paywall with RevenueCat integration.

## Files Added

1. **PaywallView.swift** - The main SwiftUI paywall screen
2. **PaywallBridge.swift** - Bridge between Flutter and SwiftUI
3. **RevenueCatConfig.swift** - Configuration file for RevenueCat settings
4. **lib/services/paywall_service.dart** - Flutter service to communicate with native paywall

## Setup Instructions

### 1. Configure RevenueCat API Key

Edit `ios/Runner/RevenueCatConfig.swift` and replace `"your_revenuecat_api_key_here"` with your actual RevenueCat API key:

```swift
static let apiKey = "your_actual_api_key_here"
```

### 2. Set Up RevenueCat Dashboard

1. Create a RevenueCat account at https://app.revenuecat.com
2. Create a new app in the dashboard
3. Add your iOS app bundle ID
4. Create a product with the entitlement identifier "pro"
5. Copy your API key and update the config file

### 3. App Store Connect Setup

1. Create your subscription products in App Store Connect
2. Make sure the product IDs match what you've configured in RevenueCat
3. Add the product IDs to your RevenueCat dashboard

### 4. Test the Integration

1. Build and run the app
2. Complete the wizard
3. Tap the "Complete" button to see the native SwiftUI paywall

## Features

- Native SwiftUI paywall using RevenueCatUI
- Automatic entitlement checking
- Purchase and restore functionality
- Seamless integration with Flutter app
- Error handling and fallbacks

## Customization

You can customize the paywall appearance by modifying:
- `ContentView` in `PaywallView.swift` for the content before paywall appears
- RevenueCat dashboard for paywall templates and styling
- `RevenueCatConfig.swift` for configuration options

## Troubleshooting

1. **Paywall doesn't appear**: Check that your API key is correct and RevenueCat is properly initialized
2. **Purchase fails**: Ensure your products are properly configured in both App Store Connect and RevenueCat
3. **Bridge errors**: Check that the method channel name matches between Swift and Dart code

## Production Checklist

- [ ] Replace API key with production key
- [ ] Set `debugMode = false` in RevenueCatConfig
- [ ] Test with TestFlight
- [ ] Verify all products work correctly
- [ ] Test restore purchases functionality 
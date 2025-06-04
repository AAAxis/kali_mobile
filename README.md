# KaliAI - Nutrition and Fitness App

A Flutter application for tracking nutrition and fitness goals.

## Environment Setup

This app requires API keys for RevenueCat and Firebase integration. For security reasons, these keys are stored in environment variables rather than hardcoded in the source code.

### Setting up Environment Variables

1. **Copy the environment template:**
   ```bash
   cp env.example .env
   ```

2. **Configure your API keys in `.env`:**
   Open the `.env` file and replace the placeholder values with your actual API keys:
   
   ```bash
   # RevenueCat API Keys
   # Get these from your RevenueCat dashboard: https://app.revenuecat.com
   REVENUECAT_APPLE_API_KEY=your_actual_apple_api_key_here
   REVENUECAT_GOOGLE_API_KEY=your_actual_google_api_key_here
   REVENUECAT_AMAZON_API_KEY=your_actual_amazon_api_key_here
   
   # Firebase API Keys
   # Get these from your Firebase project settings: https://console.firebase.google.com
   FIREBASE_ANDROID_API_KEY=your_actual_firebase_android_api_key_here
   FIREBASE_IOS_API_KEY=your_actual_firebase_ios_api_key_here
   
   # App Configuration
   ENTITLEMENT_ID=Premium
   DEFAULT_OFFERING_ID=Sale
   DISCOUNT_OFFERING_ID=Offer
   ```

3. **Get your API Keys:**
   
   **RevenueCat Keys:**
   - Visit the [RevenueCat Dashboard](https://app.revenuecat.com)
   - Navigate to your project settings
   - Copy the API keys for each platform (iOS/Apple, Android/Google, Amazon)
   
   **Firebase Keys:**
   - Visit the [Firebase Console](https://console.firebase.google.com)
   - Select your project (kaliai-6dff9)
   - Go to Project Settings → General
   - In the "Your apps" section, find your Android and iOS apps
   - Copy the API keys for each platform

4. **Important Security Notes:**
   - The `.env` file is automatically ignored by Git to prevent committing secrets
   - Never commit API keys to version control
   - Use the `env.example` file as a template for team members
   - Both `firebase_options.dart` and other config files are secured

### Environment File Structure

The app will automatically load environment variables on startup. If the `.env` file is missing, the app will show warnings but continue to run with empty API keys (which will cause Firebase and RevenueCat features to fail).

## API Integration

The application uses Firebase Cloud Functions for backend processing:

- Nutrition Plan Calculation: `https://us-central1-kaliai-6dff9.cloudfunctions.net/calculate_nutrition_plan`
  - This endpoint calculates personalized nutrition plans based on user data
  - Input parameters:
    - `weight`: (number) User's current weight in kg
    - `height`: (number) User's height in cm
    - `age`: (number) User's age in years
    - `gender`: (string) "male" or "female"
    - `goal`: (string) "lose_weight", "gain_weight", "maintain_weight", or "build_muscle"
    - `activity_level`: (string) "sedentary", "light", "moderate", "active", or "very_active"
    - `target_weight`: (number) User's target weight in kg
  - Output:
    - `daily_calories`: (number) Recommended daily calorie intake
    - `protein_g`: (number) Daily protein target in grams
    - `carbs_g`: (number) Daily carbohydrates target in grams
    - `fats_g`: (number) Daily fats target in grams
    - `bmr`: (number) Basal Metabolic Rate
    - `bmi`: (number) Body Mass Index
    - `target_date`: (string) Estimated date to reach target weight (YYYY-MM-DD)
    - `weeks_to_goal`: (number) Estimated weeks to reach target weight
  
  > Note: The app includes a local calculation fallback in case the API is unavailable

- Meal Image Analysis: Firebase Vision API integration for food recognition
  - Analyzes food images to estimate nutritional content

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Firebase account with cloud functions enabled
- RevenueCat account with configured API keys
- Internet connection for API requests

### Setup
1. Clone the repository
2. Set up environment variables as described above
3. Run `flutter pub get` to install dependencies
4. Ensure Firebase configuration is set up properly

### Running the App
```bash
flutter run
```

## Features
- Personalized nutrition plans
- Weight tracking
- Meal analysis with image recognition
- Daily goal tracking
- In-app purchases with RevenueCat integration

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class WizardProvider extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentIndex = 0;
  final int totalScreens;
  int _height = 175;
  bool _isMetric = true;
  int _age = 19;
  int? _selectedGoal;
  int? _selectedDiet;
  int? _selectedWorkoutIndex;
  double _goalSpeed = 0.9;
  int? _selectedGender;
  double _weight = 70.0;
  double _targetWeight = 65.0;
  bool _isKg = true;
  int? _selectedSocialMedia;

  FixedExtentScrollController? _scrollController;

  int get height => _height;
  bool get isMetric => _isMetric;
  int get age => _age;
  int? get selectedGoal => _selectedGoal;
  int? get selectedDiet => _selectedDiet;
  int? get selectedWorkoutIndex => _selectedWorkoutIndex;
  double get goalSpeed => _goalSpeed;
  int? get selectedGender => _selectedGender;
  double get weight => _weight;
  double get targetWeight => _targetWeight;
  bool get isKg => _isKg;
  int? get selectedSocialMedia => _selectedSocialMedia;

  FixedExtentScrollController get scrollController {
    _scrollController ??= FixedExtentScrollController(
      initialItem: ((_weight - (_isKg ? 40.0 : 90.0)) / 0.1).round(),
    );
    return _scrollController!;
  }

  WizardProvider({required this.totalScreens}) {
    _loadWizardData();
  }

  Future<void> _loadWizardData() async {
    final prefs = await SharedPreferences.getInstance();
    _targetWeight = prefs.getDouble('wizard_target_weight') ?? 65.0;
    notifyListeners();
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void goTo(int index) {
    if (index >= 0 && index < totalScreens) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void nextPage() {
    if (currentIndex < totalScreens - 1) {
      goTo(currentIndex + 1);
    }
  }

  void prevPage() {
    if (currentIndex > 0) {
      goTo(currentIndex - 1);
    }
  }

  void setWeight(double value) {
    _weight = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  void setTargetWeight(double value) {
    _targetWeight = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  void toggleUnit(bool toKg) {
    _isKg = toKg;
    _weight = toKg ? 70.0 : 120.0;

    _scrollController?.dispose();
    _scrollController = FixedExtentScrollController(
      initialItem: ((_weight - (_isKg ? 40.0 : 90.0)) / 0.1).round(),
    );

    notifyListeners();
  }

  void selectGender(int index) {
    _selectedGender = index;
    notifyListeners();
  }

  void toggleMetric(bool toMetric) {
    _isMetric = toMetric;
    _height = toMetric ? 175 : 69;
    notifyListeners();
  }

  void setHeight(int value) {
    _height = value;
    notifyListeners();
  }

  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  void selectGoal(int index) {
    _selectedGoal = index;
    notifyListeners();
  }

  void selectDiet(int index) {
    _selectedDiet = index;
    notifyListeners();
  }

  void selectWorkoutIndex(int index) {
    _selectedWorkoutIndex = index;
    notifyListeners();
  }

  void setGoalSpeed(double value) {
    _goalSpeed = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  void selectSocialMedia(int index) {
    _selectedSocialMedia = index;
    notifyListeners();
  }

  void reset() {
    currentIndex = 0;
    _height = 175;
    _isMetric = true;
    _age = 19;
    _selectedGoal = null;
    _selectedDiet = null;
    _selectedWorkoutIndex = null;
    _goalSpeed = 0.9;
    _selectedGender = null;
    _weight = 70.0;
    _targetWeight = 65.0;
    _isKg = true;
    _selectedSocialMedia = null;
    
    // Reset scroll controller
    _scrollController?.dispose();
    _scrollController = null;
    
    // Reset page controller
    pageController.jumpToPage(0);
    
    notifyListeners();
  }

  // Helper methods to check if selections are valid
  bool isGenderSelected() {
    return _selectedGender != null;
  }

  bool isGoalSelected() {
    return _selectedGoal != null;
  }

  bool isDietSelected() {
    return _selectedDiet != null;
  }

  bool isWorkoutSelected() {
    return _selectedWorkoutIndex != null;
  }

  bool isSocialMediaSelected() {
    return _selectedSocialMedia != null;
  }

  // Method to check if current screen has valid selection
  bool isCurrentScreenValid(int screenIndex) {
    switch (screenIndex) {
      case 3: // Gender selection (wizard4)
        return isGenderSelected();
      case 4: // Goal selection (wizard5)
        return isGoalSelected();
      case 5: // Diet selection (wizard6)
        return isDietSelected();
      case 8: // Workout selection (wizard9)
        return isWorkoutSelected();
      case 14: // Social media selection (wizard15)
        return isSocialMediaSelected();
      default:
        return true; // Other screens don't require selection validation
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    pageController.dispose();
    super.dispose();
  }

  // Save all wizard data to SharedPreferences
  Future<void> saveAllWizardData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save all wizard selections
    if (_selectedGender != null) {
      await prefs.setInt('wizard_gender', _selectedGender!);
    }
    await prefs.setInt('wizard_height', _height);
    await prefs.setBool('wizard_is_metric', _isMetric);
    await prefs.setInt('wizard_age', _age);
    if (_selectedGoal != null) {
      await prefs.setInt('wizard_goal', _selectedGoal!);
    }
    if (_selectedDiet != null) {
      await prefs.setInt('wizard_diet', _selectedDiet!);
    }
    if (_selectedWorkoutIndex != null) {
      await prefs.setInt('wizard_workout', _selectedWorkoutIndex!);
    }
    await prefs.setDouble('wizard_goal_speed', _goalSpeed);
    await prefs.setDouble('wizard_weight', _weight);
    await prefs.setDouble('wizard_target_weight', _targetWeight);
    await prefs.setBool('wizard_is_kg', _isKg);
    if (_selectedSocialMedia != null) {
      await prefs.setInt('wizard_social_media', _selectedSocialMedia!);
    }
  }

  // Get complete wizard data as JSON
  static Future<Map<String, dynamic>> getWizardDataAsJson() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Define mappings for human-readable values
    final genderOptions = ['Male', 'Female', 'Other'];
    final goalOptions = ['Lose weight', 'Maintain weight', 'Gain weight'];
    final dietOptions = ['Regular', 'Vegetarian', 'Vegan', 'Keto'];
    final workoutOptions = ['0-2', '2-4', '4-6', '6-8'];
    final socialMediaOptions = ['Instagram', 'Facebook', 'Website', 'TikTok'];

    // Get app version info
    PackageInfo packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      packageInfo = PackageInfo(
        appName: 'Kali AI',
        packageName: 'com.theholylabs.kaliai',
        version: '1.0.0',
        buildNumber: '1',
      );
    }
    
    // Get device info
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceInfoStr = 'Unknown';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceInfoStr = '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceInfoStr = '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
    } catch (e) {
      deviceInfoStr = 'Unknown Device';
    }
    
    // Retrieve all data
    final data = <String, dynamic>{
      'app_info': {
        'name': packageInfo.appName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
        'base_url': 'https://us-central1-kaliai-6dff9.cloudfunctions.net/analyze_meal_image_v1', // Replace with your actual API base URL
      },
  
      'device_info': {
        'platform': Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown',
        'device': deviceInfoStr,
      },
      'timestamp': {
        'generated_at': DateTime.now().toIso8601String(),
        'timezone': DateTime.now().timeZoneName,
      },
      'wizard_completed': prefs.getBool('has_completed_wizard') ?? false,
      'age': prefs.getInt('wizard_age') ?? 19,
      'height': {
        'value': prefs.getInt('wizard_height') ?? 175,
        'unit': prefs.getBool('wizard_is_metric') == true ? 'cm' : 'inches',
        'is_metric': prefs.getBool('wizard_is_metric') ?? true,
      },
      'weight': {
        'value': prefs.getDouble('wizard_weight') ?? 70.0,
        'unit': prefs.getBool('wizard_is_kg') == true ? 'kg' : 'lbs',
        'is_kg': prefs.getBool('wizard_is_kg') ?? true,
      },
      'target_weight': {
        'value': prefs.getDouble('wizard_target_weight') ?? 65.0,
        'unit': prefs.getBool('wizard_is_kg') == true ? 'kg' : 'lbs',
        'is_kg': prefs.getBool('wizard_is_kg') ?? true,
      },
      'gender': {
        'index': prefs.getInt('wizard_gender'),
        'value': prefs.getInt('wizard_gender') != null && prefs.getInt('wizard_gender')! < genderOptions.length
            ? genderOptions[prefs.getInt('wizard_gender')!]
            : null,
      },
      'goal': {
        'index': prefs.getInt('wizard_goal'),
        'value': prefs.getInt('wizard_goal') != null && prefs.getInt('wizard_goal')! < goalOptions.length
            ? goalOptions[prefs.getInt('wizard_goal')!]
            : null,
      },
      'diet': {
        'index': prefs.getInt('wizard_diet'),
        'value': prefs.getInt('wizard_diet') != null && prefs.getInt('wizard_diet')! < dietOptions.length
            ? dietOptions[prefs.getInt('wizard_diet')!]
            : null,
      },
      'workout_frequency': {
        'index': prefs.getInt('wizard_workout'),
        'value': prefs.getInt('wizard_workout') != null && prefs.getInt('wizard_workout')! < workoutOptions.length
            ? '${workoutOptions[prefs.getInt('wizard_workout')!]} hours per week'
            : null,
      },
      'goal_speed': prefs.getDouble('wizard_goal_speed') ?? 0.9,
      'social_media': {
        'index': prefs.getInt('wizard_social_media'),
        'value': prefs.getInt('wizard_social_media') != null && prefs.getInt('wizard_social_media')! < socialMediaOptions.length
            ? socialMediaOptions[prefs.getInt('wizard_social_media')!]
            : null,
      },
      'referral_code': prefs.getString('referral_code'),
      'has_used_referral_code': prefs.getBool('has_used_referral_code') ?? false,
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? false,
      'nutrition_goals': {
        'calories': prefs.getDouble('nutrition_goal_calories') ?? 2000,
        'protein': prefs.getDouble('nutrition_goal_protein') ?? 150,
        'carbs': prefs.getDouble('nutrition_goal_carbs') ?? 300,
        'fats': prefs.getDouble('nutrition_goal_fats') ?? 65,
      },
    };

    return data;
  }
}

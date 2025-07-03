import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static SharedPreferences? _preferences;
  
  // Keys
  static const String _wizardCompletedKey = 'wizard_completed';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  
  // Initialize SharedPreferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get instance {
    if (_preferences == null) {
      throw Exception('SharedPreferences not initialized. Call SharedPref.init() first.');
    }
    return _preferences!;
  }
  
  // Wizard completion
  static Future<void> setWizardCompleted(bool completed) async {
    await instance.setBool(_wizardCompletedKey, completed);
  }
  
  static bool getWizardCompleted() {
    return instance.getBool(_wizardCompletedKey) ?? false;
  }
  
  // User data
  static Future<void> setUserEmail(String email) async {
    await instance.setString(_userEmailKey, email);
  }
  
  static String? getUserEmail() {
    return instance.getString(_userEmailKey);
  }
  
  static Future<void> setUserName(String name) async {
    await instance.setString(_userNameKey, name);
  }
  
  static String? getUserName() {
    return instance.getString(_userNameKey);
  }
  
  // Clear user data only (keep wizard completion)
  static Future<void> clearUserData() async {
    await instance.remove(_userEmailKey);
    await instance.remove(_userNameKey);
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await instance.clear();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../dashboard/dashboard.dart';
import 'signup.dart';
import 'forgot_password.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert' show json;
import '../main.dart';
import '../services/paywall_service.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryColor = Color(0xFF232228);
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login.password_reset_sent'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login.password_reset_error'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> saveUserInfoToPrefs({
    required String email,
    required String displayName,
    required String uid,
    Map<String, dynamic>? wizardData,
    Map<String, dynamic>? nutritionData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_display_name', displayName);
    await prefs.setString('user_id', uid);
    await prefs.setBool('isLoggedIn', true);
    if (wizardData != null) {
      await prefs.setString('wizard_data', json.encode(wizardData));
    }
    if (nutritionData != null) {
      nutritionData.forEach((key, value) async {
        if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        }
      });
    }
    print('[SharedPreferences] Saved: email=$email, displayName=$displayName, uid=$uid, wizardData=$wizardData, nutritionData=$nutritionData');
  }

  Future<void> _handleLoginSuccess(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final firestore = FirebaseFirestore.instance;

      // First try to load from wizard_data
      final wizardDataStr = prefs.getString('wizard_data');
      Map<String, dynamic> nutritionalData = {};
      Map<String, dynamic> wizardData = {};
      if (wizardDataStr != null) {
        // Use wizard data if available
        final decoded = json.decode(wizardDataStr);
        if (decoded is Map<String, dynamic>) {
          wizardData = decoded;
          nutritionalData = decoded;
        }
      } else {
        // Fallback to individual keys
        nutritionalData = {
          'calories': prefs.getDouble('daily_calories') ?? 2000.0,
          'protein': prefs.getDouble('daily_protein') ?? 150.0,
          'carbs': prefs.getDouble('daily_carbs') ?? 300.0,
          'fats': prefs.getDouble('daily_fats') ?? 65.0,
        };
      }

      // Save to Firestore with user data and nutritional results
      final firestoreData = {
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'createdAt': FieldValue.serverTimestamp(),
        // Do not save goals here
      };
      await firestore.collection('users').doc(user.uid).set(firestoreData, SetOptions(merge: true));
      print('[Firestore] Saved: $firestoreData');

      // Save to SharedPreferences (all info)
      await saveUserInfoToPrefs(
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        uid: user.uid,
        wizardData: wizardData.isNotEmpty ? wizardData : null,
        nutritionData: nutritionalData.isNotEmpty ? nutritionalData : null,
      );

      // Login user to RevenueCat
      await PaywallService.loginUser(user.uid);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainTabScreen()),
          (Route<dynamic> route) => false,
        );
        
        // Trigger dashboard refresh after successful login to clear local storage meals
        Future.delayed(const Duration(milliseconds: 500), () {
          dashboardKey.currentState?.handleAuthStateChange();
        });
      }
    } catch (e) {
      print('Error during login success handling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during login: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add the calculation method from wizard screen
  Map<String, double> _calculateDailyNeeds({
    required double height,
    required double weight,
    required String gender,
    required DateTime birthDate,
    required String goal
  }) {
    // Calculate age
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Adjust for activity level (using moderate activity as default)
    double activityMultiplier = 1.55; // Moderate activity
    double dailyCalories = bmr * activityMultiplier;

    // Adjust calories based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        dailyCalories *= 0.85; // 15% deficit
        break;
      case 'gain weight':
      case 'build muscle':
        dailyCalories *= 1.15; // 15% surplus
        break;
      default: // maintain weight
        break;
    }

    // Calculate macros based on standard ratios
    double protein = (dailyCalories * 0.3) / 4; // 30% of calories from protein
    double carbs = (dailyCalories * 0.5) / 4;   // 50% of calories from carbs
    double fats = (dailyCalories * 0.2) / 9;    // 20% of calories from fats

    return {
      'calories': dailyCalories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats
    };
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _handleLoginSuccess(userCredential); // Use the same success handler

    } catch (e) {
      print('Error during Google sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      setState(() => _isLoading = true);
      
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        
        // Get display name with proper priority
        String displayName;
        
        // 1. Try to get from Apple credentials (first sign in)
        if (credential.givenName != null && credential.familyName != null) {
          displayName = "${credential.givenName} ${credential.familyName}";
          // Store the name for future use
          await prefs.setString('apple_display_name', displayName);
        } else {
          // 2. Try to get from stored Apple name
          final storedName = prefs.getString('apple_display_name');
          if (storedName != null && storedName.isNotEmpty) {
            displayName = storedName;
          } else {
            // 3. Try to get from Firestore
            try {
              final userDoc = await _firestore.collection('users').doc(user.uid).get();
              if (userDoc.exists && userDoc.data()?['displayName'] != null && 
                  userDoc.data()!['displayName'] != 'User') {
                displayName = userDoc.data()!['displayName'];
              } else {
                // 4. Format email as last resort
                final emailName = user.email?.split('@')[0] ?? '';
                displayName = emailName
                    .split('.')
                    .map((word) => word.isEmpty ? '' : 
                        '${word[0].toUpperCase()}${word.substring(1)}')
                    .join(' ');
              }
            } catch (e) {
              // 5. Use formatted email if Firestore fails
              final emailName = user.email?.split('@')[0] ?? '';
              displayName = emailName
                  .split('.')
                  .map((word) => word.isEmpty ? '' : 
                      '${word[0].toUpperCase()}${word.substring(1)}')
                  .join(' ');
            }
          }
        }

        // Update Firebase user profile
        await user.updateDisplayName(displayName);

        // Get nutritional data from local storage
        final calories = prefs.getDouble('daily_calories') ?? 2000.0;
        final protein = prefs.getDouble('daily_protein') ?? 150.0;
        final carbs = prefs.getDouble('daily_carbs') ?? 300.0;
        final fats = prefs.getDouble('daily_fats') ?? 65.0;

        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'email': user.email,
          'lastLogin': FieldValue.serverTimestamp(),
          'platform': Platform.isIOS ? 'ios' : 'android',
          // Store nutritional results
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fats': fats,
        }, SetOptions(merge: true));

        // Save to SharedPreferences
        await prefs.setString('user_display_name', displayName);
        await prefs.setString('user_email', user.email ?? '');
        await prefs.setString('user_id', user.uid);
        await prefs.setBool('isLoggedIn', true);

        // Login user to RevenueCat
        await PaywallService.loginUser(user.uid);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainTabScreen()),
            (Route<dynamic> route) => false,
          );
          
          // Trigger dashboard refresh after successful login to clear local storage meals
          Future.delayed(const Duration(milliseconds: 500), () {
            dashboardKey.currentState?.handleAuthStateChange();
          });
        }
      }
    } catch (e) {
      print('Error during Apple sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in with Apple: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MainTabScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'login.welcome_back'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'login.email'.tr(),
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'login.email_required'.tr();
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'login.email_invalid'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'login.password'.tr(),
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'login.password_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'login.forgot_password'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                        await _handleLoginSuccess(userCredential);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('login.login_failed'.tr(args: [e.toString()])),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'login.log_in'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'login.or_continue_with'.tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!kIsWeb && Platform.isAndroid)
                        _buildSocialButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: Icons.g_mobiledata,
                          label: 'login.google'.tr(),
                        ),
                      if (!kIsWeb && Platform.isAndroid && !kIsWeb && Platform.isIOS)
                        const SizedBox(width: 16),
                      if (!kIsWeb && Platform.isIOS)
                        _buildSocialButton(
                          onPressed: _isLoading ? null : _handleAppleSignIn,
                          icon: Icons.apple,
                          label: 'login.apple'.tr(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text(
                      'login.no_account'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

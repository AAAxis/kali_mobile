import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'dart:io' show Platform;
import 'dart:convert' show json;
import 'login.dart';
import '../dashboard/dashboard.dart';
import '../main.dart';
import '../services/paywall_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
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

  Future<void> _handleSignUpSuccess(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final auth = FirebaseAuth.instance;
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
        'displayName': _nameController.text.trim(),
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        // Do not save goals here
      };
      await firestore.collection('users').doc(user.uid).set(firestoreData, SetOptions(merge: true));
      print('[Firestore] Saved: $firestoreData');

      // Save to SharedPreferences (all info)
      await saveUserInfoToPrefs(
        email: user.email ?? '',
        displayName: _nameController.text.trim(),
        uid: user.uid,
        wizardData: wizardData.isNotEmpty ? wizardData : null,
        nutritionData: nutritionalData.isNotEmpty ? nutritionalData : null,
      );

      // Send verification code
      try {
        final response = await http.get(
          Uri.parse('https://api.theholylabs.com/global_auth').replace(
            queryParameters: {'email': user.email},
          ),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          await prefs.setString('verification_code', responseData['verification_code']);

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => DashboardScreen(dashboardKey: globalDashboardKey)),
              (Route<dynamic> route) => false,
            );
            
            // Trigger refresh on the dashboard if it exists
            globalDashboardKey.currentState?.handleAuthStateChange();
          }
        } else {
          throw Exception('Failed to send verification code');
        }
      } catch (e) {
        print('Error sending verification code: $e');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => DashboardScreen(dashboardKey: globalDashboardKey)),
            (Route<dynamic> route) => false,
          );
          
          // Trigger refresh on the dashboard if it exists
          globalDashboardKey.currentState?.handleAuthStateChange();
        }
      }
    } catch (e) {
      print('Error during signup success handling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during signup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF232228);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            }
          },
        ),
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
                    'signup.create_account'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'signup.full_name'.tr(),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'signup.name_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'signup.email'.tr(),
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 2),
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
                      labelText: 'signup.password'.tr(),
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF232228), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'login.password_required'.tr();
                      } else if (value.length < 6) {
                        return 'signup.password_length'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            final userCredential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                            await _handleSignUpSuccess(userCredential);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('signup.signup_failed'.tr(args: [e.toString()])),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
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
                              'signup.sign_up'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'signup.have_account'.tr(),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF232228)),
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
}
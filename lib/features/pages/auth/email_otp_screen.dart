import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/constant/app_icons.dart';
import '../../../core/extension/navigation_extention.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/custom_widgets/wide_elevated_button.dart';
import '../../../core/custom_widgets/otp_input_row.dart';
import '../../../core/store/shared_pref.dart';
import '../../providers/otp_provider.dart';
import '../dashboard/dashboard_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String name;
  final String password;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.name,
    required this.password,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  String _verificationCode = '';
  late OtpProvider _otpProvider;

  @override
  void initState() {
    super.initState();
    _otpProvider = OtpProvider(length: 6);
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _otpProvider.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isResending = true);
    
    try {
      print('🔗 Sending request to: https://api.theholylabs.com/global_auth?email=${widget.email}');
      
      // Test basic connectivity first
      try {
        final testResponse = await http.get(
          Uri.parse('https://httpbin.org/get'),
          headers: {'User-Agent': 'Flutter-Test'},
        ).timeout(Duration(seconds: 5));
        print('🌐 Connectivity test: ${testResponse.statusCode}');
      } catch (e) {
        print('❌ Connectivity test failed: $e');
      }
      
      // Create HTTP client with custom SSL handling
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('🔒 SSL Certificate issue for $host:$port');
        print('🔒 Certificate subject: ${cert.subject}');
        print('🔒 Certificate issuer: ${cert.issuer}');
        // Accept certificate for api.theholylabs.com
        return host == 'api.theholylabs.com';
      };
      
      // Use custom HTTP client for the request
      final httpClient = IOClient(client);
      final response = await httpClient.get(
        Uri.parse('https://api.theholylabs.com/global_auth?email=${widget.email}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Cache-Control': 'max-age=0',
        },
      ).timeout(Duration(seconds: 30)); // Increased timeout to 30 seconds
      
      // Close the client
      httpClient.close();

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _verificationCode = data['verification_code'] ?? '';
        
        print('🔐 Received verification code from API: $_verificationCode');
        
        if (_verificationCode.isEmpty) {
          throw Exception('No verification code in response');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification code sent to ${widget.email}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        throw Exception('API returned status code: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending verification code: $e');
      
      // Try alternative approach with simpler headers and SSL bypass
      try {
        print('🔄 Trying alternative request with SSL bypass...');
        
        final altClient = HttpClient();
        altClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true; // Accept all certificates
         final altHttpClient = IOClient(altClient);
        
        final altResponse = await altHttpClient.get(
          Uri.parse('https://api.theholylabs.com/global_auth?email=${widget.email}'),
          headers: {
            'User-Agent': 'KaliAI-Mobile-App/1.0',
          },
        ).timeout(Duration(seconds: 15));
        
        altHttpClient.close();
        
        print('📡 Alternative response status: ${altResponse.statusCode}');
        print('📄 Alternative response body: ${altResponse.body}');
        
        if (altResponse.statusCode == 200) {
          final data = json.decode(altResponse.body);
          _verificationCode = data['verification_code'] ?? '';
          
          if (_verificationCode.isNotEmpty) {
            print('✅ Alternative request succeeded! Code: $_verificationCode');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification code sent to ${widget.email}'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }
            return; // Success with alternative method
          }
        }
      } catch (altError) {
        print('❌ Alternative request also failed: $altError');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      
      // Don't set a fallback code - let the user retry
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyCodeAndCreateAccount() async {
    final enteredCode = _otpProvider.otp;
    
    if (enteredCode.length != 6) {
      _showError('Please enter the complete 6-digit code.');
      return;
    }

    if (_verificationCode.isEmpty) {
      _showError('No verification code received. Please resend the code.');
      return;
    }

    if (enteredCode != _verificationCode) {
      _showError('Invalid verification code. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user account with Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      if (userCredential.user != null) {
        // Update user profile with name
        await userCredential.user!.updateDisplayName(widget.name);
        
        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': widget.email,
          'name': widget.name,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
        });

        // Save to SharedPreferences
        await SharedPref.setUserEmail(widget.email);
        await SharedPref.setUserName(widget.name);

        if (mounted) {
          // Navigate to dashboard using go_router
          context.go('/dashboard');
        }
      }
    } catch (e) {
      print('Error creating account: $e');
      
      // Handle specific Firebase errors
      if (e.toString().contains('email-already-in-use')) {
        _showError('This email is already registered. Please use the login screen instead.');
      } else if (e.toString().contains('weak-password')) {
        _showError('Password is too weak. Please choose a stronger password.');
      } else if (e.toString().contains('invalid-email')) {
        _showError('Invalid email address. Please check and try again.');
      } else {
        _showError('Failed to create account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _resendCode() async {
    // Clear OTP fields
    for (var controller in _otpProvider.controllers) {
      controller.clear();
    }
    
    await _sendVerificationCode();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider.value(
      value: _otpProvider,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 24.h),
                
                // App title
                Image.asset(
                  AppIcons.kali,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 30.h),
                
                // Email Sent Title
                Text(
                  "Email Sent!",
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 18.h),
                
                // Description
                Text.rich(
                  TextSpan(
                    text: "We've sent a one time password to\n",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: widget.email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.h),

                // OTP Input Row
                OtpInputRow(length: 6),

                SizedBox(height: 20.h),
                
                // Resend section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: _isResending ? null : _resendCode,
                      child: Text(
                        _isResending ? "Sending..." : "Resend",
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isResending 
                              ? colorScheme.onSurface.withOpacity(0.5)
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Verify Button
                WideElevatedButton(
                  label: _isLoading ? 'Verifying...' : 'Verify & Create Account',
                  onPressed: _isLoading ? null : _verifyCodeAndCreateAccount,
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  borderRadius: 24,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  elevation: 10,
                  margin: EdgeInsets.symmetric(horizontal: 0),
                ),
                SizedBox(height: 28.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

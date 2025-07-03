import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';
import '../../../core/constant/app_icons.dart';
import '../../../core/custom_widgets/social_button.dart';
import '../../../core/extension/navigation_extention.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/store/shared_pref.dart';
import 'package:go_router/go_router.dart';
import 'login_with_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    
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
      await _handleLoginSuccess(userCredential);
    } catch (e) {
      print('Error during Apple sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple sign in failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    
    try {
      setState(() => _isLoading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _handleLoginSuccess(userCredential);
    } catch (e) {
      print('Error during Google sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLoginSuccess(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      // Save user info to SharedPreferences
      await SharedPref.setUserEmail(user.email ?? '');
      await SharedPref.setUserName(user.displayName ?? '');
      
      if (mounted) {
        // Navigate to dashboard using go_router
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/dashboard');
        });
      }
    } catch (e) {
      print('Error during login success handling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login success handling failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // X button in top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
              // Logo/title
              Image.asset(
                AppIcons.kali,
                color: colorScheme.primary,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              
              // Platform-specific social login buttons
              if (Platform.isIOS) ...[
                // Apple Button (iOS only)
                SocialButton(
                  label: 'Continue with Apple',
                  assetPath: AppIcons.apple,
                  onPressed: _isLoading ? null : _handleAppleSignIn,
                  borderColor: colorScheme.outline,
                  textColor: colorScheme.onSurface,
                  backgroundColor: colorScheme.surface,
                ),
                SizedBox(height: 18.h),
              ],
              
              if (Platform.isAndroid) ...[
                // Google Button (Android only)
                SocialButton(
                  label: 'Continue with Google',
                  assetPath: AppIcons.google,
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  borderColor: colorScheme.outline,
                  textColor: colorScheme.onSurface,
                  backgroundColor: colorScheme.surface,
                ),
                SizedBox(height: 18.h),
              ],
              
              // Email button (always available)
              SocialButton(
                label: 'Continue with Email',
                assetPath: AppIcons.email,
                onPressed: _isLoading ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginWithEmailScreen(),
                    ),
                  );
                },
                borderColor: colorScheme.outline,
                textColor: colorScheme.onSurface,
                backgroundColor: colorScheme.surface,
              ),
              
              // Loading indicator
              if (_isLoading) ...[
                SizedBox(height: 18.h),
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ],
              SizedBox(height: 34.h),

              const Spacer(),
              // Login Button

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t Have an Account? ",
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: () => context.goToSignup(),
                    child: Text(
                      "Signup",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
            ],
          ),
        ),
      ),
    );
  }
}

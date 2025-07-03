import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/constant/app_icons.dart';
import '../../../core/custom_widgets/social_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_text_styles.dart';
import 'login_with_email_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.signInWithApple();
      
      if (result.isSuccess) {
        await _handleLoginSuccess();
      } else {
        _showError(result.error ?? 'Apple sign in failed');
      }
    } catch (e) {
      _showError('Apple sign in failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.signInWithGoogle();
      
      if (result.isSuccess) {
        await _handleLoginSuccess();
      } else {
        _showError(result.error ?? 'Google sign in failed');
      }
    } catch (e) {
      _showError('Google sign in failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLoginSuccess() async {
    if (mounted) {
      // Navigate to dashboard using go_router
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
                  Container(
                    margin: EdgeInsets.only(top: 8.h, right: 8.w),
                    child: IconButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurface,
                        size: 24.sp,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: Size(44.w, 44.h),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
                SizedBox(height: 32.h),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ],
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

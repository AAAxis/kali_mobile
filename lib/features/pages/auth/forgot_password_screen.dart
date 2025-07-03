import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/custom_widgets/custom_text_field.dart';
import '../../../core/custom_widgets/wide_elevated_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_text_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('📧 Sending password reset email to: ${_emailController.text.trim()}');
      
      final result = await AuthService.sendPasswordResetEmail(_emailController.text.trim());

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Password reset email sent'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        _showError(result.error ?? 'Failed to send reset email');
      }
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button in top left
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                color: colorScheme.onSurface,
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20.h),

                        // App Logo
                        Image.asset(
                          AppIcons.kali,
                          color: colorScheme.primary,
                        ),
                        SizedBox(height: 24.h),

                        // Title
                        Text(
                          "Forgot Password?",
                          style: AppTextStyles.headingMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),

                        // Subtitle
                        Text(
                          "Enter your email address and we'll send you a link to reset your password.",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 48.h),

                        // Email field
                        CustomTextField(
                          controller: _emailController,
                          labelText: "Email Address",
                          hintText: "Enter your email",
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                            child: Image.asset(
                              AppIcons.email,
                              color: colorScheme.onSurfaceVariant,
                              width: 18.w,
                              height: 18.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Send Reset Email Button
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: WideElevatedButton(
                  label: _isLoading ? 'Sending...' : 'Send Reset Email',
                  onPressed: _isLoading ? null : _sendPasswordReset,
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  borderRadius: 24,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  elevation: 10,
                  margin: EdgeInsets.symmetric(horizontal: 0),
                ),
              ),

              // Back to Login link
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Remember your password? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Sign In",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
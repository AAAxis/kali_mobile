import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/custom_widgets/custom_text_field.dart';
import '../../../core/custom_widgets/wide_elevated_button.dart';
import '../../../core/extension/navigation_extention.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constant/app_icons.dart';
import 'email_otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please accept the Terms and Conditions to continue.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Navigate to email OTP screen with the email, name, and password
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailOtpScreen(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      print('Error during sign up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                        // X button in top right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                context.go('/dashboard');
                              },
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurface,
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          AppIcons.kali,
                          color: colorScheme.primary,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "Let's Create Your Account",
                          style: AppTextStyles.headingMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "Enter your details to get started.",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 36.h),

                        // Name field
                        CustomTextField(
                          controller: _nameController,
                          labelText: "Name",
                          hintText: "Enter your name",
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                            child: Image.asset(
                              AppIcons.person,
                              color: colorScheme.onSurfaceVariant,
                              width: 18.w,
                              height: 18.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),

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
                        SizedBox(height: 24.h),

                        // Password field
                        CustomTextField(
                          controller: _passwordController,
                          labelText: "Password",
                          hintText: "Enter your password",
                          obscureText: !_isPasswordVisible,
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                            child: Icon(
                              Icons.lock_outline,
                              color: colorScheme.onSurfaceVariant,
                              size: 18.sp,
                            ),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: colorScheme.onSurfaceVariant,
                              size: 18.sp,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),

                        // Terms and Conditions Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (value) {
                                  setState(() => _agreedToTerms = value ?? false);
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I accept all the applied '),
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // TODO: Navigate to Terms and Conditions
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom buttons section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WideElevatedButton(
                    label: _isLoading ? 'Creating Account...' : 'Create Account',
                    onPressed: _isLoading ? null : _handleSignUp,
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    borderRadius: 24,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    elevation: 10,
                    margin: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () => context.goToLogin(),
                        child: Text(
                          "Login",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

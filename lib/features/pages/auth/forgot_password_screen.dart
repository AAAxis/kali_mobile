import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/custom_widgets/custom_text_field.dart';
import '../../../core/custom_widgets/wide_elevated_button.dart';
import '../../../core/theme/app_text_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
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
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${_emailController.text}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
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
                  
                  // App Logo
                  Image.asset(
                    AppIcons.kali,
                    color: colorScheme.primary,
                  ),
                  SizedBox(height: 20.h),
                  
                  // Title
                  Text(
                    "Forgot Password?",
                    style: AppTextStyles.headingMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  
                  // Subtitle
                  Text(
                    "Enter your email address and we'll send you instructions to reset your password",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 36.h),

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

                  SizedBox(height: 200.h),

                  // Send Reset Email Button
                  WideElevatedButton(
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
                  
                  SizedBox(height: 24.h),

                  // Back to Login
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      "Back to Login",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/custom_widgets/wide_elevated_button.dart';
import '../../../core/custom_widgets/otp_input_row.dart';
import '../../providers/otp_provider.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String name;
  final String password;
  final String expectedVerificationCode;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.name,
    required this.password,
    required this.expectedVerificationCode,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  String _currentVerificationCode = '';
  late OtpProvider _otpProvider;

  @override
  void initState() {
    super.initState();
    _otpProvider = OtpProvider(length: 6);
    _currentVerificationCode = widget.expectedVerificationCode;
    
    // Show success message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to ${widget.email}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _otpProvider.dispose();
    super.dispose();
  }

  Future<void> _resendVerificationCode() async {
    setState(() => _isResending = true);
    
    try {
      print('📧 Resending verification code to: ${widget.email}');
      
      final result = await AuthService.sendEmailVerificationCode(widget.email);
      
      if (result.isSuccess) {
        _currentVerificationCode = result.verificationCode!;
        
        // Clear OTP fields
        for (var controller in _otpProvider.controllers) {
          controller.clear();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New verification code sent to ${widget.email}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        _showError(result.error ?? 'Failed to resend verification code');
      }
    } catch (e) {
      print('❌ Error resending verification code: $e');
      _showError('Failed to resend verification code. Please try again.');
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

    if (_currentVerificationCode.isEmpty) {
      _showError('No verification code available. Please resend the code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔐 Verifying code and creating account...');
      
      final result = await AuthService.createAccountWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
        name: widget.name,
        verificationCode: enteredCode,
        expectedCode: _currentVerificationCode,
      );

      if (result.isSuccess) {
        if (mounted) {
          // Navigate to dashboard using go_router
          context.go('/dashboard');
        }
      } else {
        _showError(result.error ?? 'Failed to create account');
      }
    } catch (e) {
      print('❌ Error creating account: $e');
      _showError('Failed to create account. Please try again.');
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                        "Check Your Email",
                        style: AppTextStyles.headingMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),

                      // Subtitle
                      Text(
                        "We've sent a 6-digit verification code to",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),

                      // Email
                      Text(
                        widget.email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 48.h),

                      // OTP Input
                      ChangeNotifierProvider.value(
                        value: _otpProvider,
                        child: const OtpInputRow(),
                      ),
                      SizedBox(height: 32.h),

                      // Resend Code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isResending ? null : _resendVerificationCode,
                            child: Text(
                              _isResending ? "Sending..." : "Resend",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _isResending ? colorScheme.onSurfaceVariant : colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Verify Button
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: WideElevatedButton(
                  label: _isLoading ? 'Verifying...' : 'Verify & Create Account',
                  onPressed: (_isLoading || _isResending) ? null : _verifyCodeAndCreateAccount,
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  borderRadius: 24,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  elevation: 10,
                  margin: EdgeInsets.symmetric(horizontal: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

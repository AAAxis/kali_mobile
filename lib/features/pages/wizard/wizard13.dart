import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/app_images.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../providers/wizard_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Wizard13 extends StatefulWidget {
  const Wizard13({super.key});

  @override
  State<Wizard13> createState() => _Wizard13State();
}

class _Wizard13State extends State<Wizard13> {
  bool _isRequesting = false;
  PermissionStatus? _notificationStatus;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationStatus = status;
    });
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final status = await Permission.notification.request();
      setState(() {
        _notificationStatus = status;
        _isRequesting = false;
      });

      if (status.isGranted) {
        _showSuccess('Notifications enabled! You\'ll get helpful reminders.');
      } else if (status.isDenied) {
        _showInfo('You can enable notifications later in your device settings.');
      } else if (status.isPermanentlyDenied) {
        _showError('Please enable notifications in your device settings.');
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
      });
      _showError('Error requesting notification permission: $e');
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
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
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: Constants.beforeIcon),
              Image.asset(
                AppIcons.kali,
                color: colorScheme.primary,
              ),
              SizedBox(height: Constants.afterIcon),

              // Image display with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.asset(
                  AppImages.notif,
                  width: double.infinity,
                  height: 240.h,
                  fit: BoxFit.cover,
                ),
              ),

              SizedBox(height: 20.h),

              // Main heading
              Text(
                "Reach your goals faster with\nnotifications",
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 24.sp,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20.h),

              // Notification permission dialog
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_notificationStatus == PermissionStatus.granted) ...[
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                        ],
                        Expanded(
                          child: Text(
                            _notificationStatus == PermissionStatus.granted
                                ? "Notifications are enabled"
                                : "Kali Ai would like to send you\nNotifications",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 16.sp,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Allow/Deny Buttons
                    Row(
                      children: [
                        // Don't Allow button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextButton(
                              onPressed: _isRequesting ? null : () {
                                // Skip notification permission
                                _showInfo('You can enable notifications later in your device settings.');
                                Provider.of<WizardProvider>(context,
                                        listen: false)
                                    .nextPage();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                "Don't Allow",
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _isRequesting 
                                      ? colorScheme.onSurface.withValues(alpha: 0.5)
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 12.w),

                        // Allow button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextButton(
                              onPressed: _isRequesting ? null : () async {
                                // Request notification permission
                                await _requestNotificationPermission();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: _isRequesting
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.surface,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Allow",
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: colorScheme.surface,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Additional text
              Text(
                "You can turn off Notifications anytime from your settings",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10.h),

              // Continue Button
              WizardButton(
                label: 'Continue',
                onPressed: () {
                  Provider.of<WizardProvider>(context, listen: false)
                      .nextPage();
                },
                padding: EdgeInsets.symmetric(vertical: 18.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
              SizedBox(height: 38.h),
              // App Title
              Image.asset(
                AppIcons.kali,
                color: colorScheme.primary,
              ),
              SizedBox(height: 20.h),
              
              // Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.asset(
                    AppImages.notif,
                    width: double.infinity,
                    height: 200.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              Text(
                'Reach your goals faster\nwith notifications',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              
              Text(
                'Kali Ai would like to send you\nNotifications',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              
              // Permission Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isRequesting ? null : () async {
                        // Skip notifications but save preference
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notifications_enabled', false);
                        if (!mounted) return;
                        Provider.of<WizardProvider>(context, listen: false).nextPage();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Text(
                        "Don't Allow",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : () async {
                        setState(() => _isRequesting = true);
                        try {
                          // Request notification permissions
                          final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
                          bool granted = true;

                          // Android permissions
                          final androidPlugin = flutterLocalNotificationsPlugin
                              .resolvePlatformSpecificImplementation<
                                AndroidFlutterLocalNotificationsPlugin
                              >();
                          if (androidPlugin != null) {
                            final result = await androidPlugin.requestNotificationsPermission();
                            if (result != null && result == false) granted = false;
                          }

                          // iOS permissions
                          final iosPlugin = flutterLocalNotificationsPlugin
                              .resolvePlatformSpecificImplementation<
                                IOSFlutterLocalNotificationsPlugin
                              >();
                          if (iosPlugin != null) {
                            final result = await iosPlugin.requestPermissions(
                              alert: true,
                              badge: true,
                              sound: true,
                            );
                            if (result != null && result == false) granted = false;
                          }

                          // Save preference
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notifications_enabled', granted);

                          if (!mounted) return;
                          Provider.of<WizardProvider>(context, listen: false).nextPage();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to enable notifications',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isRequesting = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Allow',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              Text(
                'You can turn off Notifications anytime from your settings',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Continue Button
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: WizardButton(
                  label: 'Continue',
                  onPressed: () {
                    Provider.of<WizardProvider>(context, listen: false).nextPage();
                  },
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

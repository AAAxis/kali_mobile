import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/health_service.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/constant/app_images.dart';

class Wizard19 extends StatefulWidget {
  const Wizard19({super.key});

  @override
  State<Wizard19> createState() => _Wizard19State();
}

class _Wizard19State extends State<Wizard19> {
  final HealthService _healthService = HealthService();
  bool _isConnecting = false;
  bool _isConnected = false;
  String _lastSyncTime = '';

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    final connected = await _healthService.isHealthConnected();
    final lastSync = await _healthService.getLastSyncTime();
    
    setState(() {
      _isConnected = connected;
      _lastSyncTime = lastSync != null 
          ? 'Last synced: ${_formatTime(lastSync)}'
          : 'Not connected';
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _connectToHealth() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Check if Health Connect is available (Android specific)
      final isAvailable = await _healthService.isHealthConnectAvailable();
      if (!isAvailable) {
        _showError(Platform.isAndroid 
            ? 'Health Connect is not installed or available on this device. Please install Google Health Connect from the Play Store.'
            : 'HealthKit is not available on this device');
        return;
      }

      // Request permissions - this will open Health Connect directly
      final authorized = await _healthService.requestPermissions();
      if (!authorized) {
        _showError(Platform.isAndroid 
            ? 'Health Connect permissions were denied. Tap "Connect" again to open Health Connect and grant permissions.'
            : 'HealthKit permissions not granted. Please allow access in your device settings.');
        return;
      }

      // Sync health data
      final result = await _healthService.syncAllHealthData();
      if (result['success']) {
        _showSuccess('Successfully connected to ${_healthService.getHealthAppName()}');
        await _checkConnectionStatus();
      } else {
        _showError('Failed to sync health data: ${result['error']}');
      }
    } catch (e) {
      _showError('Error connecting to health: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIOS = Platform.isIOS;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: Constants.beforeIcon),
              // App Title
              Image.asset(
                AppIcons.kali,
                color: colorScheme.primary,
              ),
              SizedBox(height: Constants.beforeIcon),
              // Main Title
              Text(
                "Connect with Health apps",
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              // Subtitle
              Text(
                isIOS 
                    ? "Sync your steps, calories, and workouts automatically\nwith Apple Health"
                    : "Connect with Health Connect to sync your fitness data.\nYou'll need to grant permissions when prompted.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              // Connection Status
              if (_isConnected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        _lastSyncTime,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20.h),
              // Platform-specific Health App Card
              _HealthAppCard(
                icon: isIOS ? AppImages.appleHealth : AppImages.googleFit,
                title: _healthService.getHealthAppName(),
                isConnected: _isConnected,
                isConnecting: _isConnecting,
                onConnect: _connectToHealth,
              ),
              const Spacer(),
              WizardButton(
                label: 'Continue',
                onPressed: () {
                  Provider.of<WizardProvider>(context, listen: false)
                      .nextPage();
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthAppCard extends StatelessWidget {
  final String icon;
  final String title;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _HealthAppCard({
    required this.icon,
    required this.title,
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        color: isConnected 
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isConnected 
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline,
          width: isConnected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            icon,
            width: 60.w,
            height: 60.w,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          if (isConnected)
            Text(
              'Connected',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          SizedBox(height: 18.h),
          SizedBox(
            width: 110.w,
            height: 38.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected 
                    ? Colors.green 
                    : colorScheme.primary,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 6.h),
                shadowColor: Colors.black.withValues(alpha: 0.18),
              ),
              onPressed: isConnecting ? null : onConnect,
              child: isConnecting
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      isConnected ? 'Reconnect' : 'Connect',
                      style: AppTextStyles.buttonText.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

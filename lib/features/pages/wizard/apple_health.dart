import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constant/app_images.dart';
import '../../../core/custom_widgets/health_status_card.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/services/health_service.dart';
import '../../providers/wizard_provider.dart';
import 'wizard13.dart';

class Wizard20 extends StatefulWidget {
  const Wizard20({super.key});

  @override
  State<Wizard20> createState() => _Wizard20State();
}

class _Wizard20State extends State<Wizard20> {
  final HealthService _healthService = HealthService();
  bool _isConnecting = false;
  bool _isConnected = false;
  String _lastSyncTime = '';

  void _navigateToNotifications(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Wizard13()),
    );
  }

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

  Future<void> _connectToAppleHealth() async {
    setState(() {
      _isConnecting = true;
      _isConnected = true; // Update switch immediately to show connecting state
    });

    try {
      // Check if health data is available
      final isAvailable = await _healthService.isHealthDataAvailable();
      if (!isAvailable) {
        _showError('Apple Health is not available on this device');
        setState(() {
          _isConnected = false;
        });
        return;
      }

      // Request permissions
      final authorized = await _healthService.requestPermissions();
      if (!authorized) {
        _showError('Apple Health permissions not granted');
        setState(() {
          _isConnected = false;
        });
        return;
      }

      // Sync health data
      final result = await _healthService.syncAllHealthData();
      if (result['success']) {
        _showSuccess('Successfully connected to Apple Health');
        await _checkConnectionStatus();
      } else {
        _showError('Failed to sync health data: ${result['error']}');
        setState(() {
          _isConnected = false;
        });
      }
    } catch (e) {
      _showError('Error connecting to Apple Health: $e');
      setState(() {
        _isConnected = false;
      });
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 46.h),
              Image.asset(
                AppImages.appleHealth,
                width: 90.w,
                height: 90.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 12.h),
              Text(
                "Apple Health",
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                "Connect Apple Health to KaliAi to see your weight data in Apple Health synced in KaliAi. Net out your caloric intake in KaliAi by seamlessly tracing the calories you burn throughout the day with Apple Health.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              HealthStatusCard(
                connected: _isConnected,
                lastSynced: _lastSyncTime,
                onChanged: (val) {
                  if (val) {
                    _connectToAppleHealth();
                  }
                },
              ),
              const Spacer(),
              WizardButton(
                label: 'Done',
                onPressed: () => _navigateToNotifications(context),
              ),
              SizedBox(height: 34.h),
            ],
          ),
        ),
      ),
    );
  }
}

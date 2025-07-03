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

class Wizard21 extends StatefulWidget {
  const Wizard21({super.key});

  @override
  State<Wizard21> createState() => _Wizard21State();
}

class _Wizard21State extends State<Wizard21> {
  final HealthService _healthService = HealthService();
  bool _isConnecting = false;
  bool _isConnected = false;
  String _lastSyncTime = '';
  Map<String, dynamic> _healthData = {};

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

  Future<void> _connectToGoogleFit() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Check if health data is available
      final isAvailable = await _healthService.isHealthDataAvailable();
      if (!isAvailable) {
        _showError('Google Fit is not available on this device');
        return;
      }

      // Request permissions
      final authorized = await _healthService.requestPermissions();
      if (!authorized) {
        _showError('Google Fit permissions not granted');
        return;
      }

      // Sync health data
      final result = await _healthService.syncAllHealthData();
      if (result['success']) {
        setState(() {
          _healthData = result;
        });
        _showSuccess('Successfully connected to Google Fit');
        await _checkConnectionStatus();
      } else {
        _showError('Failed to sync health data: ${result['error']}');
      }
    } catch (e) {
      _showError('Error connecting to Google Fit: $e');
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
                AppImages.googleFit,
                width: 90.w,
                height: 90.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 12.h),
              Text(
                "Google Fit",
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                "Connect Google Fit to KaliAi to see your weight data in Google Fit synced in KaliAi. Net out your caloric intake in KaliAi by seamlessly tracing the calories you burn throughout the day with Google Fit.",
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
                    _connectToGoogleFit();
                  }
                },
              ),
              if (_isConnected && _healthData.isNotEmpty) ...[
                SizedBox(height: 20.h),
                _buildHealthDataCard(),
              ],
              const Spacer(),
              WizardButton(
                label: _isConnecting ? 'Connecting...' : 'Done',
                onPressed: _isConnecting 
                  ? () {} // Provide empty function when connecting
                  : () {
                      Provider.of<WizardProvider>(context, listen: false).nextPage();
                    },
              ),
              SizedBox(height: 34.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthDataCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Synced Data',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          if (_healthData['steps'] != null)
            _buildDataRow('Steps', '${_healthData['steps']}'),
          if (_healthData['sleep'] != null)
            _buildDataRow('Sleep', '${_healthData['sleep'].toStringAsFixed(1)}h'),
          if (_healthData['calories'] != null)
            _buildDataRow('Calories Burned', '${_healthData['calories'].round()}'),
          if (_healthData['heartRate'] != null)
            _buildDataRow('Heart Rate', '${_healthData['heartRate'].round()} bpm'),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

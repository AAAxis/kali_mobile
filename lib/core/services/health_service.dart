import 'package:health/health.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Check if Health Connect is available (Android specific)
  Future<bool> isHealthConnectAvailable() async {
    try {
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        // Check if Health Connect SDK is available
        return status == HealthConnectSdkStatus.sdkAvailable;
      }
      return true; // iOS HealthKit is always available
    } catch (e) {
      print('Error checking Health Connect availability: $e');
      return false;
    }
  }

  // Request health permissions
  Future<bool> requestPermissions() async {
    try {
      // Check if Health Connect is available first (Android only)
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          print('Health Connect SDK not available on this device. Status: $status');
          return false;
        }
      }

      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEIGHT,
        HealthDataType.WEIGHT,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
      ];

      final permissions = List.generate(
        types.length,
        (index) => HealthDataAccess.READ,
      );

      final bool authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (authorized) {
        print('✅ Health permissions granted successfully');
        _isConnected = true;
        
        // Save connection status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connected', true);
        await prefs.setInt('health_last_sync', DateTime.now().millisecondsSinceEpoch);
        
        print('✅ Health Connect integration successful');
      } else {
        print('❌ Health permissions denied by user');
        print('ℹ️ Users can grant permissions later in Health Connect settings');
        _isConnected = false;
        
        // Save denied status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connected', false);
      }

      return authorized;
    } catch (e) {
      print('Error requesting health permissions: $e');
      _isConnected = false;
      return false;
    }
  }

  // Get steps data
  Future<int> getStepsData({int days = 1}) async {
    try {
      // Check if we have permissions first
      if (!_isConnected) {
        print('Health not connected, cannot get steps data');
        return 0;
      }

      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime.now().subtract(Duration(days: days)),
        endTime: DateTime.now(),
      );

      double totalSteps = 0;
      for (final entry in stepsData) {
        if (entry.value is NumericHealthValue) {
          final value = (entry.value as NumericHealthValue).numericValue;
          totalSteps += value;
        }
      }
      return totalSteps.round();
    } catch (e) {
      print('Error getting steps data: $e');
      // If permission error, mark as disconnected
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        _isConnected = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connected', false);
      }
      return 0;
    }
  }

  // Get sleep data (placeholder - returns default value since SLEEP_IN_BED is not available in Health Connect)
  Future<double> getSleepData({int days = 1}) async {
    try {
      // SLEEP_IN_BED is not available in Health Connect on Android
      // Return default sleep hours for consistency
      print('Sleep data not available in Health Connect - returning default value');
      return 8.0; // Default sleep hours
    } catch (e) {
      print('Error getting sleep data: $e');
      return 8.0; // Default sleep hours
    }
  }

  // Get height data
  Future<double?> getHeightData() async {
    try {
      final heightData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: DateTime.now().subtract(const Duration(days: 365 * 5)),
        endTime: DateTime.now(),
      );

      if (heightData.isNotEmpty) {
        final latestHeight = heightData.last.value is NumericHealthValue 
            ? (heightData.last.value as NumericHealthValue).numericValue 
            : null;
        return latestHeight?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting height data: $e');
      return null;
    }
  }

  // Get weight data
  Future<double?> getWeightData() async {
    try {
      final weightData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: DateTime.now().subtract(const Duration(days: 365 * 5)),
        endTime: DateTime.now(),
      );

      if (weightData.isNotEmpty) {
        final latestWeight = weightData.last.value is NumericHealthValue 
            ? (weightData.last.value as NumericHealthValue).numericValue 
            : null;
        return latestWeight?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting weight data: $e');
      return null;
    }
  }

  // Get calories burned
  Future<double> getCaloriesBurned({int days = 1}) async {
    try {
      final caloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: DateTime.now().subtract(Duration(days: days)),
        endTime: DateTime.now(),
      );

      double totalCalories = 0;
      for (final entry in caloriesData) {
        if (entry.value is NumericHealthValue) {
          final value = (entry.value as NumericHealthValue).numericValue;
          totalCalories += value;
        }
      }
      return totalCalories;
    } catch (e) {
      print('Error getting calories data: $e');
      return 0.0;
    }
  }

  // Get heart rate data
  Future<double?> getHeartRateData() async {
    try {
      final heartRateData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now(),
      );

      if (heartRateData.isNotEmpty) {
        final latestHeartRate = heartRateData.last.value is NumericHealthValue 
            ? (heartRateData.last.value as NumericHealthValue).numericValue 
            : null;
        return latestHeartRate?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting heart rate data: $e');
      return null;
    }
  }

  // Sync all health data
  Future<Map<String, dynamic>> syncAllHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all health data
      final steps = await getStepsData();
      final sleep = await getSleepData();
      final height = await getHeightData();
      final weight = await getWeightData();
      final calories = await getCaloriesBurned();
      final heartRate = await getHeartRateData();

      // Save to SharedPreferences
      await prefs.setInt('health_steps', steps);
      await prefs.setDouble('health_sleep', sleep);
      if (height != null) await prefs.setDouble('health_height', height);
      if (weight != null) await prefs.setDouble('health_weight', weight);
      await prefs.setDouble('health_calories', calories);
      if (heartRate != null) await prefs.setDouble('health_heart_rate', heartRate);
      await prefs.setBool('health_connected', true);
      await prefs.setInt('health_last_sync', DateTime.now().millisecondsSinceEpoch);

      return {
        'steps': steps,
        'sleep': sleep,
        'height': height,
        'weight': weight,
        'calories': calories,
        'heartRate': heartRate,
        'success': true,
      };
    } catch (e) {
      print('Error syncing health data: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Check if health data is available
  Future<bool> isHealthDataAvailable() async {
    try {
      // Try to get steps data to check if health is available
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now(),
      );
      return true; // If we can get data, health is available
    } catch (e) {
      print('Error checking health data availability: $e');
      return false;
    }
  }

  // Get platform-specific health app name
  String getHealthAppName() {
    return Platform.isIOS ? 'Apple Health' : 'Google Fit';
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('health_last_sync');
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  // Check if health is connected
  Future<bool> isHealthConnected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('health_connected') ?? false;
    } catch (e) {
      print('Error checking health connection: $e');
      return false;
    }
  }
} 
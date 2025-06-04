import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'completion_screen.dart';
import 'height_weight_screen.dart';
import 'speed_goal_screen.dart';

class HealthScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const HealthScreen({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _isHealthConnected = false;
  String? _stepsValue;
  double? _sleepHours;
  double? _heightValue;
  double? _weightValue;

  // Default values
  static const String _defaultSteps = '5000';
  static const double _defaultSleep = 8.0;
  static const double _defaultHeight = 170.0;
  static const double _defaultWeight = 70.0;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final steps = prefs.getString('steps');
      final sleepHours = prefs.getDouble('sleep_hours');
      final height = prefs.getDouble('height_health');
      final weight = prefs.getDouble('weight_health');
      setState(() {
        _stepsValue = steps ?? _defaultSteps;
        _sleepHours = sleepHours ?? _defaultSleep;
        _heightValue = height ?? _defaultHeight;
        _weightValue = weight ?? _defaultWeight;
      });
      // Save default steps if not set
      if (steps == null) {
        await prefs.setString('steps', _defaultSteps);
      }
      // Save default sleep_hours if not set
      if (sleepHours == null) {
        await prefs.setDouble('sleep_hours', _defaultSleep);
      }
    } catch (e) {
      print('Error loading health data: $e');
    }
  }

  Future<void> _saveHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('steps', _stepsValue ?? _defaultSteps);
      if (_sleepHours != null) {
        await prefs.setDouble('sleep_hours', _sleepHours!);
      }
      if (_heightValue != null) {
        await prefs.setDouble('height_health', _heightValue!);
      }
      if (_weightValue != null) {
        await prefs.setDouble('weight_health', _weightValue!);
      }
      print('Successfully saved health data');
    } catch (e) {
      print('Error saving health data: $e');
    }
  }

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  void _showEditStepsDialog() {
    double steps = double.tryParse(_stepsValue ?? _defaultSteps) ?? 7000;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('wizard.edit_health_data'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${'wizard.steps'.tr()}: ${steps.round()}'),
                  Slider(
                    value: steps,
                    min: 0,
                    max: 20000,
                    divisions: 200,
                    label: steps.round().toString(),
                    activeColor: Colors.black,
                    inactiveColor: Colors.black.withOpacity(0.3),
                    onChanged: (val) async {
                      setStateDialog(() => steps = val);
                      if (await Vibration.hasVibrator() ?? false) {
                        Vibration.vibrate(duration: 30);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: Text('wizard.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (await Vibration.hasVibrator() ?? false) {
                      Vibration.vibrate(duration: 30);
                    }
                    setState(() {
                      _stepsValue = steps.round().toString();
                    });
                    await _saveHealthData();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: Text('wizard.save'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSleepDialog() {
    double sleep = _sleepHours ?? _defaultSleep;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('wizard.edit_health_data'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${'wizard.sleep'.tr()}: ${sleep.toStringAsFixed(1)} h'),
                  Slider(
                    value: sleep,
                    min: 4,
                    max: 16,
                    divisions: 12,
                    label: '${sleep.toStringAsFixed(1)} h',
                    activeColor: Colors.black,
                    inactiveColor: Colors.black.withOpacity(0.3),
                    onChanged: (val) async {
                      setStateDialog(() => sleep = val);
                      if (await Vibration.hasVibrator() ?? false) {
                        Vibration.vibrate(duration: 30);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: Text('wizard.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (await Vibration.hasVibrator() ?? false) {
                      Vibration.vibrate(duration: 30);
                    }
                    setState(() {
                      _sleepHours = sleep;
                    });
                    await _saveHealthData();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: Text('wizard.save'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHealthRow(String label, String value, IconData icon, Color color, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.grey[600],
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onNext() async {
    await _saveHealthData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monitor_heart,
                  size: 64,
                  color: Colors.black,
                ),
                const SizedBox(height: 24),
                Text(
                  'wizard.connect_health'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHealthRow(
                          'wizard.steps'.tr(),
                          '${_stepsValue ?? _defaultSteps}',
                          Icons.directions_walk,
                          Colors.green,
                          _showEditStepsDialog,
                        ),
                        _buildHealthRow(
                          'wizard.sleep'.tr(),
                          '${_sleepHours?.toStringAsFixed(1) ?? _defaultSleep.toStringAsFixed(1)} h',
                          Icons.bedtime,
                          Colors.blue,
                          _showEditSleepDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (Platform.isIOS)
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final health = Health();
                        const types = [
                          HealthDataType.STEPS,
                          HealthDataType.SLEEP_IN_BED,
                          HealthDataType.HEIGHT,
                          HealthDataType.WEIGHT,
                        ];

                        const permissions = [
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                        ];

                        final bool authorized = await health.requestAuthorization(
                          types,
                          permissions: permissions,
                        );

                        if (authorized) {
                          // Get steps
                          final stepsData = await health.getHealthDataFromTypes(
                            types: [HealthDataType.STEPS],
                            startTime: DateTime.now().subtract(const Duration(days: 1)),
                            endTime: DateTime.now(),
                          );

                          double totalSteps = 0;
                          for (final entry in stepsData) {
                            final value = entry.value is NumericHealthValue ? (entry.value as NumericHealthValue).numericValue : 0.0;
                            totalSteps += value;
                          }
                          if (totalSteps > 0) {
                            setState(() {
                              _stepsValue = totalSteps.round().toString();
                            });
                          }

                          // Get sleep
                          final sleepData = await health.getHealthDataFromTypes(
                            types: [HealthDataType.SLEEP_IN_BED],
                            startTime: DateTime.now().subtract(const Duration(days: 1)),
                            endTime: DateTime.now(),
                          );
                          double totalSleep = 0;
                          for (final entry in sleepData) {
                            final value = entry.value is NumericHealthValue ? (entry.value as NumericHealthValue).numericValue : 0.0;
                            totalSleep += value;
                          }
                          if (totalSleep > 0) {
                            setState(() {
                              _sleepHours = (totalSleep / 3600).clamp(4.0, 16.0).toDouble(); // seconds to hours
                            });
                          }

                          // Get height
                          final heightData = await health.getHealthDataFromTypes(
                            types: [HealthDataType.HEIGHT],
                            startTime: DateTime.now().subtract(const Duration(days: 365 * 5)),
                            endTime: DateTime.now(),
                          );
                          if (heightData.isNotEmpty) {
                            final latestHeight = heightData.last.value is NumericHealthValue ? (heightData.last.value as NumericHealthValue).numericValue : null;
                            if (latestHeight != null && latestHeight > 0) {
                              setState(() {
                                _heightValue = latestHeight.toDouble();
                              });
                            }
                          }

                          // Get weight
                          final weightData = await health.getHealthDataFromTypes(
                            types: [HealthDataType.WEIGHT],
                            startTime: DateTime.now().subtract(const Duration(days: 365 * 5)),
                            endTime: DateTime.now(),
                          );
                          if (weightData.isNotEmpty) {
                            final latestWeight = weightData.last.value is NumericHealthValue ? (weightData.last.value as NumericHealthValue).numericValue : null;
                            if (latestWeight != null && latestWeight > 0) {
                              setState(() {
                                _weightValue = latestWeight.toDouble();
                              });
                            }
                          }

                          await _saveHealthData();
                          setState(() {
                            _isHealthConnected = true;
                          });
                        } else {
                          showError('Health permissions not granted');
                        }
                      } catch (e) {
                        print('Error connecting to health: $e');
                        showError('Error connecting to health data');
                      }
                    },
                    label: Text('Connect to Apple Health'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      side: BorderSide(color: Colors.black),
                      foregroundColor: Colors.black,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 
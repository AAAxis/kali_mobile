import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'height_weight_screen.dart';
import 'main_goal_screen.dart';
import 'completion_screen.dart';
import 'health_screen.dart';
import 'preparing_screen.dart';

class SpeedScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const SpeedScreen({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  State<SpeedScreen> createState() => _SpeedScreenState();
}

class _SpeedScreenState extends State<SpeedScreen> {
  bool isMetric = true;
  String? goal; // lose_weight, gain_weight, build_muscle
  double selectedValue = 0.8; // default

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final speedGoal = prefs.getString('speed_goal');
    setState(() {
      isMetric = prefs.getString('height_weight_unit') != 'imperial';
      goal = prefs.getString('goal');
      double? saved = prefs.getDouble('weekly_goal');
      if (saved != null) {
        selectedValue = isMetric ? saved : (saved * 2.20462); // convert kg to lb if needed
      }
    });
    // Save the default speed_goal if not set
    if (speedGoal == null) {
      await prefs.setString('speed_goal', 'medium');
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Always save in kg
    double valueKg = isMetric ? selectedValue : selectedValue / 2.20462;
    await prefs.setDouble('weekly_goal', valueKg);
  }

  double get min => 0.0;
  double get max => 100.0;
  double get divisions => 100; // 1 unit steps

  String get unit => isMetric ? 'kg' : 'lb';

  String get headingText {
    return 'wizard.how_fast_goal'.tr();
  }

  String get speedLabel {
    if (selectedValue <= 33) return 'wizard.speed_slow'.tr();
    if (selectedValue <= 66) return 'wizard.speed_medium'.tr();
    return 'wizard.speed_fast'.tr();
  }

  String get signedValueLabel {
    return speedLabel[0].toUpperCase() + speedLabel.substring(1);
  }

  Future<void> _saveSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('speed', speedLabel);
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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Image.asset('images/gain.png', width: 64, height: 64),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      headingText,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.black,
                              inactiveTrackColor: Colors.black.withOpacity(0.1),
                              thumbColor: Colors.black,
                              overlayColor: Colors.black.withOpacity(0.1),
                              trackHeight: 5,
                            ),
                            child: Slider(
                              value: selectedValue,
                              min: min,
                              max: max,
                              divisions: divisions.toInt(),
                              label: signedValueLabel,
                              onChanged: (val) async {
                                setState(() {
                                  selectedValue = double.parse(val.toStringAsFixed(0));
                                });
                                await _saveSpeed();
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('wizard.speed_slow'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('wizard.speed_medium'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('wizard.speed_fast'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 
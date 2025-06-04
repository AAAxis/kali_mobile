import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'completion_screen.dart';

class PreparingScreen extends StatefulWidget {
  final Map<String, dynamic> wizardData;
  final void Function(Map<String, dynamic> apiResult) onNext;
  final VoidCallback onBack;

  const PreparingScreen({
    Key? key,
    required this.wizardData,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  _PreparingScreenState createState() => _PreparingScreenState();
}

class _PreparingScreenState extends State<PreparingScreen> {
  String? error;
  double progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    progress = 0.0;
    _sendData();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendData() async {
    setState(() => error = null);
    final minDisplayDuration = Duration(seconds: 3);
    final startTime = DateTime.now();
    _progressTimer?.cancel();
    const tick = Duration(milliseconds: 50);
    int elapsedMs = 0;
    _progressTimer = Timer.periodic(tick, (timer) {
      elapsedMs += tick.inMilliseconds;
      setState(() {
        progress = (elapsedMs / minDisplayDuration.inMilliseconds).clamp(
          0.0,
          1.0,
        );
      });
      if (progress >= 1.0) {
        timer.cancel();
      }
    });
    try {
      // Local calculation
      final heightCm = widget.wizardData['height'] is int
          ? widget.wizardData['height']
          : int.tryParse(widget.wizardData['height'].toString()) ?? 170;
      final weightKg = widget.wizardData['weight'] is int
          ? widget.wizardData['weight']
          : int.tryParse(widget.wizardData['weight'].toString()) ?? 70;
      final heightM = heightCm / 100.0;
      final bmi = weightKg / (heightM * heightM);
      String category;
      if (bmi < 18.5) {
        category = 'Underweight';
      } else if (bmi < 25) {
        category = 'Normal weight';
      } else if (bmi < 30) {
        category = 'Overweight';
      } else {
        category = 'Obesity';
      }
      // Nutrition calculation
      final gender = (widget.wizardData['gender'] ?? '').toString().toLowerCase();
      int age = 25;
      if (widget.wizardData['age'] != null) {
        age = int.tryParse(widget.wizardData['age'].toString()) ?? 25;
      } else {
        // fallback: try to load from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        age = prefs.getInt('age') ?? 25;
      }
      double bmr;
      if (gender == 'male') {
        bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
      } else {
        bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
      }
      // Assume sedentary activity
      final tdee = bmr * 1.2;
      // Macro split: 30% protein, 40% carbs, 30% fat
      final protein = (tdee * 0.3 / 4).round();
      final carbs = (tdee * 0.4 / 4).round();
      final fat = (tdee * 0.3 / 9).round();
      final apiResult = {
        'bmi': bmi,
        'category': category,
        'height': heightCm,
        'weight': weightKg,
        'daily_calories': tdee.round(),
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        ...widget.wizardData,
      };
      // Save calculated values to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('daily_calories', tdee.roundToDouble());
      await prefs.setDouble('daily_protein', protein.toDouble());
      await prefs.setDouble('daily_carbs', carbs.toDouble());
      await prefs.setDouble('daily_fats', fat.toDouble());
      final elapsed = DateTime.now().difference(startTime);
      final waitTime = minDisplayDuration - elapsed;
      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
      }
      if (progress < 1.0) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          return progress < 1.0;
        });
      }
      widget.onNext(apiResult);
    } catch (e) {
      setState(
        () =>
            error = 'wizard.network_error'.tr(
              namedArgs: {'error': e.toString()},
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child:
              error == null
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Image.asset(
                        'images/food.gif',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'wizard.preparing_plan'.tr(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: Colors.black12,
                          color: Colors.black,
                          value: progress,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            'wizard.retry'.tr(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showPreparingDialog(
  BuildContext context,
  Map<String, dynamic> wizardData, {
  required void Function(Map<String, dynamic>) onNext,
  required VoidCallback onBack,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => PreparingScreen(
          wizardData: wizardData,
          onNext: onNext,
          onBack: onBack,
        ),
  );
}

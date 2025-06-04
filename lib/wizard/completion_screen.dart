import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:vibration/vibration.dart';
import '../services/paywall_service.dart';
import 'promocode.dart';

class CompletionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Map<String, dynamic>? apiResult;

  const CompletionScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
    this.apiResult,
  }) : super(key: key);

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  Map<String, int> _dailyNeeds = {
    'calories': 2000,
    'protein': 150,
    'carbs': 300,
    'fat': 65,
  };

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // Adjust based on your GIF duration
    );
    _setWizardCompleted();
    _vibrateOnComplete();
    _loadData();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setWizardCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wizard_completed', true);
  }

  Future<void> _vibrateOnComplete() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50);
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dailyNeeds = {
          'calories': prefs.getDouble('daily_calories')?.round() ?? 2000,
          'protein': prefs.getDouble('daily_protein')?.round() ?? 150,
          'carbs': prefs.getDouble('daily_carbs')?.round() ?? 300,
          'fat': prefs.getDouble('daily_fats')?.round() ?? 65,
        };
      });
      print('Local nutrition data loaded:');
      print('Daily Calories: [36m[1m${_dailyNeeds['calories']}\u001b[0m');
      print('Protein: [36m[1m${_dailyNeeds['protein']}g\u001b[0m');
      print('Carbs: [36m[1m${_dailyNeeds['carbs']}g\u001b[0m');
      print('Fat: [36m[1m${_dailyNeeds['fat']}g\u001b[0m');
    } catch (e) {
      print('Error loading nutrition data: $e');
      showError('Error loading nutrition data');
    }
  }

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    String imagePath,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(imagePath, width: 24, height: 24, color: color),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? motivationText;
    double? startWeight;
    double? goalWeight;
    String? goalType;

    // Only use local SharedPreferences for weights
    SharedPreferences.getInstance().then((prefs) {
      final startWeightStr = prefs.getString('start_weight');
      final goalWeightStr = prefs.getString('dream_weight');
      if (startWeightStr != null && goalWeightStr != null) {
        setState(() {
          startWeight = double.tryParse(startWeightStr);
          goalWeight = double.tryParse(goalWeightStr);
          if (startWeight != null && goalWeight != null) {
            final diff = (goalWeight! - startWeight!).abs();
            if (goalWeight! > startWeight!) {
              goalType = 'Gain';
            } else if (goalWeight! < startWeight!) {
              goalType = 'Lose';
            } else {
              goalType = 'Maintain';
            }
            if (goalType == 'Maintain') {
              motivationText =
                  'Your goal: Maintain your weight at [1m${goalWeight!.toStringAsFixed(1)} kg[0m';
            } else {
              motivationText =
                  'Your goal: $goalType [1m${diff.toStringAsFixed(1)} kg[0m (from [1m${startWeight!.toStringAsFixed(1)} kg[0m to [1m${goalWeight!.toStringAsFixed(1)} kg[0m)';
            }
          }
        });
      }
    });

    final nutritionCards = [
      _buildNutritionRow(
        'dashboard.calories'.tr(),
        '${_dailyNeeds['calories']} kcal',
        'images/calories.png',
        Colors.orange,
      ),
      _buildNutritionRow(
        'dashboard.protein'.tr(),
        '${_dailyNeeds['protein']}g',
        'images/protein.png',
        Colors.blue,
      ),
      _buildNutritionRow(
        'dashboard.carbs'.tr(),
        '${_dailyNeeds['carbs']}g',
        'images/carbs.png',
        Colors.green,
      ),
      _buildNutritionRow(
        'dashboard.fats'.tr(),
        '${_dailyNeeds['fat']}g',
        'images/fat.png',
        Colors.red,
      ),
    ];
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                        opacity: _controller,
                        child: Image.asset(
                          'images/confeti.gif',
                          width: 200,
                          height: 200,
                          gaplessPlayback: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'wizard.setup_complete'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  if (motivationText != null) ...[
                    Text(
                      motivationText!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                  SizedBox(
                    height: 120,
                    child: PageView.builder(
                      itemCount: nutritionCards.length,
                      controller: PageController(viewportFraction: 0.6),
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: nutritionCards[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

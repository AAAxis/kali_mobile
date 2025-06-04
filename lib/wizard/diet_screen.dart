import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'main_goal_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'completion_screen.dart';
import 'preparing_screen.dart';

class DietScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const DietScreen({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  String? selectedDietType;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDietType();
  }

  Future<void> _loadDietType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dietType = prefs.getString('dietType');
      if (dietType != null) {
        setState(() {
          selectedDietType = dietType;
        });
      } else {
        const defaultDiet = 'wizard.diet_classic';
        setState(() {
          selectedDietType = defaultDiet;
        });
        // Save the default dietType to shared preferences
        await prefs.setString('dietType', defaultDiet);
      }
    } catch (e) {
      print('Error loading diet type: $e');
    }
  }

  Future<void> _saveDietType(String dietType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving diet type: $dietType');
      await prefs.setString('dietType', dietType);
      print('Diet type saved successfully');
    } catch (e) {
      print('Error saving diet type: $e');
      showError('Error saving diet type');
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

  Widget _buildDietOption(String dietKey, List<String> assetPaths) {
    final isSelected = selectedDietType == dietKey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await _saveDietType(dietKey);
          if (mounted) {
            setState(() {
              selectedDietType = dietKey;
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7FC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFF232228) : Colors.transparent,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Text(
                dietKey.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF232228),
                ),
              ),
              const Spacer(),
              ...assetPaths.map((icon) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Image.asset(
                  icon,
                  width: 28,
                  height: 28,
                ),
              )),
            ],
          ),
        ),
      ),
    );
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
            
                  const SizedBox(height: 40),
                  Text(
                    'wizard.select_diet'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildDietOption('wizard.diet_classic', ['images/meat.png']),
                  _buildDietOption('wizard.diet_keto', ['images/keto.png']),
                  _buildDietOption('wizard.diet_vegetarian', ['images/vegan.png']),
                  _buildDietOption('wizard.diet_vegan', ['images/vegan.png']),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant DietScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _handleNext() async {
    final prefs = await SharedPreferences.getInstance();
    final wizardData = {
      'gender': prefs.getString('gender') ?? '',
      'birthDate': prefs.getString('birthDate') ?? '',
      'height': prefs.getInt('height') ?? 170,
      'weight': prefs.getInt('weight') ?? 70,
      'goal': prefs.getString('goal') ?? '',
      'dietType': prefs.getString('dietType') ?? '',
      'weight_goal': prefs.getDouble('weight_goal') ?? 0,
      'weekly_goal': prefs.getDouble('weekly_goal') ?? 0,
    };
    final apiResult = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PreparingScreen(
          wizardData: wizardData,
          onNext: (apiResult) {},
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (apiResult != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CompletionScreen(
            onNext: () {},
            onBack: () {},
            apiResult: apiResult,
          ),
        ),
      );
    }
  }
} 
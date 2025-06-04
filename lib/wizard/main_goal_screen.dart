import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'diet_screen.dart';
import 'gender_screen.dart';
import 'dream_weight_screen.dart';

class GoalScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const GoalScreen({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  String? selectedGoal;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mainGoal = prefs.getString('main_goal');
      if (mainGoal != null) {
        setState(() {
          selectedGoal = mainGoal;
        });
      } else {
        const defaultGoal = 'wizard.goal_lose_weight';
        setState(() {
          selectedGoal = defaultGoal;
        });
        // Save the default main_goal to shared preferences
        await prefs.setString('main_goal', defaultGoal);
      }
    } catch (e) {
      print('Error loading goal: $e');
    }
  }

  Future<void> _saveGoal(String mainGoal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving main_goal: $mainGoal');
      await prefs.setString('main_goal', mainGoal);
      print('Main goal saved successfully');
    } catch (e) {
      print('Error saving main goal: $e');
      showError('Error saving main goal');
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

  Widget _buildGoalOption(String goalKey, String assetPath) {
    final isSelected = selectedGoal == goalKey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await _saveGoal(goalKey);
          if (mounted) {
            setState(() {
              selectedGoal = goalKey;
            });
            widget.onNext();
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
              Image.asset(
                assetPath,
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 18),
              Text(
                goalKey.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF232228),
                ),
              ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
         
                Text(
                  'wizard.select_goal'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildGoalOption('wizard.goal_build_muscle', 'images/power.png'),
                _buildGoalOption('wizard.goal_improve_focus', 'images/focus.png'),
                _buildGoalOption('wizard.goal_gain_weight', 'images/gain.png'),
                _buildGoalOption('wizard.goal_lose_weight', 'images/scale.png'),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'welcome_screen.dart';
import 'main_goal_screen.dart';

class GenderScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const GenderScreen({Key? key, required this.onNext, required this.onBack})
    : super(key: key);

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  Future<void> _loadGender() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gender = prefs.getString('gender');
      if (gender != null) {
        setState(() {
          selectedGender = gender;
        });
      } else {
        const defaultGender = 'wizard.gender_male';
        setState(() {
          selectedGender = defaultGender;
        });
        // Save the default gender to shared preferences
        await prefs.setString('gender', defaultGender);
      }
    } catch (e) {
      print('Error loading gender: $e');
    }
  }

  Future<void> _saveGender(String gender) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving gender: $gender');
      await prefs.setString('gender', gender);
      print('Gender saved successfully');
    } catch (e) {
      print('Error saving gender: $e');
      showError('Error saving gender');
    }
  }

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildGenderOption(String genderKey, String assetPath) {
    final isSelected = selectedGender == genderKey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await _saveGender(genderKey);
          if (mounted) {
            setState(() {
              selectedGender = genderKey;
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
              Image.asset(assetPath, width: 32, height: 32),
              const SizedBox(width: 18),
              Text(
                genderKey.tr(),
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

  void _onNextPressed() {
    if (selectedGender == null || selectedGender!.isEmpty) {
      showError('Please select a gender');
      return;
    }
    widget.onNext();
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
                  'wizard.select_gender'.tr(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF232228),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildGenderOption('wizard.gender_male', 'images/male.png'),
                _buildGenderOption('wizard.gender_female', 'images/female.png'),
                _buildGenderOption('wizard.gender_other', 'images/other.png'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

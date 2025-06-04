import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'gender_screen.dart'; // Change to your next wizard screen if needed
import 'wizard_flow.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const WelcomeScreen({Key? key, required this.onNext, required this.onBack})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Set background color to white
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(),
              child: Image.asset(
                'images/main.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'wizard.better_calorie_tracking'.tr(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Set heading text color to black
                decoration: TextDecoration.none, // Remove yellow underline
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'wizard.faster_results'.tr(),
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF7B7B7B),
                decoration: TextDecoration.none, // Remove yellow underline
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              // Next button removed (handled by WizardController)
            ),
          ),
          const SizedBox(height: 16),
          // Pagination removed (handled by WizardController)
        ],
      ),
    );
  }
}

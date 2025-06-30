import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'main_goal_screen.dart';
import 'diet_screen.dart';
import 'height_weight_screen.dart';
import 'speed_goal_screen.dart';
import 'completion_screen.dart';
import 'welcome_screen.dart';
import 'gender_screen.dart';
import 'health_screen.dart';
import 'age_screen.dart';
import 'dream_weight_screen.dart';
import 'preparing_screen.dart';
import 'promocode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';

// Model for a wizard step
class WizardStep {
  final Widget Function(
    BuildContext context,
    VoidCallback onNext,
    VoidCallback onBack,
  )
  builder;
  final String? title;

  WizardStep({required this.builder, this.title});
}

// Centralized wizard flow
final List<WizardStep> wizardFlow = [
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            WelcomeScreen(onNext: onNext, onBack: onBack),
    title: 'Welcome',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            GenderScreen(onNext: onNext, onBack: onBack),
    title: 'Gender',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            AgeScreen(onNext: onNext, onBack: onBack),
    title: 'Age',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            HeightWeightScreen(onNext: onNext, onBack: onBack),
    title: 'Height',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            GoalScreen(onNext: onNext, onBack: onBack),
    title: 'Goal',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            DreamWeightScreen(onNext: onNext, onBack: onBack),
    title: 'DreamWeight',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            SpeedScreen(onNext: onNext, onBack: onBack),
    title: 'Speed',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) =>
            HealthScreen(onNext: onNext, onBack: onBack),
    title: 'Health',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) => DietScreen(onNext: onNext, onBack: onBack),
    title: 'Diet',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) => PreparingScreenLoader(
          onNext: (apiResult) {
            _sharedApiResult = apiResult;
            onNext();
          },
          onBack: onBack,
        ),
    title: 'Preparing',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) => CompletionScreenWithResult(
          onNext: onNext, // Continue to promo code screen
          onBack: onBack,
        ),
    title: 'Complete',
  ),
  WizardStep(
    builder:
        (context, onNext, onBack) => RedeemCodeScreen(),
    title: 'PromoCode',
  ),
];

// Shared API result for passing between steps
Map<String, dynamic>? _sharedApiResult;

// Pagination widget
class WizardPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const WizardPagination({
    required this.currentPage,
    required this.totalPages,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentPage ? Colors.black : Colors.grey[300],
          ),
        );
      }),
    );
  }
}

// Wizard controller widget
class WizardController extends StatefulWidget {
  const WizardController({Key? key}) : super(key: key);

  @override
  State<WizardController> createState() => _WizardControllerState();
}

class _WizardControllerState extends State<WizardController> {
  int currentStep = 0;

  Future<void> nextStep() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 30);
    }
    
    // If this is the last step (promocode screen), mark wizard as completed
    if (currentStep == wizardFlow.length - 2) { // -2 because we're about to go to the last step
      await _markWizardCompleted();
    }
    
    if (currentStep < wizardFlow.length - 1) {
      setState(() => currentStep++);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  Future<void> _markWizardCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);
      await prefs.setBool('wizard_completed', true);
      print('✅ Wizard marked as completed - has_seen_welcome set to true');
    } catch (e) {
      print('❌ Error marking wizard as completed: $e');
    }
  }

  // Method to handle wizard completion from any step
  Future<void> completeWizard() async {
    await _markWizardCompleted();
    // Navigate to main app
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainTabScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = wizardFlow[currentStep];
    final isLastStep = currentStep == wizardFlow.length - 1;
    final isPreparingStep = wizardFlow[currentStep].title == 'Preparing';
    final isDietStep = wizardFlow[currentStep].title == 'Diet';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Step content
            Expanded(child: step.builder(context, nextStep, previousStep)),
            const SizedBox(height: 16),
            // Next button (show on Diet step even if last, but not on Preparing)
            if ((!isLastStep && !isPreparingStep) || isDietStep)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF232228),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      'wizard.next'.tr(),
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            // Pagination (moved after button)
            WizardPagination(
              currentPage: currentStep,
              totalPages: wizardFlow.length,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class PreparingNextButton extends StatefulWidget {
  final VoidCallback onNext;
  const PreparingNextButton({Key? key, required this.onNext}) : super(key: key);

  @override
  State<PreparingNextButton> createState() => _PreparingNextButtonState();
}

class _PreparingNextButtonState extends State<PreparingNextButton> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _enabled = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _enabled ? widget.onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF232228),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class PreparingScreenLoader extends StatefulWidget {
  final void Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  const PreparingScreenLoader({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  State<PreparingScreenLoader> createState() => _PreparingScreenLoaderState();
}

class _PreparingScreenLoaderState extends State<PreparingScreenLoader> {
  Map<String, dynamic>? wizardData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      wizardData = {
        'gender': prefs.getString('gender') ?? '',
        'birthDate': prefs.getString('birthDate') ?? '',
        'height': prefs.getInt('height') ?? 170,
        'weight': prefs.getInt('weight') ?? 70,
        'main_goal': prefs.getString('main_goal') ?? '',
        'dietType': prefs.getString('dietType') ?? '',
        'weight_goal': prefs.getDouble('weight_goal') ?? 0,
        'speed_goal': prefs.getString('speed_goal') ?? 'medium',
        'social': prefs.getString('heard_about_us') ?? '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (wizardData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PreparingScreen(
      wizardData: wizardData!,
      onNext: (apiResult) {
        _sharedApiResult = apiResult;
        widget.onNext(apiResult);
      },
      onBack: widget.onBack,
    );
  }
}

class CompletionScreenWithResult extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const CompletionScreenWithResult({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CompletionScreen(
      onNext: onNext,
      onBack: onBack,
      apiResult: _sharedApiResult,
    );
  }
}

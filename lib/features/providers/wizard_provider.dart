import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class WizardProvider extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentIndex = 0;
  final int totalScreens;
  int _height = 175;
  bool _isMetric = true;
  int _age = 19;
  int? _selectedGoal;
  int? _selectedDiet;
  int? _selectedWorkoutIndex;
  double _goalSpeed = 0.9;
  int? _selectedGender;
  double _weight = 70.0;
  bool _isKg = true;
  int? _selectedSocialMedia;

  FixedExtentScrollController? _scrollController;

  int get height => _height;
  bool get isMetric => _isMetric;
  int get age => _age;
  int? get selectedGoal => _selectedGoal;
  int? get selectedDiet => _selectedDiet;
  int? get selectedWorkoutIndex => _selectedWorkoutIndex;
  double get goalSpeed => _goalSpeed;
  int? get selectedGender => _selectedGender;
  double get weight => _weight;
  bool get isKg => _isKg;
  int? get selectedSocialMedia => _selectedSocialMedia;

  FixedExtentScrollController get scrollController {
    _scrollController ??= FixedExtentScrollController(
      initialItem: ((_weight - (_isKg ? 40.0 : 90.0)) / 0.1).round(),
    );
    return _scrollController!;
  }

  WizardProvider({required this.totalScreens});

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void goTo(int index) {
    if (index >= 0 && index < totalScreens) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void nextPage() {
    if (currentIndex < totalScreens - 1) {
      goTo(currentIndex + 1);
    }
  }

  void prevPage() {
    if (currentIndex > 0) {
      goTo(currentIndex - 1);
    }
  }

  void setWeight(double value) {
    _weight = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  void toggleUnit(bool toKg) {
    _isKg = toKg;
    _weight = toKg ? 70.0 : 120.0;

    _scrollController?.dispose();
    _scrollController = FixedExtentScrollController(
      initialItem: ((_weight - (_isKg ? 40.0 : 90.0)) / 0.1).round(),
    );

    notifyListeners();
  }

  void selectGender(int index) {
    _selectedGender = index;
    notifyListeners();
  }

  void toggleMetric(bool toMetric) {
    _isMetric = toMetric;
    _height = toMetric ? 175 : 69;
    notifyListeners();
  }

  void setHeight(int value) {
    _height = value;
    notifyListeners();
  }

  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  void selectGoal(int index) {
    _selectedGoal = index;
    notifyListeners();
  }

  void selectDiet(int index) {
    _selectedDiet = index;
    notifyListeners();
  }

  void selectWorkoutIndex(int index) {
    _selectedWorkoutIndex = index;
    notifyListeners();
  }

  void setGoalSpeed(double value) {
    _goalSpeed = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  void selectSocialMedia(int index) {
    _selectedSocialMedia = index;
    notifyListeners();
  }

  void reset() {
    currentIndex = 0;
    _height = 175;
    _isMetric = true;
    _age = 19;
    _selectedGoal = null;
    _selectedDiet = null;
    _selectedWorkoutIndex = null;
    _goalSpeed = 0.9;
    _selectedGender = null;
    _weight = 70.0;
    _isKg = true;
    _selectedSocialMedia = null;
    
    // Reset scroll controller
    _scrollController?.dispose();
    _scrollController = null;
    
    // Reset page controller
    pageController.jumpToPage(0);
    
    notifyListeners();
  }

  // Helper methods to check if selections are valid
  bool isGenderSelected() {
    return _selectedGender != null;
  }

  bool isGoalSelected() {
    return _selectedGoal != null;
  }

  bool isDietSelected() {
    return _selectedDiet != null;
  }

  bool isWorkoutSelected() {
    return _selectedWorkoutIndex != null;
  }

  bool isSocialMediaSelected() {
    return _selectedSocialMedia != null;
  }

  // Method to check if current screen has valid selection
  bool isCurrentScreenValid(int screenIndex) {
    switch (screenIndex) {
      case 3: // Gender selection (wizard4)
        return isGenderSelected();
      case 4: // Goal selection (wizard5)
        return isGoalSelected();
      case 5: // Diet selection (wizard6)
        return isDietSelected();
      case 8: // Workout selection (wizard9)
        return isWorkoutSelected();
      case 14: // Social media selection (wizard15)
        return isSocialMediaSelected();
      default:
        return true; // Other screens don't require selection validation
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    pageController.dispose();
    super.dispose();
  }
}

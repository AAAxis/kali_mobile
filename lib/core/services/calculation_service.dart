import 'package:shared_preferences/shared_preferences.dart';

class CalculationService {
  // Calculate BMR using Mifflin-St Jeor Equation
  static double calculateBMR({
    required int age,
    required double weight,
    required double height,
    required int gender, // 0 = Male, 1 = Female, 2 = Other
    required bool isMetric,
  }) {
    // Convert to kg and cm if needed
    final weightKg = isMetric ? weight : weight * 0.453592;
    final heightCm = isMetric ? height : height * 2.54;
    
    double bmr;
    if (gender == 0) { // Male
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else { // Female or Other
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    
    return bmr;
  }

  // Calculate Total Daily Energy Expenditure (TDEE)
  static double calculateTDEE({
    required double bmr,
    required int workoutIndex, // 0-3: 0-2, 2-4, 4-6, 6-8 hours/week
  }) {
    // Activity multipliers based on workout frequency
    final activityMultipliers = [1.2, 1.375, 1.55, 1.725]; // Sedentary to Very Active
    final multiplier = activityMultipliers[workoutIndex.clamp(0, 3)];
    
    return bmr * multiplier;
  }

  // Calculate calorie target based on goal
  static double calculateCalorieTarget({
    required double tdee,
    required int goal, // 0 = Lose weight, 1 = Maintain, 2 = Gain weight
    required double goalSpeed, // 0.1 to 1.5 kg/week
  }) {
    double calorieDeficit;
    
    switch (goal) {
      case 0: // Lose weight
        // 1 kg of fat = 7700 calories
        // goalSpeed is in kg/week, so weekly deficit = goalSpeed * 7700
        final weeklyDeficit = goalSpeed * 7700;
        calorieDeficit = weeklyDeficit / 7; // Daily deficit
        return tdee - calorieDeficit;
        
      case 1: // Maintain weight
        return tdee;
        
      case 2: // Gain weight
        // For weight gain, we add calories instead of subtracting
        final weeklySurplus = goalSpeed * 7700;
        calorieDeficit = weeklySurplus / 7; // Daily surplus
        return tdee + calorieDeficit;
        
      default:
        return tdee;
    }
  }

  // Calculate macronutrient distribution
  static Map<String, double> calculateMacros({
    required double calories,
    required int diet, // 0 = Regular, 1 = Vegetarian, 2 = Vegan, 3 = Keto
  }) {
    double proteinRatio, carbRatio, fatRatio;
    
    switch (diet) {
      case 0: // Regular
        proteinRatio = 0.25; // 25% protein
        carbRatio = 0.45;    // 45% carbs
        fatRatio = 0.30;     // 30% fat
        break;
        
      case 1: // Vegetarian
        proteinRatio = 0.20; // 20% protein (lower due to plant sources)
        carbRatio = 0.55;    // 55% carbs (higher for energy)
        fatRatio = 0.25;     // 25% fat
        break;
        
      case 2: // Vegan
        proteinRatio = 0.18; // 18% protein (even lower)
        carbRatio = 0.60;    // 60% carbs (highest)
        fatRatio = 0.22;     // 22% fat
        break;
        
      case 3: // Keto
        proteinRatio = 0.25; // 25% protein
        carbRatio = 0.05;    // 5% carbs (very low)
        fatRatio = 0.70;     // 70% fat (very high)
        break;
        
      default:
        proteinRatio = 0.25;
        carbRatio = 0.45;
        fatRatio = 0.30;
    }
    
    // Calculate grams (1g protein = 4 cal, 1g carbs = 4 cal, 1g fat = 9 cal)
    final proteinGrams = (calories * proteinRatio) / 4;
    final carbGrams = (calories * carbRatio) / 4;
    final fatGrams = (calories * fatRatio) / 9;
    
    return {
      'calories': calories,
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fats': fatGrams,
    };
  }

  // Main method to calculate all nutrition goals
  static Future<Map<String, double>> calculateNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get wizard data
    final age = prefs.getInt('wizard_age') ?? 25;
    final weight = prefs.getDouble('wizard_weight') ?? 70.0;
    final height = prefs.getInt('wizard_height') ?? 175;
    final gender = prefs.getInt('wizard_gender') ?? 0;
    final isMetric = prefs.getBool('wizard_is_metric') ?? true;
    final workoutIndex = prefs.getInt('wizard_workout') ?? 1;
    final goal = prefs.getInt('wizard_goal') ?? 0;
    final goalSpeed = prefs.getDouble('wizard_goal_speed') ?? 0.8;
    final diet = prefs.getInt('wizard_diet') ?? 0;
    
    // Calculate step by step
    final bmr = calculateBMR(
      age: age,
      weight: weight,
      height: height.toDouble(),
      gender: gender,
      isMetric: isMetric,
    );
    
    final tdee = calculateTDEE(
      bmr: bmr,
      workoutIndex: workoutIndex,
    );
    
    final calorieTarget = calculateCalorieTarget(
      tdee: tdee,
      goal: goal,
      goalSpeed: goalSpeed,
    );
    
    final macros = calculateMacros(
      calories: calorieTarget,
      diet: diet,
    );
    
    // Save calculated values to SharedPreferences
    await prefs.setDouble('nutrition_goal_calories', macros['calories']!);
    await prefs.setDouble('nutrition_goal_protein', macros['protein']!);
    await prefs.setDouble('nutrition_goal_carbs', macros['carbs']!);
    await prefs.setDouble('nutrition_goal_fats', macros['fats']!);
    
    return macros;
  }

  // Get current nutrition goals from storage
  static Future<Map<String, double>> getCurrentNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'calories': prefs.getDouble('nutrition_goal_calories') ?? 2000,
      'protein': prefs.getDouble('nutrition_goal_protein') ?? 150,
      'carbs': prefs.getDouble('nutrition_goal_carbs') ?? 300,
      'fats': prefs.getDouble('nutrition_goal_fats') ?? 65,
    };
  }

  // Calculate weight loss/gain timeline
  static Map<String, dynamic> calculateTimeline({
    required double currentWeight,
    required double targetWeight,
    required double goalSpeed,
    required bool isMetric,
  }) {
    final weightDifference = (targetWeight - currentWeight).abs();
    final weeksToGoal = weightDifference / goalSpeed;
    final daysToGoal = weeksToGoal * 7;
    
    // Calculate target date
    final targetDate = DateTime.now().add(Duration(days: daysToGoal.toInt()));
    
    return {
      'weightDifference': weightDifference,
      'weeksToGoal': weeksToGoal,
      'daysToGoal': daysToGoal,
      'targetDate': targetDate,
      'goalSpeed': goalSpeed,
    };
  }
} 
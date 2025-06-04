import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../meal_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class WelcomeSection extends StatefulWidget {
  final String userName;
  final String currentMealTime;
  final List<Meal> meals;
  final double dailyCalories;
  final double caloriesGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatsGoal;
  final Map<String, double> macros;
  final Function() onTap;
  final List<DateTime> days;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onDaySelected;

  const WelcomeSection({
    Key? key,
    required this.userName,
    required this.currentMealTime,
    required this.meals,
    required this.dailyCalories,
    required this.caloriesGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatsGoal,
    required this.macros,
    required this.onTap,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<WelcomeSection> {
  int _pageIndex = 0; // For PageView
  final PageController _pageController = PageController();
  late Future<Map<String, dynamic>> _statsFuture;
  Timer? _autoScrollTimer;
  bool _isInitialized = false;

  // Default values to use when SharedPreferences fails
  final Map<String, dynamic> _defaultStats = {
    'steps': 8000,
    'sleep_hours': 7.5,
  };

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStatsFromPrefs();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _pageIndex = (_pageIndex + 1) % 3; // Cycle through 0, 1, 2
        });
        _pageController.animateToPage(
          _pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use default values if meals is empty
    final caloriesRemaining = widget.caloriesGoal - widget.dailyCalories;
    const double macroCardWidth = 110;
    const double macroCardMargin = 12; // 6 left + 6 right per card
    const double macrosRowWidth = macroCardWidth * 3 + macroCardMargin * 2;
    const double macrosBlockMargin = 10;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final progressBgColor = isDark ? Colors.grey[700] : Colors.grey[200];

    // Always show DayPicker regardless of FutureBuilder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DayPicker at the top
        Center(
          child: SizedBox(
            width: 354,
            height: 52,
            child: DayPicker(
              days: widget.days,
              selectedDay: widget.selectedDay,
              onDaySelected: widget.onDaySelected,
            ),
          ),
        ),
        // Use FutureBuilder just for the stats cards
        Center(
          child: SizedBox(
            width: macrosRowWidth,
            height: 131,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                // Use default values if error or still loading
                Map<String, dynamic> stats = _defaultStats;
                
                if (snapshot.hasData) {
                  stats = snapshot.data!;
                  _isInitialized = true;
                } else if (snapshot.hasError) {
                  print('Error loading stats: ${snapshot.error}');
                  // Continue with default values
                }
                
                // Always show the PageView with our stats (either from prefs or defaults)
                return PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _pageIndex = index);
                  },
                  children: [
                    _buildCaloriesCard(
                      caloriesRemaining,
                      widget.caloriesGoal,
                      cardColor,
                      textColor,
                      subTextColor,
                      borderColor,
                    ),
                    _buildStepsCard(
                      stats['steps'] as int,
                      cardColor,
                      textColor,
                      subTextColor,
                      borderColor,
                    ),
                    _buildSleepCard(
                      stats['sleep_hours'] as double,
                      cardColor,
                      textColor,
                      subTextColor,
                      borderColor,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Macro cards
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: macrosBlockMargin),
            width: macrosRowWidth,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildMacroCard(
                  context,
                  'protein',
                  widget.macros['proteins'] ?? 0,
                  widget.proteinGoal,
                  Colors.red[400]!,
                  'images/protein.png',
                  cardColor,
                  textColor,
                  subTextColor,
                  borderColor,
                  progressBgColor,
                ),
                _buildMacroCard(
                  context,
                  'carbs',
                  widget.macros['carbs'] ?? 0,
                  widget.carbsGoal,
                  Colors.orange[400]!,
                  'images/carbs.png',
                  cardColor,
                  textColor,
                  subTextColor,
                  borderColor,
                  progressBgColor,
                ),
                _buildMacroCard(
                  context,
                  'fats',
                  widget.macros['fats'] ?? 0,
                  widget.fatsGoal,
                  Colors.green[400]!,
                  'images/fat.png',
                  cardColor,
                  textColor,
                  subTextColor,
                  borderColor,
                  progressBgColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchStatsFromPrefs() async {
    try {
      print('Fetching stats from prefs...');
      final prefs = await SharedPreferences.getInstance();
      print('Prefs loaded');
      
      // Safe parsing with fallbacks
      int steps = _defaultStats['steps'] as int;
      double sleepHours = _defaultStats['sleep_hours'] as double;
      
      try {
        dynamic stepsValue = prefs.get('steps');
        if (stepsValue is int) {
          steps = stepsValue;
        } else if (stepsValue is String) {
          steps = int.tryParse(stepsValue) ?? _defaultStats['steps'] as int;
        }
      } catch (e) {
        print('Error parsing steps: $e');
      }
      
      try {
        final sleepValue = prefs.getDouble('sleep_hours');
        if (sleepValue != null) {
          sleepHours = sleepValue;
        }
      } catch (e) {
        print('Error parsing sleep_hours: $e');
      }
      
      return {
        'steps': steps,
        'sleep_hours': sleepHours,
      };
    } catch (e) {
      print('Error in _fetchStatsFromPrefs: $e');
      // Return default values on any error
      return _defaultStats;
    }
  }

  Widget _buildCaloriesCard(
    double caloriesRemaining, 
    double caloriesGoal,
    Color cardColor,
    Color textColor,
    Color? subTextColor,
    Color? borderColor,
  ) {
    // Calculate progress as percent of calories consumed
    final caloriesConsumed = caloriesGoal - caloriesRemaining;
    final percent = (caloriesGoal > 0)
        ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: _welcomeBoxDecoration(cardColor, borderColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Calories number and label (left)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  caloriesRemaining.abs().toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  caloriesRemaining >= 0
                      ? 'dashboard.calories_left'.tr()
                      : 'dashboard.calories_over'.tr(),
                  style: TextStyle(fontSize: 16, color: subTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Arc with icon inside (right)
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(70, 70),
                  painter: ArcPainter(
                    percent: percent,
                    color: textColor, // use text color
                    strokeWidth: 5.0,
                  ),
                ),
                Icon(Icons.local_fire_department, size: 32, color: textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(
    int steps,
    Color cardColor,
    Color textColor,
    Color? subTextColor,
    Color? borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: _welcomeBoxDecoration(cardColor, borderColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  steps.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'dashboard.steps_today'.tr(),
                  style: TextStyle(fontSize: 16, color: subTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.directions_walk, size: 40, color: textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard(
    double hours,
    Color cardColor,
    Color textColor,
    Color? subTextColor,
    Color? borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: _welcomeBoxDecoration(cardColor, borderColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hours.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'dashboard.sleep_hours'.tr(),
                  style: TextStyle(fontSize: 16, color: subTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [Icon(Icons.bedtime, size: 40, color: textColor)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context,
    String label,
    double value,
    double goal,
    Color color,
    String assetPath,
    Color cardColor,
    Color textColor,
    Color? subTextColor,
    Color? borderColor,
    Color? progressBgColor,
  ) {
    final remaining = goal - value;
    final percent = (goal > 0)
        ? (remaining >= 0 ? (value / goal).clamp(0.0, 1.0) : 1.0)
        : 0.0;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: _welcomeBoxDecoration(cardColor, borderColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    backgroundColor: progressBgColor,
                    color: color,
                    strokeWidth: 4,
                  ),
                  Image.asset(
                    assetPath, 
                    width: 17, 
                    height: 17,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading asset $assetPath: $error');
                      // Fallback to icon if image fails to load
                      return Icon(
                        label == 'protein' ? Icons.fitness_center : 
                        label == 'carbs' ? Icons.rice_bowl : 
                        Icons.opacity,
                        size: 17,
                        color: color,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${remaining.abs().toStringAsFixed(0)}g',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              '${("common.$label").toLowerCase().tr()} ${remaining >= 0 ? "common.left".tr() : "common.over".tr()}',
              style: TextStyle(fontSize: 12, color: subTextColor),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _welcomeBoxDecoration(Color cardColor, Color? borderColor) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? Colors.transparent, width: 1.0),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double percent;
  final Color color;
  final double strokeWidth;
  ArcPainter({
    required this.percent,
    required this.color,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startAngle = -3.14159 / 2; // Start at top
    final fullSweep = 2 * 3.14159; // 360 degrees
    final sweepAngle = fullSweep * percent;
    final bgColor = color.withOpacity(0.2);
    final backgroundPaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final foregroundPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Draw background arc (full 360 deg)
    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      startAngle,
      fullSweep,
      false,
      backgroundPaint,
    );
    // Draw foreground arc (percent)
    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DayPicker extends StatelessWidget {
  final List<DateTime> days;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onDaySelected;

  const DayPicker({
    Key? key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBgColor = isDark ? Colors.grey[700] : Colors.grey[400];
    final unselectedBgColor = isDark ? Colors.grey[900] : Colors.grey[200];
    final selectedTextColor = Colors.white;
    final unselectedTextColor = isDark ? Colors.white70 : Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((date) {
        final dayIndex = (date.weekday - 1) % 7; // Safety check
        final dayName = dayNames[dayIndex];
        final isSelected = selectedDay != null &&
            date.year == selectedDay!.year &&
            date.month == selectedDay!.month &&
            date.day == selectedDay!.day;
        final firstLetter = dayName.isNotEmpty ? dayName[0] : '';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add space between boxes
            child: InkWell(
              onTap: () {
                onDaySelected(isSelected ? null : date);
              },
              borderRadius: BorderRadius.circular(18), // More pill-like
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? (isSelected ? Colors.grey[800] : Colors.grey[900])
                      : (isSelected ? Colors.green[300] : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey[700]!
                        : (isSelected ? Colors.green[300]! : Colors.grey[300]!),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  DateFormat('d').format(date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? (isSelected ? Colors.white : Colors.grey[300])
                        : (isSelected ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
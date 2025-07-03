import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import 'package:provider/provider.dart';
import '../../providers/wizard_provider.dart';
import 'dart:io';
import 'apple_health.dart';
import 'google_fit.dart';

class Wizard12 extends StatefulWidget {
  const Wizard12({super.key});

  @override
  Wizard12State createState() => Wizard12State();
}

class Wizard12State extends State<Wizard12>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineAnimation;

  bool isGain = true; // Set to true for weight gain, false for weight loss

  void _navigateToHealthScreen(BuildContext context) {
    if (Platform.isIOS) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wizard20()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wizard21()),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Line animation goes from 0 to 1 (representing the graph growth)
    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRecommendationItem(String text, Color iconColor, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: Constants.beforeIcon),
              Image.asset(
                AppIcons.kali,
                color: colorScheme.primary,
              ),
              SizedBox(height: Constants.afterIcon),
              Text(
                "You have great potential\nto crush your goal",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),

              Text(
                "How to reach your goals:",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),

              // Recommendations
              _buildRecommendationItem(
                "Use health scores to improve your routine",
                Colors.green,
                Icons.favorite,
              ),
              _buildRecommendationItem(
                "Follow your daily calorie recommendations",
                Colors.blue,
                Icons.local_fire_department,
              ),
              _buildRecommendationItem(
                "Track your food",
                Colors.red,
                Icons.restaurant,
              ),
              _buildRecommendationItem(
                "Balance your carbs, proteins and fats.",
                Colors.teal,
                Icons.balance,
              ),

              const Spacer(),

              // Continue button
              WizardButton(
                label: 'Continue',
                onPressed: () => _navigateToHealthScreen(context),
                padding: EdgeInsets.symmetric(vertical: 18.h),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the weight transition graph
class _WeightGraphPainter extends CustomPainter {
  final double progress;
  final bool isGain;

  _WeightGraphPainter({
    required this.progress,
    required this.isGain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.05, size.height * 0.68),
      Offset(size.width * 0.30, size.height * 0.66),
      Offset(size.width * 0.60, size.height * 0.45),
      Offset(size.width * 0.90, size.height * 0.20),
    ];

    final theme =
        ThemeData.light(); // Replace with actual context ThemeData if needed

    // 1. Horizontal grid lines (dotted)
    final dottedPaint = Paint()
      ..color = theme.colorScheme.outlineVariant.withAlpha(60)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final dy = size.height * i / 4;
      _drawDottedLine(
          canvas, Offset(0, dy), Offset(size.width, dy), dottedPaint);
    }

    // 2. Vertical lines at data points (dotted)
    for (var point in points) {
      _drawDottedLine(
        canvas,
        Offset(point.dx, 0),
        Offset(point.dx, size.height),
        dottedPaint,
      );
    }

    // 3. Draw x-axis (solid)
    final xAxisPaint = Paint()
      ..color = theme.colorScheme.outline
      ..strokeWidth = 1.4;

    final xAxisY = size.height; // x-axis at bottom
    canvas.drawLine(Offset(0, xAxisY), Offset(size.width, xAxisY), xAxisPaint);

    // 4. Gradient area under curve
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.orange.withAlpha(60),
          Colors.orange.withAlpha(20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gradientPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final animatedX = point.dx * progress;
      final animatedY = point.dy;
      gradientPath.lineTo(animatedX, animatedY);
    }
    gradientPath.lineTo(size.width * progress, size.height);
    gradientPath.close();
    canvas.drawPath(gradientPath, gradientPaint);

    // 5. Line curve
    final linePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(points[0].dx * progress, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      final point = points[i];
      final animatedX = point.dx * progress;
      final animatedY = point.dy;
      linePath.lineTo(animatedX, animatedY);
    }
    canvas.drawPath(linePath, linePaint);

    // 6. Data points & trophy
    final fillPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final animatedX = point.dx * progress;
      final animatedY = point.dy;

      canvas.drawCircle(Offset(animatedX, animatedY), 6, fillPaint);
      canvas.drawCircle(Offset(animatedX, animatedY), 6, borderPaint);

      if (i == points.length - 1 && progress > 0.8) {
        final trophyPaint = Paint()..color = Colors.orange;
        canvas.drawCircle(Offset(animatedX, animatedY - 20), 12, trophyPaint);

        final tp = TextPainter(
          text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 16)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(animatedX - 8, animatedY - 28));
      }
    }
  }

  // Helper to draw dotted lines
  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final total = (end - start).distance;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    var distance = 0.0;

    while (distance < total) {
      final x1 = start.dx + (dx * distance / total);
      final y1 = start.dy + (dy * distance / total);
      distance += dashWidth;
      final x2 = start.dx + (dx * distance / total);
      final y2 = start.dy + (dy * distance / total);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      distance += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

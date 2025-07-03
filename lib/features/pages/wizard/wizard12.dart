import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import 'package:provider/provider.dart';
import '../../providers/wizard_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Set the message for weight gain or loss
    String message = isGain
        ? "Weight gain often takes a few days to kick in, but after the first week, you'll start seeing real progress!!"
        : "Weight loss often takes a few days to kick in, but after the first week, you'll start seeing real progress!!";

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

              // Graph container
              Container(
                width: double.infinity,
                height: 280.h,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Goal transition",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Expanded(
                      child: Stack(
                        children: [
                          // Animated graph
                          AnimatedBuilder(
                            animation: _lineAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(double.infinity, double.infinity),
                                painter: _WeightGraphPainter(
                                  progress: _lineAnimation.value,
                                  isGain: isGain,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Time labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "3 Days",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "7 Days",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "30 Days",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Continue button
              WizardButton(
                label: 'Continue',
                onPressed: () {
                  // Your action here
                  Provider.of<WizardProvider>(context, listen: false)
                      .nextPage();
                },
                padding: EdgeInsets.symmetric(
                    vertical: 18.h), // Adjust padding if necessary
              ),
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

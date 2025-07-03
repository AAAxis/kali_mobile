import 'package:flutter/material.dart';
import 'dart:math';

class CalorieGauge extends StatelessWidget {
  final double currentValue;
  final double maxValue;
  final int segments;
  final Color filledColor;
  final Color unfilledColor;
  final double segmentHeight;
  final double topWidth;
  final double bottomWidth;
  final double cornerRadius;

  const CalorieGauge({
    super.key,
    required this.currentValue,
    required this.maxValue,
    this.segments = 24,
    this.filledColor = Colors.deepOrange,
    this.unfilledColor = Colors.grey,
    this.segmentHeight = 15.0,
    this.topWidth = 7.0,
    this.bottomWidth = 3.0,
    this.cornerRadius = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final fillPercent = (currentValue / maxValue).clamp(0.0, 1.0);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.local_fire_department_rounded,
                    color: Colors.redAccent),
                SizedBox(width: 4),
                Text("Calories",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87)),
                SizedBox(width: 4),
                Icon(Icons.edit, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            // Gauge
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(175, 87),
                  painter: GaugePainter(
                    fillPercent: fillPercent,
                    segments: segments,
                    filledColor: filledColor,
                    unfilledColor: unfilledColor,
                    segmentHeight: segmentHeight,
                    topWidth: topWidth,
                    bottomWidth: bottomWidth,
                    cornerRadius: cornerRadius,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Text(
                    "${currentValue.toInt()}g",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double fillPercent;
  final int segments;
  final Color filledColor;
  final Color unfilledColor;
  final double segmentHeight;
  final double topWidth;
  final double bottomWidth;
  final double cornerRadius;

  final double startAngle = pi;
  final double sweepAngle = pi;

  GaugePainter({
    required this.fillPercent,
    required this.segments,
    required this.filledColor,
    required this.unfilledColor,
    required this.segmentHeight,
    required this.topWidth,
    required this.bottomWidth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final segmentAngle = sweepAngle / segments;
    final radius = size.width / 2 - segmentHeight / 2;
    final center = Offset(size.width / 2, size.height);

    final totalFillSeg = fillPercent * segments;
    final fullSegments = totalFillSeg.floor();
    final partialFrac = totalFillSeg - fullSegments;

    for (int i = 0; i < segments; i++) {
      final angle = startAngle + (i + 0.5) * segmentAngle;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      // Calculate color
      Color color;
      if (i < fullSegments) {
        color = filledColor;
      } else if (i == fullSegments && partialFrac > 0) {
        color = Color.lerp(filledColor, unfilledColor, 1 - partialFrac)!;
      } else {
        color = unfilledColor;
      }

      final path = Path();

      // Start from bottom-left
      path.moveTo(-bottomWidth / 2 + cornerRadius, segmentHeight / 2);

      // Bottom-left curve
      path.quadraticBezierTo(
        -bottomWidth / 2,
        segmentHeight / 2,
        -bottomWidth / 2,
        segmentHeight / 2 - cornerRadius,
      );

      // Left side
      path.lineTo(-topWidth / 2, -segmentHeight / 2 + cornerRadius);

      // Top-left curve
      path.quadraticBezierTo(
        -topWidth / 2,
        -segmentHeight / 2,
        -topWidth / 2 + cornerRadius,
        -segmentHeight / 2,
      );

      // Top edge
      path.lineTo(topWidth / 2 - cornerRadius, -segmentHeight / 2);

      // Top-right curve
      path.quadraticBezierTo(
        topWidth / 2,
        -segmentHeight / 2,
        topWidth / 2,
        -segmentHeight / 2 + cornerRadius,
      );

      // Right side
      path.lineTo(bottomWidth / 2, segmentHeight / 2 - cornerRadius);

      // Bottom-right curve
      path.quadraticBezierTo(
        bottomWidth / 2,
        segmentHeight / 2,
        bottomWidth / 2 - cornerRadius,
        segmentHeight / 2,
      );

      path.close();

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // // Uncomment the following lines to add a blur effect to the filled segments
      // final paint = Paint()
      //   ..color = color
      //   ..style = PaintingStyle.fill
      //   ..maskFilter = i < fullSegments
      //       ? const MaskFilter.blur(BlurStyle.normal, 0.5)
      //       : null;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + pi / 2);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.fillPercent != fillPercent ||
      oldDelegate.segments != segments ||
      oldDelegate.segmentHeight != segmentHeight ||
      oldDelegate.topWidth != topWidth ||
      oldDelegate.bottomWidth != bottomWidth ||
      oldDelegate.cornerRadius != cornerRadius;
}

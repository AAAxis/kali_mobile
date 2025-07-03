import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScannerFrame extends StatelessWidget {
  final double size;
  final double cornerRadius;
  final double cornerLength;
  final double thickness;
  final Color color;

  const ScannerFrame({
    super.key,
    required this.size,
    this.cornerRadius = 18,
    this.cornerLength = 32,
    this.thickness = 4,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.w,
      height: size.w,
      child: Stack(
        children: [
          // Left curved side
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: CustomPaint(
                size: Size(cornerLength.w, size.w),
                painter: _SideFramePainter(
                  isLeft: true,
                  color: color,
                  radius: cornerRadius.r,
                  thickness: thickness.w,
                ),
              ),
            ),
          ),

          // Right curved side
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: CustomPaint(
                size: Size(cornerLength.w, size.w),
                painter: _SideFramePainter(
                  isLeft: false,
                  color: color,
                  radius: cornerRadius.r,
                  thickness: thickness.w,
                ),
              ),
            ),
          ),

          // Middle horizontal gradient covering full width of scanner
          Positioned(
            top: 100.h,
            left: 0,
            right: 0,
            height: 100.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.onPrimary.withAlpha(240),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideFramePainter extends CustomPainter {
  final bool isLeft;
  final Color color;
  final double radius;
  final double thickness;

  _SideFramePainter({
    required this.isLeft,
    required this.color,
    required this.radius,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final arcRadius = radius;

    if (isLeft) {
      final startX = 0.0;
      final curveX = -arcRadius;

      path.moveTo(startX, 0);
      path.arcToPoint(
        Offset(curveX, arcRadius),
        radius: Radius.circular(arcRadius),
        clockwise: false,
      );
      path.lineTo(curveX, size.height - arcRadius);
      path.arcToPoint(
        Offset(startX, size.height),
        radius: Radius.circular(arcRadius),
        clockwise: false,
      );
    } else {
      final startX = size.width;
      final curveX = size.width + arcRadius;

      path.moveTo(startX, 0);
      path.arcToPoint(
        Offset(curveX, arcRadius),
        radius: Radius.circular(arcRadius),
        clockwise: true,
      );
      path.lineTo(curveX, size.height - arcRadius);
      path.arcToPoint(
        Offset(startX, size.height),
        radius: Radius.circular(arcRadius),
        clockwise: true,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

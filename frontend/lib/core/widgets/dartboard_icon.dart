import 'dart:math' as math;
import 'package:flutter/material.dart';

class DartboardIcon extends StatelessWidget {
  final double size;
  final Color color;

  const DartboardIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DartboardPainter(color: color),
    );
  }
}

class _DartboardPainter extends CustomPainter {
  final Color color;

  _DartboardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle (dartboard edge)
    canvas.drawCircle(center, radius * 0.95, paint);

    // Middle circle
    canvas.drawCircle(center, radius * 0.7, paint);

    // Inner circle
    canvas.drawCircle(center, radius * 0.45, paint);

    // Bullseye
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.15, paint);

    // Dart board segments (8 lines from center)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.03;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180);
      final startX = center.dx + (radius * 0.15) * math.cos(angle);
      final startY = center.dy + (radius * 0.15) * math.sin(angle);
      final endX = center.dx + (radius * 0.95) * math.cos(angle);
      final endY = center.dy + (radius * 0.95) * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DartIcon extends StatelessWidget {
  final double size;
  final Color color;

  const DartIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DartPainter(color: color),
    );
  }
}

class _DartPainter extends CustomPainter {
  final Color color;

  _DartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // Dart tip (triangle)
    final tipPath = Path();
    tipPath.moveTo(width * 0.5, 0);
    tipPath.lineTo(width * 0.3, height * 0.3);
    tipPath.lineTo(width * 0.7, height * 0.3);
    tipPath.close();
    canvas.drawPath(tipPath, paint);

    // Dart shaft (rectangle)
    final shaftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.45, height * 0.25, width * 0.1, height * 0.5),
      Radius.circular(width * 0.02),
    );
    canvas.drawRRect(shaftRect, paint);

    // Dart flights (back fins)
    final flightPath = Path();
    // Left flight
    flightPath.moveTo(width * 0.5, height * 0.7);
    flightPath.lineTo(width * 0.2, height * 0.6);
    flightPath.lineTo(width * 0.35, height * 0.85);
    flightPath.close();
    
    // Right flight
    flightPath.moveTo(width * 0.5, height * 0.7);
    flightPath.lineTo(width * 0.8, height * 0.6);
    flightPath.lineTo(width * 0.65, height * 0.85);
    flightPath.close();

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = width * 0.02;
    canvas.drawPath(flightPath, paint);

    paint.style = PaintingStyle.fill;
    paint.color = color.withOpacity(0.3);
    canvas.drawPath(flightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

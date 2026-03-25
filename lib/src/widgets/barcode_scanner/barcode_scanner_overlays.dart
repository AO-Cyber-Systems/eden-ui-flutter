import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';

class ViewfinderPainter extends CustomPainter {
  ViewfinderPainter({
    required this.viewfinderSize,
    required this.overlayColor,
    required this.borderColor,
    required this.cornerLength,
    required this.cornerWidth,
  });

  final double viewfinderSize;
  final Color overlayColor;
  final Color borderColor;
  final double cornerLength;
  final double cornerWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: viewfinderSize,
      height: viewfinderSize,
    );

    // Dark overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = overlayColor,
    );

    // Corner brackets
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final cl = cornerLength;

    // Top-left
    canvas.drawLine(Offset(l, t + cl), Offset(l, t + 8), paint);
    canvas.drawArc(
      Rect.fromLTWH(l, t, 16, 16),
      3.14159, // pi
      1.5708, // pi/2
      false,
      paint,
    );
    canvas.drawLine(Offset(l + 8, t), Offset(l + cl, t), paint);

    // Top-right
    canvas.drawLine(Offset(r - cl, t), Offset(r - 8, t), paint);
    canvas.drawArc(
      Rect.fromLTWH(r - 16, t, 16, 16),
      -1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(r, t + 8), Offset(r, t + cl), paint);

    // Bottom-left
    canvas.drawLine(Offset(l, b - cl), Offset(l, b - 8), paint);
    canvas.drawArc(
      Rect.fromLTWH(l, b - 16, 16, 16),
      3.14159,
      -1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(l + 8, b), Offset(l + cl, b), paint);

    // Bottom-right
    canvas.drawLine(Offset(r - cl, b), Offset(r - 8, b), paint);
    canvas.drawArc(
      Rect.fromLTWH(r - 16, b - 16, 16, 16),
      0,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(r, b - 8), Offset(r, b - cl), paint);
  }

  @override
  bool shouldRepaint(covariant ViewfinderPainter oldDelegate) {
    return viewfinderSize != oldDelegate.viewfinderSize ||
        overlayColor != oldDelegate.overlayColor ||
        borderColor != oldDelegate.borderColor;
  }
}


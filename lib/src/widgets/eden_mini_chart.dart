import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Inline sparkline/mini chart for embedding in stat cards.
///
/// Renders a small line chart without labels, axes, or interactivity.
/// Designed for trend visualization at a glance.
///
/// ```dart
/// EdenMiniChart(
///   values: [12, 18, 15, 22, 19, 25],
///   width: 80,
///   height: 32,
///   color: Colors.green,
/// )
/// ```
class EdenMiniChart extends StatelessWidget {
  const EdenMiniChart({
    super.key,
    required this.values,
    this.width = 80,
    this.height = 32,
    this.color,
    this.strokeWidth = 1.5,
    this.showFill = true,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color? color;
  final double strokeWidth;
  final bool showFill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MiniChartPainter(
          values: values,
          lineColor: effectiveColor,
          fillColor: showFill
              ? effectiveColor.withValues(alpha: 0.15)
              : Colors.transparent,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  _MiniChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = maxVal - minVal;
    final effectiveRange = range > 0 ? range : 1.0;
    final stepX = size.width / (values.length - 1);
    final padding = 2.0;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = padding +
          (size.height - padding * 2) *
              (1 - (values[i] - minVal) / effectiveRange);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter old) =>
      old.values != values || old.lineColor != lineColor;
}

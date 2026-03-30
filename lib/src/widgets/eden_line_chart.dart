import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A data point for [EdenLineChart].
class EdenLineChartPoint {
  const EdenLineChartPoint({required this.label, required this.value});
  final String label;
  final double value;
}

/// Simple line chart using CustomPaint (no external dependencies).
///
/// ```dart
/// EdenLineChart(
///   points: [
///     EdenLineChartPoint(label: 'Jan', value: 100),
///     EdenLineChartPoint(label: 'Feb', value: 150),
///     EdenLineChartPoint(label: 'Mar', value: 120),
///   ],
///   height: 200,
/// )
/// ```
class EdenLineChart extends StatelessWidget {
  const EdenLineChart({
    super.key,
    required this.points,
    this.height = 200,
    this.lineColor,
    this.fillColor,
    this.showDots = true,
    this.showLabels = true,
    this.title,
    this.strokeWidth = 2.5,
  });

  final List<EdenLineChartPoint> points;
  final double height;
  final Color? lineColor;
  final Color? fillColor;
  final bool showDots;
  final bool showLabels;
  final String? title;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size(double.infinity, height),
            painter: _LineChartPainter(
              points: points,
              lineColor: lineColor ?? theme.colorScheme.primary,
              fillColor: fillColor ??
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              dotColor: lineColor ?? theme.colorScheme.primary,
              labelColor: theme.colorScheme.onSurfaceVariant,
              showDots: showDots,
              showLabels: showLabels,
              strokeWidth: strokeWidth,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
    required this.labelColor,
    required this.showDots,
    required this.showLabels,
    required this.strokeWidth,
  });

  final List<EdenLineChartPoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;
  final Color labelColor;
  final bool showDots;
  final bool showLabels;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final labelHeight = showLabels ? 20.0 : 0.0;
    final chartHeight = size.height - labelHeight - 8;
    final maxValue = points.map((p) => p.value).reduce(math.max);
    final minValue = points.map((p) => p.value).reduce(math.min);
    final range = maxValue - minValue;
    final effectiveRange = range > 0 ? range : 1.0;

    final stepX = size.width / (points.length - 1);

    // Build path
    final path = Path();
    final fillPath = Path();
    final offsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = chartHeight -
          ((points[i].value - minValue) / effectiveRange) * chartHeight;
      offsets.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill
    fillPath.lineTo(offsets.last.dx, chartHeight);
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

    // Dots
    if (showDots) {
      for (final offset in offsets) {
        canvas.drawCircle(
            offset, 4, Paint()..color = dotColor);
        canvas.drawCircle(
            offset,
            2.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill);
      }
    }

    // Labels
    if (showLabels) {
      for (int i = 0; i < points.length; i++) {
        final tp = TextPainter(
          text: TextSpan(
            text: points[i].label,
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            offsets[i].dx - tp.width / 2,
            size.height - labelHeight + 4,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points || old.lineColor != lineColor;
}

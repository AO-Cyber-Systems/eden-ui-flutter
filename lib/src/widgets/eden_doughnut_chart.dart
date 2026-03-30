import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A segment in [EdenDoughnutChart].
class EdenDoughnutSegment {
  const EdenDoughnutSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Doughnut/pie chart using CustomPaint (no external dependencies).
///
/// ```dart
/// EdenDoughnutChart(
///   segments: [
///     EdenDoughnutSegment(label: 'Active', value: 45, color: Colors.green),
///     EdenDoughnutSegment(label: 'Pending', value: 20, color: Colors.orange),
///     EdenDoughnutSegment(label: 'Closed', value: 35, color: Colors.blue),
///   ],
///   size: 180,
///   centerLabel: '100',
///   centerSubLabel: 'Total',
/// )
/// ```
class EdenDoughnutChart extends StatelessWidget {
  const EdenDoughnutChart({
    super.key,
    required this.segments,
    this.size = 180,
    this.strokeWidth = 24,
    this.centerLabel,
    this.centerSubLabel,
    this.showLegend = true,
    this.title,
  });

  final List<EdenDoughnutSegment> segments;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final String? centerSubLabel;
  final bool showLegend;
  final String? title;

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
        Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _DoughnutPainter(
                    segments: segments,
                    strokeWidth: strokeWidth,
                  ),
                ),
                if (centerLabel != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLabel!,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (centerSubLabel != null)
                        Text(
                          centerSubLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (showLegend && segments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final segment in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: segment.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${segment.label} (${segment.value.toStringAsFixed(0)})',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  _DoughnutPainter({required this.segments, required this.strokeWidth});

  final List<EdenDoughnutSegment> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle - 0.02, // Small gap between segments
        false,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter old) =>
      old.segments != segments;
}

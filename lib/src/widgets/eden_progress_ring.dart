import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Size presets for [EdenProgressRing].
enum EdenProgressRingSize { sm, md, lg, xl }

/// A circular progress ring with optional center content.
///
/// Non-punitive: uses the same color even when value exceeds 1.0.
/// Supports center label (e.g., calorie count), custom colors, and
/// animated progress changes.
class EdenProgressRing extends StatelessWidget {
  const EdenProgressRing({
    super.key,
    required this.value,
    this.size = EdenProgressRingSize.md,
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    this.centerChild,
    this.label,
    this.sublabel,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Progress value from 0.0 to 1.0+. Values above 1.0 render as full ring
  /// in the same color (non-punitive, no red/warning).
  final double value;

  /// Ring size preset.
  final EdenProgressRingSize size;

  /// Ring fill color. Defaults to theme primary.
  final Color? color;

  /// Ring background color. Defaults to 10% opacity of fill color.
  final Color? backgroundColor;

  /// Custom stroke width. Defaults based on size preset.
  final double? strokeWidth;

  /// Widget displayed in the center of the ring (e.g., calorie count).
  final Widget? centerChild;

  /// Primary label shown in center (ignored if centerChild is provided).
  final String? label;

  /// Secondary label below primary (ignored if centerChild is provided).
  final String? sublabel;

  /// Duration for animated value changes.
  final Duration animationDuration;

  double get _diameter => switch (size) {
        EdenProgressRingSize.sm => 48,
        EdenProgressRingSize.md => 80,
        EdenProgressRingSize.lg => 120,
        EdenProgressRingSize.xl => 160,
      };

  double get _strokeWidth => strokeWidth ?? switch (size) {
        EdenProgressRingSize.sm => 4,
        EdenProgressRingSize.md => 6,
        EdenProgressRingSize.lg => 8,
        EdenProgressRingSize.xl => 10,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? fillColor.withValues(alpha: 0.1);

    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1)),
            duration: animationDuration,
            curve: Curves.easeInOut,
            builder: (context, animValue, _) => CustomPaint(
              size: Size(_diameter, _diameter),
              painter: _RingPainter(
                progress: animValue,
                color: fillColor,
                backgroundColor: bgColor,
                strokeWidth: _strokeWidth,
              ),
            ),
          ),
          if (centerChild != null)
            centerChild!
          else if (label != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label!,
                  style: _labelStyle(theme),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  TextStyle? _labelStyle(ThemeData theme) => switch (size) {
        EdenProgressRingSize.sm =>
          theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        EdenProgressRingSize.md =>
          theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        EdenProgressRingSize.lg =>
          theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        EdenProgressRingSize.xl =>
          theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      };
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = backgroundColor
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      backgroundColor != oldDelegate.backgroundColor;
}

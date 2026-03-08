import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Progress bar size presets.
enum EdenProgressSize { sm, md, lg }

/// Mirrors the eden_progress Rails component.
class EdenProgress extends StatelessWidget {
  const EdenProgress({
    super.key,
    required this.value,
    this.size = EdenProgressSize.md,
    this.color,
    this.label,
    this.showPercentage = false,
  });

  /// Progress value from 0.0 to 1.0.
  final double value;
  final EdenProgressSize size;
  final Color? color;
  final String? label;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = color ?? theme.colorScheme.primary;
    final height = _resolveHeight();
    final trackColor = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(label!, style: theme.textTheme.labelSmall),
                if (showPercentage)
                  Text(
                    '${(value * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: EdenRadii.borderRadiusFull,
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: trackColor,
              color: barColor,
              minHeight: height,
            ),
          ),
        ),
      ],
    );
  }

  double _resolveHeight() {
    switch (size) {
      case EdenProgressSize.sm:
        return 4;
      case EdenProgressSize.md:
        return 8;
      case EdenProgressSize.lg:
        return 12;
    }
  }
}

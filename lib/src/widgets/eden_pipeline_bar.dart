import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single segment in an [EdenPipelineBar].
class EdenPipelineSegment {
  const EdenPipelineSegment({
    required this.label,
    required this.value,
    required this.color,
    this.count,
    this.formattedValue,
    this.onTap,
  });

  /// Display label for the legend (e.g., "Draft", "Won").
  final String label;

  /// Numeric value determining the segment's proportional width.
  final int value;

  /// Color for the bar segment and legend dot.
  final Color color;

  /// Optional count shown in the legend (e.g., number of items).
  final int? count;

  /// Optional formatted string for the value (e.g., "\$4,500").
  final String? formattedValue;

  /// Called when the segment or legend item is tapped.
  final VoidCallback? onTap;
}

/// Horizontal proportional bar chart with colored segments and a legend.
///
/// Each segment width is proportional to its [EdenPipelineSegment.value].
/// A legend row beneath shows label, count, and formatted value per segment.
/// Useful for pipelines, funnels, stage distributions, and budget breakdowns.
///
/// ```dart
/// EdenPipelineBar(
///   title: 'Bid Pipeline',
///   totalLabel: '\$24,500 total value',
///   segments: [
///     EdenPipelineSegment(label: 'Draft', value: 5000, color: Colors.grey, count: 3, formattedValue: '\$5,000'),
///     EdenPipelineSegment(label: 'Sent', value: 8000, color: Colors.amber, count: 5, formattedValue: '\$8,000'),
///     EdenPipelineSegment(label: 'Won', value: 9000, color: Colors.green, count: 4, formattedValue: '\$9,000'),
///     EdenPipelineSegment(label: 'Lost', value: 2500, color: Colors.red, count: 2, formattedValue: '\$2,500'),
///   ],
/// )
/// ```
class EdenPipelineBar extends StatelessWidget {
  const EdenPipelineBar({
    super.key,
    required this.segments,
    this.title,
    this.totalLabel,
    this.barHeight = 24,
    this.barRadius = 6,
    this.showLegend = true,
  });

  /// The pipeline segments to display.
  final List<EdenPipelineSegment> segments;

  /// Optional title shown above the bar.
  final String? title;

  /// Optional summary label shown to the right of the title.
  final String? totalLabel;

  /// Height of the horizontal bar.
  final double barHeight;

  /// Border radius of the bar ends.
  final double barRadius;

  /// Whether to display the legend row below the bar.
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalValue =
        segments.fold<int>(0, (sum, segment) => sum + segment.value);

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || totalLabel != null) ...[
            Row(
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                const Spacer(),
                if (totalLabel != null)
                  Text(
                    totalLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: EdenSpacing.space3),
          ],
          if (totalValue > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(barRadius),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  children: segments
                      .where((s) => s.value > 0)
                      .map((s) => Expanded(
                            flex: s.value,
                            child: GestureDetector(
                              onTap: s.onTap,
                              child: Container(color: s.color),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          if (showLegend) ...[
            SizedBox(height: totalValue > 0 ? 14 : 0),
            Row(
              children: segments
                  .map((s) => Expanded(
                        child: _LegendItem(segment: s),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.segment});

  final EdenPipelineSegment segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: segment.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  segment.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (segment.count != null || segment.formattedValue != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (segment.count != null)
                      Text(
                        '${segment.count}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    if (segment.formattedValue != null)
                      Text(
                        segment.formattedValue!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

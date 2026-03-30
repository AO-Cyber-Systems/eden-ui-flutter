import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A data point for [EdenBarChart].
class EdenBarChartItem {
  const EdenBarChartItem({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}

/// Simple bar chart using CustomPaint (no external dependencies).
///
/// For advanced charting, use fl_chart directly. This widget covers
/// the common case of a labeled bar chart with value display.
///
/// ```dart
/// EdenBarChart(
///   items: [
///     EdenBarChartItem(label: 'Mon', value: 12),
///     EdenBarChartItem(label: 'Tue', value: 18),
///     EdenBarChartItem(label: 'Wed', value: 8),
///   ],
///   height: 200,
/// )
/// ```
class EdenBarChart extends StatelessWidget {
  const EdenBarChart({
    super.key,
    required this.items,
    this.height = 200,
    this.barWidth = 28,
    this.barColor,
    this.showValues = true,
    this.title,
  });

  final List<EdenBarChartItem> items;
  final double height;
  final double barWidth;
  final Color? barColor;
  final bool showValues;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = barColor ?? theme.colorScheme.primary;
    final maxValue =
        items.isEmpty ? 1.0 : items.map((e) => e.value).reduce(math.max);
    final chartHeight = height - 40; // Reserve space for labels

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const Spacer(),
                _buildBar(context, items[i], maxValue, chartHeight,
                    items[i].color ?? defaultColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(BuildContext context, EdenBarChartItem item, double maxValue,
      double chartHeight, Color color) {
    final theme = Theme.of(context);
    final barHeight = maxValue > 0 ? (item.value / maxValue) * chartHeight : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showValues)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item.value.toStringAsFixed(
                  item.value == item.value.roundToDouble() ? 0 : 1),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

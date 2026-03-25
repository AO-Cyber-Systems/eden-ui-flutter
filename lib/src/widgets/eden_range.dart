import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Range slider input with label and value display.
///
/// Wraps Flutter's Slider with consistent Eden styling, optional label,
/// min/max labels, and value formatting.
///
/// ```dart
/// EdenRange(
///   label: 'Budget',
///   value: budget,
///   min: 0,
///   max: 100000,
///   divisions: 100,
///   valueLabel: '\$${budget.toStringAsFixed(0)}',
///   onChanged: (v) => setState(() => budget = v),
/// )
/// ```
class EdenRange extends StatelessWidget {
  const EdenRange({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.valueLabel,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String? label;
  final double min;
  final double max;
  final int? divisions;
  final String? valueLabel;
  final String? minLabel;
  final String? maxLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || valueLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(label!, style: theme.textTheme.labelMedium),
                if (valueLabel != null)
                  Text(
                    valueLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: enabled ? onChanged : null,
        ),
        if (minLabel != null || maxLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (minLabel != null)
                  Text(minLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                if (maxLabel != null)
                  Text(maxLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
              ],
            ),
          ),
      ],
    );
  }
}

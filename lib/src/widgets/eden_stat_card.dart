import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Trend direction for stat cards.
enum EdenStatTrend { up, down, neutral }

/// Mirrors the eden_stat_card Rails component.
///
/// Displays a metric with label, value, optional icon, and trend indicator.
class EdenStatCard extends StatelessWidget {
  const EdenStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.trendValue,
    this.trendLabel,
    this.variant,
  });

  final String label;
  final String value;
  final IconData? icon;
  final EdenStatTrend? trend;
  final String? trendValue;
  final String? trendLabel;
  final Color? variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (variant ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                    borderRadius: EdenRadii.borderRadiusLg,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: variant ?? theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space2),
          Text(value, style: theme.textTheme.headlineLarge),
          if (trend != null || trendValue != null) ...[
            const SizedBox(height: EdenSpacing.space2),
            Row(
              children: [
                if (trend != null)
                  Icon(
                    trend == EdenStatTrend.up
                        ? Icons.trending_up
                        : trend == EdenStatTrend.down
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    size: 16,
                    color: trend == EdenStatTrend.up
                        ? EdenColors.success
                        : trend == EdenStatTrend.down
                            ? EdenColors.error
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                if (trendValue != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    trendValue!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trend == EdenStatTrend.up
                          ? EdenColors.success
                          : trend == EdenStatTrend.down
                              ? EdenColors.error
                              : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (trendLabel != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    trendLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

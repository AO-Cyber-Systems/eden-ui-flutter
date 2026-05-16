import 'package:flutter/material.dart';

/// Cross-vertical stock-level / capacity gauge.
///
/// Renders a `LinearProgressIndicator` (clipped to a rounded rect) showing
/// `currentStock` as a fraction of `maxCapacity`, with optional labels.
///
/// `maxCapacity` formula: `reorderPoint > 0 ? reorderPoint * 2 : 100`. When
/// the consumer passes `reorderPoint: 0` the gauge defaults to a capacity of
/// 100 so the bar isn't divide-by-zero.
///
/// Color thresholds (priority order):
/// - **RED** (`theme.colorScheme.error`) when `isBelowReorder` is true (i.e.
///   `reorderPoint > 0 && currentStock <= reorderPoint`) OR `percent < 0.25`.
///   `isBelowReorder` takes priority — a stock of 50 with reorderPoint 100
///   (percent=0.25) is RED even though by percent it sits at the amber edge.
/// - **AMBER** (`Colors.amber.shade700`) when `percent ∈ [0.25, 0.5)` and
///   `isBelowReorder` is false. Geometrically this region is only reachable
///   when `reorderPoint == 0` (so the isBelowReorder short-circuit is
///   suppressed and capacity is 100).
/// - **GREEN** (`Colors.green.shade600`) otherwise (`percent >= 0.5`).
///
/// `percent` is clamped to `[0.0, 1.0]` so consumers may safely pass values
/// over `maxCapacity` (the bar shows full).
///
/// Cross-vertical examples:
/// - Trades parts inventory (bolts, oxygen tanks remaining).
/// - Salon retail product stock vs reorder point.
/// - Medical pharmacy pill count vs dispense threshold.
/// - Retail SKU stock vs reorder.
/// - Fuel tank fill % vs refill threshold.
///
/// Donor: `trades-flutter/lib/shared/widgets/stock_level_indicator.dart`.
class EdenStockLevelIndicator extends StatelessWidget {
  const EdenStockLevelIndicator({
    super.key,
    required this.currentStock,
    required this.reorderPoint,
    this.showLabel = true,
    this.height = 8,
  });

  /// Current count / level. Values above `maxCapacity` clamp the bar to full.
  final int currentStock;

  /// Reorder threshold. When `> 0` it drives `maxCapacity = reorderPoint * 2`
  /// and forces RED when `currentStock <= reorderPoint`. When `0` the gauge
  /// falls back to `maxCapacity = 100` and the AMBER region becomes reachable.
  final int reorderPoint;

  /// When `true` shows two labels above the bar: `'$currentStock in stock'`
  /// and (when `reorderPoint > 0`) `'Reorder at $reorderPoint'`.
  final bool showLabel;

  /// Bar height in logical pixels. The clipping radius matches `height / 2`
  /// for a pill silhouette.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCapacity = reorderPoint > 0 ? reorderPoint * 2 : 100;
    final percent = (currentStock / maxCapacity).clamp(0.0, 1.0);

    final color = _getColor(percent, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '$currentStock in stock',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (reorderPoint > 0)
                  Flexible(
                    child: Text(
                      'Reorder at $reorderPoint',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColor(double percent, ThemeData theme) {
    final isBelowReorder = reorderPoint > 0 && currentStock <= reorderPoint;

    if (isBelowReorder || percent < 0.25) {
      return theme.colorScheme.error;
    } else if (percent < 0.5) {
      return Colors.amber.shade700;
    } else {
      return Colors.green.shade600;
    }
  }
}

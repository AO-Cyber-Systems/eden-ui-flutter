import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';

/// Trend-color polarity for a [EdenKpiTile]. Default `positiveIsGood`
/// colors `trend > 0` in success-green. For cost / churn / refund-rate
/// metrics where lower is better, pass `negativeIsGood` to flip the
/// arrow + color mapping.
enum EdenKpiTrendPolarity { positiveIsGood, negativeIsGood }

/// Aggregation type for the optional sticky footer card on
/// [EdenAggregateKpiStrip]. Renders as a Semantics prefix
/// ("Aggregate total: $1,245").
enum EdenKpiAggregateMode { sum, avg, max, min, custom }

/// Single KPI tile value class used by [EdenAggregateKpiStrip].
///
/// `displayValue` is rendered verbatim — the consumer pre-formats
/// (currency, percentage, duration, count). This is intentional — KPI
/// semantics are domain-specific and the widget shouldn't fork into N
/// format modes.
class EdenKpiTile {
  const EdenKpiTile({
    required this.label,
    required this.displayValue,
    this.secondaryLabel,
    this.trend,
    this.polarity = EdenKpiTrendPolarity.positiveIsGood,
    this.onTap,
    this.leadingIcon,
    this.trailingSlot,
  });

  final String label;
  final String displayValue;
  final String? secondaryLabel;

  /// Raw delta — only the sign matters; the widget renders an
  /// up/down/flat arrow. `null` suppresses the arrow entirely.
  final double? trend;

  final EdenKpiTrendPolarity polarity;
  final VoidCallback? onTap;
  final Widget? leadingIcon;

  /// Consumer-supplied widget slot (typically [EdenSparkline]) rendered
  /// at the right side of the tile.
  final Widget? trailingSlot;
}

/// Aggregate footer card content (when [EdenAggregateKpiStrip.aggregate]
/// is non-null). Renders with larger typography than the per-tile values
/// to communicate "this is the rollup".
class EdenKpiAggregate {
  const EdenKpiAggregate({
    required this.label,
    required this.displayValue,
    this.mode = EdenKpiAggregateMode.custom,
    this.overrideColor,
  });

  final String label;
  final String displayValue;
  final EdenKpiAggregateMode mode;
  final Color? overrideColor;
}

/// Horizontal strip of N KPI tiles with an optional sticky aggregate
/// footer (obj 012-02).
///
/// Replaces the ad-hoc 4-7-KPI-grid pattern used across 8 vertical
/// screens (M5, F4/F5, R2-R5, T3). Composes [EdenCard.interactive] per
/// tile (when `onTap` is provided) or plain [EdenCard] otherwise. Tiles
/// fixed-width via `tileWidth` (default 180); strip scrolls horizontally
/// when overflow.
///
/// **Aggregate footer** (when `aggregate` is non-null):
/// * `stickyAggregate: true` (default) — aggregate card pinned to the
///   right edge (LTR) outside the scrolling area; does NOT scroll out.
/// * `stickyAggregate: false` — aggregate scrolls with the tiles as the
///   last child of the strip.
class EdenAggregateKpiStrip extends StatelessWidget {
  const EdenAggregateKpiStrip({
    super.key,
    required this.tiles,
    this.aggregate,
    this.tileWidth = 180,
    this.height = 140,
    this.stickyAggregate = true,
    this.emptyState,
  });

  final List<EdenKpiTile> tiles;
  final EdenKpiAggregate? aggregate;
  final double tileWidth;
  final double height;
  final bool stickyAggregate;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: emptyState ??
              const Padding(
                padding: EdgeInsets.all(EdenSpacing.space4),
                child: Text('No KPIs configured'),
              ),
        ),
      );
    }

    final hasAggregate = aggregate != null;

    // Tiles row (may also include the aggregate at the tail when
    // stickyAggregate is false).
    final tileRowChildren = <Widget>[
      for (final tile in tiles) _buildTile(context, tile),
      if (hasAggregate && !stickyAggregate) _buildAggregate(context, aggregate!),
    ];

    final scroll = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tileRowChildren,
      ),
    );

    final body = (hasAggregate && stickyAggregate)
        ? Row(
            children: [
              Expanded(child: scroll),
              _buildAggregate(context, aggregate!),
            ],
          )
        : scroll;

    return SizedBox(height: height, child: body);
  }

  // ───────────────────────────── Tile ─────────────────────────────────

  Widget _buildTile(BuildContext context, EdenKpiTile tile) {
    final theme = Theme.of(context);
    final hasTap = tile.onTap != null;

    final cardChild = SizedBox(
      width: tileWidth,
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tile.leadingIcon != null) ...[
                  tile.leadingIcon!,
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    tile.label,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tile.displayValue,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (tile.trend != null) _trendIcon(context, tile),
                if (tile.secondaryLabel != null) ...[
                  if (tile.trend != null) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tile.secondaryLabel!,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox.shrink()),
                if (tile.trailingSlot != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96, maxHeight: 32),
                    child: tile.trailingSlot!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    final semanticsLabel =
        '${tile.label}: ${tile.displayValue}${_trendSuffix(tile)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        label: semanticsLabel,
        button: hasTap,
        container: true,
        excludeSemantics: true,
        child: hasTap
            ? EdenCard.interactive(onTap: tile.onTap!, child: cardChild)
            : EdenCard(child: cardChild),
      ),
    );
  }

  Widget _trendIcon(BuildContext context, EdenKpiTile tile) {
    final t = tile.trend!;
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    final goodColor = palette?.successFg ?? EdenColors.success;
    final badColor = palette?.dangerFg ?? EdenColors.error;
    final neutralColor =
        Theme.of(context).colorScheme.outline;

    IconData icon;
    Color color;
    if (t == 0) {
      icon = Icons.remove;
      color = neutralColor;
    } else if (t > 0) {
      icon = Icons.arrow_upward;
      color = tile.polarity == EdenKpiTrendPolarity.positiveIsGood
          ? goodColor
          : badColor;
    } else {
      icon = Icons.arrow_downward;
      color = tile.polarity == EdenKpiTrendPolarity.positiveIsGood
          ? badColor
          : goodColor;
    }
    return Icon(icon, size: 14, color: color);
  }

  String _trendSuffix(EdenKpiTile tile) {
    final t = tile.trend;
    if (t == null) return '';
    if (t > 0) return ' trending up';
    if (t < 0) return ' trending down';
    return ' unchanged';
  }

  // ────────────────────────── Aggregate card ───────────────────────────

  Widget _buildAggregate(BuildContext context, EdenKpiAggregate agg) {
    final theme = Theme.of(context);
    final modePrefix = switch (agg.mode) {
      EdenKpiAggregateMode.sum => 'total',
      EdenKpiAggregateMode.avg => 'average',
      EdenKpiAggregateMode.max => 'max',
      EdenKpiAggregateMode.min => 'min',
      EdenKpiAggregateMode.custom => agg.label.toLowerCase(),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: tileWidth,
        child: Semantics(
          label: 'Aggregate $modePrefix: ${agg.displayValue}',
          container: true,
          excludeSemantics: true,
          child: EdenCard(
            child: Padding(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agg.label,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agg.displayValue,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: agg.overrideColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_stat_card.dart';

/// Data model for a single item in an [EdenStatGrid].
class EdenStatGridItem {
  const EdenStatGridItem({
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.trendValue,
    this.trendLabel,
    this.variant,
    this.onTap,
    this.actionLabel,
  });

  /// Short label shown below the value (e.g., "Open Bids").
  final String label;

  /// Primary display value (e.g., "12", "\$4,500").
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Trend direction indicator.
  final EdenStatTrend? trend;

  /// Trend percentage or delta string (e.g., "+12%").
  final String? trendValue;

  /// Trend context label (e.g., "vs last month").
  final String? trendLabel;

  /// Accent color override for the card icon background.
  final Color? variant;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Optional action link text below the card (e.g., "View all ->").
  final String? actionLabel;
}

/// A responsive grid of [EdenStatCard] widgets with consistent sizing.
///
/// Renders items in a single row on wide screens (>= [breakpoint]) and wraps
/// to a 2-column grid on narrow screens. Each card gets equal flex.
///
/// ```dart
/// EdenStatGrid(
///   items: [
///     EdenStatGridItem(label: 'Open', value: '12', icon: Icons.folder_open),
///     EdenStatGridItem(label: 'Won', value: '8', variant: Colors.green),
///     EdenStatGridItem(label: 'Lost', value: '3', variant: Colors.red),
///   ],
/// )
/// ```
class EdenStatGrid extends StatelessWidget {
  const EdenStatGrid({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: EdenSpacing.space6),
    this.spacing = EdenSpacing.space3,
    this.breakpoint = 600,
  });

  /// The stat card items to display.
  final List<EdenStatGridItem> items;

  /// Outer padding around the grid.
  final EdgeInsets padding;

  /// Space between cards.
  final double spacing;

  /// Width below which the grid collapses to 2 columns.
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < breakpoint) {
            return _buildWrapLayout(context);
          }
          return _buildRowLayout(context);
        },
      ),
    );
  }

  Widget _buildRowLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: _buildCard(context, items[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildWrapLayout(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final first = Expanded(child: _buildCard(context, items[i]));
      final second = i + 1 < items.length
          ? Expanded(child: _buildCard(context, items[i + 1]))
          : const Expanded(child: SizedBox.shrink());
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [first, SizedBox(width: spacing), second],
      ));
    }
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, EdenStatGridItem item) {
    final card = GestureDetector(
      onTap: item.onTap,
      child: EdenStatCard(
        label: item.label,
        value: item.value,
        icon: item.icon,
        trend: item.trend,
        trendValue: item.trendValue,
        trendLabel: item.trendLabel,
        variant: item.variant,
      ),
    );

    if (item.actionLabel == null) return card;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: GestureDetector(
            onTap: item.onTap,
            child: Text(
              item.actionLabel!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

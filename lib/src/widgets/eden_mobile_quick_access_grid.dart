// EdenMobileQuickAccessGrid — companion-mode launcher grid.
//
// A 3-column (default) icon-tile launcher pattern for mobile-home screens
// in companion-mode dashboards (trades field-tech, medical home-visit nurse,
// fuel-truck driver, gov caseworker). Tile labels + icons + optional
// accent colors are caller-supplied; tap fires an `onTap(id)` callback so
// routing stays a consumer concern.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/mobile_home/presentation/
// widgets/quick_access_grid.dart — port strips:
//   - hardcoded 6-item trades list (consumer-supplied)
//   - hardcoded gold/red palette (per-item `accent`)
//   - go_router `context.push` (callback `onTap(id)`)
//   - hardcoded "Quick Access" title (optional `title?`)
//
// Library does NOT import go_router and knows nothing about routes.

import 'package:flutter/material.dart';

/// A single launcher tile in [EdenMobileQuickAccessGrid].
///
/// [accent] is optional. When set, it cascades to BOTH the tile border
/// (width 1.5) AND the label text color AND the icon color, producing the
/// donor's "gold" / "red" affordance pattern in a cross-vertical way
/// (medical might prefer amber/teal; consumer chooses).
///
/// When [accent] is null:
/// - Border = `Theme.of(context).dividerColor` (width 1.0)
/// - Label color = `Theme.of(context).colorScheme.onSurface`
/// - Icon color = `Theme.of(context).colorScheme.onSurfaceVariant`
class EdenMobileQuickAccessItem {
  const EdenMobileQuickAccessItem({
    required this.id,
    required this.icon,
    required this.label,
    this.accent,
  });

  /// Stable identifier emitted via `onTap(id)`. Consumer maps to routes.
  final String id;

  /// Material icon displayed in the tile centre.
  final IconData icon;

  /// Short label rendered below the icon.
  final String label;

  /// Optional accent color (border + label + icon). Caller-supplied for
  /// cross-vertical theming. Null = neutral.
  final Color? accent;
}

/// Icon-tile launcher grid for companion-mode mobile-home screens.
///
/// Composition position: this widget is designed to render INSIDE an
/// `EdenCompanionShell` content slot (Objective 002), typically under the
/// dashboard greeting strip — as a "quick actions" panel. It may also
/// stand alone full-screen on phone widths (≥390pt).
///
/// **Material ancestor requirement:** the widget uses `InkWell` ripples
/// which require a `Material` ancestor (provided by `Scaffold`, `Card`,
/// etc.). Direct mount without `Material` is not supported.
///
/// **Reorder v1 (swap-only) semantics:** when [reorderable] is true,
/// each tile is wrapped in `LongPressDraggable<int>` + `DragTarget<int>`
/// so a long-press-drag from tile A to tile B fires
/// `onReorder(indexA, indexB)`. This is "swap two tiles", NOT "drag to
/// arbitrary position". A future TRD may upgrade to full insert
/// semantics; consumers should persist the resulting order themselves.
///
/// Donor: `AOCyber-Trades/trades-flutter/lib/features/mobile_home/
/// presentation/widgets/quick_access_grid.dart`.
class EdenMobileQuickAccessGrid extends StatelessWidget {
  const EdenMobileQuickAccessGrid({
    super.key,
    required this.items,
    this.title,
    this.crossAxisCount = 3,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 1.1,
    this.physics = const NeverScrollableScrollPhysics(),
    this.onTap,
    this.reorderable = false,
    this.onReorder,
  });

  /// Launcher tiles to render in row-major order.
  final List<EdenMobileQuickAccessItem> items;

  /// Optional header label rendered above the grid. When null, no header.
  final String? title;

  /// Number of columns. Default 3 (donor parity).
  final int crossAxisCount;

  /// Vertical spacing between rows.
  final double mainAxisSpacing;

  /// Horizontal spacing between columns.
  final double crossAxisSpacing;

  /// Tile width / height ratio. Default 1.1 (donor parity).
  final double childAspectRatio;

  /// Scroll physics for the inner `GridView`. Default
  /// `NeverScrollableScrollPhysics` because this widget composes inside
  /// `ListView` dashboard sections — it must not compete for scroll.
  final ScrollPhysics physics;

  /// Tap callback. Receives the tapped item's [EdenMobileQuickAccessItem.id].
  /// When null, taps do nothing (and do not throw).
  final ValueChanged<String>? onTap;

  /// When true, enables long-press-drag-to-swap reorder semantics
  /// (see class doc). Default false.
  final bool reorderable;

  /// Reorder callback (oldIndex, newIndex). Only invoked when
  /// [reorderable] is true.
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: physics,
          children: [
            for (var i = 0; i < items.length; i++)
              _buildTile(context, items[i], i),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(
      BuildContext context, EdenMobileQuickAccessItem item, int index) {
    final tile = _Tile(
      item: item,
      onTap: onTap == null ? null : () => onTap!.call(item.id),
    );

    if (!reorderable) return tile;

    // v1 swap semantics: drag tile A onto tile B → onReorder(A, B).
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        onReorder?.call(details.data, index);
      },
      builder: (ctx, candidate, rejected) {
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Opacity(opacity: 0.85, child: tile),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile),
          child: tile,
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});

  final EdenMobileQuickAccessItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAccent = item.accent != null;
    final borderColor = hasAccent ? item.accent! : theme.dividerColor;
    final borderWidth = hasAccent ? 1.5 : 1.0;
    final labelColor =
        hasAccent ? item.accent! : theme.colorScheme.onSurface;
    final iconColor =
        hasAccent ? item.accent! : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

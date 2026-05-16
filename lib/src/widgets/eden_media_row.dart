import 'package:flutter/material.dart';

/// Data model for a single cell inside [EdenMediaRow].
///
/// Each cell renders an icon, an optional `$count $label` composite (or just
/// the label when `count` is null), and exactly ONE trailing affordance — a
/// '+ Add' button when [onAddPressed] is non-null, otherwise the [trailingText]
/// string when non-null, otherwise nothing.
///
/// Library-owned (no trades dependency).
class EdenMediaRowItem {
  const EdenMediaRowItem({
    required this.icon,
    required this.label,
    this.count,
    this.onAddPressed,
    this.trailingText,
  });

  /// Icon displayed at the start of the cell (size 14, muted).
  final IconData icon;

  /// Cell label (e.g. "photos", "documents", "budget").
  final String label;

  /// Numeric or string count rendered BEFORE the label.
  /// Null hides the count prefix; non-null produces `'$count $label'`.
  final String? count;

  /// When non-null renders a '+ Add' [InkWell] at the end of the cell.
  /// Takes priority over [trailingText] when both are provided.
  final VoidCallback? onAddPressed;

  /// When non-null AND [onAddPressed] is null, renders muted trailing text
  /// (e.g. '1 CO' for a change-order count).
  final String? trailingText;
}

/// Cross-vertical horizontal media-row of compact outlined cells.
///
/// Each cell is sized via [Expanded] with a 10pt gutter between cells. The
/// row renders nothing ([SizedBox.shrink]) for an empty `items` list.
///
/// Cross-vertical examples:
/// - Trades: photo count / document count / budget summary on a work-order.
/// - Salon: services count / products count / loyalty points.
/// - Medical: labs count / referrals count / next appointment.
/// - Retail: SKUs count / images count / discount badge.
///
/// Donor: `trades-flutter/lib/shared/widgets/media_row.dart`.
class EdenMediaRow extends StatelessWidget {
  const EdenMediaRow({
    super.key,
    required this.items,
  });

  /// Cells to render. Empty list → [SizedBox.shrink].
  final List<EdenMediaRowItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _MediaCell(item: items[i])),
        ],
      ],
    );
  }
}

class _MediaCell extends StatelessWidget {
  const _MediaCell({required this.item});

  final EdenMediaRowItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 14, color: mutedColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.count != null
                  ? '${item.count} ${item.label}'
                  : item.label,
              style: TextStyle(fontSize: 12, color: mutedColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.onAddPressed != null)
            _AddButton(onPressed: item.onAddPressed!)
          else if (item.trailingText != null)
            Text(
              item.trailingText!,
              style: TextStyle(fontSize: 11, color: mutedColor),
            ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          '+ Add',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

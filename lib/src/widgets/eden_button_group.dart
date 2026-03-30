import 'package:flutter/material.dart';
import '../tokens/radii.dart';

/// A single item in an [EdenButtonGroup].
class EdenButtonGroupItem {
  const EdenButtonGroupItem({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;
}

/// A grouped/segmented button row with toggle-style selection.
///
/// Similar to a segmented control but styled as connected buttons.
class EdenButtonGroup extends StatelessWidget {
  const EdenButtonGroup({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.allowMultiple = false,
    this.selectedIndices,
    this.onMultiChanged,
  });

  /// List of button items.
  final List<EdenButtonGroupItem> items;

  /// Currently selected index (single selection mode).
  final int selectedIndex;

  /// Called when selection changes (single selection mode).
  final ValueChanged<int> onChanged;

  /// Whether multiple selection is allowed.
  final bool allowMultiple;

  /// Currently selected indices (multi selection mode).
  final Set<int>? selectedIndices;

  /// Called when selection changes (multi selection mode).
  final ValueChanged<Set<int>>? onMultiChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                color: theme.colorScheme.outlineVariant,
              ),
            _ButtonGroupEntry(
              item: items[i],
              isSelected: allowMultiple
                  ? (selectedIndices?.contains(i) ?? false)
                  : selectedIndex == i,
              onTap: () {
                if (allowMultiple && onMultiChanged != null) {
                  final newSet = Set<int>.from(selectedIndices ?? <int>{});
                  if (newSet.contains(i)) {
                    newSet.remove(i);
                  } else {
                    newSet.add(i);
                  }
                  onMultiChanged!(newSet);
                } else {
                  onChanged(i);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ButtonGroupEntry extends StatelessWidget {
  const _ButtonGroupEntry({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final EdenButtonGroupItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              item.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

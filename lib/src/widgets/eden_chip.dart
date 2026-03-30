import 'package:flutter/material.dart';

/// Variant styles for [EdenChip].
enum EdenChipVariant { filled, outlined, tonal }

/// A standardized chip widget for labels, tags, and selections.
///
/// Three usage patterns:
/// - **EdenChip**: Display-only label/tag
/// - **EdenChoiceChip**: Radio-like single selection from a group
/// - **EdenFilterChip**: Multi-select toggleable chips
class EdenChip extends StatelessWidget {
  const EdenChip({
    super.key,
    required this.label,
    this.variant = EdenChipVariant.outlined,
    this.icon,
    this.onDeleted,
    this.color,
  });

  final String label;
  final EdenChipVariant variant;
  final IconData? icon;
  final VoidCallback? onDeleted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Chip(
      label: Text(label, style: TextStyle(
        color: variant == EdenChipVariant.filled
            ? theme.colorScheme.onPrimary
            : chipColor,
        fontSize: 12,
      )),
      avatar: icon != null ? Icon(icon, size: 16, color: chipColor) : null,
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 14, color: chipColor)
          : null,
      onDeleted: onDeleted,
      backgroundColor: switch (variant) {
        EdenChipVariant.filled => chipColor,
        EdenChipVariant.tonal => chipColor.withValues(alpha: 0.12),
        EdenChipVariant.outlined => Colors.transparent,
      },
      side: variant == EdenChipVariant.outlined
          ? BorderSide(color: chipColor.withValues(alpha: 0.3))
          : BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Single-select choice chip for radio-like behavior.
class EdenChoiceChip extends StatelessWidget {
  const EdenChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null && !selected ? Icon(icon, size: 16) : null,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Multi-select filter chip with checkmark.
class EdenFilterChip extends StatelessWidget {
  const EdenFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null && !selected ? Icon(icon, size: 16) : null,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}

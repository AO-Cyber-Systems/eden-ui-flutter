import 'package:flutter/material.dart';

/// A segmented control for switching between 2-5 options.
///
/// Used for tab-like navigation within a screen (e.g., Food tab:
/// Today / Recipes / Meal Plans). Replaces Material SegmentedButton
/// with Eden styling.
class EdenSegmentedControl<T> extends StatelessWidget {
  const EdenSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expanded = false,
  });

  /// Segments with value and label.
  final List<EdenSegment<T>> segments;

  /// Currently selected value.
  final T selected;

  /// Called when selection changes.
  final ValueChanged<T> onChanged;

  /// Whether segments expand to fill available width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final children = segments.map((segment) {
      final isSelected = segment.value == selected;

      Widget chip = GestureDetector(
        onTap: () => onChanged(segment.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(
                  segment.icon,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                segment.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );

      if (expanded) {
        chip = Expanded(child: chip);
      }

      return chip;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// A single segment in an [EdenSegmentedControl].
class EdenSegment<T> {
  const EdenSegment({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

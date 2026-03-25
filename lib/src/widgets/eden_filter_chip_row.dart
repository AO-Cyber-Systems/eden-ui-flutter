import 'package:flutter/material.dart';

/// A filter option for use with [EdenFilterChipRow].
class EdenFilterOption<T> {
  const EdenFilterOption({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final T value;
  final IconData? icon;
}

/// Horizontally scrollable row of filter chips.
///
/// Supports generic typed values, an optional "All" chip, and icons
/// on individual chips. Commonly used above data tables and list views.
///
/// ```dart
/// EdenFilterChipRow<String>(
///   options: [
///     EdenFilterOption(label: 'Active', value: 'active'),
///     EdenFilterOption(label: 'Completed', value: 'completed'),
///   ],
///   selected: currentFilter,
///   onSelected: (value) => setState(() => currentFilter = value),
/// )
/// ```
class EdenFilterChipRow<T> extends StatelessWidget {
  const EdenFilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.showAllOption = true,
    this.allLabel = 'All',
    this.height = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<EdenFilterOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final bool showAllOption;
  final String allLabel;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          if (showAllOption)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(allLabel),
                selected: selected == null,
                onSelected: (_) => onSelected(null),
              ),
            ),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar:
                    option.icon != null ? Icon(option.icon, size: 18) : null,
                label: Text(option.label),
                selected: selected == option.value,
                onSelected: (_) => onSelected(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

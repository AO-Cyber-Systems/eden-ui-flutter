import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// A filter option for [EdenFilterDropdown].
class EdenFilterDropdownOption<T> {
  const EdenFilterDropdownOption({
    required this.label,
    required this.value,
  });

  final String label;
  final T value;
}

/// Multi-select dropdown with checkboxes for filtering.
///
/// Opens a popup menu with checkbox items. Selected values are displayed
/// as a count badge on the trigger button. Supports "Select All" toggle.
///
/// ```dart
/// EdenFilterDropdown<String>(
///   label: 'Status',
///   options: [
///     EdenFilterDropdownOption(label: 'Active', value: 'active'),
///     EdenFilterDropdownOption(label: 'Completed', value: 'completed'),
///   ],
///   selected: selectedStatuses,
///   onChanged: (values) => setState(() => selectedStatuses = values),
/// )
/// ```
class EdenFilterDropdown<T> extends StatelessWidget {
  const EdenFilterDropdown({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label = 'Filter',
    this.icon = Icons.filter_list,
    this.showSelectAll = true,
  });

  final List<EdenFilterDropdownOption<T>> options;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final String label;
  final IconData icon;
  final bool showSelectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selected.isNotEmpty;

    return PopupMenuButton<_FilterAction<T>>(
      offset: const Offset(0, 40),
      onSelected: (action) {
        if (action.isSelectAll) {
          if (selected.length == options.length) {
            onChanged({});
          } else {
            onChanged(options.map((o) => o.value).toSet());
          }
        } else {
          final newSelected = Set<T>.from(selected);
          if (newSelected.contains(action.value)) {
            newSelected.remove(action.value);
          } else {
            newSelected.add(action.value as T);
          }
          onChanged(newSelected);
        }
      },
      itemBuilder: (context) => [
        if (showSelectAll)
          PopupMenuItem(
            value: _FilterAction<T>.selectAll(),
            child: Row(
              children: [
                Icon(
                  selected.length == options.length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('Select All',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        if (showSelectAll) const PopupMenuDivider(),
        for (final option in options)
          PopupMenuItem(
            value: _FilterAction<T>.toggle(option.value),
            child: Row(
              children: [
                Icon(
                  selected.contains(option.value)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: selected.contains(option.value)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(option.label)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasSelection
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasSelection
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.labelMedium),
            if (hasSelection) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selected.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _FilterAction<T> {
  final T? value;
  final bool isSelectAll;

  const _FilterAction.toggle(this.value) : isSelectAll = false;
  const _FilterAction.selectAll()
      : value = null,
        isSelectAll = true;
}

import 'package:flutter/material.dart';

/// Toolbar above data tables with search, filters, and actions.
///
/// Provides a consistent layout for table controls: search input on the
/// left, action buttons on the right. Supports a filter widget slot.
///
/// ```dart
/// EdenTableToolbar(
///   searchHint: 'Search customers...',
///   onSearchChanged: (q) => setState(() => query = q),
///   filters: EdenFilterChipRow(...),
///   actions: [
///     EdenButton(label: 'Export', onPressed: export),
///     EdenButton(label: 'Create', variant: EdenButtonVariant.primary, onPressed: create),
///   ],
/// )
/// ```
class EdenTableToolbar extends StatelessWidget {
  const EdenTableToolbar({
    super.key,
    this.onSearchChanged,
    this.searchHint = 'Search...',
    this.searchController,
    this.filters,
    this.actions = const [],
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showSearch = true,
  });

  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final TextEditingController? searchController;
  final Widget? filters;
  final List<Widget> actions;
  final EdgeInsets padding;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: padding,
          child: Row(
            children: [
              if (showSearch)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              if (showSearch && actions.isNotEmpty) const SizedBox(width: 12),
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions[i],
              ],
            ],
          ),
        ),
        if (filters != null) filters!,
      ],
    );
  }
}

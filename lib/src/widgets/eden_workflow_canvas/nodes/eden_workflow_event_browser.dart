// EdenWorkflowEventBrowser — registry-driven entity field picker popover.
//
// Donor parity: `FieldBrowser.tsx` (283 LOC). v1 ships the popover UI
// (categorized field list + search + click-to-insert via callback). The
// cursor-position insertion side is consumer-owned (text-controller-aware
// insertion logic varies per host widget).
//
// Parity row R-4.

import 'package:flutter/material.dart';

import '../workflow_field_registry.dart';

class EdenWorkflowEventBrowser extends StatefulWidget {
  const EdenWorkflowEventBrowser({
    super.key,
    required this.onFieldSelected,
    this.initialCategoryId,
  });

  /// Fired when the user picks a field from the list. Consumer wires the
  /// `{field.name}` token insertion to the host text controller.
  final ValueChanged<EdenWorkflowField> onFieldSelected;

  /// Initially-expanded category id. Falls back to the first category.
  final String? initialCategoryId;

  @override
  State<EdenWorkflowEventBrowser> createState() =>
      _EdenWorkflowEventBrowserState();
}

class _EdenWorkflowEventBrowserState extends State<EdenWorkflowEventBrowser> {
  final TextEditingController _searchController = TextEditingController();
  String _expandedCategory = '';

  @override
  void initState() {
    super.initState();
    _expandedCategory = widget.initialCategoryId ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _typeBadgeColor(String type) => switch (type) {
        'string' => Colors.blue.shade100,
        'number' => Colors.green.shade100,
        'date' => Colors.purple.shade100,
        'boolean' => Colors.amber.shade100,
        'object' => Colors.grey.shade200,
        _ => Colors.grey.shade200,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFields = EdenWorkflowFieldRegistry.instance.all();
    final query = _searchController.text;

    if (allFields.isEmpty) {
      return const SizedBox(
        width: 320,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No fields available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final visible = query.isEmpty
        ? allFields
        : EdenWorkflowFieldRegistry.instance.search(query);

    // Group by category, preserving insertion order.
    final byCategory = <String, List<EdenWorkflowField>>{};
    for (final field in visible) {
      byCategory.putIfAbsent(field.category, () => []).add(field);
    }

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search fields...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: byCategory.entries.map((entry) {
                final expanded = _expandedCategory == entry.key;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        _expandedCategory = expanded ? '' : entry.key;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.value.length}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (expanded)
                      ...entry.value.map(
                        (field) => InkWell(
                          onTap: () => widget.onFieldSelected(field),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              field.name,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _typeBadgeColor(
                                                field.type,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              field.type,
                                              style: const TextStyle(
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        field.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

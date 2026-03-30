import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A single item in the catalog.
class EdenCatalogItem {
  const EdenCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.icon,
  });

  final String id;
  final String name;
  final String description;
  final String category;

  /// Optional icon. Defaults to [Icons.extension] if null.
  final IconData? icon;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Two-column responsive catalog picker with search, category grouping,
/// and a selected/attached panel.
///
/// Left column shows a searchable, category-grouped catalog. Right column
/// shows selected items with remove toggles. On narrow screens (< [breakpoint]),
/// only the catalog is shown.
///
/// ```dart
/// EdenCatalogPicker(
///   items: [
///     EdenCatalogItem(id: '1', name: 'Query DB', description: 'Read-only SQL', category: 'Data'),
///     EdenCatalogItem(id: '2', name: 'Send Email', description: 'SMTP send', category: 'Comms'),
///   ],
///   selectedIds: {'1'},
///   onToggle: (id) => toggleSelection(id),
///   searchHint: 'Search tools...',
///   selectedLabel: 'Attached Tools',
/// )
/// ```
class EdenCatalogPicker extends StatefulWidget {
  const EdenCatalogPicker({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    this.searchHint = 'Search...',
    this.selectedLabel = 'Selected',
    this.emptySelectedLabel = 'No items selected',
    this.breakpoint = 700,
    this.accentColor,
  });

  /// All available catalog items.
  final List<EdenCatalogItem> items;

  /// IDs of currently selected items.
  final Set<String> selectedIds;

  /// Called when an item is toggled (add or remove).
  final ValueChanged<String> onToggle;

  /// Search field placeholder.
  final String searchHint;

  /// Label for the selected items panel header.
  final String selectedLabel;

  /// Text shown when no items are selected.
  final String emptySelectedLabel;

  /// Width below which the selected panel is hidden.
  final double breakpoint;

  /// Accent color for selected item borders. Defaults to primary.
  final Color? accentColor;

  @override
  State<EdenCatalogPicker> createState() => _EdenCatalogPickerState();
}

class _EdenCatalogPickerState extends State<EdenCatalogPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EdenCatalogItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<EdenCatalogItem>> get _grouped {
    final grouped = <String, List<EdenCatalogItem>>{};
    for (final item in _filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > widget.breakpoint;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildCatalog(theme)),
              VerticalDivider(
                  width: 1, color: theme.colorScheme.outlineVariant),
              Expanded(flex: 2, child: _buildSelected(theme)),
            ],
          );
        }

        return _buildCatalog(theme);
      },
    );
  }

  Widget _buildCatalog(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: EdenRadii.borderRadiusMd,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
            children: [
              for (final entry in _grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final item in entry.value)
                  _ItemCard(
                    item: item,
                    isSelected: widget.selectedIds.contains(item.id),
                    accentColor: widget.accentColor ??
                        theme.colorScheme.primary,
                    onToggle: () => widget.onToggle(item.id),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelected(ThemeData theme) {
    final selected =
        widget.items.where((t) => widget.selectedIds.contains(t.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Text(
            '${widget.selectedLabel} (${selected.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: selected.isEmpty
              ? Center(
                  child: Text(
                    widget.emptySelectedLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space3),
                  itemCount: selected.length,
                  itemBuilder: (context, index) {
                    return _ItemCard(
                      item: selected[index],
                      isSelected: true,
                      accentColor: widget.accentColor ??
                          theme.colorScheme.primary,
                      onToggle: () => widget.onToggle(selected[index].id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Item card
// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onToggle,
  });

  final EdenCatalogItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? accentColor.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(item.icon ?? Icons.extension, size: 16,
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CategoryTag(label: item.category),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Icon(
              isSelected
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.error
                  : accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

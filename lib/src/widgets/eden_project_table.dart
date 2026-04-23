import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The type of a project-table field.
enum EdenProjectFieldType {
  /// Free-form text.
  text,

  /// Numeric value.
  number,

  /// Date value.
  date,

  /// Single-select from a list of options.
  select,

  /// Assignee (rendered as avatar initials).
  assignee,

  /// Status (rendered as a colored badge).
  status,

  /// Priority (rendered as a colored badge).
  priority,
}

/// Column definition for an [EdenProjectTable].
class EdenProjectField {
  /// Creates a project field definition.
  const EdenProjectField({
    required this.id,
    required this.label,
    this.type = EdenProjectFieldType.text,
    this.width,
    this.options = const [],
  });

  /// Unique key for this field.
  final String id;

  /// Display header label.
  final String label;

  /// Data type for this column.
  final EdenProjectFieldType type;

  /// Optional fixed width. If null, column flexes.
  final double? width;

  /// Available options for [EdenProjectFieldType.select],
  /// [EdenProjectFieldType.status], and [EdenProjectFieldType.priority].
  final List<EdenProjectStatusOption> options;
}

/// A named color option for status/priority/select fields.
class EdenProjectStatusOption {
  /// Creates a status option.
  const EdenProjectStatusOption({
    required this.label,
    required this.color,
  });

  /// Display label.
  final String label;

  /// Badge color.
  final Color color;
}

/// A single data row in an [EdenProjectTable].
class EdenProjectRow {
  /// Creates a project row.
  const EdenProjectRow({
    required this.id,
    required this.fields,
  });

  /// Unique row identifier.
  final String id;

  /// Column id → value. Values are [String], [num], [DateTime], etc.
  final Map<String, dynamic> fields;
}

/// Sort direction.
enum EdenSortDirection {
  /// Ascending.
  ascending,

  /// Descending.
  descending,
}

/// Current sort state.
class EdenSortState {
  /// Creates a sort state.
  const EdenSortState({
    required this.fieldId,
    required this.direction,
  });

  /// Which field is sorted.
  final String fieldId;

  /// Direction.
  final EdenSortDirection direction;
}

/// A spreadsheet-style project table with sortable columns, inline editing,
/// row selection, grouping, and colored status/priority/assignee rendering.
class EdenProjectTable extends StatefulWidget {
  /// Creates a project table.
  const EdenProjectTable({
    super.key,
    required this.fields,
    required this.rows,
    this.selectedRowIds = const {},
    this.sort,
    this.groupByFieldId,
    this.onCellChanged,
    this.onRowTap,
    this.onSort,
    this.onAddRow,
    this.onSelectionChanged,
  });

  /// Column definitions.
  final List<EdenProjectField> fields;

  /// Data rows.
  final List<EdenProjectRow> rows;

  /// Currently selected row IDs.
  final Set<String> selectedRowIds;

  /// Current sort state.
  final EdenSortState? sort;

  /// If set, rows are grouped by this field.
  final String? groupByFieldId;

  /// Called when a cell value is edited.
  /// Parameters: rowId, fieldId, newValue.
  final void Function(String rowId, String fieldId, dynamic newValue)?
      onCellChanged;

  /// Called when a row is tapped.
  final ValueChanged<String>? onRowTap;

  /// Called when a column header is tapped for sorting.
  final ValueChanged<String>? onSort;

  /// Called when the "Add row" button is pressed.
  final VoidCallback? onAddRow;

  /// Called when row selection changes.
  final ValueChanged<Set<String>>? onSelectionChanged;

  @override
  State<EdenProjectTable> createState() => _EdenProjectTableState();
}

class _EdenProjectTableState extends State<EdenProjectTable> {
  String? _editingRowId;
  String? _editingFieldId;
  late TextEditingController _editController;
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing(String rowId, String fieldId, String currentValue) {
    setState(() {
      _editingRowId = rowId;
      _editingFieldId = fieldId;
      _editController.text = currentValue;
    });
  }

  void _commitEdit() {
    if (_editingRowId != null && _editingFieldId != null) {
      widget.onCellChanged?.call(
        _editingRowId!,
        _editingFieldId!,
        _editController.text,
      );
    }
    setState(() {
      _editingRowId = null;
      _editingFieldId = null;
    });
  }

  void _toggleSelection(String rowId) {
    final next = Set<String>.from(widget.selectedRowIds);
    if (next.contains(rowId)) {
      next.remove(rowId);
    } else {
      next.add(rowId);
    }
    widget.onSelectionChanged?.call(next);
  }

  void _toggleGroup(String groupKey) {
    setState(() {
      if (_collapsedGroups.contains(groupKey)) {
        _collapsedGroups.remove(groupKey);
      } else {
        _collapsedGroups.add(groupKey);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Grouping
  // ---------------------------------------------------------------------------

  Map<String, List<EdenProjectRow>> _groupedRows() {
    if (widget.groupByFieldId == null) return {'': widget.rows};
    final map = <String, List<EdenProjectRow>>{};
    for (final row in widget.rows) {
      final key =
          row.fields[widget.groupByFieldId]?.toString() ?? 'Ungrouped';
      (map[key] ??= []).add(row);
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Cell rendering
  // ---------------------------------------------------------------------------

  String _cellText(EdenProjectRow row, EdenProjectField field) {
    final value = row.fields[field.id];
    if (value == null) return '';
    if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  EdenProjectStatusOption? _findOption(
      EdenProjectField field, String value) {
    if (field.options.isEmpty) return null;
    for (final opt in field.options) {
      if (opt.label == value) return opt;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final headerBg =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;
    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    final groups = _groupedRows();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space2,
            ),
            child: Row(
              children: [
                // Checkbox header
                const SizedBox(
                  width: 32,
                  child: SizedBox.shrink(),
                ),
                ...widget.fields.map((field) {
                  final isSorted = widget.sort?.fieldId == field.id;
                  return Expanded(
                    flex: field.width != null ? 0 : 1,
                    child: field.width != null
                        ? SizedBox(
                            width: field.width,
                            child: _buildHeaderCell(
                              context,
                              field: field,
                              isSorted: isSorted,
                              mutedColor: mutedColor,
                            ),
                          )
                        : _buildHeaderCell(
                            context,
                            field: field,
                            isSorted: isSorted,
                            mutedColor: mutedColor,
                          ),
                  );
                }),
              ],
            ),
          ),

          // Data rows (grouped)
          ...groups.entries.expand((entry) {
            final groupKey = entry.key;
            final rows = entry.value;
            final isGrouped = widget.groupByFieldId != null;
            final isCollapsed = _collapsedGroups.contains(groupKey);

            return [
              if (isGrouped)
                _buildGroupHeader(
                  context,
                  groupKey: groupKey,
                  count: rows.length,
                  isCollapsed: isCollapsed,
                  isDark: isDark,
                  mutedColor: mutedColor,
                ),
              if (!isCollapsed)
                ...rows.map((row) => _buildDataRow(
                      context,
                      row: row,
                      isDark: isDark,
                      borderColor: borderColor,
                      mutedColor: mutedColor,
                    )),
            ];
          }),

          // Add row button
          if (widget.onAddRow != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onAddRow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space4,
                    vertical: EdenSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: mutedColor),
                      const SizedBox(width: EdenSpacing.space1),
                      Text(
                        'Add row',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context, {
    required EdenProjectField field,
    required bool isSorted,
    required Color mutedColor,
  }) {
    final theme = Theme.of(context);
    final sortDir = widget.sort?.direction;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSort?.call(field.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  field.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSorted) ...[
                const SizedBox(width: EdenSpacing.space1 / 2),
                Icon(
                  sortDir == EdenSortDirection.ascending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 12,
                  color: mutedColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context, {
    required String groupKey,
    required int count,
    required bool isCollapsed,
    required bool isDark,
    required Color mutedColor,
  }) {
    final theme = Theme.of(context);
    final bg = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;

    return Material(
      color: bg,
      child: InkWell(
        onTap: () => _toggleGroup(groupKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space2,
          ),
          child: Row(
            children: [
              Icon(
                isCollapsed ? Icons.chevron_right : Icons.expand_more,
                size: 16,
                color: mutedColor,
              ),
              const SizedBox(width: EdenSpacing.space1),
              Text(
                groupKey,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: EdenSpacing.space1),
              Text(
                '($count)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required EdenProjectRow row,
    required bool isDark,
    required Color borderColor,
    required Color mutedColor,
  }) {
    final isSelected = widget.selectedRowIds.contains(row.id);
    final selectedBg = isDark
        ? EdenColors.info.withValues(alpha: 0.08)
        : EdenColors.info.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : null,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onRowTap?.call(row.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            child: Row(
              children: [
                // Checkbox
                SizedBox(
                  width: 32,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(row.id),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...widget.fields.map((field) {
                  return Expanded(
                    flex: field.width != null ? 0 : 1,
                    child: field.width != null
                        ? SizedBox(
                            width: field.width,
                            child: _buildCell(
                              context,
                              row: row,
                              field: field,
                              isDark: isDark,
                              mutedColor: mutedColor,
                            ),
                          )
                        : _buildCell(
                            context,
                            row: row,
                            field: field,
                            isDark: isDark,
                            mutedColor: mutedColor,
                          ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required EdenProjectRow row,
    required EdenProjectField field,
    required bool isDark,
    required Color mutedColor,
  }) {
    final theme = Theme.of(context);
    final isEditing =
        _editingRowId == row.id && _editingFieldId == field.id;
    final value = _cellText(row, field);

    // Inline editing
    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
        child: TextField(
          controller: _editController,
          autofocus: true,
          style: theme.textTheme.bodySmall,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space1,
              vertical: EdenSpacing.space1,
            ),
            border: OutlineInputBorder(
              borderRadius: EdenRadii.borderRadiusSm,
            ),
          ),
          onSubmitted: (_) => _commitEdit(),
          onTapOutside: (_) => _commitEdit(),
        ),
      );
    }

    // Status / priority badge
    if (field.type == EdenProjectFieldType.status ||
        field.type == EdenProjectFieldType.priority) {
      final option = _findOption(field, value);
      if (option != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
          child: GestureDetector(
            onTap: widget.onCellChanged != null
                ? () => _startEditing(row.id, field.id, value)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space2,
                vertical: EdenSpacing.space1 / 2,
              ),
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                borderRadius: EdenRadii.borderRadiusSm,
              ),
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: option.color,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    }

    // Assignee avatar
    if (field.type == EdenProjectFieldType.assignee && value.isNotEmpty) {
      final initials = value
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
        child: GestureDetector(
          onTap: widget.onCellChanged != null
              ? () => _startEditing(row.id, field.id, value)
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: EdenColors.info.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: EdenColors.info,
                  ),
                ),
              ),
              const SizedBox(width: EdenSpacing.space1),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default text cell (tap to edit)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
      child: GestureDetector(
        onDoubleTap: widget.onCellChanged != null
            ? () => _startEditing(row.id, field.id, value)
            : null,
        child: Text(
          value,
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

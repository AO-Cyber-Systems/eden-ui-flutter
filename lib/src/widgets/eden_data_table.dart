import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../utils/eden_tsv.dart';

/// Mirrors the eden_table Rails component.
///
/// A styled data table with optional striped rows, hover highlighting, and
/// border.
///
/// **Obj 010 — dense variant.** Use [EdenDataTable.dense] for the 32pt-row
/// dense-enterprise variant with optional sticky header, freeze-first-column,
/// and bulk-select. Default constructor + behavior unchanged for backwards
/// compatibility.
class EdenDataTable extends StatelessWidget {
  const EdenDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.striped = false,
    this.hoverable = true,
    this.onRowTap,
    this.copyable = false,
  })  : isDense = false,
        freezeFirstColumn = false,
        bulkSelectable = false,
        selectedRowIndices = const {},
        onSelectionChanged = null;

  /// Dense enterprise variant. Additive — coexists with the default constructor.
  ///
  /// Features:
  /// * 32pt row height (vs ~48pt default), reduced inner padding.
  /// * Sticky header (always visible during vertical scroll).
  /// * Optional [freezeFirstColumn] for wide tables.
  /// * Optional [bulkSelectable] checkbox column with tri-state header.
  /// * Consumer-owned selection state ([selectedRowIndices] + [onSelectionChanged]).
  /// * Inline-edit affordance — accommodates 32pt-height TextField cells.
  const EdenDataTable.dense({
    super.key,
    required this.columns,
    required this.rows,
    this.striped = false,
    this.hoverable = true,
    this.onRowTap,
    this.freezeFirstColumn = false,
    this.bulkSelectable = false,
    this.selectedRowIndices = const {},
    this.onSelectionChanged,
    this.copyable = false,
  }) : isDense = true;

  final List<EdenTableColumn> columns;
  final List<EdenTableRow> rows;
  final bool striped;
  final bool hoverable;
  final ValueChanged<int>? onRowTap;

  /// Shows a copy affordance per row and a copy-table action in the header.
  ///
  /// Off by default. `SelectionArea` concatenates a drag-selection with no cell
  /// delimiters (40-RESEARCH.md section 5), so a table that wants
  /// paste-into-a-spreadsheet behaviour has to offer it explicitly; but this
  /// library has several downstream consumers and a new icon appearing in every
  /// existing table unannounced is a visual regression. Opt in per table.
  ///
  /// Honoured by BOTH constructors, including [EdenDataTable.dense].
  final bool copyable;

  // Dense-only fields. Ignored by the default constructor.
  final bool isDense;
  final bool freezeFirstColumn;
  final bool bulkSelectable;
  final Set<int> selectedRowIndices;
  final ValueChanged<Set<int>>? onSelectionChanged;

  // Inner padding override for dense variant. obj 009's EdenSpacing.spaceHalf
  // (2pt) is the target token; until it ships we use EdenSpacing.space1 (4pt)
  // as the graceful fallback. The TRD documents this so consumers know dense
  // tightens to 2pt once obj 009 lands.
  static const double _densePad = EdenSpacing.space1;

  @override
  Widget build(BuildContext context) {
    if (isDense) {
      return _DenseBody(table: this);
    }
    return _buildDefault(context);
  }

  Widget _buildDefault(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            child: Row(
              children: <Widget>[
                for (final EdenTableColumn col in columns)
                  Expanded(
                    flex: col.flex,
                    child: Text(
                      col.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (copyable) _copyTableButton(),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final stripedBg = striped && index.isOdd
                ? (isDark ? EdenColors.neutral[850]!.withValues(alpha: 0.5) : EdenColors.neutral[50]!.withValues(alpha: 0.5))
                : null;

            Widget rowWidget = Container(
              color: stripedBg,
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space3,
              ),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < columns.length; i++)
                    Expanded(
                      flex: columns[i].flex,
                      child: i < row.cells.length ? row.cells[i] : const SizedBox.shrink(),
                    ),
                  if (copyable) _copyRowButton(row),
                ],
              ),
            );

            if (hoverable || onRowTap != null) {
              rowWidget = Semantics(
                button: onRowTap != null,
                label: 'Row ${index + 1}',
                child: InkWell(
                  onTap: onRowTap != null ? () => onRowTap!(index) : null,
                  hoverColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                  child: rowWidget,
                ),
              );
            }

            // Applied last so the key sits on the OUTERMOST row widget — a
            // find.byKey then resolves the tappable row, not a child of it.
            if (row.key != null) {
              rowWidget = KeyedSubtree(key: row.key, child: rowWidget);
            }

            return Column(
              children: [
                rowWidget,
                if (index < rows.length - 1)
                  Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Clipboard values for [row], one per cell.
  ///
  /// [EdenTableRow.copyValues] wins when supplied, because the caller knows
  /// what the record actually holds; otherwise the cell widgets are read
  /// best-effort. Widgets that yield no text (an icon, an avatar, a button)
  /// become an EMPTY cell rather than the string "null", so the column
  /// alignment of the pasted grid survives.
  List<String> _rowValues(EdenTableRow row) {
    final List<String>? explicit = row.copyValues;
    if (explicit != null) return explicit;
    return row.cells
        .map((Widget cell) => edenExtractWidgetText(cell) ?? '')
        .toList();
  }

  List<List<String>> _allRowValues() => rows.map(_rowValues).toList();

  List<String> _headerValues() =>
      columns.map((EdenTableColumn col) => col.label).toList();

  /// Copies this row alone, TAB-delimited and with NO header line.
  ///
  /// Wrapped in [SelectionContainer.disabled] so a drag-select across the table
  /// picks up the data and not the word "Copy" (40-RESEARCH.md section 5).
  Widget _copyRowButton(EdenTableRow row) {
    return SelectionContainer.disabled(
      child: IconButton(
        icon: Icon(Icons.copy, size: 16, color: EdenColors.neutral[500]),
        tooltip: 'Copy row',
        onPressed: () => edenCopyTsv(<List<String>>[_rowValues(row)]),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  /// Copies the whole grid: column labels first, then every row.
  Widget _copyTableButton() {
    return SelectionContainer.disabled(
      child: IconButton(
        icon: Icon(Icons.copy_all, size: 16, color: EdenColors.neutral[500]),
        tooltip: 'Copy table',
        onPressed: () => edenCopyTsv(_allRowValues(), header: _headerValues()),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _DenseBody extends StatelessWidget {
  const _DenseBody({required this.table});

  final EdenDataTable table;

  static const double _rowHeight = 32;
  static const double _headerHeight = 32;

  bool? _headerTriValue() {
    if (!table.bulkSelectable) return false;
    final count = table.selectedRowIndices.length;
    if (count == 0) return false;
    if (count == table.rows.length) return true;
    return null;
  }

  void _toggleHeader(BuildContext context) {
    if (table.onSelectionChanged == null) return;
    final tri = _headerTriValue();
    if (tri == true) {
      table.onSelectionChanged!(<int>{});
    } else {
      // tri == false or null (some) → select all
      table.onSelectionChanged!({for (int i = 0; i < table.rows.length; i++) i});
    }
  }

  void _toggleRow(int rowIndex) {
    if (table.onSelectionChanged == null) return;
    final next = Set<int>.from(table.selectedRowIndices);
    if (next.contains(rowIndex)) {
      next.remove(rowIndex);
    } else {
      next.add(rowIndex);
    }
    table.onSelectionChanged!(next);
  }

  Widget _headerCell(BuildContext context, EdenTableColumn col) {
    final theme = Theme.of(context);
    return Text(
      col.label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _bulkSelectHeader(BuildContext context) {
    return SizedBox(
      width: 44,
      height: _headerHeight,
      child: Checkbox(
        tristate: true,
        value: _headerTriValue(),
        onChanged: table.onSelectionChanged == null
            ? null
            : (_) => _toggleHeader(context),
      ),
    );
  }

  Widget _bulkSelectCell(int rowIndex) {
    return SizedBox(
      width: 44,
      height: _rowHeight,
      child: Checkbox(
        value: table.selectedRowIndices.contains(rowIndex),
        onChanged: table.onSelectionChanged == null
            ? null
            : (_) => _toggleRow(rowIndex),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: _headerHeight,
      color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
      padding: const EdgeInsets.symmetric(
        horizontal: EdenDataTable._densePad,
      ),
      child: Row(
        children: [
          if (table.bulkSelectable) _bulkSelectHeader(context),
          for (final col in table.columns)
            Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenDataTable._densePad,
                ),
                child: _headerCell(context, col),
              ),
            ),
          if (table.copyable) table._copyTableButton(),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final row = table.rows[index];
    final stripedBg = table.striped && index.isOdd
        ? (isDark
            ? EdenColors.neutral[850]!.withValues(alpha: 0.5)
            : EdenColors.neutral[50]!.withValues(alpha: 0.5))
        : null;
    return Container(
      key: row.key,
      height: _rowHeight,
      color: stripedBg,
      padding: const EdgeInsets.symmetric(horizontal: EdenDataTable._densePad),
      child: Row(
        children: [
          if (table.bulkSelectable) _bulkSelectCell(index),
          for (int i = 0; i < table.columns.length; i++)
            Expanded(
              flex: table.columns[i].flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenDataTable._densePad,
                ),
                child: i < row.cells.length ? row.cells[i] : const SizedBox.shrink(),
              ),
            ),
          if (table.copyable) table._copyRowButton(row),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final container = Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final containerHeight = hasBoundedHeight ? constraints.maxHeight : 400.0;
        // Header + 1px divider + body. Subtract container border (1 + 1).
        const chrome = _headerHeight + 1.0 + 2.0;
        final bodyHeight = (containerHeight - chrome).clamp(0.0, double.infinity);
        return SizedBox(
          height: containerHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
              SizedBox(
                height: bodyHeight,
                child: ListView.builder(
                  itemCount: table.rows.length,
                  itemBuilder: (context, i) => _buildRow(context, i),
                ),
              ),
            ],
          ),
        );
      }),
    );
    return container;
  }
}

/// Column definition for [EdenDataTable].
class EdenTableColumn {
  const EdenTableColumn({
    required this.label,
    this.flex = 1,
  });

  final String label;
  final int flex;
}

/// Row data for [EdenDataTable].
class EdenTableRow {
  const EdenTableRow({required this.cells, this.key, this.copyValues});

  final List<Widget> cells;

  /// Explicit clipboard values for this row, one per column.
  ///
  /// When null the values are read best-effort out of the cell widgets via
  /// [edenExtractWidgetText]. Supply this whenever a cell renders something
  /// other than plain text — a badge, an avatar, a formatted amount, a relative
  /// timestamp — so the copied value is the DATA rather than whatever string
  /// happened to be on screen. `1,234.50 USD` on screen is rarely what belongs
  /// in a spreadsheet cell.
  final List<String>? copyValues;

  /// Optional key applied to the outermost rendered row widget.
  ///
  /// Lets a test locate a row by the identity of the record it renders rather
  /// than by its position, e.g. `Key('posts_list.row.$id')`. Optional and
  /// additive — existing `EdenTableRow(cells: [...])` call sites are unchanged.
  final Key? key;
}

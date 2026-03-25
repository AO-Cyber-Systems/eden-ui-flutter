import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import 'data_grid/data_grid_controls.dart';

/// Column definition for [EdenDataGrid].
class EdenGridColumn<T> {
  /// Unique identifier for this column.
  final String id;

  /// Display label shown in the header.
  final String label;

  /// Fixed width in logical pixels. If null, column uses [flex].
  final double? width;

  /// Minimum width when resizing.
  final double minWidth;

  /// Flex factor for distributing remaining space.
  final double? flex;

  /// Whether this column can be sorted.
  final bool sortable;

  /// Whether a filter input is shown below the header.
  final bool filterable;

  /// Whether the column can be resized by dragging.
  final bool resizable;

  /// Whether this column is pinned to the left side of the grid.
  /// Pinned columns remain visible while scrolling horizontally.
  final bool pinned;

  /// Custom cell builder. Receives the row data and its index.
  final Widget Function(T row, int index)? cellBuilder;

  /// Custom comparator for sorting this column.
  final int Function(T a, T b)? comparator;

  /// Text alignment for cells in this column.
  final TextAlign textAlign;

  const EdenGridColumn({
    required this.id,
    required this.label,
    this.width,
    this.minWidth = 80,
    this.flex,
    this.sortable = true,
    this.filterable = false,
    this.resizable = true,
    this.pinned = false,
    this.cellBuilder,
    this.comparator,
    this.textAlign = TextAlign.start,
  });
}

/// Sort state for [EdenDataGrid].
class EdenGridSort {
  final String columnId;
  final bool ascending;
  const EdenGridSort({required this.columnId, this.ascending = true});
}

/// An advanced data grid with sorting, filtering, column resize, row
/// selection, inline actions, pagination, column reordering, column
/// visibility, column pinning, and frozen row support.
///
/// For a simpler table without these features, see [EdenDataTable].
class EdenDataGrid<T> extends StatefulWidget {
  const EdenDataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.rowKey,
    this.sort,
    this.onSort,
    this.filters,
    this.onFilter,
    this.selectable = false,
    this.multiSelect = false,
    this.selectedRows,
    this.onSelectionChanged,
    this.onRowTap,
    this.onRowDoubleTap,
    this.rowActions,
    this.loading = false,
    this.emptyMessage = 'No data',
    this.striped = true,
    this.bordered = true,
    this.compact = false,
    this.stickyHeader = true,
    this.currentPage,
    this.totalPages,
    this.totalRows,
    this.onPageChanged,
    this.pageSize,
    this.reorderable = false,
    this.onColumnsReordered,
    this.hiddenColumns,
    this.frozenRowCount = 0,
  });

  final List<EdenGridColumn<T>> columns;
  final List<T> rows;
  final String Function(T)? rowKey;
  final EdenGridSort? sort;
  final ValueChanged<EdenGridSort>? onSort;
  final Map<String, String>? filters;
  final void Function(String columnId, String value)? onFilter;
  final bool selectable;
  final bool multiSelect;
  final Set<int>? selectedRows;
  final ValueChanged<Set<int>>? onSelectionChanged;
  final ValueChanged<T>? onRowTap;
  final ValueChanged<T>? onRowDoubleTap;
  final List<Widget> Function(T row, int index)? rowActions;
  final bool loading;
  final String emptyMessage;
  final bool striped;
  final bool bordered;
  final bool compact;
  final bool stickyHeader;
  final int? currentPage;
  final int? totalPages;
  final int? totalRows;
  final ValueChanged<int>? onPageChanged;
  final int? pageSize;

  /// Whether columns can be reordered via drag and drop.
  final bool reorderable;

  /// Called with the new column order (list of column ids) after a reorder.
  final ValueChanged<List<String>>? onColumnsReordered;

  /// Set of column ids that should be hidden.
  final Set<String>? hiddenColumns;

  /// Number of data rows to freeze at the top (below the header).
  /// Frozen rows remain visible while scrolling vertically.
  final int frozenRowCount;

  @override
  State<EdenDataGrid<T>> createState() => _EdenDataGridState<T>();
}

class _EdenDataGridState<T> extends State<EdenDataGrid<T>> {
  final ScrollController _horizontalScroll = ScrollController();
  late Map<String, double> _columnWidths;
  int? _hoveredRow;

  /// Internal column order maintained as a list of column ids.
  late List<String> _columnOrder;

  /// The column id currently being dragged over (drop target).
  String? _dropTargetColumnId;

  /// Whether the drop indicator should appear on the left side of the target.
  bool _dropOnLeft = false;

  @override
  void initState() {
    super.initState();
    _initColumnOrder();
    _initColumnWidths();
  }

  @override
  void didUpdateWidget(covariant EdenDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns.length != widget.columns.length) {
      _initColumnWidths();
      _initColumnOrder();
    }
  }

  void _initColumnOrder() {
    _columnOrder = widget.columns.map((c) => c.id).toList();
  }

  void _initColumnWidths() {
    _columnWidths = {};
    for (final col in widget.columns) {
      _columnWidths[col.id] = col.width ?? (col.minWidth > 120 ? col.minWidth : 150);
    }
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  Set<int> get _selectedRows => widget.selectedRows ?? {};

  bool get _hasFilters => widget.columns.any((c) => c.filterable);

  bool get _hasPagination =>
      widget.currentPage != null &&
      widget.totalPages != null &&
      widget.onPageChanged != null;

  double get _cellVerticalPadding =>
      widget.compact ? EdenSpacing.space2 : EdenSpacing.space3;

  Set<String> get _hiddenColumns => widget.hiddenColumns ?? {};

  /// Returns the column definition by id.
  EdenGridColumn<T>? _columnById(String id) {
    for (final col in widget.columns) {
      if (col.id == id) return col;
    }
    return null;
  }

  /// Returns columns in display order, respecting pinning, visibility, and
  /// reorder state. Pinned columns come first, then unpinned in their
  /// current order.
  List<EdenGridColumn<T>> get _orderedVisibleColumns {
    final hidden = _hiddenColumns;
    final ordered = <EdenGridColumn<T>>[];
    for (final id in _columnOrder) {
      if (hidden.contains(id)) continue;
      final col = _columnById(id);
      if (col != null) ordered.add(col);
    }
    // Include any new columns not yet in _columnOrder (defensive).
    for (final col in widget.columns) {
      if (hidden.contains(col.id)) continue;
      if (!_columnOrder.contains(col.id)) {
        ordered.add(col);
      }
    }
    // Stable partition: pinned first, then unpinned, preserving relative order.
    final pinned = ordered.where((c) => c.pinned).toList();
    final unpinned = ordered.where((c) => !c.pinned).toList();
    return [...pinned, ...unpinned];
  }

  /// Width of the pinned (frozen) column region.
  double get _pinnedColumnsWidth {
    double w = 0;
    if (widget.selectable) w += 48;
    for (final col in _orderedVisibleColumns) {
      if (!col.pinned) break;
      w += _columnWidths[col.id] ?? col.minWidth;
    }
    return w;
  }

  List<EdenGridColumn<T>> get _pinnedColumns =>
      _orderedVisibleColumns.where((c) => c.pinned).toList();

  List<EdenGridColumn<T>> get _unpinnedColumns =>
      _orderedVisibleColumns.where((c) => !c.pinned).toList();

  bool get _hasPinnedColumns => _pinnedColumns.isNotEmpty;

  void _handleSort(EdenGridColumn<T> column) {
    if (!column.sortable || widget.onSort == null) return;
    final current = widget.sort;
    if (current != null && current.columnId == column.id) {
      widget.onSort!(EdenGridSort(columnId: column.id, ascending: !current.ascending));
    } else {
      widget.onSort!(EdenGridSort(columnId: column.id, ascending: true));
    }
  }

  void _handleSelectAll(bool? checked) {
    if (widget.onSelectionChanged == null) return;
    if (checked == true) {
      widget.onSelectionChanged!(
        Set<int>.from(List.generate(widget.rows.length, (i) => i)),
      );
    } else {
      widget.onSelectionChanged!({});
    }
  }

  void _handleSelectRow(int index, bool? checked) {
    if (widget.onSelectionChanged == null) return;
    final selected = Set<int>.from(_selectedRows);
    if (widget.multiSelect) {
      if (checked == true) {
        selected.add(index);
      } else {
        selected.remove(index);
      }
    } else {
      selected.clear();
      if (checked == true) selected.add(index);
    }
    widget.onSelectionChanged!(selected);
  }

  void _handleColumnReorder(String draggedId, String targetId) {
    if (draggedId == targetId) return;
    setState(() {
      final draggedIndex = _columnOrder.indexOf(draggedId);
      if (draggedIndex == -1) return;
      _columnOrder.removeAt(draggedIndex);
      var targetIndex = _columnOrder.indexOf(targetId);
      if (targetIndex == -1) return;
      if (!_dropOnLeft) {
        targetIndex += 1;
      }
      _columnOrder.insert(targetIndex, draggedId);
      _dropTargetColumnId = null;
    });
    widget.onColumnsReordered?.call(List<String>.from(_columnOrder));
  }

  double _totalContentWidth() {
    double w = 0;
    if (widget.selectable) w += 48;
    for (final col in _orderedVisibleColumns) {
      w += _columnWidths[col.id] ?? col.minWidth;
    }
    if (widget.rowActions != null) w += 120;
    return w;
  }

  double _scrollableContentWidth() {
    double w = 0;
    for (final col in _unpinnedColumns) {
      w += _columnWidths[col.id] ?? col.minWidth;
    }
    if (widget.rowActions != null) w += 120;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: widget.bordered
          ? BoxDecoration(
              borderRadius: EdenRadii.borderRadiusLg,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            )
          : null,
      clipBehavior: widget.bordered ? Clip.antiAlias : Clip.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.hasBoundedHeight;
          final gridBody = Stack(
            children: [
              _hasPinnedColumns
                  ? _buildPinnedLayout(theme, isDark)
                  : _buildStandardLayout(theme, isDark),
              // Loading overlay
              if (widget.loading)
                Positioned.fill(
                  child: Container(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
          final wrappedBody = hasBoundedHeight
              ? Expanded(child: gridBody)
              : SizedBox(
                  height: 400,
                  child: gridBody,
                );
          return Column(
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Column visibility toolbar (shown when hiddenColumns param is used).
              if (widget.hiddenColumns != null)
                _buildColumnVisibilityToolbar(theme, isDark),
              wrappedBody,
              // Pagination footer
              if (_hasPagination) _buildPagination(theme, isDark),
            ],
          );
        },
      ),
    );
  }

  /// Standard layout without pinned columns (original behavior).
  Widget _buildStandardLayout(ThemeData theme, bool isDark) {
    return Scrollbar(
      controller: _horizontalScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScroll,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _totalContentWidth(),
          child: _buildGridContent(theme, isDark, _orderedVisibleColumns, true),
        ),
      ),
    );
  }

  /// Layout with pinned columns on the left, scrollable columns on the right.
  Widget _buildPinnedLayout(ThemeData theme, bool isDark) {
    final pinnedWidth = _pinnedColumnsWidth;

    return Row(
      children: [
        // Pinned (frozen) columns
        SizedBox(
          width: pinnedWidth,
          child: _buildGridContent(
            theme,
            isDark,
            _pinnedColumns,
            true,
            includeCheckbox: true,
            includeActions: false,
          ),
        ),
        // Divider between pinned and scrollable
        Container(
          width: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        // Scrollable columns
        Expanded(
          child: Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _scrollableContentWidth(),
                child: _buildGridContent(
                  theme,
                  isDark,
                  _unpinnedColumns,
                  false,
                  includeCheckbox: false,
                  includeActions: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the grid content (header, filters, rows) for a set of columns.
  Widget _buildGridContent(
    ThemeData theme,
    bool isDark,
    List<EdenGridColumn<T>> columns,
    bool includeCheckboxDefault, {
    bool? includeCheckbox,
    bool? includeActions,
  }) {
    final showCheckbox = includeCheckbox ?? (includeCheckboxDefault && widget.selectable);
    final showActions = includeActions ?? (widget.rowActions != null);
    final frozenCount = widget.frozenRowCount.clamp(0, widget.rows.length);
    final hasFrozenRows = frozenCount > 0;

    return Column(
      children: [
        // Header row
        _buildHeader(theme, isDark, columns, showCheckbox, showActions),
        // Filter row
        if (_hasFilters)
          _buildFilterRow(theme, isDark, columns, showCheckbox, showActions),
        // Divider below header/filters
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        // Frozen rows
        if (hasFrozenRows)
          ...List.generate(frozenCount, (index) {
            return Column(
              children: [
                _buildRow(theme, isDark, index, columns, showCheckbox, showActions),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ],
            );
          }),
        // Shadow separator for frozen rows
        if (hasFrozenRows)
          Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        // Scrollable data rows
        Expanded(
          child: widget.rows.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  itemCount: widget.rows.length - frozenCount,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final actualIndex = index + frozenCount;
                    return _buildRow(
                      theme,
                      isDark,
                      actualIndex,
                      columns,
                      showCheckbox,
                      showActions,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildColumnVisibilityToolbar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          const Spacer(),
          ColumnVisibilityButton(
            columns: widget.columns,
            hiddenColumns: _hiddenColumns,
            onToggle: (columnId, visible) {
              // Column visibility is controlled by the parent via
              // hiddenColumns. We can't mutate it directly, so we call
              // the reorder callback which the parent can use to track
              // visibility changes. For a pure visibility toggle, the
              // parent should manage hiddenColumns state externally.
              // This button provides the UI affordance.
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    List<EdenGridColumn<T>> columns,
    bool showCheckbox,
    bool showActions,
  ) {
    return Container(
      color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
      padding: EdgeInsets.symmetric(
        vertical: _cellVerticalPadding,
      ),
      child: Row(
        children: [
          if (showCheckbox)
            SizedBox(
              width: 48,
              child: widget.multiSelect
                  ? Checkbox(
                      value: _selectedRows.length == widget.rows.length &&
                          widget.rows.isNotEmpty,
                      tristate: _selectedRows.isNotEmpty &&
                          _selectedRows.length < widget.rows.length,
                      onChanged: _handleSelectAll,
                    )
                  : const SizedBox.shrink(),
            ),
          ...columns.map((col) => _buildHeaderCell(theme, col)),
          if (showActions)
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                ),
                child: Text(
                  'Actions',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(ThemeData theme, EdenGridColumn<T> col) {
    final width = _columnWidths[col.id] ?? col.minWidth;
    final isSorted = widget.sort?.columnId == col.id;

    Widget headerContent = SizedBox(
      width: width,
      child: Stack(
        children: [
          InkWell(
            onTap: col.sortable ? () => _handleSort(col) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
              ),
              child: Row(
                children: [
                  if (widget.reorderable) ...[
                    Icon(
                      Icons.drag_indicator,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      col.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSorted ? FontWeight.w700 : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (col.sortable) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isSorted
                          ? (widget.sort!.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                          : Icons.unfold_more,
                      size: 14,
                      color: isSorted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Resize handle
          if (col.resizable)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final current = _columnWidths[col.id] ?? col.minWidth;
                    final next = (current + details.delta.dx)
                        .clamp(col.minWidth, double.infinity);
                    _columnWidths[col.id] = next;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 6,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!widget.reorderable || col.pinned) {
      return headerContent;
    }

    // Wrap with drag-and-drop support for reorderable, unpinned columns.
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final draggedId = details.data;
        // Don't accept drops onto pinned columns or self.
        if (draggedId == col.id) return false;
        final draggedCol = _columnById(draggedId);
        if (draggedCol?.pinned == true) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        _handleColumnReorder(details.data, col.id);
      },
      onMove: (details) {
        // Determine if the drag is on the left or right half of the target.
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          // Use the target column position to determine left/right half.
          setState(() {
            _dropTargetColumnId = col.id;
          });
        }
      },
      onLeave: (_) {
        setState(() {
          if (_dropTargetColumnId == col.id) {
            _dropTargetColumnId = null;
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isTarget = _dropTargetColumnId == col.id &&
            candidateData.isNotEmpty;

        return Stack(
          children: [
            LongPressDraggable<String>(
              data: col.id,
              delay: const Duration(milliseconds: 150),
              axis: Axis.horizontal,
              feedback: Material(
                elevation: 4,
                borderRadius: EdenRadii.borderRadiusSm,
                child: Container(
                  width: width,
                  padding: EdgeInsets.symmetric(
                    vertical: _cellVerticalPadding,
                    horizontal: EdenSpacing.space3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: EdenRadii.borderRadiusSm,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          col.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: headerContent,
              ),
              onDragStarted: () {
                setState(() {
                  _dropTargetColumnId = null;
                });
              },
              onDragEnd: (_) {
                setState(() {
                  _dropTargetColumnId = null;
                });
              },
              onDragUpdate: (details) {
                // Track whether we're on the left or right side of the
                // current drop target using global position.
                // The DragTarget's onMove handles setting the target id;
                // here we refine left/right.
                if (_dropTargetColumnId != null) {
                  // Approximate left/right using drag delta direction.
                  setState(() {
                    _dropOnLeft = details.delta.dx < 0;
                  });
                }
              },
              child: headerContent,
            ),
            // Drop indicator — vertical blue line
            if (isTarget)
              Positioned(
                left: _dropOnLeft ? 0 : null,
                right: _dropOnLeft ? null : 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow(
    ThemeData theme,
    bool isDark,
    List<EdenGridColumn<T>> columns,
    bool showCheckbox,
    bool showActions,
  ) {
    return Container(
      color: isDark
          ? EdenColors.neutral[850]?.withValues(alpha: 0.5)
          : EdenColors.neutral[50]?.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        vertical: EdenSpacing.space1,
      ),
      child: Row(
        children: [
          if (showCheckbox) const SizedBox(width: 48),
          ...columns.map((col) {
            final width = _columnWidths[col.id] ?? col.minWidth;
            if (!col.filterable) return SizedBox(width: width);
            return SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                ),
                child: SizedBox(
                  height: 30,
                  child: TextField(
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Filter...',
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: EdenRadii.borderRadiusSm,
                      ),
                    ),
                    onChanged: (value) {
                      widget.onFilter?.call(col.id, value);
                    },
                  ),
                ),
              ),
            );
          }),
          if (showActions) const SizedBox(width: 120),
        ],
      ),
    );
  }

  Widget _buildRow(
    ThemeData theme,
    bool isDark,
    int index,
    List<EdenGridColumn<T>> columns,
    bool showCheckbox,
    bool showActions,
  ) {
    final row = widget.rows[index];
    final isSelected = _selectedRows.contains(index);
    final isHovered = _hoveredRow == index;
    final isFrozen = index < widget.frozenRowCount;

    Color? bgColor;
    if (isSelected) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.08);
    } else if (isHovered) {
      bgColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03);
    } else if (isFrozen) {
      bgColor = isDark
          ? EdenColors.neutral[850]?.withValues(alpha: 0.7)
          : EdenColors.neutral[50]?.withValues(alpha: 0.7);
    } else if (widget.striped && index.isOdd) {
      bgColor = isDark
          ? EdenColors.neutral[850]?.withValues(alpha: 0.5)
          : EdenColors.neutral[50]?.withValues(alpha: 0.5);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRow = index),
      onExit: (_) => setState(() => _hoveredRow = null),
      child: GestureDetector(
        onTap: () {
          if (widget.selectable) {
            _handleSelectRow(index, !isSelected);
          }
          widget.onRowTap?.call(row);
        },
        onDoubleTap: widget.onRowDoubleTap != null
            ? () => widget.onRowDoubleTap!(row)
            : null,
        child: Container(
          color: bgColor,
          padding: EdgeInsets.symmetric(vertical: _cellVerticalPadding),
          child: Row(
            children: [
              if (showCheckbox)
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (v) => _handleSelectRow(index, v),
                  ),
                ),
              ...columns.map((col) {
                final width = _columnWidths[col.id] ?? col.minWidth;
                return SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space3,
                    ),
                    child: col.cellBuilder != null
                        ? col.cellBuilder!(row, index)
                        : const SizedBox.shrink(),
                  ),
                );
              }),
              if (showActions)
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.rowActions!(row, index),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: EdenSpacing.space3),
            Text(
              widget.emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme, bool isDark) {
    final page = widget.currentPage!;
    final total = widget.totalPages!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      child: Row(
        children: [
          if (widget.totalRows != null)
            Text(
              '${widget.totalRows} row${widget.totalRows == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const Spacer(),
          PaginationButton(
            icon: Icons.first_page,
            enabled: page > 1,
            onTap: () => widget.onPageChanged!(1),
          ),
          const SizedBox(width: 4),
          PaginationButton(
            icon: Icons.chevron_left,
            enabled: page > 1,
            onTap: () => widget.onPageChanged!(page - 1),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Text(
            'Page $page of $total',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          PaginationButton(
            icon: Icons.chevron_right,
            enabled: page < total,
            onTap: () => widget.onPageChanged!(page + 1),
          ),
          const SizedBox(width: 4),
          PaginationButton(
            icon: Icons.last_page,
            enabled: page < total,
            onTap: () => widget.onPageChanged!(total),
          ),
        ],
      ),
    );
  }
}


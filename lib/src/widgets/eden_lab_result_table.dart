import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import '../utils/eden_tsv.dart';
import 'eden_chart.dart' show EdenSparkline;

/// FHIR-shape lab flag (library-owned).
enum EdenLabFlag { normal, high, low, criticalHigh, criticalLow }

/// The human label for a flag, used when copying.
///
/// Deliberately NOT the on-screen rendering. The table renders `H`, `L`, `HH`,
/// `LL` and a blank for `normal` — abbreviations that are legible in a dense
/// clinical column and meaningless in a spreadsheet, where the surrounding
/// colour and column header are gone. The label is the datum; the abbreviation
/// is the rendering.
///
/// `normal` copies as `normal` rather than the blank it renders, because an
/// empty cell in a pasted grid reads as "no flag recorded" rather than "flag
/// recorded, and it was normal".
///
/// Exhaustive `switch` with no default arm, so a new flag is a compile error
/// here until its label is decided.
extension EdenLabFlagLabel on EdenLabFlag {
  /// This flag's human-readable label.
  String get label => switch (this) {
        EdenLabFlag.normal => 'normal',
        EdenLabFlag.high => 'high',
        EdenLabFlag.low => 'low',
        EdenLabFlag.criticalHigh => 'critical high',
        EdenLabFlag.criticalLow => 'critical low',
      };
}

/// FHIR-shape lab result value class (library-owned — NOT FHIR-bound).
///
/// Maps to FHIR `Observation` resource shape for laboratory results.
@immutable
class EdenLabResult {
  const EdenLabResult({
    required this.id,
    required this.patientId,
    required this.testName,
    required this.testCode,
    required this.value,
    required this.unit,
    required this.collectedAt,
    this.referenceMin,
    this.referenceMax,
    this.criticalMin,
    this.criticalMax,
    this.flag = EdenLabFlag.normal,
    this.panelName,
    this.trendValues,
    this.notes,
  });

  final String id;
  final String patientId;
  final String testName;
  final String testCode;
  final double value;
  final String unit;
  final DateTime collectedAt;
  final double? referenceMin;
  final double? referenceMax;
  final double? criticalMin;
  final double? criticalMax;
  final EdenLabFlag flag;
  final String? panelName;
  final List<double>? trendValues;
  final String? notes;
}

enum _SortColumn { test, value, date }

/// Compact clinical-density lab result table.
///
/// Columns: Test name | Value | Unit | Reference range | Flag | Date | Trend.
/// Composes [EdenSparkline] (obj 012-07) for the trend cell.
class EdenLabResultTable extends StatefulWidget {
  EdenLabResultTable({
    super.key,
    required this.results,
    this.patientId,
    this.groupByPanel = false,
    this.showSparkline = true,
    this.onResultTap,
    this.padding,
    this.copyable = false,
  }) : assert(
          results.isEmpty ||
              results.every(
                (r) => r.patientId == (patientId ?? results.first.patientId),
              ),
          'EdenLabResultTable: results must share same patientId; '
          'received mixed PHI. Library widgets enforce HIPAA isolation.',
        );

  final List<EdenLabResult> results;
  final String? patientId;
  final bool groupByPanel;
  final bool showSparkline;
  final void Function(EdenLabResult)? onResultTap;
  final EdgeInsetsGeometry? padding;

  /// Shows a copy-table action in the header and a copy affordance per row.
  ///
  /// Off by default. `SelectionArea` concatenates a drag-selection with no cell
  /// delimiters (40-RESEARCH.md section 5), so a table that wants
  /// paste-into-a-spreadsheet behaviour has to offer it explicitly.
  ///
  /// Copied columns, in order: test name, test code, value, unit, reference
  /// range, flag, collected date, notes. Copy emits the DATA, so three of those
  /// deliberately differ from what is rendered:
  ///
  /// * the **reference range** is `min-max`, and EMPTY when both bounds are
  ///   null — the cell renders an em dash, which is a typographic placeholder,
  ///   not a value, and would paste as a literal dash into a numeric column;
  /// * the **flag** copies its human label, not the `H`/`HH` abbreviation
  ///   (see [EdenLabFlagLabel]);
  /// * the **date** is ISO-8601, not the rendered `MM/DD/YY` — a two-digit year
  ///   is ambiguous and a localised date pastes into a spreadsheet as text.
  ///
  /// `trendValues` is NOT copied. It is a SERIES behind one row — the sparkline
  /// draws it as a shape, and there is no honest single-cell representation of
  /// it: the last value alone would imply the trend was one number, and the
  /// whole series inlined would either need its own delimiter (there is none
  /// available inside a TSV cell) or would silently shift every later column.
  /// A caller who needs the series should copy it from the source record.
  ///
  /// Rows are copied in DISPLAY order — the active sort column and direction,
  /// or panel-grouped canonical order when [groupByPanel] is set.
  final bool copyable;

  @override
  State<EdenLabResultTable> createState() => _EdenLabResultTableState();
}

class _EdenLabResultTableState extends State<EdenLabResultTable> {
  _SortColumn _sortColumn = _SortColumn.date;
  bool _ascending = false;

  void _onSortHeader(_SortColumn col) {
    setState(() {
      if (_sortColumn == col) {
        _ascending = !_ascending;
      } else {
        _sortColumn = col;
        _ascending = true;
      }
    });
  }

  List<EdenLabResult> _sorted(List<EdenLabResult> input) {
    final out = [...input];
    out.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case _SortColumn.test:
          cmp = a.testName.compareTo(b.testName);
          break;
        case _SortColumn.value:
          cmp = a.value.compareTo(b.value);
          break;
        case _SortColumn.date:
          cmp = a.collectedAt.compareTo(b.collectedAt);
          break;
      }
      return _ascending ? cmp : -cmp;
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const SizedBox.shrink();
    }

    final groups = _displayGroups();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        // 7 cells × (width + 8 padding) = 510 + 56; the copy column adds
        // one more 32-wide cell carrying the same 8px of padding.
        width: widget.copyable ? 606 : 566,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              sortColumn: _sortColumn,
              ascending: _ascending,
              onSort: _onSortHeader,
              copyAction: widget.copyable ? _copyTableButton() : null,
            ),
            ...groups.entries.expand((entry) {
              final panel = entry.key;
              final rows = entry.value;
              return [
                if (widget.groupByPanel && panel != null)
                  _PanelHeader(panel: panel),
                ...rows.map(
                  (r) => _ResultRow(
                    key: ValueKey(r.id),
                    result: r,
                    showSparkline: widget.showSparkline,
                    onTap: widget.onResultTap,
                    copyAction: widget.copyable ? _copyRowButton(r) : null,
                  ),
                ),
              ];
            }),
          ],
        ),
      ),
    );
  }

  /// The rows exactly as they are rendered, grouped and ordered.
  ///
  /// Hoisted out of `build` so the copy callback and the render path read the
  /// SAME list. Deriving the order twice would let a copy silently disagree with
  /// the screen the moment either side changed — and the order here is not
  /// incidental: it is the active sort column and direction, or the panel
  /// grouping with its canonical intra-panel order.
  Map<String?, List<EdenLabResult>> _displayGroups() {
    return widget.groupByPanel
        ? _groupByPanel(widget.results)
        : <String?, List<EdenLabResult>>{null: _sorted(widget.results)};
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  /// Column labels for the copied grid. Mirrors [_resultCopyValues] exactly.
  static const List<String> _copyHeader = <String>[
    'Test',
    'Code',
    'Value',
    'Unit',
    'Range',
    'Flag',
    'Date',
    'Notes',
  ];

  /// The reference range as DATA: `min-max`, or empty when both bounds are null.
  ///
  /// Deliberately not the rendered `_formatRange`, which emits an em dash for a
  /// missing range. That dash is a typographic placeholder, not a value, and
  /// would paste as a literal character into an otherwise numeric column. The
  /// one-sided `<x` / `>x` forms ARE data and are kept.
  static String _copyRange(EdenLabResult r) {
    final double? lo = r.referenceMin;
    final double? hi = r.referenceMax;
    if (lo != null && hi != null) {
      return '${_formatValue(lo)}-${_formatValue(hi)}';
    }
    if (hi != null) return '<${_formatValue(hi)}';
    if (lo != null) return '>${_formatValue(lo)}';
    return '';
  }

  /// ISO-8601 calendar date, which is what a spreadsheet parses as a date.
  ///
  /// The cell renders `MM/DD/YY`; a two-digit year is ambiguous and a localised
  /// date pastes as text, so neither is copyable.
  static String _copyDate(DateTime d) {
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// One result reduced to its clipboard cells, in [_copyHeader] order.
  ///
  /// `trendValues` is absent by design — see [EdenLabResultTable.copyable].
  static List<String> _resultCopyValues(EdenLabResult r) => <String>[
        r.testName,
        r.testCode,
        _formatValue(r.value),
        r.unit,
        _copyRange(r),
        r.flag.label,
        _copyDate(r.collectedAt),
        r.notes ?? '',
      ];

  /// Every result in DISPLAY order, each reduced to its clipboard cells.
  List<List<String>> _visibleRowValues() => _displayGroups()
      .values
      .expand((rows) => rows)
      .map(_resultCopyValues)
      .toList();

  /// Copies the whole table: column labels first, then every row.
  ///
  /// Wrapped in [SelectionContainer.disabled] so a drag-select across the table
  /// picks up the data and not the word "Copy" (40-RESEARCH.md section 5).
  Widget _copyTableButton() {
    return SelectionContainer.disabled(
      child: IconButton(
        icon: const Icon(Icons.copy_all, size: 14),
        tooltip: 'Copy table',
        onPressed: () => edenCopyTsv(_visibleRowValues(), header: _copyHeader),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      ),
    );
  }

  /// Copies one result alone, TAB-delimited and with NO header line.
  Widget _copyRowButton(EdenLabResult r) {
    return SelectionContainer.disabled(
      child: IconButton(
        icon: const Icon(Icons.copy, size: 14),
        tooltip: 'Copy row',
        onPressed: () => edenCopyTsv(<List<String>>[_resultCopyValues(r)]),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      ),
    );
  }

  Map<String?, List<EdenLabResult>> _groupByPanel(List<EdenLabResult> input) {
    final map = <String?, List<EdenLabResult>>{};
    for (final r in input) {
      map.putIfAbsent(r.panelName, () => []).add(r);
    }
    // Canonical lab order within each panel.
    map.forEach((panel, rows) {
      rows.sort((a, b) {
        final order = _canonicalOrder[panel];
        if (order == null) {
          return a.testCode.compareTo(b.testCode);
        }
        final ai = order.indexOf(a.testCode);
        final bi = order.indexOf(b.testCode);
        if (ai == -1 && bi == -1) return a.testCode.compareTo(b.testCode);
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });
    });
    return map;
  }
}

const _canonicalOrder = <String?, List<String>>{
  'CBC': ['WBC', 'RBC', 'HGB', 'HCT', 'PLT'],
  'CMP': ['NA', 'K', 'CL', 'CO2', 'BUN', 'CR', 'GLU'],
  'Lipid Panel': ['TC', 'LDL', 'HDL', 'TG'],
};

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
    this.copyAction,
  });

  final _SortColumn sortColumn;
  final bool ascending;
  final void Function(_SortColumn) onSort;

  /// Trailing copy-table affordance, or null when the table is not copyable.
  ///
  /// Passed in already built rather than as a flag, so the header stays unaware
  /// of the clipboard and the affordance keeps the wrapping the state applied.
  final Widget? copyAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(
            width: 100,
            label: 'Test',
            style: style,
            active: sortColumn == _SortColumn.test,
            ascending: ascending,
            onTap: () => onSort(_SortColumn.test),
          ),
          _HeaderCell(
            width: 60,
            label: 'Value',
            style: style,
            active: sortColumn == _SortColumn.value,
            ascending: ascending,
            onTap: () => onSort(_SortColumn.value),
          ),
          _HeaderCell(width: 60, label: 'Unit', style: style),
          _HeaderCell(width: 90, label: 'Range', style: style),
          _HeaderCell(width: 40, label: 'Flag', style: style),
          _HeaderCell(
            width: 80,
            label: 'Date',
            style: style,
            active: sortColumn == _SortColumn.date,
            ascending: ascending,
            onTap: () => onSort(_SortColumn.date),
          ),
          _HeaderCell(width: 80, label: 'Trend', style: style),
          // Trailing affordance cell. Uses the same `_Cell` wrapper as the data
          // rows, so the copy column lines up with the buttons beneath it.
          if (copyAction != null) _Cell(width: 32, child: copyAction!),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.width,
    required this.label,
    this.style,
    this.active = false,
    this.ascending = true,
    this.onTap,
  });

  final double width;
  final String label;
  final TextStyle? style;
  final bool active;
  final bool ascending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Flexible(
                child: Text(label, style: style, overflow: TextOverflow.ellipsis),
              ),
              if (active)
                Icon(
                  ascending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.panel});
  final String panel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Text(
        panel,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.result,
    required this.showSparkline,
    this.onTap,
    this.copyAction,
  });

  final EdenLabResult result;
  final bool showSparkline;
  final void Function(EdenLabResult)? onTap;

  /// Trailing copy-row affordance, or null when the table is not copyable.
  final Widget? copyAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();

    final inner = Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Cell(
            width: 100,
            child: Text(
              result.testName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          _Cell(
            width: 60,
            child: Text(
              _formatValue(result.value),
              style: EdenTypography.monoFont.copyWith(fontSize: 13),
            ),
          ),
          _Cell(
            width: 60,
            child: Text(
              result.unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _Cell(
            width: 90,
            child: Text(
              _formatRange(result),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _Cell(width: 40, child: _FlagCell(flag: result.flag, palette: palette)),
          _Cell(
            width: 80,
            child: Text(
              _formatDate(result.collectedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          _Cell(
            width: 80,
            child: _TrendCell(
              result: result,
              showSparkline: showSparkline,
            ),
          ),
          if (copyAction != null) _Cell(width: 32, child: copyAction!),
        ],
      ),
    );

    if (onTap == null) return inner;
    return InkWell(onTap: () => onTap!(result), child: inner);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(width: width, child: Align(alignment: Alignment.centerLeft, child: child)),
    );
  }
}

class _FlagCell extends StatelessWidget {
  const _FlagCell({required this.flag, required this.palette});
  final EdenLabFlag flag;
  final EdenStatusPalette palette;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (flag) {
      case EdenLabFlag.normal:
        return const SizedBox.shrink();
      case EdenLabFlag.high:
        label = 'H';
        color = palette.warningFg;
        break;
      case EdenLabFlag.low:
        label = 'L';
        color = palette.warningFg;
        break;
      case EdenLabFlag.criticalHigh:
        label = 'HH';
        color = palette.dangerFg;
        break;
      case EdenLabFlag.criticalLow:
        label = 'LL';
        color = palette.dangerFg;
        break;
    }
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _TrendCell extends StatelessWidget {
  const _TrendCell({required this.result, required this.showSparkline});
  final EdenLabResult result;
  final bool showSparkline;

  @override
  Widget build(BuildContext context) {
    final trend = result.trendValues;
    if (trend == null || trend.isEmpty) {
      return const Text('—');
    }
    if (showSparkline) {
      return EdenSparkline(
        values: [...trend, result.value],
        height: 22,
        showArea: false,
        lineWidth: 1.5,
      );
    }
    final delta = result.value - trend.last;
    final arrow = delta > 0 ? '↑' : (delta < 0 ? '↓' : '→');
    final sign = delta > 0 ? '+' : '';
    return Text(
      '$sign${delta.toStringAsFixed(1)} $arrow',
      style: TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }
}

String _formatValue(double v) {
  if (v == v.truncateToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

String _formatRange(EdenLabResult r) {
  if (r.referenceMin != null && r.referenceMax != null) {
    return '${_formatValue(r.referenceMin!)}-${_formatValue(r.referenceMax!)}';
  }
  if (r.referenceMax != null) return '<${_formatValue(r.referenceMax!)}';
  if (r.referenceMin != null) return '>${_formatValue(r.referenceMin!)}';
  return '—';
}

String _formatDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final y = (d.year % 100).toString().padLeft(2, '0');
  return '$m/$day/$y';
}

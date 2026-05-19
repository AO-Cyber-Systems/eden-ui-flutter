import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';
import 'eden_data_table.dart';
import 'eden_empty_state.dart';

/// Cross-vertical line-item composer primitive (obj 012-01).
///
/// Foundational primitive used by POS register (retail), quote builder
/// (trades), invoice surface, claim posting (medical), fuel POD pricing,
/// and salon services.
///
/// Generic over `T` so consumers map their domain model (cart entry,
/// quote line, claim line, fuel grade, service catalog entry) to
/// `EdenLineItem<T>`.
///
/// **Fully controlled.** The widget never owns item state. Consumers pass
/// `items` + `onItemsChanged` and re-render on every change.
///
/// **Composes existing widgets.** Uses [EdenDataTable.dense] for table
/// chrome (obj 010), [EdenCurrencyDisplay] for line-total/unit-price
/// formatting (obj 001), [EdenCard] for stacked-card narrow mode.
class EdenLineItem<T> {
  const EdenLineItem({
    required this.id,
    required this.payload,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount,
    this.taxRate,
    this.note,
    this.modifiers = const [],
  });

  /// Stable identity for TextField controller keying and reorder semantics.
  /// Consumers MUST provide stable IDs (e.g. domain primary key, UUID).
  final String id;

  /// Consumer-typed payload — typically the domain model wrapped by this row.
  final T payload;

  final String description;
  final double quantity;
  final double unitPrice;

  /// Flat discount amount in dollars (NOT a percentage). Defaults to null
  /// (no discount). Negative values are not validated — consumers gate.
  final double? discountAmount;

  /// Tax rate as a fraction (0.0825 = 8.25%). Defaults to null (no tax).
  final double? taxRate;

  /// Free-form note (not rendered in the default columns; surfaced via
  /// [EdenLineItemColumn.custom] when consumers wire a custom column).
  final String? note;

  /// Optional list of modifier strings rendered below the description
  /// (e.g. "Oat milk", "Extra shot" for a POS beverage line item).
  /// Displayed in both table mode and stacked-card mode. Defaults to [].
  final List<String> modifiers;

  /// Subtotal — quantity × unitPrice. Allocates one double; safe per render.
  double get subtotal => quantity * unitPrice;

  /// Discounted subtotal — subtotal − discountAmount (or subtotal when
  /// discountAmount is null).
  double get discounted => subtotal - (discountAmount ?? 0);

  /// Final line total — discounted × (1 + taxRate) (or discounted when
  /// taxRate is null). Allowed to be negative when discountAmount exceeds
  /// subtotal; UI highlights negative totals in [EdenStatusPalette.dangerFg]
  /// (or [EdenColors.error] fallback) and announces via Semantics.
  double get lineTotal => discounted * (1 + (taxRate ?? 0));

  EdenLineItem<T> copyWith({
    String? id,
    T? payload,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? taxRate,
    String? note,
    List<String>? modifiers,
  }) =>
      EdenLineItem<T>(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discountAmount: discountAmount ?? this.discountAmount,
        taxRate: taxRate ?? this.taxRate,
        note: note ?? this.note,
        modifiers: modifiers ?? this.modifiers,
      );
}

/// Columns the [EdenLineItemEditor] can show. Default visible set is
/// `[description, quantity, unitPrice, lineTotal, remove]`.
///
/// `reorderHandle` is only meaningful in stacked-card (narrow) mode.
/// `custom` renders via [EdenLineItemEditor.customColumnBuilder] when set.
enum EdenLineItemColumn {
  description,
  quantity,
  unitPrice,
  discount,
  tax,
  lineTotal,
  remove,
  reorderHandle,
  custom,
}

extension _EdenLineItemColumnLabel on EdenLineItemColumn {
  /// Header label rendered above the column in table mode.
  String get headerLabel {
    switch (this) {
      case EdenLineItemColumn.description:
        return 'Description';
      case EdenLineItemColumn.quantity:
        return 'Qty';
      case EdenLineItemColumn.unitPrice:
        return 'Unit';
      case EdenLineItemColumn.discount:
        return 'Discount';
      case EdenLineItemColumn.tax:
        return 'Tax';
      case EdenLineItemColumn.lineTotal:
        return 'Total';
      case EdenLineItemColumn.remove:
        return '';
      case EdenLineItemColumn.reorderHandle:
        return '';
      case EdenLineItemColumn.custom:
        return '';
    }
  }

  /// Semantics-friendly display name used in cell labels
  /// ("Quantity for line item Coffee — Large").
  String get semanticsName {
    switch (this) {
      case EdenLineItemColumn.description:
        return 'Description';
      case EdenLineItemColumn.quantity:
        return 'Quantity';
      case EdenLineItemColumn.unitPrice:
        return 'Unit price';
      case EdenLineItemColumn.discount:
        return 'Discount';
      case EdenLineItemColumn.tax:
        return 'Tax rate';
      case EdenLineItemColumn.lineTotal:
        return 'Line total';
      case EdenLineItemColumn.remove:
        return 'Remove';
      case EdenLineItemColumn.reorderHandle:
        return 'Reorder';
      case EdenLineItemColumn.custom:
        return 'Custom';
    }
  }

  /// Relative width hint for the EdenDataTable.dense flex layout.
  int get flex {
    switch (this) {
      case EdenLineItemColumn.description:
        return 4;
      case EdenLineItemColumn.quantity:
      case EdenLineItemColumn.unitPrice:
      case EdenLineItemColumn.discount:
      case EdenLineItemColumn.tax:
      case EdenLineItemColumn.lineTotal:
        return 2;
      case EdenLineItemColumn.remove:
      case EdenLineItemColumn.reorderHandle:
        return 1;
      case EdenLineItemColumn.custom:
        return 2;
    }
  }
}

/// Composable line-item table primitive.
///
/// See class-level comment on [EdenLineItem] for the broader composition
/// pattern. This widget renders a row per item and routes edits through
/// [onItemsChanged]. Add-row UX is consumer-owned via [itemPickerSlot]
/// (vertical-specific add affordance — product grid, CPT-code picker,
/// fuel-grade chips, etc.).
///
/// ## New props added in PCF-12 / obj 012-01 enhancement
///
/// * [showQtyStepperInTableMode] — when `true`, the Qty column in table mode
///   renders +/− stepper buttons instead of a plain TextField. Defaults to
///   `false` for backward compatibility.
/// * [onTotalsComputed] — optional callback fired every build with a
///   `Map<String, double>` keyed `'subtotal'` and `'total'` (sum of all
///   `item.lineTotal`). Useful for parent widgets that want to mirror totals
///   without composing [EdenLineItemEditorTotalsBar] themselves.
///
/// ## [EdenLineItem.modifiers] rendering
///
/// When any `item.modifiers` is non-empty, modifier strings are rendered
/// below the description text in a smaller secondary style (both table and
/// stacked-card modes).
///
/// ## Responsive behavior
///
/// * `constraints.maxWidth >= narrowBreakpointPt` (default 600) →
///   table mode via [EdenDataTable.dense].
/// * `constraints.maxWidth < narrowBreakpointPt` → stacked-card mode
///   (one [EdenCard] per item). Reorder gestures are only active in
///   stacked-card mode (table mode hides the reorder handle column).
///
/// ## Negative line-total highlighting
///
/// When `item.lineTotal < 0` (discount exceeds subtotal), the line-total
/// cell renders in [EdenStatusPalette.dangerFg] (or [EdenColors.error] if
/// the EdenAdaptiveTheme is absent), and a Semantics announcement
/// "Negative line total: `<description>`" is emitted.
class EdenLineItemEditor<T> extends StatefulWidget {
  const EdenLineItemEditor({
    super.key,
    required this.items,
    required this.onItemsChanged,
    this.visibleColumns = const [
      EdenLineItemColumn.description,
      EdenLineItemColumn.quantity,
      EdenLineItemColumn.unitPrice,
      EdenLineItemColumn.lineTotal,
      EdenLineItemColumn.remove,
    ],
    this.reorderable = false,
    this.readOnly = false,
    this.customColumnBuilder,
    this.itemPickerSlot,
    this.footerSlot,
    this.currencyCode = 'USD',
    this.narrowBreakpointPt = 600,
    this.showQtyStepperInTableMode = false,
    this.onTotalsComputed,
  });

  final List<EdenLineItem<T>> items;
  final ValueChanged<List<EdenLineItem<T>>> onItemsChanged;
  final List<EdenLineItemColumn> visibleColumns;
  final bool reorderable;
  final bool readOnly;
  final Widget Function(BuildContext, EdenLineItem<T>, int)? customColumnBuilder;
  final Widget? itemPickerSlot;
  final Widget? footerSlot;
  final String currencyCode;
  final double narrowBreakpointPt;

  /// When `true`, the Qty column in table mode renders +/− stepper buttons
  /// alongside the quantity display instead of a plain editable [TextField].
  /// Defaults to `false` — existing consumers are unaffected.
  final bool showQtyStepperInTableMode;

  /// Optional callback fired every time the widget builds, providing computed
  /// totals over all items:
  ///
  /// * `'subtotal'` — sum of `item.subtotal` (before discount/tax).
  /// * `'totalDiscount'` — sum of `item.discountAmount ?? 0`.
  /// * `'total'` — sum of `item.lineTotal` (after discount + tax).
  ///
  /// Consumers can use this to mirror totals without composing
  /// [EdenLineItemEditorTotalsBar] directly.
  final void Function(Map<String, double>)? onTotalsComputed;

  @override
  State<EdenLineItemEditor<T>> createState() => _EdenLineItemEditorState<T>();
}

class _EdenLineItemEditorState<T> extends State<EdenLineItemEditor<T>> {
  /// Controllers keyed by `"<item.id>-<column.name>"` so cursor position
  /// + draft text survive rebuilds. Lazily created on first paint of each
  /// editable cell and disposed in [dispose].
  final Map<String, TextEditingController> _controllers = {};

  /// Tracks line items previously seen as having negative totals so the
  /// Semantics announcement fires only on the leading edge (avoids
  /// spamming the screen reader on every rebuild).
  final Set<String> _announcedNegativeIds = <String>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  TextEditingController _controllerFor(
    String itemId,
    EdenLineItemColumn column,
    String initialText,
  ) {
    final key = '$itemId-${column.name}';
    final existing = _controllers[key];
    if (existing != null) {
      // Sync controller text on prop-change without disturbing cursor
      // unless the values actually differ (avoids cursor reset on parent
      // rebuilds with identical row data).
      if (existing.text != initialText) {
        existing.value = TextEditingValue(
          text: initialText,
          selection: TextSelection.collapsed(offset: initialText.length),
        );
      }
      return existing;
    }
    final created = TextEditingController(text: initialText);
    _controllers[key] = created;
    return created;
  }

  Color _dangerColor(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    return palette?.dangerFg ?? EdenColors.error;
  }

  /// Decimal-friendly input filter. Allows digits and a single decimal
  /// point. Rejects leading minus and non-numeric characters. The
  /// `FilteringTextInputFormatter.allow` semantics keep only characters
  /// that individually match the pattern, so we constrain to `[0-9.]`
  /// and rely on `double.tryParse` to discard malformed multi-period
  /// strings (e.g. `'2.5.3'` → tryParse returns null → no emit).
  static final RegExp _decimalRegex = RegExp(r'[0-9.]');

  TextInputFormatter _decimalFormatter() =>
      FilteringTextInputFormatter.allow(_decimalRegex);

  void _emitChange(int index, EdenLineItem<T> updated) {
    final next = List<EdenLineItem<T>>.from(widget.items);
    next[index] = updated;
    widget.onItemsChanged(next);
  }

  void _handleRemove(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    final removingId = widget.items[index].id;
    final next = List<EdenLineItem<T>>.from(widget.items)..removeAt(index);
    // Dispose controllers for the removed row so we don't leak.
    final keysToDrop = _controllers.keys
        .where((k) => k.startsWith('$removingId-'))
        .toList();
    for (final k in keysToDrop) {
      _controllers.remove(k)?.dispose();
    }
    _announcedNegativeIds.remove(removingId);
    widget.onItemsChanged(next);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    // Flutter ReorderableListView quirk: when moving down, newIndex is +1
    // of the visual target. Mirror the eden_route_stop_list.dart pattern.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final reordered = List<EdenLineItem<T>>.from(widget.items);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, item);
    widget.onItemsChanged(reordered);
  }

  String _formatDoubleForField(double value) {
    // Render quantity 2.0 as '2', 2.5 as '2.5', 0.125 as '0.125'.
    if (value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isNarrow = constraints.maxWidth < widget.narrowBreakpointPt;
      final body = widget.items.isEmpty
          ? _buildEmptyState(ctx)
          : (isNarrow ? _buildStackedCardMode(ctx) : _buildTableMode(ctx));

      // Announce newly-negative line totals via Semantics announcements.
      _maybeAnnounceNegatives();

      // Fire onTotalsComputed on each build with fresh aggregate values.
      _maybeFireTotalsCallback();

      final children = <Widget>[];
      if (widget.itemPickerSlot != null) {
        children.add(widget.itemPickerSlot!);
        children.add(const SizedBox(height: EdenSpacing.space2));
      }
      children.add(body);
      if (widget.footerSlot != null) {
        children.add(const SizedBox(height: EdenSpacing.space2));
        children.add(widget.footerSlot!);
      }

      if (children.length == 1) return body;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });
  }

  void _maybeFireTotalsCallback() {
    final cb = widget.onTotalsComputed;
    if (cb == null) return;
    double subtotal = 0;
    double totalDiscount = 0;
    double total = 0;
    for (final item in widget.items) {
      subtotal += item.subtotal;
      totalDiscount += item.discountAmount ?? 0;
      total += item.lineTotal;
    }
    // Schedule post-frame so we don't call setState-like callbacks during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        cb({
          'subtotal': subtotal,
          'totalDiscount': totalDiscount,
          'total': total,
        });
      }
    });
  }

  void _maybeAnnounceNegatives() {
    final newlyNegative = <String>{};
    for (final item in widget.items) {
      if (item.lineTotal < 0 && !_announcedNegativeIds.contains(item.id)) {
        newlyNegative.add(item.id);
        // sendAnnouncement is the modern API but it requires a FlutterView
        // arg that varies by SDK; the deprecated form is still emitted by
        // the framework on 3.41 and is the lowest-friction cross-version
        // path for accessibility announcements.
        // ignore: deprecated_member_use
        SemanticsService.announce(
          'Negative line total: ${item.description}',
          TextDirection.ltr,
        );
      }
      if (item.lineTotal >= 0) {
        _announcedNegativeIds.remove(item.id);
      }
    }
    _announcedNegativeIds.addAll(newlyNegative);
  }

  // ───────────────────────────── Empty state ─────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: EdenSpacing.space4),
      child: EdenEmptyState(
        title: 'No items yet',
        icon: Icons.list_alt_outlined,
      ),
    );
  }

  // ───────────────────────────── Table mode ──────────────────────────────

  /// Columns to render in table mode (filters out reorderHandle which is
  /// only meaningful in stacked-card mode).
  List<EdenLineItemColumn> get _tableColumns => widget.visibleColumns
      .where((c) => c != EdenLineItemColumn.reorderHandle)
      .toList(growable: false);

  Widget _buildTableMode(BuildContext context) {
    final columns = _tableColumns;
    final dataColumns = columns
        .map((c) => EdenTableColumn(label: c.headerLabel, flex: c.flex))
        .toList(growable: false);

    final rows = <EdenTableRow>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      rows.add(EdenTableRow(
        cells: columns.map((col) => _buildCell(context, col, item, i)).toList(),
      ));
    }

    // EdenDataTable.dense uses LayoutBuilder + ListView.builder internally;
    // without an explicit bounded height it defaults to 400pt. Force the
    // body height to match the actual content (header + rows × row height).
    const headerHeight = 32.0;
    const rowHeight = 32.0;
    const chrome = 1.0 + 2.0; // divider + container border
    final desiredHeight =
        headerHeight + chrome + rowHeight * widget.items.length;

    return SizedBox(
      height: desiredHeight,
      child: EdenDataTable.dense(
        columns: dataColumns,
        rows: rows,
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    EdenLineItemColumn column,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    switch (column) {
      case EdenLineItemColumn.description:
        return _buildDescriptionCell(context, item, rowIndex);
      case EdenLineItemColumn.quantity:
        return _buildQuantityCell(context, item, rowIndex);
      case EdenLineItemColumn.unitPrice:
        return _buildUnitPriceCell(context, item, rowIndex);
      case EdenLineItemColumn.discount:
        return _buildDiscountCell(context, item, rowIndex);
      case EdenLineItemColumn.tax:
        return _buildTaxCell(context, item, rowIndex);
      case EdenLineItemColumn.lineTotal:
        return _buildLineTotalCell(context, item);
      case EdenLineItemColumn.remove:
        return _buildRemoveCell(context, item, rowIndex);
      case EdenLineItemColumn.reorderHandle:
        // Hidden in table mode; emit a shrink box so column counts line up.
        return const SizedBox.shrink();
      case EdenLineItemColumn.custom:
        if (widget.customColumnBuilder == null) {
          return const SizedBox.shrink();
        }
        return widget.customColumnBuilder!(context, item, rowIndex);
    }
  }

  Widget _semanticsWrap(
    EdenLineItemColumn column,
    EdenLineItem<T> item,
    Widget child,
  ) {
    return Semantics(
      label: '${column.semanticsName} for line item ${item.description}',
      child: child,
    );
  }

  Widget _buildDescriptionCell(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    final theme = Theme.of(context);
    final modifierStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.6),
    );

    Widget modifiersWidget = const SizedBox.shrink();
    if (item.modifiers.isNotEmpty) {
      modifiersWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: item.modifiers
            .map((m) => Text(m, style: modifierStyle, overflow: TextOverflow.ellipsis))
            .toList(),
      );
    }

    if (widget.readOnly) {
      return _semanticsWrap(
        EdenLineItemColumn.description,
        item,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, overflow: TextOverflow.ellipsis),
            modifiersWidget,
          ],
        ),
      );
    }
    final controller = _controllerFor(
      item.id,
      EdenLineItemColumn.description,
      item.description,
    );
    return _semanticsWrap(
      EdenLineItemColumn.description,
      item,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodySmall,
            onChanged: (value) => _emitChange(
              rowIndex,
              item.copyWith(description: value),
            ),
          ),
          modifiersWidget,
        ],
      ),
    );
  }

  Widget _buildQuantityCell(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    if (widget.readOnly) {
      return _semanticsWrap(
        EdenLineItemColumn.quantity,
        item,
        Text(_formatDoubleForField(item.quantity)),
      );
    }
    // When showQtyStepperInTableMode is true, render the same +/- stepper
    // that stacked-card mode uses. This gives POS-style table UX.
    if (widget.showQtyStepperInTableMode) {
      return _buildQtyStepper(context, item, rowIndex);
    }
    final controller = _controllerFor(
      item.id,
      EdenLineItemColumn.quantity,
      _formatDoubleForField(item.quantity),
    );
    return _semanticsWrap(
      EdenLineItemColumn.quantity,
      item,
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_decimalFormatter()],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodySmall,
        onChanged: (raw) {
          final parsed = double.tryParse(raw);
          if (parsed == null) return;
          _emitChange(rowIndex, item.copyWith(quantity: parsed));
        },
      ),
    );
  }

  Widget _buildUnitPriceCell(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    if (widget.readOnly) {
      return _semanticsWrap(
        EdenLineItemColumn.unitPrice,
        item,
        EdenCurrencyDisplay(
          cents: (item.unitPrice * 100).round(),
          currencyCode: widget.currencyCode,
        ),
      );
    }
    final controller = _controllerFor(
      item.id,
      EdenLineItemColumn.unitPrice,
      _formatDoubleForField(item.unitPrice),
    );
    return _semanticsWrap(
      EdenLineItemColumn.unitPrice,
      item,
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_decimalFormatter()],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodySmall,
        onChanged: (raw) {
          final parsed = double.tryParse(raw);
          if (parsed == null) return;
          _emitChange(rowIndex, item.copyWith(unitPrice: parsed));
        },
      ),
    );
  }

  Widget _buildDiscountCell(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    final initial = item.discountAmount == null
        ? ''
        : _formatDoubleForField(item.discountAmount!);
    if (widget.readOnly) {
      return _semanticsWrap(
        EdenLineItemColumn.discount,
        item,
        Text(initial.isEmpty ? '—' : initial),
      );
    }
    final controller = _controllerFor(
      item.id,
      EdenLineItemColumn.discount,
      initial,
    );
    return _semanticsWrap(
      EdenLineItemColumn.discount,
      item,
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_decimalFormatter()],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodySmall,
        onChanged: (raw) {
          if (raw.isEmpty) {
            _emitChange(rowIndex, item.copyWith(discountAmount: null));
            return;
          }
          final parsed = double.tryParse(raw);
          if (parsed == null) return;
          _emitChange(
            rowIndex,
            item.copyWith(discountAmount: parsed),
          );
        },
      ),
    );
  }

  Widget _buildTaxCell(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    final initial =
        item.taxRate == null ? '' : _formatDoubleForField(item.taxRate!);
    if (widget.readOnly) {
      return _semanticsWrap(
        EdenLineItemColumn.tax,
        item,
        Text(initial.isEmpty ? '—' : initial),
      );
    }
    final controller = _controllerFor(
      item.id,
      EdenLineItemColumn.tax,
      initial,
    );
    return _semanticsWrap(
      EdenLineItemColumn.tax,
      item,
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_decimalFormatter()],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodySmall,
        onChanged: (raw) {
          if (raw.isEmpty) {
            _emitChange(rowIndex, item.copyWith(taxRate: null));
            return;
          }
          final parsed = double.tryParse(raw);
          if (parsed == null) return;
          _emitChange(rowIndex, item.copyWith(taxRate: parsed));
        },
      ),
    );
  }

  Widget _buildLineTotalCell(
    BuildContext context,
    EdenLineItem<T> item,
  ) {
    final cents = (item.lineTotal * 100).round();
    final isNegative = item.lineTotal < 0;
    final danger = _dangerColor(context);
    final style = isNegative
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: danger)
        : null;
    return _semanticsWrap(
      EdenLineItemColumn.lineTotal,
      item,
      EdenCurrencyDisplay(
        cents: cents,
        currencyCode: widget.currencyCode,
        style: style,
      ),
    );
  }

  Widget _buildRemoveCell(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    if (widget.readOnly) return const SizedBox.shrink();
    return Tooltip(
      message: 'Remove line item: ${item.description}',
      child: Semantics(
        label: 'Remove line item: ${item.description}',
        button: true,
        child: IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: () => _handleRemove(rowIndex),
        ),
      ),
    );
  }

  // ─────────────────────────── Stacked-card mode ──────────────────────────

  Widget _buildStackedCardMode(BuildContext context) {
    if (!widget.reorderable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < widget.items.length; i++)
            Padding(
              key: ValueKey('card-${widget.items[i].id}'),
              padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
              child: _buildItemCard(context, widget.items[i], i, draggable: false),
            ),
        ],
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: widget.items.length,
      onReorder: _handleReorder,
      itemBuilder: (ctx, i) {
        final item = widget.items[i];
        return Padding(
          key: ValueKey('reorder-${item.id}'),
          padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
          child: _buildItemCard(context, item, i, draggable: true),
        );
      },
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex, {
    required bool draggable,
  }) {
    final isNegative = item.lineTotal < 0;
    final danger = _dangerColor(context);
    final totalCents = (item.lineTotal * 100).round();
    return EdenCard(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (draggable)
                ReorderableDragStartListener(
                  index: rowIndex,
                  child: const Padding(
                    padding: EdgeInsets.only(right: EdenSpacing.space2),
                    child: Icon(Icons.drag_indicator, size: 20),
                  ),
                ),
              Expanded(child: _buildDescriptionCell(context, item, rowIndex)),
              if (!widget.readOnly) _buildRemoveCell(context, item, rowIndex),
            ],
          ),
          const SizedBox(height: EdenSpacing.space2),
          Row(
            children: [
              Expanded(child: _buildQtyStepper(context, item, rowIndex)),
              const SizedBox(width: EdenSpacing.space2),
              Expanded(child: _buildUnitPriceCell(context, item, rowIndex)),
            ],
          ),
          if (widget.visibleColumns.contains(EdenLineItemColumn.discount)) ...[
            const SizedBox(height: EdenSpacing.space2),
            _buildDiscountCell(context, item, rowIndex),
          ],
          if (widget.visibleColumns.contains(EdenLineItemColumn.tax)) ...[
            const SizedBox(height: EdenSpacing.space2),
            _buildTaxCell(context, item, rowIndex),
          ],
          const SizedBox(height: EdenSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.labelMedium),
              EdenCurrencyDisplay(
                cents: totalCents,
                currencyCode: widget.currencyCode,
                style: isNegative
                    ? Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: danger, fontWeight: FontWeight.w700)
                    : Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (widget.visibleColumns.contains(EdenLineItemColumn.custom) &&
              widget.customColumnBuilder != null) ...[
            const SizedBox(height: EdenSpacing.space2),
            widget.customColumnBuilder!(context, item, rowIndex),
          ],
        ],
      ),
    );
  }

  Widget _buildQtyStepper(
    BuildContext context,
    EdenLineItem<T> item,
    int rowIndex,
  ) {
    if (widget.readOnly) {
      return _semanticsWrap(
        EdenLineItemColumn.quantity,
        item,
        Text('Qty: ${_formatDoubleForField(item.quantity)}'),
      );
    }
    final qty = item.quantity;
    return _semanticsWrap(
      EdenLineItemColumn.quantity,
      item,
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Decrease quantity',
            onPressed: () {
              final next = (qty - 1).clamp(0.0, double.infinity);
              _emitChange(rowIndex, item.copyWith(quantity: next));
              // Sync controller so a subsequent table render reflects the change.
              final key = '${item.id}-${EdenLineItemColumn.quantity.name}';
              _controllers[key]?.text = _formatDoubleForField(next);
            },
          ),
          Expanded(
            child: Center(
              child: Text(_formatDoubleForField(qty)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Increase quantity',
            onPressed: () {
              final next = qty + 1;
              _emitChange(rowIndex, item.copyWith(quantity: next));
              final key = '${item.id}-${EdenLineItemColumn.quantity.name}';
              _controllers[key]?.text = _formatDoubleForField(next);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EdenLineItemEditorTotalsBar
// ─────────────────────────────────────────────────────────────────────────────

/// Computed totals display for use below an [EdenLineItemEditor].
///
/// Renders a Subtotal row, a conditional Discounts row (only shown when any
/// item has a non-zero [EdenLineItem.discountAmount]), and a bold Total row.
/// Intended to be passed as [EdenLineItemEditor.footerSlot] or rendered
/// independently by consumer layouts.
///
/// **Fully presentational** — pass the same `items` list you give to
/// [EdenLineItemEditor]. No state is owned; re-renders on every `items` change.
///
/// ```dart
/// EdenLineItemEditor<CartItem>(
///   items: edenItems,
///   onItemsChanged: ...,
///   footerSlot: EdenLineItemEditorTotalsBar<CartItem>(
///     items: edenItems,
///     currencyCode: 'USD',
///   ),
/// )
/// ```
class EdenLineItemEditorTotalsBar<T> extends StatelessWidget {
  const EdenLineItemEditorTotalsBar({
    super.key,
    required this.items,
    this.currencyCode = 'USD',
    this.padding = const EdgeInsets.symmetric(
      horizontal: EdenSpacing.space4,
      vertical: EdenSpacing.space3,
    ),
  });

  final List<EdenLineItem<T>> items;

  /// ISO 4217 currency code passed through to [EdenCurrencyDisplay].
  final String currencyCode;

  /// Padding around the totals column. Defaults to horizontal 16pt / vertical
  /// 12pt to match the POS cart panel spacing.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    double subtotal = 0;
    double totalDiscount = 0;
    double total = 0;
    for (final item in items) {
      subtotal += item.subtotal;
      totalDiscount += item.discountAmount ?? 0;
      total += item.lineTotal;
    }

    final subtotalCents = (subtotal * 100).round();
    final discountCents = (totalDiscount * 100).round();
    final totalCents = (total * 100).round();

    final hasDiscount = discountCents > 0;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalsRow(
            label: 'Subtotal',
            cents: subtotalCents,
            currencyCode: currencyCode,
            style: textTheme.bodyMedium,
          ),
          if (hasDiscount)
            _TotalsRow(
              label: 'Discounts',
              cents: discountCents,
              currencyCode: currencyCode,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
              prefix: '- ',
            ),
          const SizedBox(height: EdenSpacing.space1),
          _TotalsRow(
            label: 'Total',
            cents: totalCents,
            currencyCode: currencyCode,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.cents,
    required this.currencyCode,
    this.style,
    this.prefix = '',
  });

  final String label;
  final int cents;
  final String currencyCode;
  final TextStyle? style;

  /// Optional string prefix prepended before the formatted currency value
  /// (e.g. `'- '` for the discounts row).
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefix.isNotEmpty)
                Text(prefix, style: style),
              EdenCurrencyDisplay(
                cents: cents,
                currencyCode: currencyCode,
                style: style,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

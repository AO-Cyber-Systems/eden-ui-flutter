import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_adaptive_layout.dart';
import 'eden_currency_display.dart';
import 'eden_input.dart';
import 'eden_stock_level_indicator.dart';

// ───────────────────────────────────────────────────────────────────────────
// Value classes
// ───────────────────────────────────────────────────────────────────────────

/// Single inventory row payload — generic across retail / salon back-bar /
/// trades truck stock / fuel parts / medical supplies. Consumer maps domain
/// onto this shape.
@immutable
class EdenInventoryRowData {
  const EdenInventoryRowData({
    required this.rowId,
    required this.sku,
    required this.name,
    this.costCents,
    this.priceCents,
    this.onHand,
    this.reorderPoint,
    this.location,
    this.currency = 'USD',
    this.unitLabel = 'ea',
  });

  final String rowId;
  final String sku;
  final String name;
  final int? costCents;
  final int? priceCents;
  final int? onHand;
  final int? reorderPoint;
  final String? location;
  final String currency;
  final String unitLabel;
}

/// Edit submission payload. Only fields the user actually changed are
/// populated — all other fields stay `null` so the consumer's onCommit
/// handler can issue a minimal PATCH/UPDATE.
@immutable
class EdenInventoryRowDraft {
  const EdenInventoryRowDraft({
    required this.rowId,
    this.costCents,
    this.priceCents,
    this.onHand,
    this.reorderPoint,
    this.location,
  });

  final String rowId;
  final int? costCents;
  final int? priceCents;
  final int? onHand;
  final int? reorderPoint;
  final String? location;

  bool get hasAnyChange =>
      costCents != null ||
      priceCents != null ||
      onHand != null ||
      reorderPoint != null ||
      location != null;
}

// ───────────────────────────────────────────────────────────────────────────
// EdenInventoryRowEditor
// ───────────────────────────────────────────────────────────────────────────

/// Inline-edit row primitive for inventory lists. SKU + name read-only;
/// cost / price / onHand / reorderPoint / location editable when
/// `editable: true`. Bulk-select checkbox at leading edge wired to
/// `selected` + `onSelectionChanged`.
///
/// Composes existing primitives: [EdenCurrencyDisplay] for read-only money
/// cells; [EdenInput] for editable cells; [EdenStockLevelIndicator] for
/// stock gauge when both [EdenInventoryRowData.onHand] and
/// [EdenInventoryRowData.reorderPoint] are non-null (or binary mode when
/// only `onHand` is set).
///
/// Layout — auto-derives compact (2-row stack) vs expanded (single row)
/// via [LayoutBuilder] constraints:
/// - `< 700pt` → compact 2-row layout.
/// - `>= 700pt` → expanded single-row layout.
///
/// Explicit [compact] param wins; [EdenAdaptiveTierScope.maybeOf]
/// ancestor's [EdenAdaptiveTier.compact] tier also forces compact.
///
/// Controlled component pattern: the consumer owns the `editable` flag;
/// the widget commits drafts via [onCommit] and signals discard via
/// [onCancel]. The consumer is expected to flip `editable` back to
/// `false` (and update the underlying row data) after a successful
/// commit.
class EdenInventoryRowEditor extends StatefulWidget {
  const EdenInventoryRowEditor({
    super.key,
    required this.data,
    this.editable = false,
    this.selected = false,
    this.onSelectionChanged,
    this.onCommit,
    this.onCancel,
    this.onRequestEdit,
    this.compact,
  });

  final EdenInventoryRowData data;
  final bool editable;
  final bool selected;

  /// `(rowId, newSelectedValue)`. When null, the bulk-select checkbox is
  /// rendered disabled.
  final void Function(String rowId, bool selected)? onSelectionChanged;

  /// Fires on Save. The draft only carries fields the user changed.
  final void Function(EdenInventoryRowDraft draft)? onCommit;

  /// Fires on Cancel (no commit).
  final VoidCallback? onCancel;

  /// Fires when the user taps the edit-pencil icon while `editable: false`.
  /// Consumer is expected to flip `editable` to true.
  final VoidCallback? onRequestEdit;

  /// Explicit override for compact vs expanded layout. When `null`,
  /// auto-derives from constraints + [EdenAdaptiveTierScope].
  final bool? compact;

  @override
  State<EdenInventoryRowEditor> createState() => _EdenInventoryRowEditorState();
}

class _EdenInventoryRowEditorState extends State<EdenInventoryRowEditor> {
  late TextEditingController _costCtl;
  late TextEditingController _priceCtl;
  late TextEditingController _onHandCtl;
  late TextEditingController _reorderCtl;
  late TextEditingController _locationCtl;

  String _centsToStr(int? cents) =>
      cents == null ? '' : (cents / 100).toStringAsFixed(2);

  int? _strToCents(String s) {
    if (s.trim().isEmpty) return null;
    final v = double.tryParse(s);
    if (v == null) return null;
    return (v * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _costCtl = TextEditingController(text: _centsToStr(widget.data.costCents));
    _priceCtl = TextEditingController(text: _centsToStr(widget.data.priceCents));
    _onHandCtl =
        TextEditingController(text: widget.data.onHand?.toString() ?? '');
    _reorderCtl =
        TextEditingController(text: widget.data.reorderPoint?.toString() ?? '');
    _locationCtl = TextEditingController(text: widget.data.location ?? '');
  }

  @override
  void didUpdateWidget(covariant EdenInventoryRowEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the row data changes from above (e.g., post-commit refresh),
    // reset the in-flight draft controllers to the new baseline.
    if (oldWidget.data.rowId != widget.data.rowId ||
        oldWidget.data.costCents != widget.data.costCents ||
        oldWidget.data.priceCents != widget.data.priceCents ||
        oldWidget.data.onHand != widget.data.onHand ||
        oldWidget.data.reorderPoint != widget.data.reorderPoint ||
        oldWidget.data.location != widget.data.location) {
      _costCtl.text = _centsToStr(widget.data.costCents);
      _priceCtl.text = _centsToStr(widget.data.priceCents);
      _onHandCtl.text = widget.data.onHand?.toString() ?? '';
      _reorderCtl.text = widget.data.reorderPoint?.toString() ?? '';
      _locationCtl.text = widget.data.location ?? '';
    }
  }

  @override
  void dispose() {
    _costCtl.dispose();
    _priceCtl.dispose();
    _onHandCtl.dispose();
    _reorderCtl.dispose();
    _locationCtl.dispose();
    super.dispose();
  }

  EdenInventoryRowDraft _buildDraft() {
    final origCost = widget.data.costCents;
    final newCost = _strToCents(_costCtl.text);
    final origPrice = widget.data.priceCents;
    final newPrice = _strToCents(_priceCtl.text);
    final origOnHand = widget.data.onHand;
    final newOnHand = int.tryParse(_onHandCtl.text);
    final origReorder = widget.data.reorderPoint;
    final newReorder = int.tryParse(_reorderCtl.text);
    final origLocation = widget.data.location ?? '';
    final newLocation = _locationCtl.text;
    return EdenInventoryRowDraft(
      rowId: widget.data.rowId,
      costCents: newCost != origCost ? newCost : null,
      priceCents: newPrice != origPrice ? newPrice : null,
      onHand: newOnHand != origOnHand ? newOnHand : null,
      reorderPoint: newReorder != origReorder ? newReorder : null,
      location: newLocation != origLocation ? newLocation : null,
    );
  }

  ({int currentStock, int reorderPoint})? _stockArgs() {
    final h = widget.data.onHand;
    if (h == null) return null;
    final rp = widget.data.reorderPoint;
    if (rp == null || rp <= 0) {
      // Binary in-stock vs out-of-stock — pass reorderPoint=0 to
      // EdenStockLevelIndicator which falls back to max=100.
      return (currentStock: h, reorderPoint: 0);
    }
    return (currentStock: h, reorderPoint: rp);
  }

  bool _resolveCompact(BuildContext context, double maxWidth) {
    if (widget.compact != null) return widget.compact!;
    final tier = EdenAdaptiveTierScope.maybeOf(context);
    if (tier == EdenAdaptiveTier.compact) return true;
    return maxWidth < 700;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _resolveCompact(context, constraints.maxWidth);
        return isCompact ? _buildCompact(context) : _buildExpanded(context);
      },
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final theme = Theme.of(context);
    final stock = _stockArgs();
    // Minimum width when name has its own Flex slot. ~660pt covers all
    // fixed-width cells + 40pt for the name column.
    return LayoutBuilder(
      key: const ValueKey('eden-inventory-row-expanded'),
      builder: (context, c) {
        final fixedCellsWidth =
            40 + 100 + 80 + 80 + 60 + 60 + 100 + (stock != null ? 40 : 0);
        // 96pt for actions cell (worst-case Save+Cancel icon pair).
        const actionsWidth = 96.0;
        const namePreferredMin = 80.0;
        final minRowWidth =
            fixedCellsWidth + actionsWidth + namePreferredMin;
        if (c.maxWidth >= minRowWidth) {
          return _expandedRow(theme, stock, useExpanded: true, width: null);
        }
        // Consumer forced expanded at narrow width — wrap in horizontal
        // scroll so cells stay readable instead of overflowing.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minRowWidth,
            child: _expandedRow(
              theme,
              stock,
              useExpanded: true,
              width: minRowWidth,
            ),
          ),
        );
      },
    );
  }

  Widget _expandedRow(
    ThemeData theme,
    ({int currentStock, int reorderPoint})? stock, {
    required bool useExpanded,
    double? width,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: EdenSpacing.space1,
        horizontal: EdenSpacing.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 40, child: _checkbox()),
          SizedBox(
            width: 100,
            child: Text(
              widget.data.sku,
              style: const TextStyle(fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (useExpanded)
            Expanded(
              child: Text(
                widget.data.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            SizedBox(
              width: 120,
              child: Text(
                widget.data.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(width: 80, child: _costCell(theme)),
          SizedBox(width: 80, child: _priceCell(theme)),
          SizedBox(width: 60, child: _onHandCell(theme)),
          SizedBox(width: 60, child: _reorderCell(theme)),
          SizedBox(width: 100, child: _locationCell(theme)),
          if (stock != null)
            SizedBox(
              width: 40,
              child: EdenStockLevelIndicator(
                currentStock: stock.currentStock,
                reorderPoint: stock.reorderPoint,
                showLabel: false,
                height: 6,
              ),
            ),
          _actionsCell(),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final stock = _stockArgs();
    return Padding(
      key: const ValueKey('eden-inventory-row-compact'),
      padding: const EdgeInsets.symmetric(
        vertical: EdenSpacing.space1,
        horizontal: EdenSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(width: 40, child: _checkbox()),
              SizedBox(
                width: 80,
                child: Text(
                  widget.data.sku,
                  style: const TextStyle(fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  widget.data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stock != null)
                SizedBox(
                  width: 40,
                  child: EdenStockLevelIndicator(
                    currentStock: stock.currentStock,
                    reorderPoint: stock.reorderPoint,
                    showLabel: false,
                    height: 6,
                  ),
                ),
              _actionsCell(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _costCell(theme)),
              const SizedBox(width: 8),
              Expanded(child: _priceCell(theme)),
              const SizedBox(width: 8),
              Expanded(child: _onHandCell(theme)),
              const SizedBox(width: 8),
              Expanded(child: _reorderCell(theme)),
              const SizedBox(width: 8),
              Expanded(child: _locationCell(theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkbox() {
    return Checkbox(
      value: widget.selected,
      onChanged: widget.onSelectionChanged == null
          ? null
          : (v) =>
              widget.onSelectionChanged!(widget.data.rowId, v ?? false),
    );
  }

  Widget _costCell(ThemeData theme) {
    if (widget.editable) {
      return EdenInput(
        controller: _costCtl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        size: EdenInputSize.sm,
      );
    }
    return widget.data.costCents == null
        ? const Text('—')
        : EdenCurrencyDisplay(
            cents: widget.data.costCents!,
            currencyCode: widget.data.currency,
          );
  }

  Widget _priceCell(ThemeData theme) {
    if (widget.editable) {
      return EdenInput(
        controller: _priceCtl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        size: EdenInputSize.sm,
      );
    }
    return widget.data.priceCents == null
        ? const Text('—')
        : EdenCurrencyDisplay(
            cents: widget.data.priceCents!,
            currencyCode: widget.data.currency,
          );
  }

  Widget _onHandCell(ThemeData theme) {
    if (widget.editable) {
      return EdenInput(
        controller: _onHandCtl,
        keyboardType: TextInputType.number,
        size: EdenInputSize.sm,
      );
    }
    return Text(widget.data.onHand?.toString() ?? '—');
  }

  Widget _reorderCell(ThemeData theme) {
    if (widget.editable) {
      return EdenInput(
        controller: _reorderCtl,
        keyboardType: TextInputType.number,
        size: EdenInputSize.sm,
      );
    }
    return Text(widget.data.reorderPoint?.toString() ?? '—');
  }

  Widget _locationCell(ThemeData theme) {
    if (widget.editable) {
      return EdenInput(
        controller: _locationCtl,
        size: EdenInputSize.sm,
      );
    }
    return Text(widget.data.location ?? '—');
  }

  Widget _actionsCell() {
    if (widget.editable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: widget.onCommit == null
                ? null
                : () => widget.onCommit!(_buildDraft()),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: widget.onCancel,
          ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.edit_outlined),
      tooltip: 'Edit',
      onPressed: widget.onRequestEdit,
    );
  }
}

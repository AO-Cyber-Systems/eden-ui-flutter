import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_payment_entry.dart';

/// Multi-method payment composer (obj 012-04).
///
/// Composes N [EdenPaymentEntry] rows + tracks total / tendered /
/// remaining / overage / change-due. Returns `List<EdenPaymentDraft>` via
/// [onDraftsChanged]. Transport-agnostic per the TRD anti-patterns:
/// downstream consumer code wires actual payment processing.
///
/// ## Capacity-state banners
///
/// * **Balanced** (|sum - total| ≤ 0.01) — `EdenBanner.success` "Balanced
///   — ready to submit"
/// * **Under** (sum < total - 0.01) — `EdenBanner.info` "Remaining: $X.XX"
/// * **Over** + `allowOverCapacity=false` — `EdenBanner.danger`
///   "Over total by $X.XX"
/// * **Over** + `allowOverCapacity=true` + last-modified-method=cash —
///   `EdenBanner.success` "Change due: $X.XX"
/// * **Over** + `allowOverCapacity=true` + last-modified-method≠cash —
///   `EdenBanner.warning` "Overage: $X.XX"
///
/// The library never blocks submission; consumer decides whether to gate
/// save UI on the over-capacity state via the [onDraftsChanged] callback.
class EdenSplitTender extends StatefulWidget {
  const EdenSplitTender({
    super.key,
    required this.total,
    required this.allowedMethods,
    required this.onDraftsChanged,
    this.initialDrafts,
    this.currencyCode = 'USD',
    this.allowOverCapacity = false,
  });

  final double total;
  final List<EdenPaymentMethod> allowedMethods;
  final ValueChanged<List<EdenPaymentDraft>> onDraftsChanged;
  final List<EdenPaymentDraft>? initialDrafts;
  final String currencyCode;
  final bool allowOverCapacity;

  @override
  State<EdenSplitTender> createState() => _EdenSplitTenderState();
}

class _EdenSplitTenderState extends State<EdenSplitTender> {
  late List<EdenPaymentDraft> _drafts;
  late List<String> _rowIds;
  int? _lastModifiedIndex;
  int _rowIdCounter = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDrafts ??
        [
          EdenPaymentDraft(
            method: widget.allowedMethods.first,
            amount: widget.total,
          ),
        ];
    _drafts = List<EdenPaymentDraft>.from(initial);
    _rowIds = List<String>.generate(_drafts.length, (_) => _nextRowId());
  }

  String _nextRowId() => 'st-row-${_rowIdCounter++}';

  double get _sum => _drafts.fold(0.0, (acc, d) => acc + d.amount);
  double get _remaining => widget.total - _sum;
  bool get _isBalanced => _remaining.abs() <= 0.011;
  bool get _isOver => _sum > widget.total + 0.011;
  bool get _isUnder => _sum < widget.total - 0.011;

  /// Hand-built currency formatter — mirrors EdenCurrencyDisplay's symbol
  /// map (USD/CAD/AUD → $, EUR → €, GBP → £). Avoids the intl dependency.
  static const Map<String, String> _currencySymbols = {
    'USD': r'$',
    'CAD': r'$',
    'AUD': r'$',
    'EUR': '€',
    'GBP': '£',
  };

  String _format(double amount) {
    final symbol = _currencySymbols[widget.currencyCode] ??
        '${widget.currencyCode} ';
    final cents = (amount * 100).round();
    final absCents = cents.abs();
    final whole = absCents ~/ 100;
    final fraction = absCents % 100;
    final wholeStr = _thousands(whole);
    final formatted = '$symbol$wholeStr.${fraction.toString().padLeft(2, '0')}';
    return cents < 0 ? '-$formatted' : formatted;
  }

  static String _thousands(int v) {
    final raw = v.toString();
    if (raw.length <= 3) return raw;
    final buf = StringBuffer();
    var count = 0;
    for (var i = raw.length - 1; i >= 0; i--) {
      buf.write(raw[i]);
      count++;
      if (count == 3 && i > 0) {
        buf.write(',');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }

  void _updateRow(int index, EdenPaymentDraft draft) {
    if (index >= _drafts.length) return;
    // Avoid re-rendering if nothing meaningful changed (prevents the
    // initialDraft-hydration re-emit loop documented in the TRD).
    final existing = _drafts[index];
    if (existing.method == draft.method &&
        existing.amount == draft.amount &&
        existing.reference == draft.reference &&
        existing.note == draft.note) {
      return;
    }
    setState(() {
      _drafts[index] = draft;
      _lastModifiedIndex = index;
    });
    widget.onDraftsChanged(List<EdenPaymentDraft>.unmodifiable(_drafts));
  }

  void _addRow() {
    final remaining = _remaining < 0 ? 0.0 : _remaining;
    setState(() {
      _drafts.add(EdenPaymentDraft(
        method: widget.allowedMethods.first,
        amount: remaining,
      ));
      _rowIds.add(_nextRowId());
    });
    widget.onDraftsChanged(List<EdenPaymentDraft>.unmodifiable(_drafts));
  }

  void _removeRow(int index) {
    if (_drafts.length <= 1) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _drafts.removeAt(index);
      _rowIds.removeAt(index);
      if (_lastModifiedIndex == index) _lastModifiedIndex = null;
    });
    widget.onDraftsChanged(List<EdenPaymentDraft>.unmodifiable(_drafts));
  }

  bool _shouldShowChangeDue() {
    if (_lastModifiedIndex == null) {
      // No edits since the initial state — derive last-modified from the
      // tail row (typical cash-overpayment-on-open scenario).
      return _drafts.isNotEmpty &&
          _drafts.last.method == EdenPaymentMethod.cash;
    }
    final idx = _lastModifiedIndex!;
    if (idx >= _drafts.length) return false;
    return _drafts[idx].method == EdenPaymentMethod.cash;
  }

  // ───────────────────────────── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final banner = _resolveBanner();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _summaryHeader(),
        if (banner != null) ...[
          const SizedBox(height: EdenSpacing.space2),
          banner,
        ],
        const SizedBox(height: EdenSpacing.space3),
        for (int i = 0; i < _drafts.length; i++) _buildRow(i),
        const SizedBox(height: EdenSpacing.space3),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            label: 'Add payment method',
            button: true,
            container: true,
            excludeSemantics: true,
            child: Tooltip(
              message: 'Add payment method',
              child: EdenButton(
                label: 'Add payment method',
                icon: Icons.add,
                onPressed: _addRow,
                outline: true,
                size: EdenButtonSize.sm,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryHeader() {
    final total = _format(widget.total);
    final tendered = _format(_sum);
    final remainingOrOverage = _remaining >= 0
        ? 'Remaining: ${_format(_remaining)}'
        : 'Overage: ${_format(-_remaining)}';
    final semanticsLabel =
        'Total: $total. Tendered: $tendered. $remainingOrOverage.';
    return Semantics(
      label: semanticsLabel,
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: $total',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Tendered: $tendered',
                style: Theme.of(context).textTheme.bodyMedium),
            Text(remainingOrOverage,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget? _resolveBanner() {
    if (_isBalanced) {
      return const EdenBanner(
        message: 'Balanced — ready to submit',
        variant: EdenBannerVariant.success,
        dismissible: false,
      );
    }
    if (_isUnder) {
      return EdenBanner(
        message: 'Remaining: ${_format(_remaining)}',
        variant: EdenBannerVariant.info,
        dismissible: false,
      );
    }
    if (_isOver) {
      final overage = -_remaining;
      if (!widget.allowOverCapacity) {
        return EdenBanner(
          message: 'Over total by ${_format(overage)}',
          variant: EdenBannerVariant.danger,
          dismissible: false,
        );
      }
      if (_shouldShowChangeDue()) {
        return EdenBanner(
          message: 'Change due: ${_format(overage)}',
          variant: EdenBannerVariant.success,
          dismissible: false,
        );
      }
      return EdenBanner(
        message: 'Overage: ${_format(overage)}',
        variant: EdenBannerVariant.warning,
        dismissible: false,
      );
    }
    return null;
  }

  Widget _buildRow(int index) {
    final draft = _drafts[index];
    return Padding(
      key: ValueKey(_rowIds[index]),
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: EdenPaymentEntry(
              key: ValueKey('entry-${_rowIds[index]}'),
              allowedMethods: widget.allowedMethods,
              onDraftChanged: (d) => _updateRow(index, d),
              initialDraft: draft,
              currencyCode: widget.currencyCode,
            ),
          ),
          if (_drafts.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: EdenSpacing.space1),
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove payment row',
                onPressed: () => _removeRow(index),
              ),
            ),
        ],
      ),
    );
  }
}

// Refund-flow primitive. 4-step state machine mirrors obj 014-05's
// EdenReceivingFlow pattern.
//
// Composes:
//   - obj 011-08 EdenSecretField (classified clipboard-mode) for manager PIN.
//   - obj 012 EdenPaymentMethod enum (originalTender callout text + mapping).
//
// Does NOT compose obj 012 EdenLineItemEditor at this revision — refund-mode
// line editing is implemented via a private _RefundLineRow because the
// per-line reason picker + refundable-qty cap is tightly coupled to refund
// semantics. TODO(obj-018-04 EdenLineItemEditor swap): if EdenLineItemEditor
// later exposes refund-mode hooks (customColumns + maxQtyPerLine), inline.

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_alert.dart';
import 'eden_payment_entry.dart';
import 'eden_search_input.dart';
import 'eden_secret_field.dart';
import 'eden_select.dart';

// ─────────────────────────────────────────────────────────────────────────
// Enums + value classes
// ─────────────────────────────────────────────────────────────────────────

enum EdenRefundStep { lookupSale, selectLines, method, managerApprove }

enum EdenRefundReason {
  damaged,
  wrongItem,
  notAsDescribed,
  changedMind,
  sizing,
  other,
}

enum EdenRefundMethod { originalTender, storeCredit, cash }

@immutable
class EdenSaleLine {
  const EdenSaleLine({
    required this.lineId,
    required this.sku,
    required this.name,
    required this.originalQty,
    required this.unitPriceCents,
    required this.taxCents,
    required this.refundableQty,
  });

  final String lineId;
  final String sku;
  final String name;
  final num originalQty;
  final int unitPriceCents;
  final int taxCents;
  final num refundableQty;
}

@immutable
class EdenSaleRecord {
  const EdenSaleRecord({
    required this.saleId,
    required this.occurredAt,
    required this.lines,
    required this.originalTender,
    required this.originalTotalCents,
    this.customerId,
    this.customerName,
    this.receiptRef,
  });

  final String saleId;
  final DateTime occurredAt;
  final List<EdenSaleLine> lines;
  final EdenPaymentMethod originalTender;
  final int originalTotalCents;
  final String? customerId;
  final String? customerName;
  final String? receiptRef;
}

@immutable
class EdenRefundLine {
  const EdenRefundLine({
    required this.lineId,
    required this.refundQty,
    required this.reason,
    this.notes,
  });

  final String lineId;
  final num refundQty;
  final EdenRefundReason reason;
  final String? notes;

  EdenRefundLine copyWith({
    num? refundQty,
    EdenRefundReason? reason,
    String? notes,
  }) =>
      EdenRefundLine(
        lineId: lineId,
        refundQty: refundQty ?? this.refundQty,
        reason: reason ?? this.reason,
        notes: notes ?? this.notes,
      );
}

@immutable
class EdenRefundDraft {
  const EdenRefundDraft({
    required this.saleId,
    required this.refundLines,
    required this.method,
    required this.managerApproved,
    required this.totalRefundCents,
    this.managerApprovalRef,
  });

  final String saleId;
  final List<EdenRefundLine> refundLines;
  final EdenRefundMethod method;
  final bool managerApproved;
  final int totalRefundCents;
  final String? managerApprovalRef;
}

// ─────────────────────────────────────────────────────────────────────────
// Helpers (file-private)
// ─────────────────────────────────────────────────────────────────────────

String _refundReasonLabel(EdenRefundReason r) {
  switch (r) {
    case EdenRefundReason.damaged:
      return 'Damaged';
    case EdenRefundReason.wrongItem:
      return 'Wrong item';
    case EdenRefundReason.notAsDescribed:
      return 'Not as described';
    case EdenRefundReason.changedMind:
      return 'Changed mind';
    case EdenRefundReason.sizing:
      return 'Sizing';
    case EdenRefundReason.other:
      return 'Other';
  }
}

String _methodLabel(EdenRefundMethod m) {
  switch (m) {
    case EdenRefundMethod.originalTender:
      return 'Original tender';
    case EdenRefundMethod.storeCredit:
      return 'Store credit';
    case EdenRefundMethod.cash:
      return 'Cash';
  }
}

String _stepLabel(EdenRefundStep s) {
  switch (s) {
    case EdenRefundStep.lookupSale:
      return 'Find the original sale';
    case EdenRefundStep.selectLines:
      return 'Select lines to refund';
    case EdenRefundStep.method:
      return 'Refund method';
    case EdenRefundStep.managerApprove:
      return 'Manager approval required';
  }
}

String _formatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}\$$dollars.$fraction';
}

// Used by demo/consumer code to map an original tender → suggested refund
// method. Kept available even though the widget itself only renders the
// original-tender label.
// ignore: unused_element
EdenRefundMethod _paymentToRefundMethod(EdenPaymentMethod p) {
  switch (p) {
    case EdenPaymentMethod.cash:
      return EdenRefundMethod.cash;
    default:
      return EdenRefundMethod.originalTender;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────

class EdenRefundFlow extends StatefulWidget {
  const EdenRefundFlow({
    super.key,
    required this.onLookupSale,
    required this.onSubmit,
    this.onManagerApprove,
    this.managerApprovalThresholdCents = 5000,
    this.allowedMethods = const [
      EdenRefundMethod.originalTender,
      EdenRefundMethod.storeCredit,
      EdenRefundMethod.cash,
    ],
  });

  final Future<EdenSaleRecord?> Function(String query) onLookupSale;
  final void Function(EdenRefundDraft draft) onSubmit;
  final Future<bool> Function()? onManagerApprove;
  final int managerApprovalThresholdCents;
  final List<EdenRefundMethod> allowedMethods;

  @override
  State<EdenRefundFlow> createState() => _EdenRefundFlowState();
}

class _EdenRefundFlowState extends State<EdenRefundFlow> {
  EdenRefundStep _step = EdenRefundStep.lookupSale;
  EdenSaleRecord? _sale;
  final Map<String, EdenRefundLine> _refundLines = {};
  EdenRefundMethod? _method;
  bool _managerApproved = false;
  bool _approving = false;
  bool _approvalDenied = false;
  bool _saleNotFound = false;
  String _lookupQuery = '';
  bool _lookingUp = false;

  // ───── Helpers ─────
  int _computeTotalCents() {
    final sale = _sale;
    if (sale == null) return 0;
    var total = 0;
    for (final r in _refundLines.values) {
      final line = sale.lines.firstWhere((l) => l.lineId == r.lineId);
      final unitTaxCents = line.originalQty > 0
          ? (line.taxCents / line.originalQty).round()
          : 0;
      total +=
          (line.unitPriceCents * r.refundQty).round() + (unitTaxCents * r.refundQty).round();
    }
    return total;
  }

  bool _canAdvanceFromSelectLines() => _refundLines.isNotEmpty;

  bool _requiresManagerApproval() {
    if (widget.onManagerApprove == null) return false;
    if (_computeTotalCents() >= widget.managerApprovalThresholdCents) return true;
    if (_method != EdenRefundMethod.originalTender) return true;
    return false;
  }

  String _approvalReasonText() {
    final reasons = <String>[];
    if (_computeTotalCents() >= widget.managerApprovalThresholdCents) {
      reasons.add(
          'refund ≥ ${_formatMoney(widget.managerApprovalThresholdCents)}');
    }
    if (_method != EdenRefundMethod.originalTender) {
      reasons.add('refund method is not original tender');
    }
    return 'Manager approval required: ${reasons.join(' AND ')}.';
  }

  // ───── Actions ─────
  Future<void> _doLookup() async {
    setState(() {
      _lookingUp = true;
      _saleNotFound = false;
    });
    EdenSaleRecord? res;
    try {
      res = await widget.onLookupSale(_lookupQuery);
    } catch (_) {
      res = null;
    }
    if (!mounted) return;
    setState(() {
      _lookingUp = false;
      if (res == null) {
        _saleNotFound = true;
      } else {
        _sale = res;
        _refundLines.clear();
        _step = EdenRefundStep.selectLines;
      }
    });
  }

  void _next() {
    switch (_step) {
      case EdenRefundStep.lookupSale:
        // Driven by Lookup button, not Next.
        return;
      case EdenRefundStep.selectLines:
        if (!_canAdvanceFromSelectLines()) return;
        setState(() => _step = EdenRefundStep.method);
        return;
      case EdenRefundStep.method:
        if (_method == null) return;
        if (_requiresManagerApproval()) {
          setState(() => _step = EdenRefundStep.managerApprove);
        } else {
          _submit();
        }
        return;
      case EdenRefundStep.managerApprove:
        return;
    }
  }

  void _back() {
    switch (_step) {
      case EdenRefundStep.lookupSale:
        return;
      case EdenRefundStep.selectLines:
        setState(() {
          _step = EdenRefundStep.lookupSale;
          _sale = null;
          _refundLines.clear();
          _saleNotFound = false;
        });
        return;
      case EdenRefundStep.method:
        setState(() => _step = EdenRefundStep.selectLines);
        return;
      case EdenRefundStep.managerApprove:
        setState(() {
          _step = EdenRefundStep.method;
          _approvalDenied = false;
        });
        return;
    }
  }

  void _submit() {
    final sale = _sale;
    if (sale == null || _refundLines.isEmpty || _method == null) return;
    if (_requiresManagerApproval() && !_managerApproved) return;
    widget.onSubmit(EdenRefundDraft(
      saleId: sale.saleId,
      refundLines: _refundLines.values.toList(),
      method: _method!,
      managerApproved: _managerApproved,
      totalRefundCents: _computeTotalCents(),
    ));
  }

  Future<void> _doApprove() async {
    setState(() {
      _approving = true;
      _approvalDenied = false;
    });
    bool ok;
    try {
      ok = await widget.onManagerApprove!();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _approving = false;
      if (ok) {
        _managerApproved = true;
        _submit();
      } else {
        _approvalDenied = true;
      }
    });
  }

  void _setLineQty(EdenSaleLine line, int qty) {
    final clamped = qty.clamp(0, line.refundableQty.toInt());
    setState(() {
      if (clamped == 0) {
        _refundLines.remove(line.lineId);
      } else {
        final existing = _refundLines[line.lineId];
        _refundLines[line.lineId] = existing == null
            ? EdenRefundLine(
                lineId: line.lineId,
                refundQty: clamped,
                reason: EdenRefundReason.other,
              )
            : existing.copyWith(refundQty: clamped);
      }
    });
  }

  void _setLineReason(String lineId, EdenRefundReason reason) {
    final existing = _refundLines[lineId];
    if (existing == null) return;
    setState(() {
      _refundLines[lineId] = existing.copyWith(reason: reason);
    });
  }

  // ───── Build ─────
  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_step) {
      case EdenRefundStep.lookupSale:
        body = _buildLookupSale(context);
        break;
      case EdenRefundStep.selectLines:
        body = _buildSelectLines(context);
        break;
      case EdenRefundStep.method:
        body = _buildMethod(context);
        break;
      case EdenRefundStep.managerApprove:
        body = _buildManagerApprove(context);
        break;
    }
    return body;
  }

  Widget _stepIndicator() {
    final theme = Theme.of(context);
    final n = _step.index + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Step $n of 4 — ${_stepLabel(_step)}',
        style: theme.textTheme.titleMedium,
      ),
    );
  }

  Widget _buildLookupSale(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepIndicator(),
          Text(
            'Receipt #, phone, email, or card last 4',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          EdenSearchInput(
            hint: 'Search...',
            onChanged: (v) => setState(() => _lookupQuery = v),
            onSubmitted: (_) => _doLookup(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: (_lookupQuery.trim().isEmpty || _lookingUp)
                  ? null
                  : _doLookup,
              child: Text(_lookingUp ? 'Looking up...' : 'Lookup'),
            ),
          ),
          if (_saleNotFound)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: EdenAlert(
                variant: EdenAlertVariant.warning,
                message: 'Sale not found. Check the reference and try again.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectLines(BuildContext context) {
    final theme = Theme.of(context);
    final sale = _sale!;
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          Text(
            'Sale ${sale.saleId} · ${_formatDate(sale.occurredAt)} · ${_formatMoney(sale.originalTotalCents)} on ${sale.originalTender.displayLabel}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final l in sale.lines)
                  _RefundLineRow(
                    line: l,
                    current: _refundLines[l.lineId],
                    onQtyChanged: (q) => _setLineQty(l, q),
                    onReasonChanged: (r) => _setLineReason(l.lineId, r),
                  ),
              ],
            ),
          ),
          Text(
            'Refund total: ${_formatMoney(_computeTotalCents())}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _stepNav(),
        ],
      ),
    );
  }

  Widget _buildMethod(BuildContext context) {
    final theme = Theme.of(context);
    final sale = _sale!;
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          EdenAlert(
            message:
                'Original sale was paid by ${sale.originalTender.displayLabel}. Refund to original tender for fastest processing.',
          ),
          const SizedBox(height: 12),
          Text('Refund method', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final m in widget.allowedMethods)
            // ignore: deprecated_member_use
            RadioListTile<EdenRefundMethod>(
              title: Text(_methodLabel(m)),
              value: m,
              // ignore: deprecated_member_use
              groupValue: _method,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _method = v),
            ),
          const Spacer(),
          Text(
            'Refund total: ${_formatMoney(_computeTotalCents())}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _stepNav(),
        ],
      ),
    );
  }

  Widget _buildManagerApprove(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          EdenAlert(
            variant: EdenAlertVariant.warning,
            message: _approvalReasonText(),
          ),
          const SizedBox(height: 12),
          const EdenSecretField(
            label: 'Manager PIN',
            value: '',
            clipboardMode: EdenSecretClipboardMode.classified,
          ),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton(onPressed: _back, child: const Text('Back')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _approving ? null : _doApprove,
              child: Text(_approving ? 'Approving...' : 'Approve'),
            ),
          ]),
          if (_approvalDenied)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: EdenAlert(
                variant: EdenAlertVariant.danger,
                message: 'Approval denied. Refund cannot be submitted.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepNav() {
    final isFirstStep = _step == EdenRefundStep.lookupSale;
    final canNext = switch (_step) {
      EdenRefundStep.lookupSale => false,
      EdenRefundStep.selectLines => _canAdvanceFromSelectLines(),
      EdenRefundStep.method => _method != null,
      EdenRefundStep.managerApprove => false,
    };
    return Row(
      children: [
        if (!isFirstStep)
          OutlinedButton(onPressed: _back, child: const Text('Back')),
        const Spacer(),
        ElevatedButton(
          onPressed: canNext ? _next : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _RefundLineRow extends StatelessWidget {
  const _RefundLineRow({
    required this.line,
    required this.current,
    required this.onQtyChanged,
    required this.onReasonChanged,
  });

  final EdenSaleLine line;
  final EdenRefundLine? current;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<EdenRefundReason> onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reasonOptions = [
      for (final r in EdenRefundReason.values)
        EdenSelectOption<EdenRefundReason>(
          value: r,
          label: _refundReasonLabel(r),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          final infoColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${line.sku} — ${line.name}',
                  style: theme.textTheme.bodyMedium),
              Text(
                '${line.refundableQty} available @ ${_formatMoney(line.unitPriceCents)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
          final qtyField = SizedBox(
            width: 80,
            child: TextField(
              key: ValueKey('refundQty-${line.lineId}'),
              decoration: const InputDecoration(
                hintText: 'Qty',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final q = int.tryParse(v) ?? 0;
                onQtyChanged(q);
              },
            ),
          );
          final reasonPicker = SizedBox(
            width: narrow ? double.infinity : 220,
            child: current == null
                ? const SizedBox.shrink()
                : EdenSelect<EdenRefundReason>(
                    options: reasonOptions,
                    value: current!.reason,
                    onChanged: (r) {
                      if (r != null) onReasonChanged(r);
                    },
                  ),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoColumn,
                const SizedBox(height: 6),
                Row(children: [qtyField]),
                const SizedBox(height: 6),
                reasonPicker,
                const Divider(height: 16),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: infoColumn),
              const SizedBox(width: 12),
              qtyField,
              const SizedBox(width: 12),
              reasonPicker,
            ],
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

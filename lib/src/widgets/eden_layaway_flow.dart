// Layaway-flow primitive. Two operating modes:
//   - EdenLayawayFlow.create — NEW layaway: 3-step state machine
//     (create → deposit → schedule → submit).
//   - EdenLayawayFlow.manage — EXISTING layaway: summary + 3-action picker
//     (recordInstallment / releaseToCustomer / cancelAndRefund).
//
// Composes obj 011 EdenDatePicker (schedule step) + obj 012 EdenPaymentMethod
// (installment payment method). No PCI-sensitive widgets (consumer wires
// downstream card capture).

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_alert.dart';
import 'eden_badge.dart';
import 'eden_date_picker.dart';
import 'eden_payment_entry.dart';
import 'eden_select.dart';

// ─────────────────────────────────────────────────────────────────────────
// Enums + value classes
// ─────────────────────────────────────────────────────────────────────────

@immutable
class EdenLayawayCartItem {
  const EdenLayawayCartItem({
    required this.lineId,
    required this.sku,
    required this.name,
    required this.qty,
    required this.unitPriceCents,
    this.taxCents = 0,
  });

  final String lineId;
  final String sku;
  final String name;
  final num qty;
  final int unitPriceCents;
  final int taxCents;
}

@immutable
class EdenLayawayInstallment {
  const EdenLayawayInstallment({
    required this.id,
    required this.paidAt,
    required this.amountCents,
    required this.method,
    this.ref,
  });

  final String id;
  final DateTime paidAt;
  final int amountCents;
  final EdenPaymentMethod method;
  final String? ref;
}

enum EdenLayawayStatus { active, readyForPickup, completed, cancelled }

@immutable
class EdenLayawayState {
  const EdenLayawayState({
    required this.id,
    required this.cartItems,
    required this.depositCents,
    required this.balanceCents,
    required this.pickupByDate,
    required this.status,
    this.installments = const [],
    this.customerId,
    this.customerName,
  });

  final String id;
  final List<EdenLayawayCartItem> cartItems;
  final int depositCents;
  final int balanceCents;
  final DateTime pickupByDate;
  final EdenLayawayStatus status;
  final List<EdenLayawayInstallment> installments;
  final String? customerId;
  final String? customerName;
}

enum EdenLayawayStep { create, deposit, schedule }

enum EdenLayawayAction { recordInstallment, releaseToCustomer, cancelAndRefund }

enum EdenLayawayNotifyChannel { email, sms, none }

enum EdenLayawayDraftKind { created, installment, release, cancel }

sealed class EdenLayawayDraft {
  const EdenLayawayDraft({required this.kind});
  final EdenLayawayDraftKind kind;
}

final class EdenLayawayCreatedDraft extends EdenLayawayDraft {
  const EdenLayawayCreatedDraft({
    required this.cartItems,
    required this.depositCents,
    this.pickupByDate,
    this.installmentCount,
    this.customerId,
  }) : super(kind: EdenLayawayDraftKind.created);

  final List<EdenLayawayCartItem> cartItems;
  final int depositCents;
  final DateTime? pickupByDate;
  final int? installmentCount;
  final String? customerId;
}

final class EdenLayawayInstallmentDraft extends EdenLayawayDraft {
  const EdenLayawayInstallmentDraft({
    required this.layawayId,
    required this.amountCents,
    required this.method,
  }) : super(kind: EdenLayawayDraftKind.installment);

  final String layawayId;
  final int amountCents;
  final EdenPaymentMethod method;
}

final class EdenLayawayReleaseDraft extends EdenLayawayDraft {
  const EdenLayawayReleaseDraft({required this.layawayId})
      : super(kind: EdenLayawayDraftKind.release);

  final String layawayId;
}

final class EdenLayawayCancelDraft extends EdenLayawayDraft {
  const EdenLayawayCancelDraft({
    required this.layawayId,
    required this.refundCents,
  }) : super(kind: EdenLayawayDraftKind.cancel);

  final String layawayId;
  final int refundCents;
}

// ─────────────────────────────────────────────────────────────────────────
// Library-private top-level helpers (exposed for tests)
// ─────────────────────────────────────────────────────────────────────────

int edenLayawayCartTotalCents(List<EdenLayawayCartItem> items) {
  var total = 0;
  for (final i in items) {
    total += (i.unitPriceCents * i.qty).round() + i.taxCents;
  }
  return total;
}

int edenLayawayMinDepositCents(int cartTotal, double percent) {
  return (cartTotal * percent).round();
}

int edenLayawayDaysUntilPickup(DateTime pickupBy, DateTime now) {
  // Use day-precision difference (drop time component).
  final p = DateTime(pickupBy.year, pickupBy.month, pickupBy.day);
  final n = DateTime(now.year, now.month, now.day);
  return p.difference(n).inDays;
}

int edenLayawayPaidSoFarCents(EdenLayawayState s) {
  return s.depositCents +
      s.installments.fold<int>(0, (acc, i) => acc + i.amountCents);
}

String _formatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}\$$dollars.$fraction';
}

String _actionLabel(EdenLayawayAction a) {
  switch (a) {
    case EdenLayawayAction.recordInstallment:
      return 'Record installment';
    case EdenLayawayAction.releaseToCustomer:
      return 'Release to customer';
    case EdenLayawayAction.cancelAndRefund:
      return 'Cancel & refund';
  }
}

String _stepLabel(EdenLayawayStep s) {
  switch (s) {
    case EdenLayawayStep.create:
      return 'Cart';
    case EdenLayawayStep.deposit:
      return 'Collect deposit';
    case EdenLayawayStep.schedule:
      return 'Schedule pickup';
  }
}

String _channelLabel(EdenLayawayNotifyChannel c) {
  switch (c) {
    case EdenLayawayNotifyChannel.email:
      return 'Email';
    case EdenLayawayNotifyChannel.sms:
      return 'SMS';
    case EdenLayawayNotifyChannel.none:
      return 'No notification';
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────

enum _EdenLayawayMode { create, manage }

class EdenLayawayFlow extends StatefulWidget {
  const EdenLayawayFlow.create({
    super.key,
    required this.cartItems,
    required this.onSubmit,
    this.onCustomerAttach,
    this.onNotifyCustomer,
    this.minDepositPercent = 0.20,
    this.customerId,
    this.customerName,
    this.now,
  })  : mode = _EdenLayawayMode.create,
        state = null;

  const EdenLayawayFlow.manage({
    super.key,
    required EdenLayawayState this.state,
    required this.onSubmit,
    this.onNotifyCustomer,
    this.minDepositPercent = 0.20,
    this.now,
  })  : mode = _EdenLayawayMode.manage,
        cartItems = const [],
        onCustomerAttach = null,
        customerId = null,
        customerName = null;

  // ignore: library_private_types_in_public_api
  final _EdenLayawayMode mode;
  final List<EdenLayawayCartItem> cartItems;
  final EdenLayawayState? state;
  final void Function(EdenLayawayDraft draft) onSubmit;
  final VoidCallback? onCustomerAttach;
  final Future<void> Function(
    EdenLayawayNotifyChannel channel,
    String payload,
  )? onNotifyCustomer;
  final double minDepositPercent;
  final String? customerId;
  final String? customerName;

  /// Injectable clock for deterministic tests.
  final DateTime? now;

  @override
  State<EdenLayawayFlow> createState() => _EdenLayawayFlowState();
}

class _EdenLayawayFlowState extends State<EdenLayawayFlow> {
  // Create-mode state.
  EdenLayawayStep _step = EdenLayawayStep.create;
  late int _depositCents;
  DateTime? _pickupByDate;
  int? _installmentCount;
  EdenLayawayNotifyChannel _notifyChannel = EdenLayawayNotifyChannel.none;
  late TextEditingController _depositController;

  // Manage-mode state.
  EdenLayawayAction? _selectedAction;
  late TextEditingController _installmentAmountController;
  EdenPaymentMethod _installmentMethod = EdenPaymentMethod.card;

  DateTime _now() => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.mode == _EdenLayawayMode.create) {
      final total = edenLayawayCartTotalCents(widget.cartItems);
      _depositCents =
          edenLayawayMinDepositCents(total, widget.minDepositPercent);
      _depositController = TextEditingController(
        text: (_depositCents / 100).toStringAsFixed(2),
      );
    } else {
      _depositCents = 0;
      _depositController = TextEditingController();
    }
    _installmentAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _depositController.dispose();
    _installmentAmountController.dispose();
    super.dispose();
  }

  int get _cartTotal => edenLayawayCartTotalCents(widget.cartItems);
  int get _minDeposit =>
      edenLayawayMinDepositCents(_cartTotal, widget.minDepositPercent);

  // ───── Build ─────
  @override
  Widget build(BuildContext context) {
    return widget.mode == _EdenLayawayMode.create
        ? _buildCreateMode(context)
        : _buildManageMode(context);
  }

  // ───── Create-mode ─────
  Widget _buildCreateMode(BuildContext context) {
    switch (_step) {
      case EdenLayawayStep.create:
        return _buildCreateStep1(context);
      case EdenLayawayStep.deposit:
        return _buildCreateStep2(context);
      case EdenLayawayStep.schedule:
        return _buildCreateStep3(context);
    }
  }

  Widget _stepIndicator() {
    final theme = Theme.of(context);
    final n = _step.index + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Step $n of 3 — ${_stepLabel(_step)}',
        style: theme.textTheme.titleMedium,
      ),
    );
  }

  Widget _buildCreateStep1(BuildContext context) {
    final theme = Theme.of(context);
    final total = _cartTotal;
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          Text(
            'Cart (${widget.cartItems.length} items)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final i in widget.cartItems)
                  ListTile(
                    dense: true,
                    title: Text('${i.sku} — ${i.name}'),
                    subtitle: Text(
                      '${i.qty} @ ${_formatMoney(i.unitPriceCents)}',
                    ),
                    trailing: Text(_formatMoney(
                      (i.unitPriceCents * i.qty).round() + i.taxCents,
                    )),
                  ),
              ],
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text(_formatMoney(total), style: theme.textTheme.titleMedium),
            ],
          ),
          if (widget.onCustomerAttach != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Attach customer'),
                onPressed: widget.onCustomerAttach,
              ),
            ),
          _stepNavCreate(canNext: true),
        ],
      ),
    );
  }

  Widget _buildCreateStep2(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          Text(
            'Minimum deposit: ${_formatMoney(_minDeposit)} (${(widget.minDepositPercent * 100).toStringAsFixed(0)}% of ${_formatMoney(_cartTotal)})',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            key: const ValueKey('depositAmount'),
            width: 200,
            child: TextField(
              controller: _depositController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: r'$',
                labelText: 'Deposit amount',
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                setState(() {
                  _depositCents =
                      parsed == null ? 0 : (parsed * 100).round();
                });
              },
            ),
          ),
          const Spacer(),
          _stepNavCreate(canNext: _depositCents >= _minDeposit),
        ],
      ),
    );
  }

  Widget _buildCreateStep3(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepIndicator(),
            EdenDatePicker(
              label: 'Pickup by',
              value: _pickupByDate,
              firstDate: _now(),
              lastDate: _now().add(const Duration(days: 365)),
              onChanged: (d) => setState(() => _pickupByDate = d),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Installment count (optional)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setState(() => _installmentCount = int.tryParse(v));
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('Notify customer', style: theme.textTheme.titleSmall),
            for (final c in EdenLayawayNotifyChannel.values)
              // ignore: deprecated_member_use
              RadioListTile<EdenLayawayNotifyChannel>(
                title: Text(_channelLabel(c)),
                value: c,
                // ignore: deprecated_member_use
                groupValue: _notifyChannel,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(
                  () => _notifyChannel = v ?? EdenLayawayNotifyChannel.none,
                ),
              ),
            const SizedBox(height: 12),
            _stepNavCreate(canNext: true, lastStep: true),
          ],
        ),
      ),
    );
  }

  Widget _stepNavCreate({required bool canNext, bool lastStep = false}) {
    final firstStep = _step == EdenLayawayStep.create;
    return Row(
      children: [
        if (!firstStep)
          OutlinedButton(
            onPressed: () => setState(() {
              _step = EdenLayawayStep
                  .values[(_step.index - 1).clamp(0, 2)];
            }),
            child: const Text('Back'),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: canNext
              ? () {
                  if (lastStep) {
                    _submitCreate();
                  } else {
                    setState(() {
                      _step = EdenLayawayStep
                          .values[(_step.index + 1).clamp(0, 2)];
                    });
                  }
                }
              : null,
          child: Text(lastStep ? 'Submit' : 'Next'),
        ),
      ],
    );
  }

  Future<void> _submitCreate() async {
    widget.onSubmit(EdenLayawayCreatedDraft(
      cartItems: widget.cartItems,
      depositCents: _depositCents,
      pickupByDate: _pickupByDate,
      installmentCount: _installmentCount,
      customerId: widget.customerId,
    ));
    await _maybeNotify('Layaway created');
  }

  Future<void> _maybeNotify(String payload) async {
    final cb = widget.onNotifyCustomer;
    if (cb == null) return;
    if (_notifyChannel == EdenLayawayNotifyChannel.none) return;
    await cb(_notifyChannel, payload);
  }

  // ───── Manage-mode ─────
  Widget _buildManageMode(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state!;
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(context, state),
            const SizedBox(height: 16),
            Text('Action', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            EdenSelect<EdenLayawayAction>(
              value: _selectedAction,
              options: [
                for (final a in EdenLayawayAction.values)
                  EdenSelectOption<EdenLayawayAction>(
                    value: a,
                    label: _actionLabel(a),
                  ),
              ],
              hint: 'Choose an action',
              onChanged: (a) => setState(() => _selectedAction = a),
            ),
            const SizedBox(height: 16),
            if (_selectedAction != null)
              _buildActionSubflow(context, state),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, EdenLayawayState s) {
    final theme = Theme.of(context);
    final installmentsTotal = s.installments
        .fold<int>(0, (acc, i) => acc + i.amountCents);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Layaway ${s.id}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                _pickupCountdown(context, s.pickupByDate),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${s.cartItems.length} items${s.customerName != null ? ' · ${s.customerName}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _summaryStat('Deposit paid', s.depositCents),
                _summaryStat('Installments paid', installmentsTotal),
                _summaryStat('Balance due', s.balanceCents),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String label, int cents) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(_formatMoney(cents), style: theme.textTheme.titleMedium),
      ],
    );
  }

  Widget _pickupCountdown(BuildContext context, DateTime pickupBy) {
    final days = edenLayawayDaysUntilPickup(pickupBy, _now());
    final overdue = days < 0;
    return EdenBadge(
      label: overdue ? '${-days}d overdue' : 'Pickup in ${days}d',
      variant: overdue
          ? EdenBadgeVariant.danger
          : (days <= 3
              ? EdenBadgeVariant.warning
              : EdenBadgeVariant.success),
      size: EdenBadgeSize.sm,
    );
  }

  Widget _buildActionSubflow(BuildContext context, EdenLayawayState s) {
    switch (_selectedAction!) {
      case EdenLayawayAction.recordInstallment:
        return _buildInstallmentForm(context, s);
      case EdenLayawayAction.releaseToCustomer:
        return _buildReleaseForm(context, s);
      case EdenLayawayAction.cancelAndRefund:
        return _buildCancelForm(context, s);
    }
  }

  Widget _buildInstallmentForm(BuildContext context, EdenLayawayState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Record installment', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _installmentAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: r'$',
              labelText: 'Amount',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 220,
          child: EdenSelect<EdenPaymentMethod>(
            label: 'Method',
            value: _installmentMethod,
            options: [
              for (final m in [
                EdenPaymentMethod.cash,
                EdenPaymentMethod.card,
                EdenPaymentMethod.check,
                EdenPaymentMethod.ach,
              ])
                EdenSelectOption<EdenPaymentMethod>(
                  value: m,
                  label: m.displayLabel,
                ),
            ],
            onChanged: (m) {
              if (m != null) setState(() => _installmentMethod = m);
            },
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final parsed = double.tryParse(_installmentAmountController.text);
            if (parsed == null || parsed <= 0) return;
            widget.onSubmit(EdenLayawayInstallmentDraft(
              layawayId: s.id,
              amountCents: (parsed * 100).round(),
              method: _installmentMethod,
            ));
          },
          child: const Text('Submit installment'),
        ),
      ],
    );
  }

  Widget _buildReleaseForm(BuildContext context, EdenLayawayState s) {
    final theme = Theme.of(context);
    final balanceDue = s.balanceCents > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Release to customer', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (balanceDue)
          EdenAlert(
            variant: EdenAlertVariant.warning,
            message:
                'Balance due ${_formatMoney(s.balanceCents)} — collect remaining before release.',
          ),
        const SizedBox(height: 12),
        _notifyChannelPicker(),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: balanceDue
              ? null
              : () async {
                  widget.onSubmit(EdenLayawayReleaseDraft(layawayId: s.id));
                  await _maybeNotify('Layaway ${s.id} ready for pickup');
                },
          child: const Text('Confirm release'),
        ),
      ],
    );
  }

  Widget _buildCancelForm(BuildContext context, EdenLayawayState s) {
    final theme = Theme.of(context);
    final refund = edenLayawayPaidSoFarCents(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cancel & refund', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        EdenAlert(
          variant: EdenAlertVariant.danger,
          message:
              'Cancel layaway? Customer will be refunded ${_formatMoney(refund)}.',
        ),
        const SizedBox(height: 12),
        _notifyChannelPicker(),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm cancellation'),
                content: Text(
                  'Cancel layaway ${s.id}? Customer will be refunded ${_formatMoney(refund)}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Keep layaway'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirm cancel'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              widget.onSubmit(EdenLayawayCancelDraft(
                layawayId: s.id,
                refundCents: refund,
              ));
              await _maybeNotify('Layaway ${s.id} cancelled');
            }
          },
          child: const Text('Cancel layaway'),
        ),
      ],
    );
  }

  Widget _notifyChannelPicker() {
    return Wrap(
      spacing: 8,
      children: [
        for (final c in EdenLayawayNotifyChannel.values)
          ChoiceChip(
            label: Text(_channelLabel(c)),
            selected: _notifyChannel == c,
            onSelected: (sel) {
              if (sel) setState(() => _notifyChannel = c);
            },
          ),
      ],
    );
  }
}

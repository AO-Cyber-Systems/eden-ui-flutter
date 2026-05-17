import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';

/// A single bill / coin denomination.
@immutable
class EdenDenomination {
  const EdenDenomination({required this.value, required this.label});
  final double value;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenDenomination &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// Canonical denomination sets.
class EdenDenominations {
  EdenDenominations._();

  static const List<EdenDenomination> usd = <EdenDenomination>[
    EdenDenomination(value: 100.00, label: r'$100'),
    EdenDenomination(value: 50.00, label: r'$50'),
    EdenDenomination(value: 20.00, label: r'$20'),
    EdenDenomination(value: 10.00, label: r'$10'),
    EdenDenomination(value: 5.00, label: r'$5'),
    EdenDenomination(value: 1.00, label: r'$1'),
    EdenDenomination(value: 0.25, label: 'Quarter'),
    EdenDenomination(value: 0.10, label: 'Dime'),
    EdenDenomination(value: 0.05, label: 'Nickel'),
    EdenDenomination(value: 0.01, label: 'Penny'),
  ];

  static const List<EdenDenomination> cad = usd; // Same denominations in v1.
}

/// Count of one denomination.
@immutable
class EdenDenominationCount {
  const EdenDenominationCount({
    required this.denomination,
    required this.count,
  });

  final EdenDenomination denomination;
  final int count;

  double get lineTotal => denomination.value * count;

  EdenDenominationCount copyWith({
    EdenDenomination? denomination,
    int? count,
  }) {
    return EdenDenominationCount(
      denomination: denomination ?? this.denomination,
      count: count ?? this.count,
    );
  }
}

/// A pay-in / pay-out transaction recorded mid-shift.
@immutable
class EdenCashTransaction {
  const EdenCashTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.occurredAt,
    this.witnessId,
    this.memo,
  });

  final String id;

  /// Positive for pay-in, negative for pay-out / cash-drop.
  final double amount;
  final String reason;
  final DateTime occurredAt;
  final String? witnessId;
  final String? memo;
}

/// An open or closed drawer session.
@immutable
class EdenDrawerSession {
  const EdenDrawerSession({
    required this.drawerId,
    required this.openedAt,
    required this.startingFloat,
    required this.transactions,
    this.closedAt,
    this.closingCount,
    this.variance,
  });

  final String drawerId;
  final DateTime openedAt;
  final double startingFloat;
  final List<EdenCashTransaction> transactions;
  final DateTime? closedAt;
  final List<EdenDenominationCount>? closingCount;
  final double? variance;

  double get expectedClosingBalance {
    return startingFloat +
        transactions.fold<double>(0, (acc, t) => acc + t.amount);
  }

  double get countedClosingBalance {
    final c = closingCount;
    if (c == null) return 0.0;
    return c.fold<double>(0, (acc, e) => acc + e.lineTotal);
  }

  double get computedVariance =>
      countedClosingBalance - expectedClosingBalance;

  EdenDrawerSession copyWith({
    String? drawerId,
    DateTime? openedAt,
    double? startingFloat,
    List<EdenCashTransaction>? transactions,
    DateTime? closedAt,
    List<EdenDenominationCount>? closingCount,
    double? variance,
  }) {
    return EdenDrawerSession(
      drawerId: drawerId ?? this.drawerId,
      openedAt: openedAt ?? this.openedAt,
      startingFloat: startingFloat ?? this.startingFloat,
      transactions: transactions ?? this.transactions,
      closedAt: closedAt ?? this.closedAt,
      closingCount: closingCount ?? this.closingCount,
      variance: variance ?? this.variance,
    );
  }
}

/// Bank-deposit form data emitted from the deposit step.
@immutable
class EdenBankDepositDraft {
  const EdenBankDepositDraft({
    required this.cashAmount,
    required this.checkAmount,
    required this.checkCount,
    this.bankAccountLabel,
    this.memo,
    this.depositedAt,
  });

  final double cashAmount;
  final double checkAmount;
  final int checkCount;
  final String? bankAccountLabel;
  final String? memo;
  final DateTime? depositedAt;

  EdenBankDepositDraft copyWith({
    double? cashAmount,
    double? checkAmount,
    int? checkCount,
    String? bankAccountLabel,
    String? memo,
    DateTime? depositedAt,
  }) {
    return EdenBankDepositDraft(
      cashAmount: cashAmount ?? this.cashAmount,
      checkAmount: checkAmount ?? this.checkAmount,
      checkCount: checkCount ?? this.checkCount,
      bankAccountLabel: bankAccountLabel ?? this.bankAccountLabel,
      memo: memo ?? this.memo,
      depositedAt: depositedAt ?? this.depositedAt,
    );
  }
}

/// Result emitted on Confirm close.
@immutable
class EdenCashDrawerCloseResult {
  const EdenCashDrawerCloseResult({
    required this.finalSession,
    required this.deposit,
    required this.finalTransactions,
  });

  final EdenDrawerSession finalSession;
  final EdenBankDepositDraft? deposit;
  final List<EdenCashTransaction> finalTransactions;
}

/// Wizard steps.
enum EdenCashDrawerCloseStep { count, transactions, deposit, review }

/// End-of-day cash drawer close (obj 015-06).
class EdenCashDrawerClose extends StatefulWidget {
  const EdenCashDrawerClose({
    super.key,
    required this.initialSession,
    required this.onSessionChanged,
    required this.onSubmit,
    this.denominations = EdenDenominations.usd,
    this.allowDeposit = true,
    this.currencyCode = 'USD',
    this.varianceManagerOverrideMessage,
  });

  final EdenDrawerSession initialSession;
  final ValueChanged<EdenDrawerSession> onSessionChanged;
  final ValueChanged<EdenCashDrawerCloseResult> onSubmit;
  final List<EdenDenomination> denominations;
  final bool allowDeposit;
  final String currencyCode;
  final String? varianceManagerOverrideMessage;

  @override
  State<EdenCashDrawerClose> createState() => _EdenCashDrawerCloseState();
}

class _EdenCashDrawerCloseState extends State<EdenCashDrawerClose> {
  late EdenDrawerSession _session;
  EdenCashDrawerCloseStep _step = EdenCashDrawerCloseStep.count;

  late Map<String, TextEditingController> _denomControllers;
  late TextEditingController _depositCashController;
  late TextEditingController _depositCheckAmountController;
  late TextEditingController _depositCheckCountController;
  late TextEditingController _depositMemoController;
  bool _depositSkipped = false;
  bool _managerApproved = false;

  // Add-transaction inline form
  bool _showAddTxForm = false;
  bool _addTxIsDebit = true;
  final _txAmountController = TextEditingController();
  final _txReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _denomControllers = {
      for (final d in widget.denominations)
        d.label: TextEditingController(text: _initialCountFor(d).toString()),
    };
    _depositCashController = TextEditingController();
    _depositCheckAmountController = TextEditingController(text: '0.00');
    _depositCheckCountController = TextEditingController(text: '0');
    _depositMemoController = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _denomControllers.values) {
      c.dispose();
    }
    _depositCashController.dispose();
    _depositCheckAmountController.dispose();
    _depositCheckCountController.dispose();
    _depositMemoController.dispose();
    _txAmountController.dispose();
    _txReasonController.dispose();
    super.dispose();
  }

  int _initialCountFor(EdenDenomination d) {
    final c = _session.closingCount ?? const <EdenDenominationCount>[];
    for (final e in c) {
      if (e.denomination == d) return e.count;
    }
    return 0;
  }

  void _emitSession(EdenDrawerSession s) {
    setState(() {
      _session = s;
    });
    widget.onSessionChanged(s);
  }

  void _onDenomChanged(EdenDenomination d, String raw) {
    final count = int.tryParse(raw) ?? 0;
    final existing = List<EdenDenominationCount>.from(
        _session.closingCount ?? const <EdenDenominationCount>[]);
    final idx = existing.indexWhere((e) => e.denomination == d);
    if (idx >= 0) {
      existing[idx] = existing[idx].copyWith(count: count);
    } else {
      existing.add(EdenDenominationCount(denomination: d, count: count));
    }
    _emitSession(_session.copyWith(closingCount: existing));
  }

  void _addTransaction() {
    final amount = double.tryParse(_txAmountController.text) ?? 0;
    final reason = _txReasonController.text;
    if (reason.isEmpty || amount.abs() < 0.001) return;
    final signed = _addTxIsDebit ? -amount.abs() : amount.abs();
    final tx = EdenCashTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      amount: signed,
      reason: reason,
      occurredAt: DateTime.now(),
    );
    final list = List<EdenCashTransaction>.from(_session.transactions)
      ..add(tx);
    _emitSession(_session.copyWith(transactions: list));
    _txAmountController.clear();
    _txReasonController.clear();
    setState(() {
      _showAddTxForm = false;
    });
  }

  EdenBankDepositDraft _buildDepositDraft() {
    return EdenBankDepositDraft(
      cashAmount: double.tryParse(_depositCashController.text) ?? 0,
      checkAmount:
          double.tryParse(_depositCheckAmountController.text) ?? 0,
      checkCount: int.tryParse(_depositCheckCountController.text) ?? 0,
      memo: _depositMemoController.text.isEmpty
          ? null
          : _depositMemoController.text,
    );
  }

  void _advance() {
    switch (_step) {
      case EdenCashDrawerCloseStep.count:
        setState(() => _step = EdenCashDrawerCloseStep.transactions);
        break;
      case EdenCashDrawerCloseStep.transactions:
        if (widget.allowDeposit) {
          // Prefill deposit cash to max(0, countedClosingBalance - startingFloat)
          final suggested =
              (_session.countedClosingBalance - _session.startingFloat)
                  .clamp(0.0, double.infinity);
          _depositCashController.text = suggested.toStringAsFixed(2);
          setState(() => _step = EdenCashDrawerCloseStep.deposit);
        } else {
          setState(() => _step = EdenCashDrawerCloseStep.review);
        }
        break;
      case EdenCashDrawerCloseStep.deposit:
        setState(() => _step = EdenCashDrawerCloseStep.review);
        break;
      case EdenCashDrawerCloseStep.review:
        break;
    }
  }

  void _retreat() {
    switch (_step) {
      case EdenCashDrawerCloseStep.count:
        break;
      case EdenCashDrawerCloseStep.transactions:
        setState(() => _step = EdenCashDrawerCloseStep.count);
        break;
      case EdenCashDrawerCloseStep.deposit:
        setState(() => _step = EdenCashDrawerCloseStep.transactions);
        break;
      case EdenCashDrawerCloseStep.review:
        setState(() {
          _step = widget.allowDeposit
              ? EdenCashDrawerCloseStep.deposit
              : EdenCashDrawerCloseStep.transactions;
        });
        break;
    }
  }

  void _skipDeposit() {
    setState(() {
      _depositSkipped = true;
      _step = EdenCashDrawerCloseStep.review;
    });
  }

  void _confirmClose() {
    final variance = _session.computedVariance;
    if (variance.abs() > 5.0 &&
        widget.varianceManagerOverrideMessage != null &&
        !_managerApproved) {
      return;
    }
    final deposit =
        _depositSkipped || !widget.allowDeposit ? null : _buildDepositDraft();
    final finalSession = _session.copyWith(
      closedAt: DateTime.now(),
      variance: variance,
    );
    widget.onSubmit(EdenCashDrawerCloseResult(
      finalSession: finalSession,
      deposit: deposit,
      finalTransactions: List.unmodifiable(finalSession.transactions),
    ));
  }

  Color _varianceColor() {
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    if (_session.computedVariance.abs() <= 0.01) return palette.successFg;
    return palette.dangerFg;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 600;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(),
          const SizedBox(height: EdenSpacing.space3),
          _buildBody(narrow),
          const SizedBox(height: EdenSpacing.space3),
          _buildNavRow(),
        ],
      );
    });
  }

  Widget _buildStepHeader() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final s in EdenCashDrawerCloseStep.values)
          if (widget.allowDeposit || s != EdenCashDrawerCloseStep.deposit)
            ChoiceChip(
              label: Text(s.name),
              selected: _step == s,
              onSelected: (_) => setState(() => _step = s),
            ),
      ],
    );
  }

  Widget _buildBody(bool narrow) {
    switch (_step) {
      case EdenCashDrawerCloseStep.count:
        return _buildCountBody(narrow);
      case EdenCashDrawerCloseStep.transactions:
        return _buildTransactionsBody();
      case EdenCashDrawerCloseStep.deposit:
        return _buildDepositBody();
      case EdenCashDrawerCloseStep.review:
        return _buildReviewBody();
    }
  }

  Widget _buildCountBody(bool narrow) {
    final rows = <Widget>[];
    for (final d in widget.denominations) {
      final controller = _denomControllers[d.label]!;
      final currentCount = int.tryParse(controller.text) ?? 0;
      final subtotal = d.value * currentCount;
      final row = Semantics(
        label:
            '$currentCount count of ${d.label}, subtotal \$${subtotal.toStringAsFixed(2)}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(d.label)),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (raw) => _onDenomChanged(d, raw),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: EdenCurrencyDisplay(
                  cents: (subtotal * 100).round(),
                  currencyCode: widget.currencyCode,
                ),
              ),
            ],
          ),
        ),
      );
      rows.add(narrow ? EdenCard(child: Padding(padding: const EdgeInsets.all(8), child: row)) : row);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...rows,
        const Divider(),
        _buildVarianceFooter(),
      ],
    );
  }

  Widget _buildVarianceFooter() {
    final v = _session.computedVariance;
    final overLimit = v.abs() > 5.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Expected: '),
                EdenCurrencyDisplay(
                  cents: (_session.expectedClosingBalance * 100).round(),
                  currencyCode: widget.currencyCode,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Counted: '),
                EdenCurrencyDisplay(
                  cents: (_session.countedClosingBalance * 100).round(),
                  currencyCode: widget.currencyCode,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Semantics(
          label:
              'Variance: \$${v.toStringAsFixed(2)}, ${v >= 0 ? 'over' : 'under'}',
          excludeSemantics: true,
          child: Row(
            children: [
              const Text('Variance: '),
              Text(
                '\$${v.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _varianceColor(),
                ),
              ),
            ],
          ),
        ),
        if (overLimit)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: EdenBanner(
              message:
                  'Variance exceeds \$5.00 — manager review may be required',
              variant: EdenBannerVariant.warning,
              dismissible: false,
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_session.transactions.isEmpty)
          const Text('No transactions recorded')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('When')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Memo')),
              ],
              rows: [
                for (final t in _session.transactions)
                  DataRow(cells: [
                    DataCell(Text(_formatTime(t.occurredAt))),
                    DataCell(Text(t.reason)),
                    DataCell(Text(
                      '\$${t.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: t.amount < 0
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )),
                    DataCell(Text(t.memo ?? '')),
                  ]),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (!_showAddTxForm)
          Wrap(
            spacing: 8,
            children: [
              EdenButton(
                label: 'Add cash drop',
                variant: EdenButtonVariant.secondary,
                outline: true,
                onPressed: () => setState(() {
                  _showAddTxForm = true;
                  _addTxIsDebit = true;
                  _txReasonController.text = 'Cash drop';
                }),
              ),
              EdenButton(
                label: 'Add petty cash',
                variant: EdenButtonVariant.secondary,
                outline: true,
                onPressed: () => setState(() {
                  _showAddTxForm = true;
                  _addTxIsDebit = true;
                  _txReasonController.text = 'Petty cash';
                }),
              ),
            ],
          )
        else
          _buildAddTxForm(),
      ],
    );
  }

  Widget _buildAddTxForm() {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _txAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: r'$',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _txReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                EdenButton(
                  label: 'Submit',
                  onPressed: _addTransaction,
                ),
                const SizedBox(width: 8),
                EdenButton(
                  label: 'Cancel',
                  variant: EdenButtonVariant.secondary,
                  outline: true,
                  onPressed: () =>
                      setState(() => _showAddTxForm = false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _depositCashController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Cash to deposit',
            prefixText: r'$',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _depositCheckAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Check amount',
                  prefixText: r'$',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _depositCheckCountController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: '#',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _depositMemoController,
          decoration: const InputDecoration(
            labelText: 'Memo',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        EdenButton(
          label: 'Skip deposit',
          variant: EdenButtonVariant.secondary,
          outline: true,
          onPressed: _skipDeposit,
        ),
      ],
    );
  }

  Widget _buildReviewBody() {
    final v = _session.computedVariance;
    final overLimit = v.abs() > 5.0;
    final managerNeeded =
        overLimit && widget.varianceManagerOverrideMessage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Starting float: \$${_session.startingFloat.toStringAsFixed(2)}'),
        Text(
            'Expected close: \$${_session.expectedClosingBalance.toStringAsFixed(2)}'),
        Text(
            'Counted close: \$${_session.countedClosingBalance.toStringAsFixed(2)}'),
        Text('Variance: \$${v.toStringAsFixed(2)}',
            style: TextStyle(
                color: _varianceColor(), fontWeight: FontWeight.w700)),
        if (!_depositSkipped && widget.allowDeposit) ...[
          const SizedBox(height: 8),
          Text(
              'Deposit cash: \$${(double.tryParse(_depositCashController.text) ?? 0).toStringAsFixed(2)}'),
          Text(
              'Deposit checks: ${_depositCheckCountController.text} × \$${(double.tryParse(_depositCheckAmountController.text) ?? 0).toStringAsFixed(2)}'),
        ],
        if (managerNeeded) ...[
          const SizedBox(height: 12),
          EdenBanner(
            message: widget.varianceManagerOverrideMessage!,
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
          const SizedBox(height: 8),
          if (!_managerApproved)
            EdenButton(
              label: 'Manager approves',
              variant: EdenButtonVariant.secondary,
              outline: true,
              onPressed: () => setState(() => _managerApproved = true),
            )
          else
            const EdenBanner(
              message: 'Manager-approved variance',
              variant: EdenBannerVariant.info,
              dismissible: false,
            ),
        ],
      ],
    );
  }

  Widget _buildNavRow() {
    final isCount = _step == EdenCashDrawerCloseStep.count;
    final isReview = _step == EdenCashDrawerCloseStep.review;
    final v = _session.computedVariance;
    final overLimit = v.abs() > 5.0;
    final managerGate =
        overLimit && widget.varianceManagerOverrideMessage != null;
    final confirmDisabled = isReview && managerGate && !_managerApproved;
    final completeLabel =
        'Complete checkout, total \$${_session.countedClosingBalance.toStringAsFixed(2)}';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!isCount)
          EdenButton(
            label: 'Back',
            variant: EdenButtonVariant.secondary,
            outline: true,
            onPressed: _retreat,
          ),
        if (!isReview)
          EdenButton(
            label: 'Continue',
            onPressed: _advance,
          )
        else
          Semantics(
            label: completeLabel,
            container: true,
            excludeSemantics: true,
            child: EdenButton(
              label: 'Confirm close',
              variant: EdenButtonVariant.primary,
              onPressed: confirmDisabled ? null : _confirmClose,
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_app_mode.dart' show kEdenAppModeCompactMax;
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';

/// Modes of [EdenGiftCardManager].
enum EdenGiftCardMode { issue, redeem, lookup, balance, ledger }

/// Action recorded in a gift-card ledger entry.
enum EdenGiftCardLedgerAction { issue, redeem, refund, reload, adjustment }

/// A gift-card record. Library masks the [code] for display — callers
/// pass either the full code or the last-4 chars.
@immutable
class EdenGiftCardRecord {
  const EdenGiftCardRecord({
    required this.code,
    required this.initialAmount,
    required this.currentBalance,
    required this.issuedAt,
    this.recipientName,
    this.recipientContact,
    this.expiresAt,
    this.notes,
  });

  final String code;
  final double initialAmount;
  final double currentBalance;
  final DateTime issuedAt;
  final String? recipientName;
  final String? recipientContact;
  final DateTime? expiresAt;
  final String? notes;

  EdenGiftCardRecord copyWith({
    String? code,
    double? initialAmount,
    double? currentBalance,
    DateTime? issuedAt,
    String? recipientName,
    String? recipientContact,
    DateTime? expiresAt,
    String? notes,
  }) {
    return EdenGiftCardRecord(
      code: code ?? this.code,
      initialAmount: initialAmount ?? this.initialAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      issuedAt: issuedAt ?? this.issuedAt,
      recipientName: recipientName ?? this.recipientName,
      recipientContact: recipientContact ?? this.recipientContact,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
    );
  }
}

/// A single audit-trail entry in a gift-card ledger.
@immutable
class EdenGiftCardLedgerEntry {
  const EdenGiftCardLedgerEntry({
    required this.occurredAt,
    required this.action,
    required this.amount,
    required this.balanceAfter,
    this.memo,
  });

  final DateTime occurredAt;
  final EdenGiftCardLedgerAction action;
  final double amount;
  final double balanceAfter;
  final String? memo;
}

/// Draft emitted on every keystroke when [EdenGiftCardManager.mode]
/// is [EdenGiftCardMode.issue].
@immutable
class EdenGiftCardIssueDraft {
  const EdenGiftCardIssueDraft({
    required this.amount,
    this.recipientName,
    this.recipientContact,
    this.expiresAt,
    this.notes,
  });

  final double amount;
  final String? recipientName;
  final String? recipientContact;
  final DateTime? expiresAt;
  final String? notes;

  EdenGiftCardIssueDraft copyWith({
    double? amount,
    String? recipientName,
    String? recipientContact,
    DateTime? expiresAt,
    String? notes,
  }) {
    return EdenGiftCardIssueDraft(
      amount: amount ?? this.amount,
      recipientName: recipientName ?? this.recipientName,
      recipientContact: recipientContact ?? this.recipientContact,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
    );
  }
}

/// Draft emitted on every keystroke when [EdenGiftCardManager.mode]
/// is [EdenGiftCardMode.redeem].
@immutable
class EdenGiftCardRedeemDraft {
  const EdenGiftCardRedeemDraft({
    required this.code,
    required this.amountToApply,
    required this.balanceBefore,
  });

  final String code;
  final double amountToApply;
  final double balanceBefore;

  EdenGiftCardRedeemDraft copyWith({
    String? code,
    double? amountToApply,
    double? balanceBefore,
  }) {
    return EdenGiftCardRedeemDraft(
      code: code ?? this.code,
      amountToApply: amountToApply ?? this.amountToApply,
      balanceBefore: balanceBefore ?? this.balanceBefore,
    );
  }
}

/// Masks a gift-card code to `'•••• <last4>'`.
@visibleForTesting
String maskGiftCardCode(String code) {
  if (code.isEmpty) return '•••• ';
  final last = code.substring(math.max(0, code.length - 4));
  return '•••• $last';
}

/// Multi-mode gift-card manager (obj 015-03).
///
/// One widget, 5 modes (issue / redeem / lookup / balance / ledger).
/// The parent controls the mode; the library never auto-toggles.
class EdenGiftCardManager extends StatefulWidget {
  const EdenGiftCardManager({
    super.key,
    required this.mode,
    required this.onDraftChanged,
    this.record,
    this.ledgerEntries,
    this.onLookup,
    this.currencyCode = 'USD',
    this.checkoutSubtotal,
  });

  final EdenGiftCardMode mode;
  final ValueChanged<dynamic> onDraftChanged;
  final EdenGiftCardRecord? record;
  final List<EdenGiftCardLedgerEntry>? ledgerEntries;
  final FutureOr<EdenGiftCardRecord?> Function(String code)? onLookup;
  final String currencyCode;
  final double? checkoutSubtotal;

  @override
  State<EdenGiftCardManager> createState() => _EdenGiftCardManagerState();
}

class _EdenGiftCardManagerState extends State<EdenGiftCardManager> {
  // ISSUE controllers
  final _issueAmountController = TextEditingController();
  final _issueRecipientNameController = TextEditingController();
  final _issueRecipientContactController = TextEditingController();
  final _issueNotesController = TextEditingController();
  DateTime? _issueExpiresAt;

  // REDEEM controllers
  late TextEditingController _redeemAmountController;

  // LOOKUP controllers
  final _lookupCodeController = TextEditingController();
  EdenGiftCardRecord? _lookedUpRecord;
  bool _lookupNotFound = false;
  bool _lookupInProgress = false;

  @override
  void initState() {
    super.initState();
    _redeemAmountController =
        TextEditingController(text: _redeemPrefill().toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(EdenGiftCardManager old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      // Mode changed — clear lookup state and re-seed redeem prefill.
      setState(() {
        _lookedUpRecord = null;
        _lookupNotFound = false;
        _redeemAmountController.text = _redeemPrefill().toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _issueAmountController.dispose();
    _issueRecipientNameController.dispose();
    _issueRecipientContactController.dispose();
    _issueNotesController.dispose();
    _redeemAmountController.dispose();
    _lookupCodeController.dispose();
    super.dispose();
  }

  double _redeemPrefill() {
    final r = widget.record;
    if (r == null) return 0;
    if (widget.checkoutSubtotal == null) return r.currentBalance;
    return math.min(r.currentBalance, widget.checkoutSubtotal!);
  }

  void _emitIssueDraft() {
    widget.onDraftChanged(EdenGiftCardIssueDraft(
      amount: double.tryParse(_issueAmountController.text) ?? 0,
      recipientName: _issueRecipientNameController.text.isEmpty
          ? null
          : _issueRecipientNameController.text,
      recipientContact: _issueRecipientContactController.text.isEmpty
          ? null
          : _issueRecipientContactController.text,
      expiresAt: _issueExpiresAt,
      notes: _issueNotesController.text.isEmpty
          ? null
          : _issueNotesController.text,
    ));
  }

  void _emitRedeemDraft() {
    final r = widget.record;
    if (r == null) return;
    final amount = double.tryParse(_redeemAmountController.text) ?? 0;
    widget.onDraftChanged(EdenGiftCardRedeemDraft(
      code: r.code,
      amountToApply: amount,
      balanceBefore: r.currentBalance,
    ));
  }

  Future<void> _runLookup() async {
    if (widget.onLookup == null) return;
    final code = _lookupCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _lookupInProgress = true;
      _lookupNotFound = false;
      _lookedUpRecord = null;
    });
    final result = await widget.onLookup!(code);
    if (!mounted) return;
    setState(() {
      _lookupInProgress = false;
      if (result == null) {
        _lookupNotFound = true;
      } else {
        _lookedUpRecord = result;
      }
    });
  }

  Color _balanceColor(BuildContext context, double balance) {
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    if (balance <= 0) return palette.dangerFg;
    return palette.successFg;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case EdenGiftCardMode.issue:
        return _buildIssue();
      case EdenGiftCardMode.redeem:
        return _buildRedeem();
      case EdenGiftCardMode.lookup:
        return _buildLookup();
      case EdenGiftCardMode.balance:
        return _buildBalance();
      case EdenGiftCardMode.ledger:
        return _buildLedger();
    }
  }

  Widget _buildIssue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _issueAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Initial amount',
            prefixText: r'$',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            setState(() {});
            _emitIssueDraft();
          },
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextFormField(
          controller: _issueRecipientNameController,
          decoration: const InputDecoration(
            labelText: 'Recipient name',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emitIssueDraft(),
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextFormField(
          controller: _issueRecipientContactController,
          decoration: const InputDecoration(
            labelText: 'Recipient contact',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emitIssueDraft(),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Row(
          children: [
            const Text('Expires: '),
            const SizedBox(width: EdenSpacing.space2),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) {
                  setState(() => _issueExpiresAt = picked);
                  _emitIssueDraft();
                }
              },
              child: Text(_issueExpiresAt == null
                  ? 'No expiry'
                  : _formatDate(_issueExpiresAt!)),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextFormField(
          controller: _issueNotesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emitIssueDraft(),
        ),
        const SizedBox(height: EdenSpacing.space3),
        Row(
          children: [
            const Text('Preview: ',
                style: TextStyle(fontWeight: FontWeight.w600)),
            EdenCurrencyDisplay(
              cents: ((double.tryParse(_issueAmountController.text) ?? 0) * 100)
                  .round(),
              currencyCode: widget.currencyCode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRedeem() {
    final r = widget.record;
    if (r == null) {
      return const EdenBanner(
        message: 'No card record provided',
        variant: EdenBannerVariant.warning,
        dismissible: false,
      );
    }
    final masked = maskGiftCardCode(r.code);
    final typedAmount = double.tryParse(_redeemAmountController.text) ?? 0;
    final overBalance = typedAmount > r.currentBalance + 0.001;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label:
              'Card ending in ${r.code.substring(math.max(0, r.code.length - 4))}',
          container: true,
          excludeSemantics: true,
          child: Text(masked,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Semantics(
          label: 'Current balance: \$${r.currentBalance.toStringAsFixed(2)}',
          child: Row(
            children: [
              const Text('Balance: '),
              EdenCurrencyDisplay(
                cents: (r.currentBalance * 100).round(),
                currencyCode: widget.currencyCode,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _balanceColor(context, r.currentBalance),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        TextFormField(
          controller: _redeemAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount to apply',
            prefixText: r'$',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            setState(() {});
            _emitRedeemDraft();
          },
        ),
        if (overBalance) ...[
          const SizedBox(height: EdenSpacing.space2),
          const EdenBanner(
            message: 'Amount exceeds balance',
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
        ],
        if (widget.onLookup != null) ...[
          const SizedBox(height: EdenSpacing.space2),
          EdenButton(
            label: 'Scan card',
            variant: EdenButtonVariant.secondary,
            outline: true,
            onPressed: () async {
              // Library does not embed a real scanner — consumer wires
              // the platform plugin via onLookup with a scanned code.
              // For dev-catalog smoke testing, this acts as a hook.
              final result = await widget.onLookup!('scanned-stub');
              if (!mounted) return;
              if (result != null) {
                setState(() {});
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLookup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _lookupCodeController,
          decoration: const InputDecoration(
            labelText: 'Gift card code',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Row(
          children: [
            EdenButton(
              label: 'Lookup',
              onPressed: _lookupInProgress ? null : _runLookup,
            ),
            const SizedBox(width: EdenSpacing.space2),
            EdenButton(
              label: 'Scan',
              variant: EdenButtonVariant.secondary,
              outline: true,
              onPressed: () async {
                if (widget.onLookup == null) return;
                final result = await widget.onLookup!('scanned-stub');
                if (!mounted) return;
                setState(() {
                  if (result == null) {
                    _lookupNotFound = true;
                  } else {
                    _lookedUpRecord = result;
                    _lookupNotFound = false;
                  }
                });
              },
            ),
          ],
        ),
        if (_lookupInProgress) ...[
          const SizedBox(height: EdenSpacing.space3),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_lookupNotFound) ...[
          const SizedBox(height: EdenSpacing.space2),
          const EdenBanner(
            message: 'Card not found',
            variant: EdenBannerVariant.danger,
            dismissible: false,
          ),
        ],
        if (_lookedUpRecord != null) ...[
          const SizedBox(height: EdenSpacing.space3),
          _balanceBody(_lookedUpRecord!),
        ],
      ],
    );
  }

  Widget _buildBalance() {
    final r = widget.record;
    if (r == null) {
      return const EdenBanner(
        message: 'No card record provided',
        variant: EdenBannerVariant.warning,
        dismissible: false,
      );
    }
    return _balanceBody(r);
  }

  Widget _balanceBody(EdenGiftCardRecord r) {
    final masked = maskGiftCardCode(r.code);
    final last4 = r.code.substring(math.max(0, r.code.length - 4));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Card ending in $last4',
          container: true,
          excludeSemantics: true,
          child: Text(masked,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Semantics(
          label: 'Current balance: \$${r.currentBalance.toStringAsFixed(2)}',
          excludeSemantics: true,
          child: EdenCurrencyDisplay(
            cents: (r.currentBalance * 100).round(),
            currencyCode: widget.currencyCode,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: _balanceColor(context, r.currentBalance),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'Initial: \$${r.initialAmount.toStringAsFixed(2)} • '
          'Issued: ${_formatDate(r.issuedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        if (r.recipientName != null)
          Text('Recipient: ${r.recipientName}',
              style: theme.textTheme.bodySmall),
        if (r.recipientContact != null)
          Text('Contact: ${r.recipientContact}',
              style: theme.textTheme.bodySmall),
        Text(
          'Expires: '
          '${r.expiresAt == null ? 'no expiry' : _formatDate(r.expiresAt!)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLedger() {
    final r = widget.record;
    final entries = widget.ledgerEntries ?? const <EdenGiftCardLedgerEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (r != null) _balanceBody(r),
        const SizedBox(height: EdenSpacing.space3),
        if (entries.isEmpty)
          const Text('No activity yet.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < kEdenAppModeCompactMax;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: EdenSpacing.space2),
                        child: EdenCard(
                          child: Padding(
                            padding: const EdgeInsets.all(EdenSpacing.space2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${_formatDate(e.occurredAt)}'
                                    ' — ${e.action.name}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text('Amount: \$${e.amount.toStringAsFixed(2)} '
                                    '• Balance after: \$${e.balanceAfter.toStringAsFixed(2)}'),
                                if (e.memo != null) Text('Memo: ${e.memo}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Balance after')),
                    DataColumn(label: Text('Memo')),
                  ],
                  rows: [
                    for (final e in entries)
                      DataRow(cells: [
                        DataCell(Text(_formatDate(e.occurredAt))),
                        DataCell(Text(e.action.name)),
                        DataCell(Text('\$${e.amount.toStringAsFixed(2)}')),
                        DataCell(
                            Text('\$${e.balanceAfter.toStringAsFixed(2)}')),
                        DataCell(Text(e.memo ?? '')),
                      ]),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}

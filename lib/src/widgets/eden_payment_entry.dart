import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_chip.dart';

/// Allowed payment methods used by [EdenPaymentEntry] + [EdenSplitTender].
///
/// `displayLabel` powers the chip label. `iconData` provides a default
/// avatar. `requiresReference` is consumed by the reference-visibility
/// rules in [EdenPaymentEntry] (see [EdenPaymentEntry.requireReference]
/// for `accountOnFile` + `other` override semantics).
enum EdenPaymentMethod {
  cash,
  card,
  ach,
  check,
  portal,
  giftCard,
  accountOnFile,
  other;

  String get displayLabel => switch (this) {
        cash => 'Cash',
        card => 'Card',
        ach => 'ACH',
        check => 'Check',
        portal => 'Portal',
        giftCard => 'Gift card',
        accountOnFile => 'Account',
        other => 'Other',
      };

  IconData get iconData => switch (this) {
        cash => Icons.payments_outlined,
        card => Icons.credit_card,
        ach => Icons.account_balance_outlined,
        check => Icons.receipt_long_outlined,
        portal => Icons.public,
        giftCard => Icons.card_giftcard,
        accountOnFile => Icons.person_outline,
        other => Icons.more_horiz,
      };
}

/// Immutable payment-entry draft emitted by [EdenPaymentEntry.onDraftChanged].
///
/// Transport-agnostic — this widget produces intent. Consumer wires the
/// actual payment processor (Stripe, Square, Adyen, etc.).
class EdenPaymentDraft {
  const EdenPaymentDraft({
    required this.method,
    required this.amount,
    this.reference,
    this.note,
    this.capturedAt,
  });

  final EdenPaymentMethod method;
  final double amount;

  /// Method-specific reference — last-4 of card, check #, ACH last-4,
  /// portal confirmation #, gift card #, etc.
  final String? reference;

  /// Free-form operator note ("tip included", "split with table 4").
  final String? note;

  /// Optional capture timestamp set by the consumer at submission time.
  /// The widget never sets this — leaves it null in the emitted draft.
  final DateTime? capturedAt;

  EdenPaymentDraft copyWith({
    EdenPaymentMethod? method,
    double? amount,
    String? reference,
    String? note,
    DateTime? capturedAt,
  }) =>
      EdenPaymentDraft(
        method: method ?? this.method,
        amount: amount ?? this.amount,
        reference: reference ?? this.reference,
        note: note ?? this.note,
        capturedAt: capturedAt ?? this.capturedAt,
      );
}

/// Payment-method picker + amount + reference + note entry (obj 012-03).
///
/// Configurable allowed-method allowlist (consumer constrains POS to
/// cash+card+gift, medical to card+check+portal, trades to card+ACH+check,
/// fuel POD to cash+card+account). Emits [EdenPaymentDraft] via
/// [onDraftChanged] on every field change.
///
/// **No submit button.** This widget is fully real-time-controlled by
/// the consumer; downstream code renders the submit UI.
class EdenPaymentEntry extends StatefulWidget {
  const EdenPaymentEntry({
    super.key,
    required this.allowedMethods,
    required this.onDraftChanged,
    this.initialDraft,
    this.expectedAmount,
    this.currencyCode = 'USD',
    this.requireReference = false,
  });

  /// The methods the consumer permits for this flow. Order is preserved
  /// in the chip rendering.
  final List<EdenPaymentMethod> allowedMethods;

  /// Real-time draft callback — fires on every field change.
  final ValueChanged<EdenPaymentDraft> onDraftChanged;

  /// Pre-populates the form on first build.
  final EdenPaymentDraft? initialDraft;

  /// When set, the widget surfaces a non-blocking
  /// `EdenBanner(variant: warning)` if the entered amount differs from
  /// expected by more than \$0.01. The consumer decides whether to gate
  /// submission on the mismatch.
  final double? expectedAmount;

  /// ISO-4217 currency code (USD / EUR / GBP / CAD / AUD supported by
  /// the local symbol map below; unknown codes fall back to a "USD "
  /// prefix string).
  final String currencyCode;

  /// When true, makes the reference field required for `accountOnFile`
  /// and `other` methods (which default to no reference). Methods that
  /// always need a reference (card/ach/check/portal/giftCard) are
  /// unaffected by this flag.
  final bool requireReference;

  @override
  State<EdenPaymentEntry> createState() => _EdenPaymentEntryState();
}

class _EdenPaymentEntryState extends State<EdenPaymentEntry> {
  late EdenPaymentMethod _method;
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _method = widget.initialDraft?.method ?? widget.allowedMethods.first;
    _amountController = TextEditingController(
      text: widget.initialDraft?.amount == null
          ? ''
          : _formatDouble(widget.initialDraft!.amount),
    );
    _referenceController =
        TextEditingController(text: widget.initialDraft?.reference ?? '');
    _noteController =
        TextEditingController(text: widget.initialDraft?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Hand-built currency symbol map mirroring EdenCurrencyDisplay's
  /// constant set. Avoids pulling in `intl` (not in pubspec).
  static const Map<String, String> _currencySymbols = {
    'USD': r'$',
    'CAD': r'$',
    'AUD': r'$',
    'EUR': '€',
    'GBP': '£',
  };

  String _currencySymbol() =>
      _currencySymbols[widget.currencyCode] ?? '${widget.currencyCode} ';

  String _formatDouble(double v) {
    if (v == v.truncateToDouble()) return v.truncate().toString();
    return v.toString();
  }

  /// Hand-formatted "$100.00" for the mismatch banner. Mirrors the
  /// thousand-separator + 2-decimal pattern used by EdenCurrencyDisplay
  /// without bringing intl into the dependency graph.
  String _formatCurrency(double amount) {
    final symbol = _currencySymbol();
    final cents = (amount * 100).round();
    final absCents = cents.abs();
    final whole = absCents ~/ 100;
    final fraction = absCents % 100;
    final wholeStr = _formatThousands(whole);
    final formatted = '$symbol$wholeStr.${fraction.toString().padLeft(2, '0')}';
    return cents < 0 ? '-$formatted' : formatted;
  }

  static String _formatThousands(int value) {
    final raw = value.toString();
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

  bool _showReference() {
    if (_method == EdenPaymentMethod.cash) return false;
    if (_method == EdenPaymentMethod.accountOnFile ||
        _method == EdenPaymentMethod.other) {
      return widget.requireReference;
    }
    return true;
  }

  String _referenceHint() => switch (_method) {
        EdenPaymentMethod.card => 'Last 4 of card',
        EdenPaymentMethod.ach => 'Account last 4',
        EdenPaymentMethod.check => 'Check #',
        EdenPaymentMethod.portal => 'Confirmation #',
        EdenPaymentMethod.giftCard => 'Gift card #',
        EdenPaymentMethod.accountOnFile => 'Account ID',
        EdenPaymentMethod.other => 'Reference',
        _ => '',
      };

  void _emit() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final reference =
        _referenceController.text.isEmpty ? null : _referenceController.text;
    final note = _noteController.text.isEmpty ? null : _noteController.text;
    widget.onDraftChanged(EdenPaymentDraft(
      method: _method,
      amount: amount,
      reference: reference,
      note: note,
    ));
  }

  Widget? _amountMismatchBanner() {
    if (widget.expectedAmount == null) return null;
    if (_amountController.text.isEmpty) return null;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final diff = (amount - widget.expectedAmount!).abs();
    // Use a slightly-relaxed tolerance to absorb floating-point noise from
    // computations like (99.99 - 100.0).abs() which can produce 0.01000...
    // due to IEEE 754 rounding.
    if (diff <= 0.011) return null;
    final expected = _formatCurrency(widget.expectedAmount!);
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space2),
      child: EdenBanner(
        message: 'Amount differs from expected: $expected',
        variant: EdenBannerVariant.warning,
        dismissible: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showReference = _showReference();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: EdenSpacing.space2,
          runSpacing: EdenSpacing.space2,
          children: [
            for (final m in widget.allowedMethods)
              Semantics(
                label:
                    '${m.displayLabel} payment method, ${m == _method ? 'selected' : 'not selected'}',
                container: true,
                excludeSemantics: true,
                child: EdenChoiceChip(
                  label: m.displayLabel,
                  icon: m.iconData,
                  selected: m == _method,
                  onSelected: (_) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _method = m);
                    _emit();
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space3),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: _currencySymbol(),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) {
            // setState so the mismatch banner re-evaluates against the new
            // amount entry.
            setState(() {});
            _emit();
          },
        ),
        if (_amountMismatchBanner() != null) _amountMismatchBanner()!,
        if (showReference) ...[
          const SizedBox(height: EdenSpacing.space3),
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: _referenceHint(),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => _emit(),
          ),
        ],
        const SizedBox(height: EdenSpacing.space3),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}

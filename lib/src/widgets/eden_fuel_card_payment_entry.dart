import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_input.dart';

/// Fleet-card networks Eden's fuel module supports out-of-the-box.
enum EdenFuelCardNetwork { fleetCor, wex, voyager, efs, generic }

/// Kind of prompt for a per-transaction fleet-card field.
enum EdenFuelCardPromptKind { text, numeric, numericPin, odometer }

/// Declarative spec for a single network-specific prompt field.
@immutable
class EdenFuelCardPromptSpec {
  const EdenFuelCardPromptSpec({
    required this.fieldKey,
    required this.label,
    required this.kind,
    required this.required,
    this.maxLength,
    this.regexPattern,
    this.hint,
  });

  final String fieldKey;
  final String label;
  final EdenFuelCardPromptKind kind;
  final bool required;
  final int? maxLength;
  final String? regexPattern;
  final String? hint;
}

/// Emit-only draft captured by [EdenFuelCardPaymentEntry.onSubmit].
@immutable
class EdenFuelCardPaymentDraft {
  const EdenFuelCardPaymentDraft({
    required this.network,
    required this.panLast4,
    required this.promptValues,
    required this.amountUsd,
    this.receiptEmail,
  });

  final EdenFuelCardNetwork network;

  /// Only last 4 of PAN. Full PAN handled via consumer tokenization (PCI
  /// scope reduction).
  final String panLast4;
  final Map<String, String> promptValues;
  final double amountUsd;
  final String? receiptEmail;
}

/// Network-aware fuel card payment flow. 4-step: Card → Prompts → Amount →
/// Confirmation. Consumer supplies hardware swipe + tokenization callbacks.
class EdenFuelCardPaymentEntry extends StatefulWidget {
  const EdenFuelCardPaymentEntry({
    super.key,
    required this.network,
    required this.onSubmit,
    this.onCancel,
    this.prefilledAmount,
    this.promptsOverride,
    this.onSwipeCard,
  });

  final EdenFuelCardNetwork network;
  final ValueChanged<EdenFuelCardPaymentDraft> onSubmit;
  final VoidCallback? onCancel;
  final double? prefilledAmount;
  final List<EdenFuelCardPromptSpec>? promptsOverride;
  final Future<String> Function(BuildContext)? onSwipeCard;

  /// Built-in default prompts per network.
  static List<EdenFuelCardPromptSpec> defaultPromptsFor(
      EdenFuelCardNetwork n) {
    switch (n) {
      case EdenFuelCardNetwork.fleetCor:
        return const [
          EdenFuelCardPromptSpec(
            fieldKey: 'driverId',
            label: 'Driver ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
            maxLength: 8,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'vehicleId',
            label: 'Vehicle ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'odometer',
            label: 'Odometer (mi)',
            kind: EdenFuelCardPromptKind.odometer,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'tripNumber',
            label: 'Trip number',
            kind: EdenFuelCardPromptKind.text,
            required: false,
          ),
        ];
      case EdenFuelCardNetwork.wex:
        return const [
          EdenFuelCardPromptSpec(
            fieldKey: 'driverId',
            label: 'Driver ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'odometer',
            label: 'Odometer (mi)',
            kind: EdenFuelCardPromptKind.odometer,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'purchaseDeviceId',
            label: 'Purchase device ID',
            kind: EdenFuelCardPromptKind.text,
            required: false,
          ),
        ];
      case EdenFuelCardNetwork.voyager:
        return const [
          EdenFuelCardPromptSpec(
            fieldKey: 'driverId',
            label: 'Driver ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'vehicleId',
            label: 'Vehicle ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'customPrompt1',
            label: 'Custom prompt',
            kind: EdenFuelCardPromptKind.text,
            required: false,
          ),
        ];
      case EdenFuelCardNetwork.efs:
        return const [
          EdenFuelCardPromptSpec(
            fieldKey: 'driverId',
            label: 'Driver ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'vehicleId',
            label: 'Vehicle ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'odometer',
            label: 'Odometer (mi)',
            kind: EdenFuelCardPromptKind.odometer,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'tripNumber',
            label: 'Trip number',
            kind: EdenFuelCardPromptKind.text,
            required: false,
          ),
        ];
      case EdenFuelCardNetwork.generic:
        return const [
          EdenFuelCardPromptSpec(
            fieldKey: 'driverId',
            label: 'Driver ID',
            kind: EdenFuelCardPromptKind.text,
            required: true,
          ),
          EdenFuelCardPromptSpec(
            fieldKey: 'vehicleId',
            label: 'Vehicle ID',
            kind: EdenFuelCardPromptKind.text,
            required: false,
          ),
        ];
    }
  }

  static String networkLabel(EdenFuelCardNetwork n) {
    switch (n) {
      case EdenFuelCardNetwork.fleetCor:
        return 'FleetCor';
      case EdenFuelCardNetwork.wex:
        return 'WEX';
      case EdenFuelCardNetwork.voyager:
        return 'Voyager';
      case EdenFuelCardNetwork.efs:
        return 'EFS';
      case EdenFuelCardNetwork.generic:
        return 'Generic fleet card';
    }
  }

  @override
  State<EdenFuelCardPaymentEntry> createState() =>
      _EdenFuelCardPaymentEntryState();
}

class _EdenFuelCardPaymentEntryState extends State<EdenFuelCardPaymentEntry> {
  int _step = 0;

  final TextEditingController _panCtrl = TextEditingController();
  late TextEditingController _amountCtrl;
  final TextEditingController _emailCtrl = TextEditingController();
  late Map<String, TextEditingController> _promptCtrls;
  late List<EdenFuelCardPromptSpec> _prompts;

  @override
  void initState() {
    super.initState();
    _prompts = widget.promptsOverride ??
        EdenFuelCardPaymentEntry.defaultPromptsFor(widget.network);
    _promptCtrls = {
      for (final p in _prompts) p.fieldKey: TextEditingController(),
    };
    _amountCtrl = TextEditingController(
        text: widget.prefilledAmount?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _panCtrl.dispose();
    _amountCtrl.dispose();
    _emailCtrl.dispose();
    for (final c in _promptCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _panLast4 {
    final p = _panCtrl.text;
    return p.length >= 4 ? p.substring(p.length - 4) : p;
  }

  bool _step1Valid() => _panCtrl.text.length >= 4;
  bool _step2Valid() {
    for (final p in _prompts) {
      if (p.required && (_promptCtrls[p.fieldKey]?.text.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  bool _step3Valid() {
    final v = double.tryParse(_amountCtrl.text);
    return v != null && v > 0;
  }

  EdenFuelCardPaymentDraft _buildDraft() => EdenFuelCardPaymentDraft(
        network: widget.network,
        panLast4: _panLast4,
        promptValues: {
          for (final entry in _promptCtrls.entries)
            entry.key: entry.value.text,
        },
        amountUsd: double.tryParse(_amountCtrl.text) ?? 0,
        receiptEmail: _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
      );

  Future<void> _handleSwipe() async {
    final pan = await widget.onSwipeCard!(context);
    setState(() {
      _panCtrl.text = pan;
    });
  }

  @override
  Widget build(BuildContext context) {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(context),
            const SizedBox(height: EdenSpacing.space3),
            switch (_step) {
              0 => _buildStep1Card(context),
              1 => _buildStep2Prompts(context),
              2 => _buildStep3Amount(context),
              _ => _buildStep4Confirm(context),
            },
            const SizedBox(height: EdenSpacing.space3),
            _buildNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    const labels = ['Card', 'Prompts', 'Amount', 'Confirm'];
    return Row(
      children: [
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? Theme.of(context).colorScheme.primary
                        : EdenColors.neutral[200],
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(
                        color: i <= _step
                            ? Theme.of(context).colorScheme.onPrimary
                            : EdenColors.neutral[600],
                        fontWeight: FontWeight.w600,
                      )),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1Card(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, size: 18),
              const SizedBox(width: 6),
              Text(EdenFuelCardPaymentEntry.networkLabel(widget.network),
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        if (widget.onSwipeCard != null) ...[
          ElevatedButton.icon(
            key: const Key('fuel-card-swipe'),
            onPressed: _handleSwipe,
            icon: const Icon(Icons.tap_and_play),
            label: const Text('Swipe card'),
          ),
          const SizedBox(height: 8),
        ],
        EdenInput(
          controller: _panCtrl,
          label: 'Card number',
          hint: 'PAN — securely retained as last 4 only',
          obscureText: true,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        if (_panCtrl.text.length >= 4) ...[
          const SizedBox(height: 8),
          Text('Last 4: $_panLast4',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _buildStep2Prompts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in _prompts) ...[
          _promptField(context, p),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _promptField(BuildContext context, EdenFuelCardPromptSpec p) {
    final ctrl = _promptCtrls[p.fieldKey]!;
    switch (p.kind) {
      case EdenFuelCardPromptKind.numericPin:
        return EdenInput(
          controller: ctrl,
          label: p.label,
          obscureText: true,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        );
      case EdenFuelCardPromptKind.numeric:
      case EdenFuelCardPromptKind.odometer:
        return EdenInput(
          controller: ctrl,
          label: p.label,
          hint: p.hint,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        );
      case EdenFuelCardPromptKind.text:
        return EdenInput(
          controller: ctrl,
          label: p.label,
          hint: p.hint,
          onChanged: (_) => setState(() {}),
        );
    }
  }

  Widget _buildStep3Amount(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Fuel Card', textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        EdenInput(
          controller: _amountCtrl,
          label: 'Amount (USD)',
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        EdenInput(
          controller: _emailCtrl,
          label: 'Receipt email (optional)',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildStep4Confirm(BuildContext context) {
    final draft = _buildDraft();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _summaryRow(context, 'Network',
            EdenFuelCardPaymentEntry.networkLabel(draft.network)),
        _summaryRow(context, 'Card', '•••• ${draft.panLast4}'),
        _summaryRow(context, 'Amount', '\$${draft.amountUsd.toStringAsFixed(2)}'),
        for (final entry in draft.promptValues.entries)
          _summaryRow(context, entry.key, entry.value.isEmpty ? '—' : entry.value),
        if (draft.receiptEmail != null)
          _summaryRow(context, 'Receipt', draft.receiptEmail!),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step == 0 && widget.onCancel != null)
          TextButton(onPressed: widget.onCancel, child: const Text('Cancel'))
        else if (_step > 0)
          TextButton(
            key: const Key('fuel-card-back'),
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),
        if (_step < 3)
          ElevatedButton(
            key: const Key('fuel-card-next'),
            onPressed: _stepValid() ? () => setState(() => _step++) : null,
            child: const Text('Next'),
          )
        else
          ElevatedButton(
            key: const Key('fuel-card-submit'),
            onPressed: () => widget.onSubmit(_buildDraft()),
            child: const Text('Submit'),
          ),
      ],
    );
  }

  bool _stepValid() {
    if (_step == 0) return _step1Valid();
    if (_step == 1) return _step2Valid();
    if (_step == 2) return _step3Valid();
    return true;
  }
}

// Suppress unused-import warning if FilteringTextInputFormatter isn't used.
// ignore: unused_element
final _unusedFilter = FilteringTextInputFormatter.digitsOnly;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_chip.dart';
import 'eden_currency_display.dart';

/// Tip preset (e.g. 18% / 20% / 25%). Stored as fraction 0..1.
@immutable
class EdenTipPreset {
  const EdenTipPreset({required this.percent, required this.label});

  /// Percent as a fraction (0.18 == 18%).
  final double percent;

  /// Human-readable label (e.g. '18%').
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenTipPreset &&
          other.percent == percent &&
          other.label == label;

  @override
  int get hashCode => Object.hash(percent, label);
}

/// Curated tip preset arrays for the most common verticals.
///
/// Consumers may also pass a custom `List<EdenTipPreset>`.
class EdenTipPresets {
  EdenTipPresets._();

  /// Salon standard — 15 / 18 / 20 / 25.
  static const List<EdenTipPreset> salonStandard = <EdenTipPreset>[
    EdenTipPreset(percent: 0.15, label: '15%'),
    EdenTipPreset(percent: 0.18, label: '18%'),
    EdenTipPreset(percent: 0.20, label: '20%'),
    EdenTipPreset(percent: 0.25, label: '25%'),
  ];

  /// Restaurant standard — 18 / 20 / 22 / 25.
  static const List<EdenTipPreset> restaurantStandard = <EdenTipPreset>[
    EdenTipPreset(percent: 0.18, label: '18%'),
    EdenTipPreset(percent: 0.20, label: '20%'),
    EdenTipPreset(percent: 0.22, label: '22%'),
    EdenTipPreset(percent: 0.25, label: '25%'),
  ];

  /// Light tier — 10 / 15 / 18 / 20.
  static const List<EdenTipPreset> lightTier = <EdenTipPreset>[
    EdenTipPreset(percent: 0.10, label: '10%'),
    EdenTipPreset(percent: 0.15, label: '15%'),
    EdenTipPreset(percent: 0.18, label: '18%'),
    EdenTipPreset(percent: 0.20, label: '20%'),
  ];
}

/// Which form of tip the user has selected.
enum EdenTipMode { percent, fixedAmount, none }

/// Real-time tip draft emitted by [EdenTippingSelector].
@immutable
class EdenTipDraft {
  const EdenTipDraft({
    required this.mode,
    required this.tipAmount,
    this.selectedPercent,
    this.capturedAt,
  });

  /// Which form of tip was selected.
  final EdenTipMode mode;

  /// Computed tip in dollars (percent × subtotal, or the typed
  /// custom amount). Always >= 0.
  final double tipAmount;

  /// The selected preset percent (0..1) when [mode] is [EdenTipMode.percent].
  /// Null otherwise.
  final double? selectedPercent;

  /// Consumer fills at submit time; the library leaves it null.
  final DateTime? capturedAt;

  EdenTipDraft copyWith({
    EdenTipMode? mode,
    double? tipAmount,
    double? selectedPercent,
    DateTime? capturedAt,
  }) {
    return EdenTipDraft(
      mode: mode ?? this.mode,
      tipAmount: tipAmount ?? this.tipAmount,
      selectedPercent: selectedPercent ?? this.selectedPercent,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenTipDraft &&
          other.mode == mode &&
          other.tipAmount == tipAmount &&
          other.selectedPercent == selectedPercent &&
          other.capturedAt == capturedAt;

  @override
  int get hashCode =>
      Object.hash(mode, tipAmount, selectedPercent, capturedAt);
}

/// Tip selector (obj 015-01).
///
/// Preset percent chips + optional custom-amount field + optional no-tip
/// chip. Real-time emission via [onDraftChanged]; the widget never owns
/// a "Submit" button (consumer renders submit UI separately).
///
/// Transport-agnostic per the obj 012-03 EdenPaymentEntry contract:
/// downstream consumer code wires actual checkout flow.
class EdenTippingSelector extends StatefulWidget {
  const EdenTippingSelector({
    super.key,
    required this.subtotal,
    required this.onDraftChanged,
    this.presets = EdenTipPresets.salonStandard,
    this.allowCustom = true,
    this.allowNoTip = true,
    this.currencyCode = 'USD',
    this.initialDraft,
  });

  /// Line-items subtotal that tipping applies to (dollars).
  final double subtotal;

  /// Emitted on every preset selection / custom-amount keystroke /
  /// no-tip toggle.
  final ValueChanged<EdenTipDraft> onDraftChanged;

  /// Tip preset chips to render. Defaults to [EdenTipPresets.salonStandard].
  final List<EdenTipPreset> presets;

  /// Whether to show the 'Custom' chip + custom-amount field.
  final bool allowCustom;

  /// Whether to show the 'No tip' chip.
  final bool allowNoTip;

  /// ISO-4217 currency code for the computed-tip preview. Defaults USD.
  final String currencyCode;

  /// Optional initial draft (pre-population). When null, the widget
  /// starts in no-tip-not-yet-chosen state.
  final EdenTipDraft? initialDraft;

  @override
  State<EdenTippingSelector> createState() => _EdenTippingSelectorState();
}

class _EdenTippingSelectorState extends State<EdenTippingSelector> {
  late EdenTipDraft _draft;
  late TextEditingController _customController;
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ??
        const EdenTipDraft(mode: EdenTipMode.none, tipAmount: 0);
    _showCustomField = _draft.mode == EdenTipMode.fixedAmount;
    _customController = TextEditingController(
      text: _draft.mode == EdenTipMode.fixedAmount
          ? _draft.tipAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _emit(EdenTipDraft draft) {
    setState(() {
      _draft = draft;
    });
    widget.onDraftChanged(draft);
  }

  void _selectPreset(EdenTipPreset preset) {
    FocusScope.of(context).unfocus();
    final tip = widget.subtotal * preset.percent;
    setState(() {
      _showCustomField = false;
    });
    _emit(EdenTipDraft(
      mode: EdenTipMode.percent,
      tipAmount: tip,
      selectedPercent: preset.percent,
    ));
  }

  void _selectNoTip() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showCustomField = false;
    });
    _emit(const EdenTipDraft(mode: EdenTipMode.none, tipAmount: 0));
  }

  void _selectCustom() {
    setState(() {
      _showCustomField = true;
    });
    final parsed = double.tryParse(_customController.text) ?? 0.0;
    _emit(EdenTipDraft(
      mode: EdenTipMode.fixedAmount,
      tipAmount: parsed,
    ));
  }

  void _onCustomChanged(String raw) {
    final parsed = double.tryParse(raw) ?? 0.0;
    _emit(EdenTipDraft(
      mode: EdenTipMode.fixedAmount,
      tipAmount: parsed,
    ));
  }

  Color _selectedChipColor(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    return palette.infoBg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = _selectedChipColor(context);

    final presetChildren = <Widget>[
      for (final preset in widget.presets)
        _buildPresetChip(preset, selectedColor),
      if (widget.allowCustom) _buildCustomChip(selectedColor),
      if (widget.allowNoTip) _buildNoTipChip(selectedColor),
    ];

    final tipCents = (_draft.tipAmount * 100).round();
    final previewLabel = 'Tip amount: ${_formatCurrency(_draft.tipAmount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: EdenSpacing.space2,
          runSpacing: EdenSpacing.space2,
          children: presetChildren,
        ),
        if (_showCustomField) ...[
          const SizedBox(height: EdenSpacing.space3),
          TextFormField(
            controller: _customController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Custom tip amount',
              prefixText: r'$',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: _onCustomChanged,
          ),
        ],
        const SizedBox(height: EdenSpacing.space3),
        Semantics(
          label: previewLabel,
          liveRegion: true,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tip: ',
                style: theme.textTheme.bodyMedium,
              ),
              EdenCurrencyDisplay(
                cents: tipCents,
                currencyCode: widget.currencyCode,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(EdenTipPreset preset, Color selectedColor) {
    final isSelected = _draft.mode == EdenTipMode.percent &&
        _draft.selectedPercent == preset.percent;
    return Semantics(
      label: '${preset.label} tip, ${isSelected ? 'selected' : 'not selected'}',
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _selectPreset(preset),
        child: _chipShell(
          label: preset.label,
          isSelected: isSelected,
          selectedColor: selectedColor,
        ),
      ),
    );
  }

  Widget _buildCustomChip(Color selectedColor) {
    final isSelected =
        _draft.mode == EdenTipMode.fixedAmount || _showCustomField;
    return Semantics(
      label: 'Custom tip, ${isSelected ? 'selected' : 'not selected'}',
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _selectCustom,
        child: _chipShell(
          label: 'Custom',
          isSelected: isSelected,
          selectedColor: selectedColor,
        ),
      ),
    );
  }

  Widget _buildNoTipChip(Color selectedColor) {
    final isSelected = _draft.mode == EdenTipMode.none;
    return Semantics(
      label: 'No tip, ${isSelected ? 'selected' : 'not selected'}',
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _selectNoTip,
        child: _chipShell(
          label: 'No tip',
          isSelected: isSelected,
          selectedColor: selectedColor,
        ),
      ),
    );
  }

  Widget _chipShell({
    required String label,
    required bool isSelected,
    required Color selectedColor,
  }) {
    final theme = Theme.of(context);
    return EdenChip(
      label: label,
      variant: isSelected ? EdenChipVariant.tonal : EdenChipVariant.outlined,
      color: isSelected ? selectedColor : theme.colorScheme.primary,
      icon: isSelected ? Icons.check : null,
    );
  }

  static const Map<String, String> _currencySymbols = {
    'USD': r'$',
    'CAD': r'$',
    'AUD': r'$',
    'EUR': '€',
    'GBP': '£',
  };

  String _formatCurrency(double amount) {
    final symbol = _currencySymbols[widget.currencyCode] ??
        '${widget.currencyCode} ';
    final cents = (amount * 100).round();
    final absCents = cents.abs();
    final whole = absCents ~/ 100;
    final fraction = absCents % 100;
    final formatted =
        '$symbol$whole.${fraction.toString().padLeft(2, '0')}';
    return cents < 0 ? '-$formatted' : formatted;
  }
}

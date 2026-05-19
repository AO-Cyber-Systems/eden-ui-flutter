import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_app_mode.dart' show kEdenAppModeCompactMax;
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';
import 'eden_segmented_control.dart';

/// Modes of commission supported by [EdenCommissionsEditor].
enum EdenCommissionMode { percent, fixed, tiered, split }

/// A single tier in a tiered commission rule.
@immutable
class EdenCommissionTier {
  const EdenCommissionTier({
    required this.thresholdAmount,
    required this.rate,
  });

  /// The sale-amount floor for this tier (dollars).
  final double thresholdAmount;

  /// The rate (0..1 percent fraction OR fixed dollars depending on
  /// parent rule mode — by convention this lib uses percent for tiered
  /// rules).
  final double rate;

  EdenCommissionTier copyWith({
    double? thresholdAmount,
    double? rate,
  }) {
    return EdenCommissionTier(
      thresholdAmount: thresholdAmount ?? this.thresholdAmount,
      rate: rate ?? this.rate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenCommissionTier &&
          other.thresholdAmount == thresholdAmount &&
          other.rate == rate;

  @override
  int get hashCode => Object.hash(thresholdAmount, rate);
}

/// A participant in a split commission rule.
@immutable
class EdenCommissionSplitParticipant {
  const EdenCommissionSplitParticipant({
    required this.id,
    required this.displayName,
    required this.sharePercent,
  });

  /// Stable consumer-provided id.
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Fraction 0..1 — the participant's share of the commission.
  final double sharePercent;

  EdenCommissionSplitParticipant copyWith({
    String? id,
    String? displayName,
    double? sharePercent,
  }) {
    return EdenCommissionSplitParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      sharePercent: sharePercent ?? this.sharePercent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenCommissionSplitParticipant &&
          other.id == id &&
          other.displayName == displayName &&
          other.sharePercent == sharePercent;

  @override
  int get hashCode => Object.hash(id, displayName, sharePercent);
}

/// A commission rule. Generic across salon / retail / trades / medical.
@immutable
class EdenCommissionRule {
  const EdenCommissionRule({
    required this.id,
    required this.label,
    required this.mode,
    this.percent,
    this.fixedAmount,
    this.tiers,
    this.splits,
  });

  /// Stable consumer-provided id.
  final String id;

  /// Human-readable rule label (e.g. 'Senior stylist — 50%').
  final String label;

  /// Which mode the rule uses.
  final EdenCommissionMode mode;

  /// Used when [mode] is [EdenCommissionMode.percent] — fraction 0..1.
  final double? percent;

  /// Used when [mode] is [EdenCommissionMode.fixed] — dollars.
  final double? fixedAmount;

  /// Used when [mode] is [EdenCommissionMode.tiered]. Emitted sorted
  /// ascending by threshold.
  final List<EdenCommissionTier>? tiers;

  /// Used when [mode] is [EdenCommissionMode.split]. Each share is a
  /// fraction 0..1; consumer sees a danger banner when sum != 1.0.
  final List<EdenCommissionSplitParticipant>? splits;

  /// Direct constructor — `copyWith` semantics here intentionally pass
  /// raw values (no sentinel pattern). Use this to clear non-applicable
  /// fields when switching modes.
  EdenCommissionRule withRaw({
    String? id,
    String? label,
    EdenCommissionMode? mode,
    double? percent,
    double? fixedAmount,
    List<EdenCommissionTier>? tiers,
    List<EdenCommissionSplitParticipant>? splits,
  }) {
    return EdenCommissionRule(
      id: id ?? this.id,
      label: label ?? this.label,
      mode: mode ?? this.mode,
      percent: percent,
      fixedAmount: fixedAmount,
      tiers: tiers,
      splits: splits,
    );
  }

  EdenCommissionRule copyWith({
    String? id,
    String? label,
    EdenCommissionMode? mode,
    double? percent,
    double? fixedAmount,
    List<EdenCommissionTier>? tiers,
    List<EdenCommissionSplitParticipant>? splits,
  }) {
    return EdenCommissionRule(
      id: id ?? this.id,
      label: label ?? this.label,
      mode: mode ?? this.mode,
      percent: percent ?? this.percent,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      tiers: tiers ?? this.tiers,
      splits: splits ?? this.splits,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenCommissionRule &&
          other.id == id &&
          other.label == label &&
          other.mode == mode &&
          other.percent == percent &&
          other.fixedAmount == fixedAmount &&
          _listEq(other.tiers, tiers) &&
          _listEq(other.splits, splits);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        mode,
        percent,
        fixedAmount,
        tiers == null ? null : Object.hashAll(tiers!),
        splits == null ? null : Object.hashAll(splits!),
      );

  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Commission-rules editor (obj 015-04).
///
/// Generic across salon (stylist split), retail (associate %),
/// trades (technician tiered). Library produces drafts; the consumer
/// wires actual pay-out persistence.
class EdenCommissionsEditor extends StatefulWidget {
  const EdenCommissionsEditor({
    super.key,
    required this.rule,
    required this.onRuleChanged,
    this.currencyCode = 'USD',
    this.showLabelField = true,
    this.onAddParticipantTap,
  });

  /// Initial rule value (the widget owns the working copy in state).
  final EdenCommissionRule rule;

  /// Real-time emission on any keystroke / segment-change / tier-add.
  final ValueChanged<EdenCommissionRule> onRuleChanged;

  /// ISO-4217 currency code.
  final String currencyCode;

  /// Whether to show the rule-label TextField at the top.
  final bool showLabelField;

  /// Optional consumer-provided callback to add a participant in
  /// split mode. When null, the 'Add participant' button is hidden.
  final VoidCallback? onAddParticipantTap;

  @override
  State<EdenCommissionsEditor> createState() => _EdenCommissionsEditorState();
}

class _EdenCommissionsEditorState extends State<EdenCommissionsEditor> {
  late EdenCommissionRule _rule;
  late TextEditingController _labelController;
  late TextEditingController _percentController;
  late TextEditingController _fixedController;
  late List<TextEditingController> _tierThresholdControllers;
  late List<TextEditingController> _tierRateControllers;
  late List<TextEditingController> _splitShareControllers;

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
    _labelController = TextEditingController(text: _rule.label);
    _percentController = TextEditingController(
      text: _rule.percent != null
          ? (_rule.percent! * 100).toStringAsFixed(0)
          : '',
    );
    _fixedController = TextEditingController(
      text: _rule.fixedAmount?.toStringAsFixed(2) ?? '',
    );
    _rebuildTierControllers();
    _rebuildSplitControllers();
  }

  void _rebuildTierControllers() {
    final tiers = _rule.tiers ?? const <EdenCommissionTier>[];
    _tierThresholdControllers = [
      for (final t in tiers)
        TextEditingController(text: t.thresholdAmount.toStringAsFixed(2)),
    ];
    _tierRateControllers = [
      for (final t in tiers)
        TextEditingController(text: (t.rate * 100).toStringAsFixed(1)),
    ];
  }

  void _rebuildSplitControllers() {
    final splits = _rule.splits ?? const <EdenCommissionSplitParticipant>[];
    _splitShareControllers = [
      for (final s in splits)
        TextEditingController(text: (s.sharePercent * 100).toStringAsFixed(0)),
    ];
  }

  @override
  void dispose() {
    _labelController.dispose();
    _percentController.dispose();
    _fixedController.dispose();
    for (final c in _tierThresholdControllers) {
      c.dispose();
    }
    for (final c in _tierRateControllers) {
      c.dispose();
    }
    for (final c in _splitShareControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit(EdenCommissionRule rule) {
    setState(() {
      _rule = rule;
    });
    widget.onRuleChanged(rule);
  }

  void _onLabelChanged(String raw) {
    _emit(_rule.copyWith(label: raw));
  }

  void _onModeChange(EdenCommissionMode newMode) {
    if (newMode == _rule.mode) return;
    // Clear non-applicable fields, seed defaults for the new mode.
    EdenCommissionRule next;
    switch (newMode) {
      case EdenCommissionMode.percent:
        next = _rule.withRaw(mode: newMode, percent: _rule.percent);
        break;
      case EdenCommissionMode.fixed:
        next = _rule.withRaw(mode: newMode, fixedAmount: _rule.fixedAmount);
        break;
      case EdenCommissionMode.tiered:
        next = _rule.withRaw(
          mode: newMode,
          tiers: _rule.tiers ??
              const <EdenCommissionTier>[
                EdenCommissionTier(thresholdAmount: 0, rate: 0),
              ],
        );
        break;
      case EdenCommissionMode.split:
        next = _rule.withRaw(
          mode: newMode,
          splits: _rule.splits ?? const <EdenCommissionSplitParticipant>[],
        );
        break;
    }
    setState(() {
      _rule = next;
      _percentController.text =
          next.percent != null ? (next.percent! * 100).toStringAsFixed(0) : '';
      _fixedController.text = next.fixedAmount?.toStringAsFixed(2) ?? '';
      _rebuildTierControllers();
      _rebuildSplitControllers();
    });
    widget.onRuleChanged(next);
  }

  void _onPercentChanged(String raw) {
    final parsed = double.tryParse(raw);
    final fraction = parsed == null ? null : (parsed / 100.0).clamp(0.0, 1.0);
    _emit(_rule.withRaw(mode: EdenCommissionMode.percent, percent: fraction));
  }

  void _onFixedChanged(String raw) {
    final parsed = double.tryParse(raw);
    _emit(_rule.withRaw(
      mode: EdenCommissionMode.fixed,
      fixedAmount: parsed,
    ));
  }

  void _onTierThresholdChanged(int index, String raw) {
    final tiers = List<EdenCommissionTier>.from(_rule.tiers ?? const []);
    if (index >= tiers.length) return;
    final parsed = double.tryParse(raw) ?? 0.0;
    tiers[index] = tiers[index].copyWith(thresholdAmount: parsed);
    _emit(_rule.withRaw(
        mode: EdenCommissionMode.tiered, tiers: _sortedTiers(tiers)));
  }

  void _onTierRateChanged(int index, String raw) {
    final tiers = List<EdenCommissionTier>.from(_rule.tiers ?? const []);
    if (index >= tiers.length) return;
    final parsed = double.tryParse(raw) ?? 0.0;
    final asFraction = (parsed / 100.0).clamp(0.0, 1.0);
    tiers[index] = tiers[index].copyWith(rate: asFraction);
    _emit(_rule.withRaw(
        mode: EdenCommissionMode.tiered, tiers: _sortedTiers(tiers)));
  }

  List<EdenCommissionTier> _sortedTiers(List<EdenCommissionTier> tiers) {
    final sorted = List<EdenCommissionTier>.from(tiers)
      ..sort((a, b) => a.thresholdAmount.compareTo(b.thresholdAmount));
    return sorted;
  }

  void _onAddTier() {
    final tiers = List<EdenCommissionTier>.from(_rule.tiers ?? const []);
    tiers.add(const EdenCommissionTier(thresholdAmount: 0, rate: 0));
    final sorted = _sortedTiers(tiers);
    setState(() {
      _rule = _rule.withRaw(mode: EdenCommissionMode.tiered, tiers: sorted);
      _rebuildTierControllers();
    });
    widget.onRuleChanged(_rule);
  }

  void _onRemoveTier(int index) {
    final tiers = List<EdenCommissionTier>.from(_rule.tiers ?? const []);
    if (tiers.length <= 1) return;
    if (index >= tiers.length) return;
    tiers.removeAt(index);
    setState(() {
      _rule = _rule.withRaw(mode: EdenCommissionMode.tiered, tiers: tiers);
      _rebuildTierControllers();
    });
    widget.onRuleChanged(_rule);
  }

  void _onSplitShareChanged(int index, String raw) {
    final splits =
        List<EdenCommissionSplitParticipant>.from(_rule.splits ?? const []);
    if (index >= splits.length) return;
    final parsed = double.tryParse(raw) ?? 0.0;
    final asFraction = (parsed / 100.0).clamp(0.0, 1.0);
    splits[index] = splits[index].copyWith(sharePercent: asFraction);
    _emit(_rule.withRaw(mode: EdenCommissionMode.split, splits: splits));
  }

  bool get _splitBalanced {
    final splits = _rule.splits ?? const <EdenCommissionSplitParticipant>[];
    if (splits.isEmpty) return false;
    final sum = splits.fold<double>(0, (acc, s) => acc + s.sharePercent);
    return (sum - 1.0).abs() <= 0.01;
  }

  Color _selectedColor(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    return palette.infoBg;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final narrowTier = constraints.maxWidth < kEdenAppModeCompactMax;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showLabelField) ...[
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Commission rule label',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: _onLabelChanged,
              ),
              const SizedBox(height: EdenSpacing.space3),
            ],
            _buildModeSelector(narrow),
            const SizedBox(height: EdenSpacing.space3),
            _buildBody(narrowTier),
          ],
        );
      },
    );
  }

  Widget _buildModeSelector(bool narrow) {
    const segments = <EdenSegment<EdenCommissionMode>>[
      EdenSegment(value: EdenCommissionMode.percent, label: 'Percent'),
      EdenSegment(value: EdenCommissionMode.fixed, label: 'Fixed'),
      EdenSegment(value: EdenCommissionMode.tiered, label: 'Tiered'),
      EdenSegment(value: EdenCommissionMode.split, label: 'Split'),
    ];
    if (!narrow) {
      return EdenSegmentedControl<EdenCommissionMode>(
        segments: segments,
        selected: _rule.mode,
        onChanged: _onModeChange,
      );
    }
    // 2x2 Wrap at <420pt to avoid horizontal overflow on phones.
    return Wrap(
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space2,
      children: [
        for (final s in segments)
          Semantics(
            label:
                'Commission mode: ${s.label}, ${s.value == _rule.mode ? 'selected' : 'not selected'}',
            button: true,
            selected: s.value == _rule.mode,
            excludeSemantics: true,
            child: ChoiceChip(
              label: Text(s.label),
              selected: s.value == _rule.mode,
              onSelected: (_) => _onModeChange(s.value),
              selectedColor: _selectedColor(context),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(bool narrowTier) {
    switch (_rule.mode) {
      case EdenCommissionMode.percent:
        return _buildPercentForm();
      case EdenCommissionMode.fixed:
        return _buildFixedForm();
      case EdenCommissionMode.tiered:
        return _buildTieredForm(narrowTier);
      case EdenCommissionMode.split:
        return _buildSplitForm();
    }
  }

  Widget _buildPercentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _percentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Percent',
            suffixText: '%',
            helperText: 'Of qualifying sale amount',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: _onPercentChanged,
        ),
        if (_rule.percent == null) ...[
          const SizedBox(height: EdenSpacing.space2),
          const EdenBanner(
            message: 'Enter percent',
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
        ],
      ],
    );
  }

  Widget _buildFixedForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _fixedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: r'$',
            helperText: 'Flat dollar amount per qualifying sale',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: _onFixedChanged,
        ),
        if (_rule.fixedAmount == null) ...[
          const SizedBox(height: EdenSpacing.space2),
          const EdenBanner(
            message: 'Enter amount',
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
        ],
      ],
    );
  }

  Widget _buildTieredForm(bool narrowTier) {
    final tiers = _rule.tiers ?? const <EdenCommissionTier>[];
    if (tiers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const EdenBanner(
            message: 'Add at least one tier',
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
          const SizedBox(height: EdenSpacing.space2),
          EdenButton(
            label: 'Add tier',
            variant: EdenButtonVariant.secondary,
            outline: true,
            onPressed: _onAddTier,
          ),
        ],
      );
    }

    if (narrowTier) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tiers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
              child: _tierCardCompact(i, tiers[i], tiers.length > 1),
            ),
          EdenButton(
            label: 'Add tier',
            variant: EdenButtonVariant.secondary,
            outline: true,
            onPressed: _onAddTier,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row.
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text('Above',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 5,
                child:
                    Text('Rate', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 48),
            ],
          ),
        ),
        for (var i = 0; i < tiers.length; i++)
          _tierRow(i, tiers[i], tiers.length > 1),
        const SizedBox(height: EdenSpacing.space2),
        EdenButton(
          label: 'Add tier',
          variant: EdenButtonVariant.secondary,
          onPressed: _onAddTier,
        ),
      ],
    );
  }

  Widget _tierRow(int index, EdenCommissionTier tier, bool canRemove) {
    final threshold = tier.thresholdAmount.toStringAsFixed(2);
    final ratePct = (tier.rate * 100).toStringAsFixed(1);
    return Semantics(
      label: 'Tier above \$$threshold, rate $ratePct%',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _tierThresholdControllers[index],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  prefixText: r'$',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (raw) => _onTierThresholdChanged(index, raw),
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _tierRateControllers[index],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}\.?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  suffixText: '%',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (raw) => _onTierRateChanged(index, raw),
              ),
            ),
            SizedBox(
              width: 48,
              child: canRemove
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Remove tier',
                      onPressed: () => _onRemoveTier(index),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierCardCompact(int index, EdenCommissionTier tier, bool canRemove) {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space2),
        child: _tierRow(index, tier, canRemove),
      ),
    );
  }

  Widget _buildSplitForm() {
    final splits = _rule.splits ?? const <EdenCommissionSplitParticipant>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (splits.isEmpty) ...[
          const EdenBanner(
            message: 'Add at least one participant',
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
          const SizedBox(height: EdenSpacing.space2),
        ],
        for (var i = 0; i < splits.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
            child: _splitRow(i, splits[i]),
          ),
        if (splits.isNotEmpty && !_splitBalanced) ...[
          Builder(builder: (context) {
            final sum =
                splits.fold<double>(0, (acc, s) => acc + s.sharePercent);
            final msg =
                'Splits must total 100% (currently ${(sum * 100).toStringAsFixed(0)}%)';
            return Semantics(
              liveRegion: true,
              label: msg,
              child: EdenBanner(
                message: msg,
                variant: EdenBannerVariant.danger,
                dismissible: false,
              ),
            );
          }),
          const SizedBox(height: EdenSpacing.space2),
        ],
        if (widget.onAddParticipantTap != null)
          EdenButton(
            label: 'Add participant',
            variant: EdenButtonVariant.secondary,
            outline: true,
            onPressed: widget.onAddParticipantTap,
          ),
      ],
    );
  }

  Widget _splitRow(int index, EdenCommissionSplitParticipant participant) {
    final theme = Theme.of(context);
    final initial = participant.displayName.isNotEmpty
        ? participant.displayName.substring(0, 1).toUpperCase()
        : '?';
    final shareLabel = (participant.sharePercent * 100).toStringAsFixed(0);
    return Semantics(
      label: 'Split participant ${participant.displayName}, $shareLabel%',
      explicitChildNodes: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _selectedColor(context),
            child: Text(
              initial,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            flex: 4,
            child: Text(
              participant.displayName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _splitShareControllers[index],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}')),
              ],
              decoration: const InputDecoration(
                suffixText: '%',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: (raw) => _onSplitShareChanged(index, raw),
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
          EdenCurrencyDisplay(
            cents: (participant.sharePercent * 100).round(),
            currencyCode: widget.currencyCode,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

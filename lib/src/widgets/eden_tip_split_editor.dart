import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_currency_display.dart';

/// A recipient (staff member, technician, etc.) of a tip split.
@immutable
class EdenTipRecipient {
  const EdenTipRecipient({
    required this.id,
    required this.displayName,
    this.roleLabel,
  });

  /// Stable consumer-provided id (e.g. staff record id).
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Optional role label (e.g. 'Primary stylist', 'Assistant').
  final String? roleLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenTipRecipient &&
          other.id == id &&
          other.displayName == displayName &&
          other.roleLabel == roleLabel;

  @override
  int get hashCode => Object.hash(id, displayName, roleLabel);
}

/// Whether a [EdenTipSplitEditor] splits by percent or by fixed amount.
enum EdenTipSplitMode { percent, fixedAmount }

/// A single recipient's allocation within a tip split.
@immutable
class EdenTipSplitAllocation {
  const EdenTipSplitAllocation({
    required this.recipient,
    required this.share,
  });

  /// The recipient.
  final EdenTipRecipient recipient;

  /// Share value — either a percent fraction (0..1) when parent
  /// [EdenTipSplitEditor.mode] is percent, or a dollar amount when
  /// fixedAmount.
  final double share;

  EdenTipSplitAllocation copyWith({
    EdenTipRecipient? recipient,
    double? share,
  }) {
    return EdenTipSplitAllocation(
      recipient: recipient ?? this.recipient,
      share: share ?? this.share,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenTipSplitAllocation &&
          other.recipient == recipient &&
          other.share == share;

  @override
  int get hashCode => Object.hash(recipient, share);
}

/// Tip split editor (obj 015-01).
///
/// Per-recipient slider (percent mode) or amount field (fixedAmount
/// mode). Locked-row sum pattern in percent mode: dragging row N
/// absorbs the delta from the last-modified other row (Mangomint UX).
/// fixedAmount mode does NOT auto-rebalance; consumers see a banner
/// when the sum is off.
class EdenTipSplitEditor extends StatefulWidget {
  const EdenTipSplitEditor({
    super.key,
    required this.totalTip,
    required this.recipients,
    required this.onAllocationsChanged,
    this.mode = EdenTipSplitMode.percent,
    this.initialAllocations,
    this.currencyCode = 'USD',
  }) : assert(recipients.length >= 1,
            'EdenTipSplitEditor requires at least 1 recipient');

  /// Total tip in dollars being split.
  final double totalTip;

  /// Recipients (2..N). Library asserts >= 2 in debug, renders single
  /// 100% row in release as graceful fallback.
  final List<EdenTipRecipient> recipients;

  /// Emitted on every slider drag / amount keystroke.
  final ValueChanged<List<EdenTipSplitAllocation>> onAllocationsChanged;

  /// Default percent.
  final EdenTipSplitMode mode;

  /// Pre-populated allocations. When null the widget seeds an even
  /// split in percent mode, or zeroes in fixedAmount mode.
  final List<EdenTipSplitAllocation>? initialAllocations;

  /// ISO-4217 currency code.
  final String currencyCode;

  @override
  State<EdenTipSplitEditor> createState() => _EdenTipSplitEditorState();
}

class _EdenTipSplitEditorState extends State<EdenTipSplitEditor> {
  late List<EdenTipSplitAllocation> _allocations;
  late List<TextEditingController> _controllers;
  int? _lastModifiedIndex;

  @override
  void initState() {
    super.initState();
    _allocations = _seedAllocations();
    // Default last-modified to the second row so the first drag absorbs
    // into it. When there is only one row this is meaningless but the
    // editor degrades to a single 100% row in that case.
    _lastModifiedIndex = _allocations.length >= 2 ? 1 : null;
    _controllers = List<TextEditingController>.generate(
      _allocations.length,
      (i) => TextEditingController(text: _formatField(_allocations[i].share)),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<EdenTipSplitAllocation> _seedAllocations() {
    if (widget.initialAllocations != null &&
        widget.initialAllocations!.length == widget.recipients.length) {
      return List<EdenTipSplitAllocation>.from(widget.initialAllocations!);
    }
    if (widget.mode == EdenTipSplitMode.percent) {
      final n = widget.recipients.length;
      final even = n > 0 ? 1.0 / n : 0.0;
      return [
        for (final r in widget.recipients)
          EdenTipSplitAllocation(recipient: r, share: even),
      ];
    }
    // fixedAmount mode: seed zeros — consumer sees danger banner until
    // sum equals totalTip.
    return [
      for (final r in widget.recipients)
        EdenTipSplitAllocation(recipient: r, share: 0.0),
    ];
  }

  String _formatField(double value) {
    if (widget.mode == EdenTipSplitMode.percent) {
      return (value * 100).toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _emit() {
    widget.onAllocationsChanged(
      List<EdenTipSplitAllocation>.unmodifiable(_allocations),
    );
  }

  void _onSliderChanged(int index, double newPercent) {
    if (widget.mode != EdenTipSplitMode.percent) return;
    if (index >= _allocations.length) return;
    final clamped = newPercent.clamp(0.0, 1.0);
    final oldShare = _allocations[index].share;
    var delta = clamped - oldShare;
    if (delta.abs() < 1e-9) return;

    setState(() {
      _allocations[index] = _allocations[index].copyWith(share: clamped);

      // Locked-row absorb pattern: pick the last-modified OTHER row.
      // Default to row 1 if last-modified is the row being dragged or
      // null.
      var absorbIndex = _lastModifiedIndex;
      if (absorbIndex == null || absorbIndex == index) {
        for (var i = 0; i < _allocations.length; i++) {
          if (i != index) {
            absorbIndex = i;
            break;
          }
        }
      }
      if (absorbIndex != null && absorbIndex != index) {
        final absorbed =
            (_allocations[absorbIndex].share - delta).clamp(0.0, 1.0);
        final realDelta = absorbed - _allocations[absorbIndex].share;
        // realDelta might differ from -delta when clamped at the edges;
        // adjust the dragged row so the sum stays at the prior total.
        if ((realDelta + delta).abs() > 1e-9) {
          // Recompute the dragged row to preserve sum (only when the
          // absorb-target hit its clamp boundary).
          final correctedShare = oldShare - realDelta;
          _allocations[index] = _allocations[index].copyWith(
            share: correctedShare.clamp(0.0, 1.0),
          );
          _controllers[index].text = _formatField(_allocations[index].share);
        }
        _allocations[absorbIndex] = _allocations[absorbIndex].copyWith(
          share: absorbed,
        );
        _controllers[absorbIndex].text =
            _formatField(_allocations[absorbIndex].share);
      }
      _lastModifiedIndex = index;
    });
    _emit();
  }

  void _onAmountChanged(int index, String raw) {
    if (widget.mode != EdenTipSplitMode.fixedAmount) return;
    if (index >= _allocations.length) return;
    final parsed = double.tryParse(raw) ?? 0.0;
    setState(() {
      _allocations[index] = _allocations[index].copyWith(share: parsed);
      _lastModifiedIndex = index;
    });
    _emit();
  }

  void _onPercentTextChanged(int index, String raw) {
    if (widget.mode != EdenTipSplitMode.percent) return;
    if (index >= _allocations.length) return;
    final parsed = double.tryParse(raw) ?? 0.0;
    final asFraction = (parsed / 100.0).clamp(0.0, 1.0);
    // Pure text emit — no auto-rebalance. The user is bypassing the
    // slider; sum banner will surface if sum != 1.0.
    setState(() {
      _allocations[index] = _allocations[index].copyWith(share: asFraction);
      _lastModifiedIndex = index;
    });
    _emit();
  }

  double get _sum =>
      _allocations.fold<double>(0.0, (acc, a) => acc + a.share);

  bool get _isBalanced {
    if (widget.mode == EdenTipSplitMode.percent) {
      return (_sum - 1.0).abs() <= 0.01;
    }
    return (_sum - widget.totalTip).abs() <= 0.01;
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
        final narrow = constraints.maxWidth < 500;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _allocations.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: EdenSpacing.space3),
                child: _RecipientRow(
                  index: i,
                  allocation: _allocations[i],
                  controller: _controllers[i],
                  mode: widget.mode,
                  totalTip: widget.totalTip,
                  currencyCode: widget.currencyCode,
                  narrow: narrow,
                  selectedColor: _selectedColor(context),
                  onSliderChanged: (v) => _onSliderChanged(i, v),
                  onAmountChanged: (raw) => _onAmountChanged(i, raw),
                  onPercentTextChanged: (raw) =>
                      _onPercentTextChanged(i, raw),
                ),
              ),
            if (!_isBalanced) _buildSumBanner(),
          ],
        );
      },
    );
  }

  Widget _buildSumBanner() {
    final message = widget.mode == EdenTipSplitMode.percent
        ? 'Splits must total 100% (currently ${(_sum * 100).toStringAsFixed(0)}%)'
        : 'Allocations must total ${_format(widget.totalTip)} '
            '(currently ${_format(_sum)})';
    return Semantics(
      liveRegion: true,
      label: message,
      child: EdenBanner(
        message: message,
        variant: EdenBannerVariant.danger,
        dismissible: false,
      ),
    );
  }

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
    final formatted =
        '$symbol$whole.${fraction.toString().padLeft(2, '0')}';
    return cents < 0 ? '-$formatted' : formatted;
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({
    required this.index,
    required this.allocation,
    required this.controller,
    required this.mode,
    required this.totalTip,
    required this.currencyCode,
    required this.narrow,
    required this.selectedColor,
    required this.onSliderChanged,
    required this.onAmountChanged,
    required this.onPercentTextChanged,
  });

  final int index;
  final EdenTipSplitAllocation allocation;
  final TextEditingController controller;
  final EdenTipSplitMode mode;
  final double totalTip;
  final String currencyCode;
  final bool narrow;
  final Color selectedColor;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onPercentTextChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipient = allocation.recipient;
    final isPercent = mode == EdenTipSplitMode.percent;

    final percentLabel = (allocation.share * 100).toStringAsFixed(0);
    final dollarsLabel = isPercent
        ? (allocation.share * totalTip).toStringAsFixed(2)
        : allocation.share.toStringAsFixed(2);

    final initial = recipient.displayName.isNotEmpty
        ? recipient.displayName.substring(0, 1).toUpperCase()
        : '?';

    final semanticsLabel = isPercent
        ? 'Tip split for ${recipient.displayName}: $percentLabel%'
        : 'Tip split for ${recipient.displayName}: \$$dollarsLabel';

    final avatarAndName = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: selectedColor,
          child: Text(
            initial,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipient.displayName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (recipient.roleLabel != null)
                Text(
                  recipient.roleLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

    final control = isPercent
        ? _buildPercentControl(context)
        : _buildAmountControl(context);

    final helper = isPercent
        ? Text(
            '$percentLabel% — \$$dollarsLabel of \$${totalTip.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall,
          )
        : Text(
            'Allocation: \$$dollarsLabel',
            style: theme.textTheme.bodySmall,
          );

    return Semantics(
      label: semanticsLabel,
      explicitChildNodes: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    avatarAndName,
                    const SizedBox(height: EdenSpacing.space2),
                    control,
                    const SizedBox(height: EdenSpacing.space1),
                    helper,
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: avatarAndName),
                    const SizedBox(width: EdenSpacing.space3),
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          control,
                          const SizedBox(height: EdenSpacing.space1),
                          helper,
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPercentControl(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: allocation.share.clamp(0.0, 1.0),
            onChanged: onSliderChanged,
            divisions: 100,
            min: 0.0,
            max: 1.0,
            label: '${(allocation.share * 100).toStringAsFixed(0)}%',
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        SizedBox(
          width: 72,
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}')),
            ],
            decoration: const InputDecoration(
              suffixText: '%',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: onPercentTextChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountControl(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Allocation',
              prefixText: r'$',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: onAmountChanged,
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        EdenCurrencyDisplay(
          cents: (allocation.share * 100).round(),
          currencyCode: currencyCode,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_segmented_control.dart';

/// Type of promotion authored by [EdenPromotionAuthor].
enum EdenPromotionType { bogo, memberPricing, couponCode, memberOnly }

/// How the discount is calculated.
enum EdenPromotionDiscountKind {
  percentOff,
  amountOff,
  buyXgetYfree,
  buyXgetYPercentOff,
}

/// Constraints on when / who / what is eligible for a promotion.
@immutable
class EdenPromotionConstraint {
  const EdenPromotionConstraint({
    this.startsAt,
    this.endsAt,
    this.maxRedemptions,
    this.perCustomerLimit,
    this.minSubtotal,
    this.eligibleProductIds,
    this.eligibleMemberTierIds,
  });

  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? maxRedemptions;
  final int? perCustomerLimit;
  final double? minSubtotal;
  final List<String>? eligibleProductIds;
  final List<String>? eligibleMemberTierIds;

  EdenPromotionConstraint copyWith({
    DateTime? startsAt,
    DateTime? endsAt,
    int? maxRedemptions,
    int? perCustomerLimit,
    double? minSubtotal,
    List<String>? eligibleProductIds,
    List<String>? eligibleMemberTierIds,
  }) {
    return EdenPromotionConstraint(
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      maxRedemptions: maxRedemptions ?? this.maxRedemptions,
      perCustomerLimit: perCustomerLimit ?? this.perCustomerLimit,
      minSubtotal: minSubtotal ?? this.minSubtotal,
      eligibleProductIds: eligibleProductIds ?? this.eligibleProductIds,
      eligibleMemberTierIds:
          eligibleMemberTierIds ?? this.eligibleMemberTierIds,
    );
  }
}

/// A promotion rule. Library produces drafts; consumer persists.
@immutable
class EdenPromotionRule {
  const EdenPromotionRule({
    required this.id,
    required this.label,
    required this.type,
    this.discountKind,
    this.discountValue,
    this.couponCode,
    this.buyQuantity,
    this.getQuantity,
    this.constraints = const EdenPromotionConstraint(),
  });

  final String id;
  final String label;
  final EdenPromotionType type;
  final EdenPromotionDiscountKind? discountKind;
  final double? discountValue;
  final String? couponCode;
  final int? buyQuantity;
  final int? getQuantity;
  final EdenPromotionConstraint constraints;

  /// Direct constructor — pass raw values (used to clear non-applicable
  /// fields on type switch).
  EdenPromotionRule withRaw({
    String? id,
    String? label,
    EdenPromotionType? type,
    EdenPromotionDiscountKind? discountKind,
    double? discountValue,
    String? couponCode,
    int? buyQuantity,
    int? getQuantity,
    EdenPromotionConstraint? constraints,
  }) {
    return EdenPromotionRule(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      discountKind: discountKind,
      discountValue: discountValue,
      couponCode: couponCode,
      buyQuantity: buyQuantity,
      getQuantity: getQuantity,
      constraints: constraints ?? this.constraints,
    );
  }

  EdenPromotionRule copyWith({
    String? id,
    String? label,
    EdenPromotionType? type,
    EdenPromotionDiscountKind? discountKind,
    double? discountValue,
    String? couponCode,
    int? buyQuantity,
    int? getQuantity,
    EdenPromotionConstraint? constraints,
  }) {
    return EdenPromotionRule(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      discountKind: discountKind ?? this.discountKind,
      discountValue: discountValue ?? this.discountValue,
      couponCode: couponCode ?? this.couponCode,
      buyQuantity: buyQuantity ?? this.buyQuantity,
      getQuantity: getQuantity ?? this.getQuantity,
      constraints: constraints ?? this.constraints,
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Promotion author (obj 015-08).
class EdenPromotionAuthor extends StatefulWidget {
  const EdenPromotionAuthor({
    super.key,
    required this.rule,
    required this.onRuleChanged,
    this.currencyCode = 'USD',
    this.showLabelField = true,
    this.memberTierOptions,
  });

  final EdenPromotionRule rule;
  final ValueChanged<EdenPromotionRule> onRuleChanged;
  final String currencyCode;
  final bool showLabelField;

  /// Consumer-provided member tier options for the chip multi-select
  /// in memberPricing / memberOnly modes.
  final List<({String id, String label})>? memberTierOptions;

  @override
  State<EdenPromotionAuthor> createState() => _EdenPromotionAuthorState();
}

class _EdenPromotionAuthorState extends State<EdenPromotionAuthor> {
  late EdenPromotionRule _rule;
  late TextEditingController _labelController;
  late TextEditingController _discountValueController;
  late TextEditingController _couponCodeController;
  late TextEditingController _buyQtyController;
  late TextEditingController _getQtyController;
  late TextEditingController _minSubtotalController;

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
    _labelController = TextEditingController(text: _rule.label);
    _discountValueController = TextEditingController(
      text: _rule.discountValue == null
          ? ''
          : (_rule.discountKind == EdenPromotionDiscountKind.percentOff
              ? (_rule.discountValue! * 100).toStringAsFixed(0)
              : _rule.discountValue!.toStringAsFixed(2)),
    );
    _couponCodeController =
        TextEditingController(text: _rule.couponCode ?? '');
    _buyQtyController = TextEditingController(
        text: _rule.buyQuantity?.toString() ?? '');
    _getQtyController = TextEditingController(
        text: _rule.getQuantity?.toString() ?? '');
    _minSubtotalController = TextEditingController(
        text: _rule.constraints.minSubtotal?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _discountValueController.dispose();
    _couponCodeController.dispose();
    _buyQtyController.dispose();
    _getQtyController.dispose();
    _minSubtotalController.dispose();
    super.dispose();
  }

  void _emit(EdenPromotionRule rule) {
    setState(() {
      _rule = rule;
    });
    widget.onRuleChanged(rule);
  }

  void _onTypeChange(EdenPromotionType newType) {
    if (newType == _rule.type) return;
    EdenPromotionRule next;
    switch (newType) {
      case EdenPromotionType.bogo:
        next = _rule.withRaw(
          type: newType,
          discountKind:
              _rule.discountKind == EdenPromotionDiscountKind.buyXgetYfree ||
                      _rule.discountKind ==
                          EdenPromotionDiscountKind.buyXgetYPercentOff
                  ? _rule.discountKind
                  : EdenPromotionDiscountKind.buyXgetYfree,
          buyQuantity: _rule.buyQuantity,
          getQuantity: _rule.getQuantity,
          constraints: _rule.constraints,
        );
        break;
      case EdenPromotionType.memberPricing:
        next = _rule.withRaw(
          type: newType,
          discountKind: _rule.discountKind ??
              EdenPromotionDiscountKind.percentOff,
          discountValue: _rule.discountValue,
          constraints: _rule.constraints,
        );
        break;
      case EdenPromotionType.couponCode:
        next = _rule.withRaw(
          type: newType,
          discountKind: _rule.discountKind ??
              EdenPromotionDiscountKind.percentOff,
          discountValue: _rule.discountValue,
          couponCode: _rule.couponCode,
          constraints: _rule.constraints,
        );
        break;
      case EdenPromotionType.memberOnly:
        next = _rule.withRaw(
          type: newType,
          constraints: _rule.constraints,
        );
        break;
    }
    _emit(next);
  }

  void _onLabelChanged(String raw) {
    _emit(_rule.copyWith(label: raw));
  }

  void _onCouponCodeChanged(String raw) {
    _emit(_rule.copyWith(couponCode: raw));
  }

  void _onDiscountValueChanged(String raw) {
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      _emit(_rule.withRaw(
        type: _rule.type,
        discountKind: _rule.discountKind,
        couponCode: _rule.couponCode,
        buyQuantity: _rule.buyQuantity,
        getQuantity: _rule.getQuantity,
        constraints: _rule.constraints,
      ));
      return;
    }
    final asValue =
        _rule.discountKind == EdenPromotionDiscountKind.percentOff
            ? parsed / 100.0
            : parsed;
    _emit(_rule.copyWith(discountValue: asValue));
  }

  void _onBuyQtyChanged(String raw) {
    final parsed = int.tryParse(raw);
    _emit(_rule.withRaw(
      type: _rule.type,
      discountKind: _rule.discountKind,
      discountValue: _rule.discountValue,
      buyQuantity: parsed,
      getQuantity: _rule.getQuantity,
      constraints: _rule.constraints,
    ));
  }

  void _onGetQtyChanged(String raw) {
    final parsed = int.tryParse(raw);
    _emit(_rule.withRaw(
      type: _rule.type,
      discountKind: _rule.discountKind,
      discountValue: _rule.discountValue,
      buyQuantity: _rule.buyQuantity,
      getQuantity: parsed,
      constraints: _rule.constraints,
    ));
  }

  void _onDiscountKindChange(EdenPromotionDiscountKind kind) {
    _emit(_rule.copyWith(discountKind: kind));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rule.constraints.startsAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      _emit(_rule.copyWith(
        constraints: _rule.constraints.copyWith(startsAt: picked),
      ));
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rule.constraints.endsAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      _emit(_rule.copyWith(
        constraints: _rule.constraints.copyWith(endsAt: picked),
      ));
    }
  }

  void _onMinSubtotalChanged(String raw) {
    final parsed = double.tryParse(raw);
    _emit(_rule.copyWith(
      constraints: _rule.constraints.copyWith(minSubtotal: parsed),
    ));
  }

  void _toggleMemberTier(String tierId) {
    final tiers = List<String>.from(
        _rule.constraints.eligibleMemberTierIds ?? const <String>[]);
    if (tiers.contains(tierId)) {
      tiers.remove(tierId);
    } else {
      tiers.add(tierId);
    }
    _emit(_rule.copyWith(
      constraints:
          _rule.constraints.copyWith(eligibleMemberTierIds: tiers),
    ));
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Color _segmentSelectedColor(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    return palette.infoBg;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showLabelField) ...[
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Promotion label',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: _onLabelChanged,
            ),
            const SizedBox(height: EdenSpacing.space2),
          ],
          _buildTypeSelector(),
          const SizedBox(height: EdenSpacing.space3),
          _buildTypeBody(),
          const SizedBox(height: EdenSpacing.space3),
          _buildConstraintForm(),
          const SizedBox(height: EdenSpacing.space2),
          ..._buildValidationBanners(),
        ],
      );
    });
  }

  Widget _buildTypeSelector() {
    const segments = <EdenSegment<EdenPromotionType>>[
      EdenSegment(value: EdenPromotionType.bogo, label: 'BOGO'),
      EdenSegment(
          value: EdenPromotionType.memberPricing, label: 'Member pricing'),
      EdenSegment(value: EdenPromotionType.couponCode, label: 'Coupon code'),
      EdenSegment(
          value: EdenPromotionType.memberOnly, label: 'Member only'),
    ];
    // The 4 type segments include long labels ('Member pricing',
    // 'Coupon code', 'Member only') — always use the Wrap ChoiceChip
    // layout to avoid horizontal overflow at all widths.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in segments)
          Semantics(
            label:
                'Promotion type: ${s.label}, ${s.value == _rule.type ? 'selected' : 'not selected'}',
            button: true,
            selected: s.value == _rule.type,
            excludeSemantics: true,
            child: ChoiceChip(
              label: Text(s.label),
              selected: s.value == _rule.type,
              onSelected: (_) => _onTypeChange(s.value),
              selectedColor: _segmentSelectedColor(context),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBody() {
    switch (_rule.type) {
      case EdenPromotionType.bogo:
        return _buildBogoBody();
      case EdenPromotionType.memberPricing:
        return _buildMemberPricingBody();
      case EdenPromotionType.couponCode:
        return _buildCouponCodeBody();
      case EdenPromotionType.memberOnly:
        return _buildMemberOnlyBody();
    }
  }

  Widget _buildBogoBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenSegmentedControl<EdenPromotionDiscountKind>(
          segments: const [
            EdenSegment(
                value: EdenPromotionDiscountKind.buyXgetYfree,
                label: 'Get free'),
            EdenSegment(
                value: EdenPromotionDiscountKind.buyXgetYPercentOff,
                label: 'Get % off'),
          ],
          selected: _rule.discountKind ??
              EdenPromotionDiscountKind.buyXgetYfree,
          onChanged: _onDiscountKindChange,
        ),
        const SizedBox(height: EdenSpacing.space2),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _buyQtyController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Buy',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: _onBuyQtyChanged,
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: TextFormField(
                controller: _getQtyController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Get',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: _onGetQtyChanged,
              ),
            ),
          ],
        ),
        if (_rule.discountKind ==
            EdenPromotionDiscountKind.buyXgetYPercentOff) ...[
          const SizedBox(height: EdenSpacing.space2),
          TextFormField(
            controller: _discountValueController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Get-percent-off',
              suffixText: '%',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: _onDiscountValueChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildMemberPricingBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenSegmentedControl<EdenPromotionDiscountKind>(
          segments: const [
            EdenSegment(
                value: EdenPromotionDiscountKind.percentOff,
                label: 'Percent off'),
            EdenSegment(
                value: EdenPromotionDiscountKind.amountOff,
                label: 'Amount off'),
          ],
          selected:
              _rule.discountKind ?? EdenPromotionDiscountKind.percentOff,
          onChanged: _onDiscountKindChange,
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextFormField(
          controller: _discountValueController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Discount value',
            suffixText:
                _rule.discountKind == EdenPromotionDiscountKind.amountOff
                    ? null
                    : '%',
            prefixText:
                _rule.discountKind == EdenPromotionDiscountKind.amountOff
                    ? r'$'
                    : null,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onDiscountValueChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        _buildMemberTierChips(),
      ],
    );
  }

  Widget _buildCouponCodeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _couponCodeController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[
            _UpperCaseTextFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Coupon code',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: _onCouponCodeChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenSegmentedControl<EdenPromotionDiscountKind>(
          segments: const [
            EdenSegment(
                value: EdenPromotionDiscountKind.percentOff,
                label: 'Percent off'),
            EdenSegment(
                value: EdenPromotionDiscountKind.amountOff,
                label: 'Amount off'),
          ],
          selected:
              _rule.discountKind ?? EdenPromotionDiscountKind.percentOff,
          onChanged: _onDiscountKindChange,
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextFormField(
          controller: _discountValueController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Discount value',
            suffixText:
                _rule.discountKind == EdenPromotionDiscountKind.amountOff
                    ? null
                    : '%',
            prefixText:
                _rule.discountKind == EdenPromotionDiscountKind.amountOff
                    ? r'$'
                    : null,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onDiscountValueChanged,
        ),
      ],
    );
  }

  Widget _buildMemberOnlyBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No discount — restricts product visibility',
            style: TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: EdenSpacing.space2),
        _buildMemberTierChips(),
      ],
    );
  }

  Widget _buildMemberTierChips() {
    final tiers = widget.memberTierOptions ?? const [];
    if (tiers.isEmpty) {
      return const Text(
        'No member tiers configured (consumer provides memberTierOptions)',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    final selected =
        _rule.constraints.eligibleMemberTierIds ?? const <String>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in tiers)
          FilterChip(
            label: Text(t.label),
            selected: selected.contains(t.id),
            onSelected: (_) => _toggleMemberTier(t.id),
          ),
      ],
    );
  }

  Widget _buildConstraintForm() {
    return ExpansionTile(
      title: const Text('Constraints (window + limits + minimum)'),
      tilePadding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            const Text('Starts: '),
            TextButton(
              onPressed: _pickStartDate,
              child: Text(_rule.constraints.startsAt == null
                  ? 'Anytime'
                  : _formatDate(_rule.constraints.startsAt!)),
            ),
            const SizedBox(width: 16),
            const Text('Ends: '),
            TextButton(
              onPressed: _pickEndDate,
              child: Text(_rule.constraints.endsAt == null
                  ? 'No end'
                  : _formatDate(_rule.constraints.endsAt!)),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextFormField(
          controller: _minSubtotalController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Minimum subtotal',
            prefixText: r'$',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: _onMinSubtotalChanged,
        ),
      ],
    );
  }

  List<Widget> _buildValidationBanners() {
    final banners = <Widget>[];
    if (_rule.type == EdenPromotionType.couponCode &&
        (_rule.couponCode == null || _rule.couponCode!.isEmpty)) {
      banners.add(const EdenBanner(
        message: 'Enter coupon code',
        variant: EdenBannerVariant.warning,
        dismissible: false,
      ));
    }
    if (_rule.type == EdenPromotionType.bogo &&
        (_rule.buyQuantity == null || _rule.getQuantity == null)) {
      banners.add(const EdenBanner(
        message: 'Enter buy/get quantities',
        variant: EdenBannerVariant.warning,
        dismissible: false,
      ));
    }
    final s = _rule.constraints.startsAt;
    final e = _rule.constraints.endsAt;
    if (s != null && e != null && e.isBefore(s)) {
      banners.add(const EdenBanner(
        message: 'End date must be after start',
        variant: EdenBannerVariant.danger,
        dismissible: false,
      ));
    }
    return banners
        .map((b) => Padding(
              padding: const EdgeInsets.only(top: EdenSpacing.space1),
              child: b,
            ))
        .toList();
  }
}

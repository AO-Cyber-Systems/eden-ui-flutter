import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';
import 'eden_line_item_editor.dart';
import 'eden_promotion_author.dart';
import 'eden_status_badge.dart';

/// Context required to evaluate a promotion at checkout.
@immutable
class EdenPromotionApplyContext {
  const EdenPromotionApplyContext({
    required this.lineItems,
    required this.subtotal,
    required this.currentTime,
    this.customerId,
    this.customerMemberTierIds,
  });

  final List<EdenLineItem<dynamic>> lineItems;
  final double subtotal;
  final DateTime currentTime;
  final String? customerId;
  final List<String>? customerMemberTierIds;
}

/// Result of [evaluatePromotionEligibility].
@immutable
class EdenPromotionEligibilityResult {
  const EdenPromotionEligibilityResult({
    required this.rule,
    required this.eligible,
    required this.ineligibleReason,
    this.computedDiscount,
  });

  final EdenPromotionRule rule;
  final bool eligible;
  final String? ineligibleReason;
  final double? computedDiscount;
}

/// Result emitted by [EdenPromotionApply.onPromotionApplied].
@immutable
class EdenPromotionApplyResult {
  const EdenPromotionApplyResult({
    required this.appliedRule,
    required this.discountAmount,
    required this.updatedLineItems,
  });

  final EdenPromotionRule appliedRule;
  final double discountAmount;
  final List<EdenLineItem<dynamic>> updatedLineItems;
}

/// Pure-fn eligibility check for direct testing.
EdenPromotionEligibilityResult evaluatePromotionEligibility(
  EdenPromotionRule rule,
  EdenPromotionApplyContext context,
) {
  // Time window
  if (rule.constraints.startsAt != null &&
      context.currentTime.isBefore(rule.constraints.startsAt!)) {
    return EdenPromotionEligibilityResult(
      rule: rule,
      eligible: false,
      ineligibleReason: 'Not yet active',
    );
  }
  if (rule.constraints.endsAt != null &&
      context.currentTime.isAfter(rule.constraints.endsAt!)) {
    return EdenPromotionEligibilityResult(
      rule: rule,
      eligible: false,
      ineligibleReason: 'Expired',
    );
  }

  // Min subtotal
  if (rule.constraints.minSubtotal != null &&
      context.subtotal < rule.constraints.minSubtotal!) {
    return EdenPromotionEligibilityResult(
      rule: rule,
      eligible: false,
      ineligibleReason:
          'Subtotal below \$${rule.constraints.minSubtotal!.toStringAsFixed(2)}',
    );
  }

  // Member tier gate (memberPricing + memberOnly)
  if (rule.type == EdenPromotionType.memberPricing ||
      rule.type == EdenPromotionType.memberOnly) {
    final eligibleTiers =
        rule.constraints.eligibleMemberTierIds ?? const <String>[];
    final customerTiers = context.customerMemberTierIds ?? const <String>[];
    if (eligibleTiers.isNotEmpty &&
        !eligibleTiers.any(customerTiers.contains)) {
      return EdenPromotionEligibilityResult(
        rule: rule,
        eligible: false,
        ineligibleReason: 'Not a member of required tier',
      );
    }
  }

  // BOGO qty
  if (rule.type == EdenPromotionType.bogo) {
    final totalQty =
        context.lineItems.fold<double>(0, (acc, item) => acc + item.quantity);
    if (totalQty < (rule.buyQuantity ?? 1)) {
      return EdenPromotionEligibilityResult(
        rule: rule,
        eligible: false,
        ineligibleReason: 'Need at least ${rule.buyQuantity} items',
      );
    }
    return EdenPromotionEligibilityResult(
      rule: rule,
      eligible: true,
      ineligibleReason: null,
      computedDiscount: null,
    );
  }

  // Discount math
  double? discount;
  if (rule.discountKind == EdenPromotionDiscountKind.percentOff) {
    discount = context.subtotal * (rule.discountValue ?? 0);
  } else if (rule.discountKind == EdenPromotionDiscountKind.amountOff) {
    discount = rule.discountValue ?? 0;
  }

  return EdenPromotionEligibilityResult(
    rule: rule,
    eligible: true,
    ineligibleReason: null,
    computedDiscount: discount,
  );
}

/// Promotion apply (obj 015-08).
class EdenPromotionApply extends StatefulWidget {
  const EdenPromotionApply({
    super.key,
    required this.context,
    required this.availableRules,
    required this.onPromotionApplied,
    this.showCouponCodeEntry = true,
    this.currencyCode = 'USD',
  });

  final EdenPromotionApplyContext context;
  final List<EdenPromotionRule> availableRules;
  final ValueChanged<EdenPromotionApplyResult?> onPromotionApplied;
  final bool showCouponCodeEntry;
  final String currencyCode;

  @override
  State<EdenPromotionApply> createState() => _EdenPromotionApplyState();
}

class _EdenPromotionApplyState extends State<EdenPromotionApply> {
  EdenPromotionApplyResult? _applied;
  late TextEditingController _couponController;
  bool _couponMismatch = false;

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _apply(EdenPromotionRule rule, EdenPromotionEligibilityResult eligibility) {
    if (!eligibility.eligible) return;
    double discount = eligibility.computedDiscount ?? 0;
    final updated =
        List<EdenLineItem<dynamic>>.from(widget.context.lineItems);
    if (rule.type == EdenPromotionType.bogo && updated.isNotEmpty) {
      final parent = updated.first;
      final freeItem = EdenLineItem<dynamic>(
        id: 'bogo-free-${parent.id}',
        payload: parent.payload,
        description: 'FREE — ${parent.description}',
        quantity: (rule.getQuantity ?? 1).toDouble(),
        unitPrice: parent.unitPrice,
        discountAmount: parent.unitPrice * (rule.getQuantity ?? 1),
      );
      updated.add(freeItem);
      // BOGO discount displayed value = free items × unit price.
      discount = parent.unitPrice * (rule.getQuantity ?? 1);
    }
    final result = EdenPromotionApplyResult(
      appliedRule: rule,
      discountAmount: discount,
      updatedLineItems: List<EdenLineItem<dynamic>>.unmodifiable(updated),
    );
    setState(() {
      _applied = result;
      _couponMismatch = false;
    });
    widget.onPromotionApplied(result);
  }

  void _clear() {
    setState(() {
      _applied = null;
    });
    widget.onPromotionApplied(null);
  }

  void _tryApplyCoupon() {
    final entered = _couponController.text.trim().toUpperCase();
    if (entered.isEmpty) return;
    EdenPromotionRule? match;
    for (final r in widget.availableRules) {
      if (r.type == EdenPromotionType.couponCode &&
          (r.couponCode?.toUpperCase() ?? '') == entered) {
        match = r;
        break;
      }
    }
    if (match == null) {
      setState(() => _couponMismatch = true);
      return;
    }
    final eligibility =
        evaluatePromotionEligibility(match, widget.context);
    if (!eligibility.eligible) {
      setState(() => _couponMismatch = true);
      return;
    }
    _apply(match, eligibility);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_applied != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Applied: ${_applied!.appliedRule.label} '
                  '(\$${_applied!.discountAmount.toStringAsFixed(2)} off)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              EdenButton(
                label: 'Remove promotion',
                variant: EdenButtonVariant.danger,
                outline: true,
                size: EdenButtonSize.sm,
                onPressed: _clear,
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space2),
        ],
        const Text('Available promotions',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: EdenSpacing.space2),
        for (final rule in widget.availableRules) _buildRuleCard(rule),
        if (widget.showCouponCodeEntry) ...[
          const SizedBox(height: EdenSpacing.space3),
          TextFormField(
            controller: _couponController,
            decoration: const InputDecoration(
              labelText: 'Enter coupon code',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_couponMismatch) {
                setState(() => _couponMismatch = false);
              }
            },
          ),
          const SizedBox(height: EdenSpacing.space2),
          EdenButton(
            label: 'Apply code',
            onPressed: _tryApplyCoupon,
          ),
          if (_couponMismatch) ...[
            const SizedBox(height: EdenSpacing.space2),
            const EdenBanner(
              message: 'Coupon code not recognized',
              variant: EdenBannerVariant.warning,
              dismissible: false,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildRuleCard(EdenPromotionRule rule) {
    final eligibility = evaluatePromotionEligibility(rule, widget.context);
    final discountLabel = eligibility.eligible
        ? (eligibility.computedDiscount == null
            ? '(see free item)'
            : '\$${eligibility.computedDiscount!.toStringAsFixed(2)} off')
        : eligibility.ineligibleReason ?? 'Not eligible';
    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
      child: Semantics(
        label:
            'Promotion: ${rule.label}, '
            '${eligibility.eligible ? "eligible" : "not eligible — ${eligibility.ineligibleReason}"}, '
            '$discountLabel',
        explicitChildNodes: true,
        child: EdenCard(
          child: Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(rule.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                    EdenStatusBadge(
                      status:
                          eligibility.eligible ? 'completed' : 'expired',
                    ),
                  ],
                ),
                const SizedBox(height: EdenSpacing.space1),
                Text('Type: ${rule.type.name}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: EdenSpacing.space1),
                if (eligibility.eligible)
                  Row(
                    children: [
                      const Text('Discount: '),
                      if (eligibility.computedDiscount != null)
                        EdenCurrencyDisplay(
                          cents: (eligibility.computedDiscount! * 100)
                              .round(),
                          currencyCode: widget.currencyCode,
                        )
                      else
                        const Text('Free item included'),
                    ],
                  )
                else
                  Text(
                    'Not eligible — ${eligibility.ineligibleReason ?? "unknown"}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                if (eligibility.eligible) ...[
                  const SizedBox(height: EdenSpacing.space2),
                  EdenButton(
                    label: 'Apply',
                    onPressed: () => _apply(rule, eligibility),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

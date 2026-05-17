// Do NOT regenerate via LLM — hand-built fixtures for EdenPromotionAuthor.
//
// Cross-vertical promotion rule archetypes for obj 015-08.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPromotionAuthorFixtures {
  static const EdenPromotionRule bogoBuy2Get1Rule = EdenPromotionRule(
    id: 'p-1',
    label: 'Buy 2 get 1 free — facial mask',
    type: EdenPromotionType.bogo,
    discountKind: EdenPromotionDiscountKind.buyXgetYfree,
    buyQuantity: 2,
    getQuantity: 1,
    constraints: EdenPromotionConstraint(
      eligibleProductIds: ['sku-mask-aloe', 'sku-mask-charcoal'],
    ),
  );

  static const EdenPromotionRule memberPricingGoldRule = EdenPromotionRule(
    id: 'p-2',
    label: 'Gold-tier 15% off',
    type: EdenPromotionType.memberPricing,
    discountKind: EdenPromotionDiscountKind.percentOff,
    discountValue: 0.15,
    constraints: EdenPromotionConstraint(
      eligibleMemberTierIds: ['gold'],
    ),
  );

  static final EdenPromotionRule couponSummer20Rule = EdenPromotionRule(
    id: 'p-3',
    label: 'Summer 20% off',
    type: EdenPromotionType.couponCode,
    discountKind: EdenPromotionDiscountKind.percentOff,
    discountValue: 0.20,
    couponCode: 'SUMMER20',
    constraints: EdenPromotionConstraint(
      startsAt: DateTime(2026, 6, 1),
      endsAt: DateTime(2026, 8, 31),
      minSubtotal: 50.0,
    ),
  );

  static const EdenPromotionRule memberOnlyVipRule = EdenPromotionRule(
    id: 'p-4',
    label: 'VIP-only product access',
    type: EdenPromotionType.memberOnly,
    constraints: EdenPromotionConstraint(
      eligibleMemberTierIds: ['vip'],
    ),
  );

  static final EdenPromotionRule expiredRule = EdenPromotionRule(
    id: 'p-5',
    label: 'Winter 25% off — expired',
    type: EdenPromotionType.couponCode,
    discountKind: EdenPromotionDiscountKind.percentOff,
    discountValue: 0.25,
    couponCode: 'WINTER25',
    constraints: EdenPromotionConstraint(
      startsAt: DateTime(2025, 12, 1),
      endsAt: DateTime(2026, 2, 28),
    ),
  );
}

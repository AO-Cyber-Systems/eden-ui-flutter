// Do NOT regenerate via LLM — hand-built fixtures for EdenCheckoutSheet.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenCheckoutSheetFixtures {
  static final EdenCheckoutDraft draftWithLineItems = EdenCheckoutDraft(
    lineItems: const [
      EdenLineItem<dynamic>(
        id: 'li-1',
        payload: null,
        description: 'Haircut',
        quantity: 1,
        unitPrice: 65.0,
      ),
      EdenLineItem<dynamic>(
        id: 'li-2',
        payload: null,
        description: 'Color',
        quantity: 1,
        unitPrice: 95.0,
      ),
    ],
    tip: const EdenTipDraft(mode: EdenTipMode.none, tipAmount: 0),
    payments: const <EdenPaymentDraft>[],
    taxRate: 0.0825,
    currentStep: EdenCheckoutStep.lineItems,
  );

  static final EdenCheckoutDraft draftAtTipStep =
      draftWithLineItems.copyWith(currentStep: EdenCheckoutStep.tip);

  static final EdenCheckoutDraft draftAtPaymentStep =
      draftWithLineItems.copyWith(currentStep: EdenCheckoutStep.payment);

  static final EdenCheckoutDraft draftAtReviewStep =
      draftWithLineItems.copyWith(currentStep: EdenCheckoutStep.review);

  static final EdenCheckoutDraft emptyDraft = EdenCheckoutDraft(
    lineItems: const <EdenLineItem<dynamic>>[],
    tip: const EdenTipDraft(mode: EdenTipMode.none, tipAmount: 0),
    payments: const <EdenPaymentDraft>[],
    taxRate: 0.0,
    currentStep: EdenCheckoutStep.lineItems,
  );

  static const List<EdenPromotionRule> threePromotions = [
    EdenPromotionRule(
      id: 'p-1',
      label: 'Buy 2 get 1 free',
      type: EdenPromotionType.bogo,
      discountKind: EdenPromotionDiscountKind.buyXgetYfree,
      buyQuantity: 2,
      getQuantity: 1,
    ),
    EdenPromotionRule(
      id: 'p-2',
      label: 'Gold 15%',
      type: EdenPromotionType.memberPricing,
      discountKind: EdenPromotionDiscountKind.percentOff,
      discountValue: 0.15,
      constraints: EdenPromotionConstraint(eligibleMemberTierIds: ['gold']),
    ),
    EdenPromotionRule(
      id: 'p-3',
      label: 'SUMMER20',
      type: EdenPromotionType.couponCode,
      discountKind: EdenPromotionDiscountKind.percentOff,
      discountValue: 0.20,
      couponCode: 'SUMMER20',
    ),
  ];
}

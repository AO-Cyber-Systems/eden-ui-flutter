// Do NOT regenerate via LLM — hand-built fixtures for EdenPromotionApply.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPromotionApplyFixtures {
  static final List<EdenLineItem<String>> sampleLineItems = [
    const EdenLineItem<String>(
      id: 'sku-mask-aloe',
      payload: 'sku-mask-aloe',
      description: 'Aloe mask',
      quantity: 2,
      unitPrice: 15.00,
    ),
    const EdenLineItem<String>(
      id: 'sku-mask-charcoal',
      payload: 'sku-mask-charcoal',
      description: 'Charcoal mask',
      quantity: 1,
      unitPrice: 18.00,
    ),
  ];

  static EdenPromotionApplyContext eligibleContext({
    List<String>? tiers,
    DateTime? at,
    double? subtotal,
  }) {
    return EdenPromotionApplyContext(
      lineItems: sampleLineItems,
      subtotal: subtotal ?? 48.00,
      currentTime: at ?? DateTime(2026, 7, 1),
      customerId: 'cust-1',
      customerMemberTierIds: tiers,
    );
  }

  static EdenPromotionApplyContext ineligibleContextBelowMinSubtotal() {
    return EdenPromotionApplyContext(
      lineItems: sampleLineItems,
      subtotal: 10.00, // < SUMMER20's $50 minimum
      currentTime: DateTime(2026, 7, 1),
    );
  }
}

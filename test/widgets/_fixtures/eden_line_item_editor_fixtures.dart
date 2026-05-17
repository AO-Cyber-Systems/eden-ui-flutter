// Do NOT regenerate via LLM — hand-built fixtures for EdenLineItemEditor.
//
// Realistic cross-vertical line-item rows used by the test suite for
// obj 012-01 (EdenLineItemEditor). Each fixture method returns a
// freshly-constructed list so tests can mutate without bleed.
//
// All fixtures use STABLE string IDs so TextField controller keying is
// deterministic across rebuilds.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenLineItemEditorFixtures {
  /// Retail cart — 3 items, no discounts, no tax, simple multiply-and-add.
  static List<EdenLineItem<String>> retailCart() => const [
        EdenLineItem<String>(
          id: 'retail-1',
          payload: 'SKU-COFFEE',
          description: 'Coffee — Large',
          quantity: 2,
          unitPrice: 4.50,
        ),
        EdenLineItem<String>(
          id: 'retail-2',
          payload: 'SKU-PASTRY',
          description: 'Almond Croissant',
          quantity: 1,
          unitPrice: 6.25,
        ),
        EdenLineItem<String>(
          id: 'retail-3',
          payload: 'SKU-MILK',
          description: 'Oat Milk (substitution)',
          quantity: 1,
          unitPrice: 0.75,
        ),
      ];

  /// Trades quote — labor + material + discount line, exercises taxRate.
  static List<EdenLineItem<String>> tradesQuote() => const [
        EdenLineItem<String>(
          id: 'trades-1',
          payload: 'labor',
          description: 'HVAC diagnostic',
          quantity: 1.5,
          unitPrice: 120.0,
        ),
        EdenLineItem<String>(
          id: 'trades-2',
          payload: 'labor',
          description: 'Coil cleaning',
          quantity: 2.0,
          unitPrice: 95.0,
        ),
        EdenLineItem<String>(
          id: 'trades-3',
          payload: 'material',
          description: 'R-410A refrigerant 2lbs',
          quantity: 2.0,
          unitPrice: 45.0,
          taxRate: 0.0625,
        ),
        EdenLineItem<String>(
          id: 'trades-4',
          payload: 'discount',
          description: 'Senior discount',
          quantity: 1.0,
          unitPrice: 0.0,
          discountAmount: 25.0,
        ),
      ];

  /// Medical claim — 2 items, exercises tax (0.0 — medical typically no
  /// sales tax) and a discount on the lab.
  static List<EdenLineItem<String>> medicalClaim() => const [
        EdenLineItem<String>(
          id: 'med-1',
          payload: 'visit',
          description: 'Office visit, established patient',
          quantity: 1.0,
          unitPrice: 125.0,
          taxRate: 0.0,
        ),
        EdenLineItem<String>(
          id: 'med-2',
          payload: 'lab',
          description: 'CBC panel',
          quantity: 1.0,
          unitPrice: 45.0,
          discountAmount: 5.0,
        ),
      ];

  /// Fuel POD — single high-volume delivery (200 gal × $3.45 = $690.00).
  static List<EdenLineItem<String>> fuelPod() => const [
        EdenLineItem<String>(
          id: 'fuel-1',
          payload: 'diesel',
          description: 'Off-road diesel',
          quantity: 200.0,
          unitPrice: 3.45,
        ),
      ];

  /// Salon services — 1 service + 1 add-on (read-only checkout fixture).
  static List<EdenLineItem<String>> salonServices() => const [
        EdenLineItem<String>(
          id: 'salon-1',
          payload: 'cut',
          description: 'Stylist cut',
          quantity: 1.0,
          unitPrice: 75.0,
        ),
        EdenLineItem<String>(
          id: 'salon-2',
          payload: 'addon',
          description: 'Olaplex add-on',
          quantity: 1.0,
          unitPrice: 25.0,
        ),
      ];

  /// Negative line total — discount exceeds subtotal. Used to verify
  /// danger color + Semantics announcement for negative balances.
  /// (qty 2 × unitPrice 50 − discount 110 = -10.00)
  static List<EdenLineItem<String>> negativeLineTotal() => const [
        EdenLineItem<String>(
          id: 'neg-1',
          payload: 'test',
          description: 'Tip jar',
          quantity: 2.0,
          unitPrice: 50.0,
          discountAmount: 110.0,
        ),
      ];
}

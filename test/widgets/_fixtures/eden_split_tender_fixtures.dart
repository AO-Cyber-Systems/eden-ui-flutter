// Do NOT regenerate via LLM — hand-built fixtures for EdenSplitTender.
//
// Realistic split-tender scenarios used by the test suite for obj 012-04.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenSplitTenderFixtures {
  /// Balanced — single $50 cash tender for a $50 total.
  static List<EdenPaymentDraft> balancedSingleCash() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 50.0),
      ];

  /// Two-way split — cash $30 + card $20, total $50.
  static List<EdenPaymentDraft> twoWayCashCard() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 30.0),
        EdenPaymentDraft(method: EdenPaymentMethod.card, amount: 20.0, reference: '4242'),
      ];

  /// Three-way split — cash $50 + card $40 + check $30, total $120.
  static List<EdenPaymentDraft> threeWaySplit() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 50.0),
        EdenPaymentDraft(method: EdenPaymentMethod.card, amount: 40.0, reference: '4242'),
        EdenPaymentDraft(method: EdenPaymentMethod.check, amount: 30.0, reference: '#1003'),
      ];

  /// Under-capacity — card $60, total $100, under by $40.
  static List<EdenPaymentDraft> underCapacity() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.card, amount: 60.0, reference: '4242'),
      ];

  /// Over-capacity — cash $70 + card $50, total $100, over by $20.
  static List<EdenPaymentDraft> overCapacity() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 70.0),
        EdenPaymentDraft(method: EdenPaymentMethod.card, amount: 50.0, reference: '4242'),
      ];

  /// Cash overpayment — single cash $60 against total $50 (change due $10).
  static List<EdenPaymentDraft> cashOverpayment() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 60.0),
      ];

  /// Card overpayment — single card $60 against total $50 (overage, no
  /// change because cards don't make change).
  static List<EdenPaymentDraft> cardOverpayment() => const [
        EdenPaymentDraft(method: EdenPaymentMethod.card, amount: 60.0, reference: '4242'),
      ];
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenPaymentEntry.
//
// Cross-vertical method allowlists + sample payment drafts used by the
// test suite for obj 012-03.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPaymentEntryFixtures {
  /// Retail POS: cash, card, gift card.
  static List<EdenPaymentMethod> posAllowedMethods() => const [
        EdenPaymentMethod.cash,
        EdenPaymentMethod.card,
        EdenPaymentMethod.giftCard,
      ];

  /// Medical copay: card, check, portal.
  static List<EdenPaymentMethod> medicalAllowedMethods() => const [
        EdenPaymentMethod.card,
        EdenPaymentMethod.check,
        EdenPaymentMethod.portal,
      ];

  /// Trades invoice: card, ACH, check.
  static List<EdenPaymentMethod> tradesAllowedMethods() => const [
        EdenPaymentMethod.card,
        EdenPaymentMethod.ach,
        EdenPaymentMethod.check,
      ];

  /// Fuel POD: cash, card, account on file.
  static List<EdenPaymentMethod> fuelAllowedMethods() => const [
        EdenPaymentMethod.cash,
        EdenPaymentMethod.card,
        EdenPaymentMethod.accountOnFile,
      ];

  /// Sample drafts.
  static EdenPaymentDraft cashTwentyDollars() =>
      const EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 20.0);

  static EdenPaymentDraft cardWithLast4() => const EdenPaymentDraft(
        method: EdenPaymentMethod.card,
        amount: 47.50,
        reference: '4242',
      );

  static EdenPaymentDraft checkWithNumber() => const EdenPaymentDraft(
        method: EdenPaymentMethod.check,
        amount: 250.00,
        reference: '#1003',
      );
}

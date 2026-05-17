// Do NOT regenerate via LLM — hand-built fixtures for EdenGiftCardBalanceLookup.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenGiftCardLookupFixtures {
  EdenGiftCardLookupFixtures._();

  static DateTime get t0 => DateTime(2026, 5, 17, 12, 0, 0);

  static EdenGiftCardBalanceResult activeWithActivity({DateTime? now}) {
    final n = now ?? t0;
    return EdenGiftCardBalanceResult(
      cardNumber: '1234567890123456',
      balanceCents: 4250,
      status: EdenGiftCardStatus.active,
      lastUsedAt: n.subtract(const Duration(days: 5)),
      expiresAt: DateTime(n.year + 2, n.month, n.day),
      recentActivity: [
        EdenGiftCardActivity(
          id: 'a-1',
          occurredAt: n.subtract(const Duration(days: 5)),
          type: EdenGiftCardActivityType.redeemed,
          amountCents: -1500,
          reason: 'POS sale',
          receiptRef: 'R-2103',
        ),
        EdenGiftCardActivity(
          id: 'a-2',
          occurredAt: n.subtract(const Duration(days: 12)),
          type: EdenGiftCardActivityType.loaded,
          amountCents: 5000,
          reason: 'New card',
          receiptRef: 'R-2087',
        ),
        EdenGiftCardActivity(
          id: 'a-3',
          occurredAt: n.subtract(const Duration(days: 18)),
          type: EdenGiftCardActivityType.adjustment,
          amountCents: 750,
          reason: 'Promo bonus',
        ),
      ],
    );
  }

  static EdenGiftCardBalanceResult deactivated() {
    return const EdenGiftCardBalanceResult(
      cardNumber: '4444333322221111',
      balanceCents: 0,
      status: EdenGiftCardStatus.deactivated,
    );
  }

  static EdenGiftCardBalanceResult expired() {
    return const EdenGiftCardBalanceResult(
      cardNumber: '9999888877776666',
      balanceCents: 500,
      status: EdenGiftCardStatus.expired,
    );
  }

  static EdenGiftCardBalanceResult zeroBalanceActive() {
    return const EdenGiftCardBalanceResult(
      cardNumber: '1111222233334444',
      balanceCents: 0,
      status: EdenGiftCardStatus.active,
    );
  }

  static Future<EdenGiftCardBalanceResult?> Function(String) okLookupFn(
    EdenGiftCardBalanceResult result,
  ) {
    return (cardNumber) async => result;
  }

  static Future<EdenGiftCardBalanceResult?> Function(String) notFoundLookupFn() {
    return (cardNumber) async => null;
  }

  static Future<EdenGiftCardBalanceResult?> Function(String) throwingLookupFn() {
    return (cardNumber) async {
      throw StateError('Simulated upstream failure');
    };
  }
}

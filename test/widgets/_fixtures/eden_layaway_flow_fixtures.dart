// Do NOT regenerate via LLM — hand-built fixtures for EdenLayawayFlow.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenLayawayFlowFixtures {
  EdenLayawayFlowFixtures._();

  static DateTime get t0 => DateTime(2026, 5, 17, 12, 0, 0);

  /// 2 items totalling $305.80 — leather jacket $250 + 20 tax, belt $35 + 2.80 tax.
  static List<EdenLayawayCartItem> sampleCart() {
    return const [
      EdenLayawayCartItem(
        lineId: 'L-1',
        sku: 'SKU-A',
        name: 'Leather jacket',
        qty: 1,
        unitPriceCents: 25000,
        taxCents: 2000,
      ),
      EdenLayawayCartItem(
        lineId: 'L-2',
        sku: 'SKU-B',
        name: 'Belt',
        qty: 1,
        unitPriceCents: 3500,
        taxCents: 280,
      ),
    ];
  }

  static List<EdenLayawayCartItem> minimalCart() {
    return const [
      EdenLayawayCartItem(
        lineId: 'M-1',
        sku: 'M',
        name: 'Item',
        qty: 1,
        unitPriceCents: 10000,
      ),
    ];
  }

  static EdenLayawayState sampleActiveState({DateTime? now}) {
    final n = now ?? t0;
    return EdenLayawayState(
      id: 'LAY-001',
      cartItems: sampleCart(),
      depositCents: 6100,
      balanceCents: 18380,
      pickupByDate: n.add(const Duration(days: 30)),
      status: EdenLayawayStatus.active,
      customerId: 'c-1',
      customerName: 'Jane Doe',
      installments: [
        EdenLayawayInstallment(
          id: 'INS-1',
          paidAt: n.subtract(const Duration(days: 10)),
          amountCents: 6100,
          method: EdenPaymentMethod.card,
        ),
      ],
    );
  }

  static EdenLayawayState readyForPickupState({DateTime? now}) {
    final n = now ?? t0;
    return EdenLayawayState(
      id: 'LAY-002',
      cartItems: sampleCart(),
      depositCents: 30580,
      balanceCents: 0,
      pickupByDate: n.add(const Duration(days: 2)),
      status: EdenLayawayStatus.readyForPickup,
      customerId: 'c-2',
      customerName: 'Sam Lee',
    );
  }

  static EdenLayawayState overdueState({DateTime? now}) {
    final n = now ?? t0;
    return EdenLayawayState(
      id: 'LAY-003',
      cartItems: sampleCart(),
      depositCents: 10000,
      balanceCents: 20580,
      pickupByDate: n.subtract(const Duration(days: 5)),
      status: EdenLayawayStatus.active,
    );
  }

  static EdenLayawayState zeroBalanceState({DateTime? now}) {
    final n = now ?? t0;
    return EdenLayawayState(
      id: 'LAY-004',
      cartItems: sampleCart(),
      depositCents: 30580,
      balanceCents: 0,
      pickupByDate: n.add(const Duration(days: 10)),
      status: EdenLayawayStatus.active,
      customerId: 'c-4',
      customerName: 'Olivia Martinez',
    );
  }
}

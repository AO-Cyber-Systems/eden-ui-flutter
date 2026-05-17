// Do NOT regenerate via LLM — hand-built fixtures for EdenStoreTransferFlow.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenStoreTransferFixtures {
  EdenStoreTransferFixtures._();

  static DateTime get t0 => DateTime(2026, 5, 17, 12, 0, 0);

  static const List<EdenLocation> locations = [
    EdenLocation(id: 'L-DOWN', name: 'Downtown'),
    EdenLocation(id: 'L-AIR', name: 'Airport'),
    EdenLocation(id: 'L-FLAG', name: 'Flagship'),
  ];

  static EdenLocation get downtown => locations[0];
  static EdenLocation get airport => locations[1];

  static EdenStoreTransfer sampleInTransitTransfer({DateTime? now}) {
    final n = now ?? t0;
    return EdenStoreTransfer(
      id: 'XFR-101',
      sourceLocation: downtown,
      destLocation: airport,
      items: const [
        EdenStoreTransferItem(
          lineId: 'I-1',
          sku: 'SKU-A',
          name: 'Espresso 1kg',
          qty: 12,
          unitLabel: 'kg',
        ),
        EdenStoreTransferItem(
          lineId: 'I-2',
          sku: 'SKU-B',
          name: 'Mocha mix',
          qty: 6,
        ),
      ],
      status: EdenStoreTransferStatus.inTransit,
      shippingCarrier: 'FedEx',
      trackingRef: 'TRK-999-001',
      dispatchedAt: n.subtract(const Duration(hours: 12)),
    );
  }

  static EdenStoreTransfer walkInTransfer({DateTime? now}) {
    final n = now ?? t0;
    return EdenStoreTransfer(
      id: 'XFR-200',
      sourceLocation: downtown,
      destLocation: airport,
      items: const [
        EdenStoreTransferItem(
          lineId: 'W-1',
          sku: 'SKU-Z',
          name: 'Counter mat',
          qty: 1,
        ),
      ],
      status: EdenStoreTransferStatus.inTransit,
      isWalkIn: true,
      dispatchedAt: n.subtract(const Duration(hours: 1)),
    );
  }

  static Future<EdenStoreTransferItem?> Function(String) okLookupFn(
    EdenStoreTransferItem item,
  ) {
    return (q) async => item;
  }

  static Future<EdenStoreTransferItem?> Function(String) notFoundLookupFn() {
    return (q) async => null;
  }

  static EdenStoreTransferItem sampleItem() {
    return const EdenStoreTransferItem(
      lineId: 'L-1',
      sku: 'SKU-A',
      name: 'Espresso 1kg',
      qty: 1,
      unitLabel: 'kg',
    );
  }
}

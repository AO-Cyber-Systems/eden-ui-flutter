// Do NOT regenerate via LLM — hand-built fixtures for EdenRefundFlow.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenRefundFlowFixtures {
  EdenRefundFlowFixtures._();

  static DateTime get t0 => DateTime(2026, 5, 17, 12, 0, 0);

  /// 3 lines totaling $89.50 paid by card; espresso line is $25/unit x 2.
  static EdenSaleRecord sampleSale({
    DateTime? occurredAt,
    EdenPaymentMethod tender = EdenPaymentMethod.card,
  }) {
    return EdenSaleRecord(
      saleId: 'S-1042',
      occurredAt: occurredAt ?? t0.subtract(const Duration(days: 3)),
      originalTender: tender,
      originalTotalCents: 8950,
      customerId: 'c-1',
      customerName: 'Jane Doe',
      receiptRef: 'R-1042',
      lines: const [
        EdenSaleLine(
          lineId: 'L-1',
          sku: 'SKU-A',
          name: 'Espresso 1kg',
          originalQty: 2,
          unitPriceCents: 2500,
          taxCents: 200,
          refundableQty: 2,
        ),
        EdenSaleLine(
          lineId: 'L-2',
          sku: 'SKU-B',
          name: 'Mocha mix',
          originalQty: 1,
          unitPriceCents: 900,
          taxCents: 75,
          refundableQty: 1,
        ),
        EdenSaleLine(
          lineId: 'L-3',
          sku: 'SKU-C',
          name: 'Filter coffee',
          originalQty: 3,
          unitPriceCents: 800,
          taxCents: 175,
          refundableQty: 3,
        ),
      ],
    );
  }

  /// Single line $20 — minimal happy path.
  static EdenSaleRecord singleLineSale() {
    return EdenSaleRecord(
      saleId: 'S-2001',
      occurredAt: t0.subtract(const Duration(days: 1)),
      originalTender: EdenPaymentMethod.card,
      originalTotalCents: 2000,
      lines: const [
        EdenSaleLine(
          lineId: 'A',
          sku: 'A',
          name: 'Item A',
          originalQty: 1,
          unitPriceCents: 2000,
          taxCents: 0,
          refundableQty: 1,
        ),
      ],
    );
  }

  /// Line 1 already partially refunded (refundableQty 1 of original 2).
  static EdenSaleRecord partialAlreadyRefundedSale() {
    return EdenSaleRecord(
      saleId: 'S-3001',
      occurredAt: t0.subtract(const Duration(days: 7)),
      originalTender: EdenPaymentMethod.card,
      originalTotalCents: 6000,
      lines: const [
        EdenSaleLine(
          lineId: 'P-1',
          sku: 'P1',
          name: 'Already half refunded',
          originalQty: 2,
          unitPriceCents: 2000,
          taxCents: 0,
          refundableQty: 1,
        ),
        EdenSaleLine(
          lineId: 'P-2',
          sku: 'P2',
          name: 'Untouched',
          originalQty: 1,
          unitPriceCents: 2000,
          taxCents: 0,
          refundableQty: 1,
        ),
      ],
    );
  }

  /// Big-ticket single line for threshold-trigger tests ($250).
  static EdenSaleRecord bigTicketSale() {
    return EdenSaleRecord(
      saleId: 'S-BIG',
      occurredAt: t0,
      originalTender: EdenPaymentMethod.card,
      originalTotalCents: 25000,
      lines: const [
        EdenSaleLine(
          lineId: 'B-1',
          sku: 'BIG',
          name: 'Premium kit',
          originalQty: 1,
          unitPriceCents: 25000,
          taxCents: 0,
          refundableQty: 1,
        ),
      ],
    );
  }

  static EdenSaleRecord cashTenderSale() {
    return sampleSale(tender: EdenPaymentMethod.cash);
  }
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenReceivingFlow.
//
// Hand-built per global TDD Playbook habit 4. Touch by hand when adding
// PO shapes (short qty + over-shipped, damaged-only, multi-vendor).

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenReceivingFixtures {
  EdenReceivingFixtures._();

  /// 5-line coffee shop receiving PO.
  static EdenReceivingDoc acmeCoffeePo() => const EdenReceivingDoc(
        poNumber: 'PO-4827',
        vendor: 'Acme Coffee Co.',
        expectedItems: <EdenReceivingExpectedItem>[
          EdenReceivingExpectedItem(
            lineId: 'L-1',
            sku: 'CB-001',
            name: 'Espresso Blend 1kg',
            expectedQty: 10,
            expectedUnitCostCents: 1200,
          ),
          EdenReceivingExpectedItem(
            lineId: 'L-2',
            sku: 'AM-FLT',
            name: 'Americano filter',
            expectedQty: 5,
            expectedUnitCostCents: 800,
          ),
          EdenReceivingExpectedItem(
            lineId: 'L-3',
            sku: 'CP-SYR',
            name: 'Cappuccino syrup',
            expectedQty: 3,
            expectedUnitCostCents: 600,
          ),
          EdenReceivingExpectedItem(
            lineId: 'L-4',
            sku: 'MO-MIX',
            name: 'Mocha mix',
            expectedQty: 2,
            expectedUnitCostCents: 900,
          ),
          EdenReceivingExpectedItem(
            lineId: 'L-5',
            sku: 'SW-024',
            name: 'Sparkling Water 24-pack',
            expectedQty: 24,
            expectedUnitCostCents: 100,
          ),
        ],
        expectedTotalCents: 20600,
      );

  /// Single-line PO — exercises the minimal happy-path through the 4-step
  /// flow.
  static EdenReceivingDoc smallPo() => const EdenReceivingDoc(
        poNumber: 'PO-1',
        vendor: 'Small Vendor',
        expectedItems: <EdenReceivingExpectedItem>[
          EdenReceivingExpectedItem(
            lineId: 'L-A',
            sku: 'WIDGET',
            name: 'Single widget',
            expectedQty: 1,
            expectedUnitCostCents: 500,
          ),
        ],
      );

  /// Zero-line edge case.
  static EdenReceivingDoc emptyPo() => const EdenReceivingDoc(
        poNumber: 'PO-EMPTY',
        vendor: 'Empty Vendor',
        expectedItems: <EdenReceivingExpectedItem>[],
      );
}

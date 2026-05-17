// Do NOT regenerate via LLM — hand-built fixtures for EdenInventoryRowEditor.
//
// Hand-built per global TDD Playbook habit 4. Touch by hand when adding
// edge cases (negative on-hand, multi-currency, hard-to-parse location codes).

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenInventoryRowFixtures {
  EdenInventoryRowFixtures._();

  static const coffeeBeans = EdenInventoryRowData(
    rowId: 'r-1',
    sku: 'CB-001',
    name: 'Espresso Blend 1kg',
    costCents: 1200,
    priceCents: 2400,
    onHand: 18,
    reorderPoint: 10,
    location: 'A-12',
  );

  static const tshirt = EdenInventoryRowData(
    rowId: 'r-2',
    sku: 'TS-RED-M',
    name: 'T-shirt Red Medium',
    costCents: 700,
    priceCents: 1995,
    onHand: 35,
    reorderPoint: 20,
    location: 'B-04',
  );

  static const lowStock = EdenInventoryRowData(
    rowId: 'r-3',
    sku: 'PG-090',
    name: 'PVC Elbow 90deg',
    costCents: 80,
    priceCents: 350,
    onHand: 3,
    reorderPoint: 20,
    location: 'C-08',
  );

  /// Partial: cost + price set, no stock data.
  static const partial = EdenInventoryRowData(
    rowId: 'r-4',
    sku: 'SP-NEW',
    name: 'New Sparkling Water',
    costCents: 150,
    priceCents: 300,
  );

  /// Minimal: only rowId + sku + name set.
  static const minimal = EdenInventoryRowData(
    rowId: 'r-5',
    sku: 'MIN',
    name: 'Minimal Row',
  );

  /// onHand set, reorderPoint null — exercises the binary-mode stock path.
  static const stockNoReorder = EdenInventoryRowData(
    rowId: 'r-6',
    sku: 'BN-001',
    name: 'Binary Stock',
    onHand: 10,
  );
}

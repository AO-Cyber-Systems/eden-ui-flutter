// Do NOT regenerate via LLM — hand-built fixtures for EdenStockLevelIndicator.
//
// Enumerates the (currentStock, reorderPoint) tuples covering each colour
// threshold the donor maps. The amber region is geometrically narrow — only
// reachable when reorderPoint=0 (so maxCapacity=100) AND currentStock ∈
// [25, 49]; whenever reorderPoint>0 currentStock<=reorderPoint forces RED.
//
// Add new tuples by hand only.

class EdenStockLevelCase {
  const EdenStockLevelCase({
    required this.currentStock,
    required this.reorderPoint,
    required this.label,
  });

  final int currentStock;
  final int reorderPoint;
  final String label;
}

class EdenStockLevelIndicatorFixtures {
  EdenStockLevelIndicatorFixtures._();

  static const List<EdenStockLevelCase> greenCases = <EdenStockLevelCase>[
    EdenStockLevelCase(
      currentStock: 80,
      reorderPoint: 50,
      label: '80/100, healthy',
    ),
    EdenStockLevelCase(
      currentStock: 100,
      reorderPoint: 50,
      label: 'clamped to 1.0',
    ),
  ];

  static const List<EdenStockLevelCase> amberCases = <EdenStockLevelCase>[
    EdenStockLevelCase(
      currentStock: 35,
      reorderPoint: 0,
      label: 'reorderPoint=0; percent=0.35',
    ),
  ];

  static const List<EdenStockLevelCase> redCases = <EdenStockLevelCase>[
    EdenStockLevelCase(
      currentStock: 50,
      reorderPoint: 100,
      label: 'isBelowReorder forces red even at percent=0.25',
    ),
    EdenStockLevelCase(
      currentStock: 5,
      reorderPoint: 0,
      label: 'percent<0.25 with reorderPoint=0',
    ),
    EdenStockLevelCase(
      currentStock: 100,
      reorderPoint: 100,
      label: 'boundary inclusive isBelowReorder',
    ),
  ];
}

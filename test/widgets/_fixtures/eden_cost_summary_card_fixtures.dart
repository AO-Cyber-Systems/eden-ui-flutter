// Do NOT regenerate via LLM — hand-built fixtures for EdenCostSummaryCard.
//
// Hand-picked tuples covering the cost-summary card's expected behaviours per
// 003-05-TRD.md test list — particularly the donor quirk that `extraRows` are
// rendered but NOT included in the displayed total.
//
// Add new tuples by hand only.

class EdenCostSummaryFixtureExtraRow {
  const EdenCostSummaryFixtureExtraRow({
    required this.label,
    required this.cents,
  });

  final String label;
  final int cents;
}

class EdenCostSummaryCardFixtures {
  EdenCostSummaryCardFixtures._();

  // Happy path: labor 120000 + material 45000 + equipment 25000 = 190000 cents
  // → '$1,900.00'.
  static const int happyLaborCents = 120000;
  static const int happyMaterialCents = 45000;
  static const int happyEquipmentCents = 25000;
  static const int happyTotalCents = 190000;
  static const String happyTotalLabel = r'$1,900.00';

  // ExtraRows quirk: total stays = labor + material + equipment.
  static const int extraRowsLaborCents = 100;
  static const int extraRowsMaterialCents = 100;
  static const int extraRowsEquipmentCents = 100;
  static const int extraRowsTotalCents = 300; // $3.00; subcontractor + permits NOT included
  static const String extraRowsTotalLabel = r'$3.00';

  static const List<EdenCostSummaryFixtureExtraRow> extraRows =
      <EdenCostSummaryFixtureExtraRow>[
    EdenCostSummaryFixtureExtraRow(label: 'Subcontractor', cents: 50000),
    EdenCostSummaryFixtureExtraRow(label: 'Permits', cents: 7500),
  ];

  // Long label to exercise iPhone-narrow ellipsis.
  static const String longLabel =
      'Equipment rental + operator labor (50ch label)';
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenSparkline.
//
// Cross-vertical trend-line data used by the test suite for obj 012-05.

class EdenSparklineFixtures {
  /// Lab trend — hemoglobin g/dL across 6 visits.
  static List<double> labTrendHemoglobin() =>
      const [12.5, 13.1, 12.8, 11.9, 12.2, 12.5];

  /// Retail sales — daily totals for a 7-day window.
  static List<double> sales7Day() =>
      const [1200.0, 1340.0, 1180.0, 1420.0, 1520.0, 1480.0, 1245.0];

  /// Fuel tank level — 7-snapshot history, descending toward refill.
  static List<double> tankLevelHistory() =>
      const [88.0, 75.0, 62.0, 51.0, 40.0, 30.0, 23.0];

  /// Flat — no movement, exercises the maxV == minV edge case.
  static List<double> flatLine() => const [50.0, 50.0, 50.0, 50.0];

  /// Offline-sensor scenario — gaps in data. nullablePoints=true skips
  /// NaN segments without drawing through them.
  static List<double> withNanGaps() =>
      const [10.0, double.nan, 15.0, 12.0, double.nan, 14.0];

  static List<double> singleValue() => const [42.0];

  static List<double> empty() => const [];
}

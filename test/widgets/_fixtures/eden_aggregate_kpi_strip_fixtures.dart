// Do NOT regenerate via LLM — hand-built fixtures for EdenAggregateKpiStrip.
//
// Realistic cross-vertical KPI strips used by the test suite for
// obj 012-02. Each fixture method returns a freshly-constructed list
// so tests can mutate without bleed.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenAggregateKpiStripFixtures {
  /// Retail — sales day: 4 tiles with positive / negative trend mix and a
  /// negativeIsGood polarity for the refund-rate metric.
  static List<EdenKpiTile> salesDay() => const [
        EdenKpiTile(label: 'Sales', displayValue: r'$1,245', trend: 0.12),
        EdenKpiTile(label: 'Orders', displayValue: '47', trend: 0.04),
        EdenKpiTile(label: 'Avg ticket', displayValue: r'$26.49', trend: -0.02),
        EdenKpiTile(
          label: 'Refund rate',
          displayValue: '2.1%',
          trend: 0.01,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
      ];

  static EdenKpiAggregate salesDayAggregate() => const EdenKpiAggregate(
        label: 'Total',
        displayValue: r'$1,245',
        mode: EdenKpiAggregateMode.sum,
      );

  /// Fuel — week volume: 5 tiles + aggregate.
  static List<EdenKpiTile> fuelVolumeWeek() => const [
        EdenKpiTile(label: 'Gallons', displayValue: '8,420', trend: 0.08),
        EdenKpiTile(label: 'Stops', displayValue: '34', trend: 0.05),
        EdenKpiTile(label: 'Avg/stop', displayValue: '247.6 gal', trend: 0.03),
        EdenKpiTile(label: 'Truck util', displayValue: '82%', trend: 0.06),
        EdenKpiTile(label: 'Routes', displayValue: '6', trend: 0),
      ];

  /// Medical — claims rollup: 3 tiles, mixed polarities.
  static List<EdenKpiTile> medicalClaims() => const [
        EdenKpiTile(label: 'Submitted', displayValue: '124', trend: 0.07),
        EdenKpiTile(label: 'Paid', displayValue: '108', trend: 0.09),
        EdenKpiTile(
          label: 'Denied',
          displayValue: '8',
          trend: -0.02,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
        EdenKpiTile(
          label: 'AR days',
          displayValue: '42',
          trend: 0.03,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
      ];

  /// Trades — revenue: 4 tiles + aggregate.
  static List<EdenKpiTile> tradesRevenue() => const [
        EdenKpiTile(label: 'Booked', displayValue: r'$24,600', trend: 0.15),
        EdenKpiTile(label: 'Completed', displayValue: r'$19,200', trend: 0.10),
        EdenKpiTile(
          label: 'Outstanding',
          displayValue: r'$5,400',
          trend: 0.03,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
        EdenKpiTile(label: 'Win rate', displayValue: '34%', trend: 0.04),
      ];

  /// Empty fixture for empty-state tests.
  static List<EdenKpiTile> emptyTiles() => const [];
}

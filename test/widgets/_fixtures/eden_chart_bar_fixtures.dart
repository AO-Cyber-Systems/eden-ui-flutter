// Do NOT regenerate via LLM — hand-built fixtures for EdenBarChart.
//
// Cross-vertical bar-chart series used by the test suite for obj 012-06.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenChartBarFixtures {
  /// Retail — daily sales (single series, 7 days).
  static List<EdenChartSeries> retailDailySales() => const [
        EdenChartSeries(name: 'Sales', data: [
          EdenChartDataPoint(label: 'Mon', value: 1200),
          EdenChartDataPoint(label: 'Tue', value: 1340),
          EdenChartDataPoint(label: 'Wed', value: 1180),
          EdenChartDataPoint(label: 'Thu', value: 1420),
          EdenChartDataPoint(label: 'Fri', value: 1520),
          EdenChartDataPoint(label: 'Sat', value: 1680),
          EdenChartDataPoint(label: 'Sun', value: 1245),
        ]),
      ];

  /// Fuel — by truck (3 series, 4 weeks each).
  static List<EdenChartSeries> fuelByTruck() => const [
        EdenChartSeries(name: 'Truck A', data: [
          EdenChartDataPoint(label: 'W1', value: 2400),
          EdenChartDataPoint(label: 'W2', value: 2600),
          EdenChartDataPoint(label: 'W3', value: 2200),
          EdenChartDataPoint(label: 'W4', value: 2800),
        ]),
        EdenChartSeries(name: 'Truck B', data: [
          EdenChartDataPoint(label: 'W1', value: 2100),
          EdenChartDataPoint(label: 'W2', value: 2400),
          EdenChartDataPoint(label: 'W3', value: 2000),
          EdenChartDataPoint(label: 'W4', value: 2500),
        ]),
        EdenChartSeries(name: 'Truck C', data: [
          EdenChartDataPoint(label: 'W1', value: 1800),
          EdenChartDataPoint(label: 'W2', value: 2000),
          EdenChartDataPoint(label: 'W3', value: 1900),
          EdenChartDataPoint(label: 'W4', value: 2100),
        ]),
      ];

  /// Medical — claims by status (Paid + Denied, 6 months — stacked use case).
  static List<EdenChartSeries> medicalClaimsStatus() => const [
        EdenChartSeries(name: 'Paid', data: [
          EdenChartDataPoint(label: 'Jan', value: 92),
          EdenChartDataPoint(label: 'Feb', value: 88),
          EdenChartDataPoint(label: 'Mar', value: 95),
          EdenChartDataPoint(label: 'Apr', value: 91),
          EdenChartDataPoint(label: 'May', value: 94),
          EdenChartDataPoint(label: 'Jun', value: 89),
        ]),
        EdenChartSeries(name: 'Denied', data: [
          EdenChartDataPoint(label: 'Jan', value: 8),
          EdenChartDataPoint(label: 'Feb', value: 12),
          EdenChartDataPoint(label: 'Mar', value: 5),
          EdenChartDataPoint(label: 'Apr', value: 9),
          EdenChartDataPoint(label: 'May', value: 6),
          EdenChartDataPoint(label: 'Jun', value: 11),
        ]),
      ];

  /// Trades — revenue by service category (single series, long category
  /// labels for the horizontal-variant scenario).
  static List<EdenChartSeries> tradesRevenueByCategory() => const [
        EdenChartSeries(name: 'Revenue', data: [
          EdenChartDataPoint(label: 'HVAC Install', value: 24600),
          EdenChartDataPoint(label: 'HVAC Repair', value: 18200),
          EdenChartDataPoint(label: 'Plumbing', value: 12400),
          EdenChartDataPoint(label: 'Electrical', value: 9800),
          EdenChartDataPoint(label: 'Refrig.', value: 6200),
        ]),
      ];
}

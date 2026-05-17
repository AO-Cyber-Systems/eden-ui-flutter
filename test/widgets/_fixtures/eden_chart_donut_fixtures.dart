// Do NOT regenerate via LLM — hand-built fixtures for EdenDonutChart / EdenPieChart.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenChartDonutFixtures {
  /// Salon — service mix (Cut 40%, Color 30%, Treatment 20%, Retail 10%).
  static List<EdenChartDataPoint> serviceMix() => const [
        EdenChartDataPoint(label: 'Cut', value: 40),
        EdenChartDataPoint(label: 'Color', value: 30),
        EdenChartDataPoint(label: 'Treatment', value: 20),
        EdenChartDataPoint(label: 'Retail', value: 10),
      ];

  /// Retail — inventory by category (5 cats).
  static List<EdenChartDataPoint> inventoryByCategory() => const [
        EdenChartDataPoint(label: 'Apparel', value: 1850),
        EdenChartDataPoint(label: 'Accessories', value: 1200),
        EdenChartDataPoint(label: 'Footwear', value: 980),
        EdenChartDataPoint(label: 'Home', value: 640),
        EdenChartDataPoint(label: 'Other', value: 220),
      ];

  /// Medical — payment-method split (4 methods).
  static List<EdenChartDataPoint> paymentMethodSplit() => const [
        EdenChartDataPoint(label: 'Insurance', value: 65),
        EdenChartDataPoint(label: 'Patient card', value: 20),
        EdenChartDataPoint(label: 'Check', value: 10),
        EdenChartDataPoint(label: 'Portal', value: 5),
      ];

  /// Trades — revenue distribution by service type (3 types).
  static List<EdenChartDataPoint> tradesRevenueDist() => const [
        EdenChartDataPoint(label: 'HVAC', value: 56),
        EdenChartDataPoint(label: 'Plumbing', value: 28),
        EdenChartDataPoint(label: 'Electrical', value: 16),
      ];

  static List<EdenChartDataPoint> empty() => const [];
}

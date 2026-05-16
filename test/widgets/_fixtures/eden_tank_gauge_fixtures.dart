// Do NOT regenerate via LLM — hand-built fixtures for EdenTankGauge.
import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for EdenTankGauge tests.
class EdenTankGaugeFixtures {
  EdenTankGaugeFixtures._();

  /// 0% — 0/500 gal. Triggers red color + red border (≤low default 20%).
  static const empty = EdenTankGaugeData(capacityGal: 500, currentGal: 0);

  /// 16% — 80/500 gal. ≤low default → red + red border.
  static const low = EdenTankGaugeData(capacityGal: 500, currentGal: 80);

  /// 40% — 200/500 gal. >low & ≤warning → amber, no border.
  static const amber = EdenTankGaugeData(capacityGal: 500, currentGal: 200);

  /// 64% — 320/500 gal with Propane label. >warning → green, no border.
  static const normal = EdenTankGaugeData(
    capacityGal: 500,
    currentGal: 320,
    fuelTypeLabel: 'Propane',
  );

  /// 100% — 500/500 gal. Green.
  static const full = EdenTankGaugeData(capacityGal: 500, currentGal: 500);

  /// 110% — overfull. Clamps display to 100% + overflow badge.
  static const overfull = EdenTankGaugeData(capacityGal: 500, currentGal: 550);

  /// Capacity 0 — defensive (division-by-zero guard).
  static const zeroCapacity = EdenTankGaugeData(capacityGal: 0, currentGal: 0);

  /// Decimal-precision case — 320.5/500.0.
  static const decimal = EdenTankGaugeData(
    capacityGal: 500.0,
    currentGal: 320.5,
  );

  /// Metric unit label override.
  static const metricUnit = EdenTankGaugeData(
    capacityGal: 500,
    currentGal: 320,
    unitLabel: 'L',
  );
}

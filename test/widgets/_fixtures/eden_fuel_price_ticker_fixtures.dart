// Do NOT regenerate via LLM — hand-built fixtures for EdenFuelPriceTicker.
import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for EdenFuelPriceTicker tests.
class EdenFuelPriceTickerFixtures {
  EdenFuelPriceTickerFixtures._();

  /// Reference "as-of" time used across fixtures; tests inject a `now`
  /// offset from this for deterministic relative-time assertions.
  static final DateTime asOfRef = DateTime(2026, 5, 16, 9, 0);

  /// +5 cents (current $2.50, prior $2.45). Up = unfavorable (default
  /// lowerIsBetter polarity) — chip should render red.
  static final EdenFuelPriceData up5cents = EdenFuelPriceData(
    currentCents: 250,
    priorCents: 245,
    fuelTypeLabel: 'Heating oil',
    asOf: asOfRef,
  );

  /// -10 cents (current $2.40, prior $2.50). Down = favorable for buyer —
  /// chip renders green by default.
  static final EdenFuelPriceData down10cents = EdenFuelPriceData(
    currentCents: 240,
    priorCents: 250,
    fuelTypeLabel: 'Diesel',
    asOf: asOfRef,
  );

  /// Flat (no change). Chip renders grey regardless of polarity.
  static final EdenFuelPriceData flat = EdenFuelPriceData(
    currentCents: 250,
    priorCents: 250,
    fuelTypeLabel: 'Propane',
    asOf: asOfRef,
  );

  /// +$1.00 delta (current $3.50, prior $2.50).
  static final EdenFuelPriceData largeUp1dollar = EdenFuelPriceData(
    currentCents: 350,
    priorCents: 250,
    fuelTypeLabel: 'Aviation fuel',
    asOf: asOfRef,
  );

  /// EUR currency variant.
  static final EdenFuelPriceData euroPrice = EdenFuelPriceData(
    currentCents: 100,
    priorCents: 95,
    fuelTypeLabel: 'Gasoline',
    asOf: asOfRef,
    currencyCode: 'EUR',
  );

  /// Long fuel-type label for iPhone-narrow overflow tests.
  static final EdenFuelPriceData longFuelTypeLabel = EdenFuelPriceData(
    currentCents: 250,
    priorCents: 240,
    fuelTypeLabel: 'Ultra-Low-Sulfur Diesel #2 Premium Grade',
    asOf: asOfRef,
  );
}

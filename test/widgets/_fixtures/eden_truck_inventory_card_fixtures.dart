// Do NOT regenerate via LLM — hand-built fixtures for EdenTruckInventoryCard.
import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for EdenTruckInventoryCard tests.
class EdenTruckInventoryCardFixtures {
  EdenTruckInventoryCardFixtures._();

  /// 64% — 320/500 gal Propane.
  static const normal = EdenTruckInventoryData(
    truckLabel: 'Truck 47',
    fuelTypeLabel: 'Propane',
    capacityGal: 500,
    currentGal: 320,
  );

  /// 64.1% — decimal precision case.
  static const decimalFuel = EdenTruckInventoryData(
    truckLabel: 'Truck 12',
    fuelTypeLabel: 'Heating oil',
    capacityGal: 500.0,
    currentGal: 320.5,
  );

  /// 0% — empty tank.
  static const emptyTank = EdenTruckInventoryData(
    truckLabel: 'Truck 99',
    fuelTypeLabel: 'Diesel',
    capacityGal: 500,
    currentGal: 0,
  );

  /// 100% — full.
  static const full = EdenTruckInventoryData(
    truckLabel: 'Truck 14',
    fuelTypeLabel: 'Gasoline',
    capacityGal: 500,
    currentGal: 500,
  );

  /// 110% — overfull (un-clamped capacity display, clamped bar).
  static const overfull = EdenTruckInventoryData(
    truckLabel: 'Tanker A-12',
    fuelTypeLabel: 'Heating oil',
    capacityGal: 500,
    currentGal: 550,
  );

  /// 0/0 — defensive zero-capacity case.
  static const zeroCapacity = EdenTruckInventoryData(
    truckLabel: 'Truck 0',
    fuelTypeLabel: 'Propane',
    capacityGal: 0,
    currentGal: 0,
  );

  /// Long-labels case for iPhone-narrow safety.
  static const longLabels = EdenTruckInventoryData(
    truckLabel: 'Premium Long Distance Tanker Number 999 Special Edition',
    fuelTypeLabel: 'Ultra Low Sulfur Diesel #2 Heating Oil Premium',
    capacityGal: 2500,
    currentGal: 1200,
  );
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenDeliveryVarianceCard.
//
// Realistic fuel-delivery + trades-labor reconciliation scenarios.

import 'package:eden_ui_flutter/src/widgets/eden_delivery_variance_card.dart';

class VarianceFixtures {
  VarianceFixtures._();

  /// Under-fill: scheduled 850 gal, actual 700 gal → -17.6% (beyond 10%).
  static EdenDeliveryVarianceData underFill() => const EdenDeliveryVarianceData(
        scheduled: 850.0,
        actual: 700.0,
        metric: EdenVarianceMetric.gallons,
      );

  /// Over-fill: scheduled 500, actual 540 → +8% (within 10%).
  static EdenDeliveryVarianceData overFill() => const EdenDeliveryVarianceData(
        scheduled: 500.0,
        actual: 540.0,
        metric: EdenVarianceMetric.gallons,
      );

  /// Trades labor hours: scheduled 2.0 hr, actual 2.5 hr → +25% (beyond).
  static EdenDeliveryVarianceData laborHours() =>
      const EdenDeliveryVarianceData(
        scheduled: 2.0,
        actual: 2.5,
        metric: EdenVarianceMetric.hours,
      );

  /// Divide-by-zero edge case.
  static EdenDeliveryVarianceData zeroScheduled() =>
      const EdenDeliveryVarianceData(
        scheduled: 0.0,
        actual: 100.0,
        metric: EdenVarianceMetric.gallons,
      );

  static EdenDeliveryVarianceData equalScheduled() =>
      const EdenDeliveryVarianceData(
        scheduled: 100.0,
        actual: 100.0,
        metric: EdenVarianceMetric.gallons,
      );

  static EdenDeliveryVarianceData feeVariance() =>
      const EdenDeliveryVarianceData(
        scheduled: 25.00,
        actual: 28.50,
        metric: EdenVarianceMetric.fee,
      );

  static EdenDeliveryVarianceData customLbs() => const EdenDeliveryVarianceData(
        scheduled: 100.0,
        actual: 80.0,
        metric: EdenVarianceMetric.custom,
        unitLabel: 'lbs',
      );

  /// Read-only "accepted" draft from yesterday.
  static EdenDeliveryVarianceDraft acceptedDraft() => EdenDeliveryVarianceDraft(
        data: underFill(),
        reason: EdenDeliveryVarianceReason.tankCapEarly,
        reasonNote: 'Customer tank already 60% full on arrival.',
        disposition: EdenDeliveryVarianceDisposition.accepted,
      );
}

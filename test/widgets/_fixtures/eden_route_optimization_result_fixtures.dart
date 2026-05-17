// Do NOT regenerate via LLM — hand-built fixtures for EdenRouteOptimizationResult.
//
// Realistic 3-truck route optimization scenario per TRD 019-06 catalog spec:
// before 24 stops / 187 miles / 6h, after 22 stops / 159 miles / 4h48m.

import 'package:eden_ui_flutter/src/widgets/eden_route_optimization_result.dart';
import 'package:eden_ui_flutter/src/widgets/eden_route_stop_list.dart';

class RouteOptimizationFixtures {
  RouteOptimizationFixtures._();

  /// 3-truck route demo: 24 → 22 stops, 187 → 159 mi, 6h → 4h48m, 78% util.
  static EdenRouteOptimizationData demo3Truck() {
    return EdenRouteOptimizationData(
      before: _stops(prefix: 'before', count: 24),
      after: _stops(prefix: 'after', count: 22),
      metrics: const EdenRouteOptimizationMetrics(
        totalStopsBefore: 24,
        totalStopsAfter: 22,
        totalMilesBefore: 187.0,
        totalMilesAfter: 159.0,
        totalTimeBefore: Duration(hours: 6),
        totalTimeAfter: Duration(hours: 4, minutes: 48),
        capacityUtilizationAfter: 0.78,
      ),
      truckUtilizations: const [
        EdenRouteOptimizationTruckUtil(
          truckId: 'truck-12',
          truckLabel: 'Truck-12',
          capacityGal: 4000.0,
          scheduledGal: 3200.0,
        ),
        EdenRouteOptimizationTruckUtil(
          truckId: 'truck-14',
          truckLabel: 'Truck-14',
          capacityGal: 3000.0,
          scheduledGal: 2100.0,
        ),
        EdenRouteOptimizationTruckUtil(
          truckId: 'truck-22',
          truckLabel: 'Truck-22',
          capacityGal: 4000.0,
          scheduledGal: 3380.0,
        ),
      ],
      infeasibleStopIds: const ['after-14', 'after-19'],
    );
  }

  static EdenRouteOptimizationData emptyDemo() {
    return const EdenRouteOptimizationData(
      before: [],
      after: [],
      metrics: EdenRouteOptimizationMetrics(
        totalStopsBefore: 0,
        totalStopsAfter: 0,
        totalMilesBefore: 0.0,
        totalMilesAfter: 0.0,
        totalTimeBefore: Duration.zero,
        totalTimeAfter: Duration.zero,
        capacityUtilizationAfter: 0.0,
      ),
      truckUtilizations: [],
    );
  }

  /// 2-truck demo where one truck is over-capacity (>100% util).
  static EdenRouteOptimizationData overCapacityDemo() {
    return EdenRouteOptimizationData(
      before: _stops(prefix: 'b', count: 8),
      after: _stops(prefix: 'a', count: 8),
      metrics: const EdenRouteOptimizationMetrics(
        totalStopsBefore: 8,
        totalStopsAfter: 8,
        totalMilesBefore: 95.0,
        totalMilesAfter: 88.0,
        totalTimeBefore: Duration(hours: 3, minutes: 15),
        totalTimeAfter: Duration(hours: 3),
        capacityUtilizationAfter: 1.08,
      ),
      truckUtilizations: const [
        EdenRouteOptimizationTruckUtil(
          truckId: 'truck-a',
          truckLabel: 'Truck-A',
          capacityGal: 2000.0,
          scheduledGal: 2200.0, // OVER capacity
        ),
        EdenRouteOptimizationTruckUtil(
          truckId: 'truck-b',
          truckLabel: 'Truck-B',
          capacityGal: 2000.0,
          scheduledGal: 1450.0,
        ),
      ],
    );
  }

  static EdenRouteOptimizationDriverNotes singleNote() {
    return EdenRouteOptimizationDriverNotes(
      driverId: 'drv-smith',
      driverName: 'Smith',
      notes: const [
        'Stop #14 was at customer site with locked gate after-hours; rescheduling to next day.',
      ],
      submittedAt: DateTime(2026, 5, 18, 19, 45),
    );
  }

  static List<EdenRouteStopData> _stops(
      {required String prefix, required int count}) {
    return [
      for (int i = 1; i <= count; i++)
        EdenRouteStopData(
          id: '$prefix-$i',
          label: 'Stop $i',
        ),
    ];
  }
}

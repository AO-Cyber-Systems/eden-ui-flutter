import 'package:eden_ui_flutter/src/widgets/eden_route_optimization_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_route_optimization_result_fixtures.dart';

Widget wrap(Widget child, {double width = 1024}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: 900, child: child),
      ),
    );

Future<void> pumpWide(WidgetTester tester, Widget child,
    {double width = 1024}) async {
  await tester.binding.setSurfaceSize(Size(width + 200, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrap(child, width: width));
}

void main() {
  group('EdenRouteOptimizationTruckUtil', () {
    test('utilizationPct clamps to [0, 1]', () {
      const t = EdenRouteOptimizationTruckUtil(
        truckId: 't',
        truckLabel: 'T',
        capacityGal: 1000,
        scheduledGal: 1500,
      );
      expect(t.utilizationPct, 1.0);
      expect(t.isOverCapacity, isTrue);
    });

    test('utilizationPct=0 when capacity is 0', () {
      const t = EdenRouteOptimizationTruckUtil(
        truckId: 't',
        truckLabel: 'T',
        capacityGal: 0,
        scheduledGal: 500,
      );
      expect(t.utilizationPct, 0.0);
    });

    test('utilizationPct computes fraction', () {
      const t = EdenRouteOptimizationTruckUtil(
        truckId: 't',
        truckLabel: 'T',
        capacityGal: 1000,
        scheduledGal: 750,
      );
      expect(t.utilizationPct, 0.75);
      expect(t.isOverCapacity, isFalse);
    });
  });

  group('EdenRouteOptimizationResult — static rendering', () {
    testWidgets('renders Before and After panels at 1024pt', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
    });

    testWidgets('renders KPI labels Stops / Miles / Time / Capacity',
        (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.text('Stops'), findsOneWidget);
      expect(find.text('Miles'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Capacity'), findsOneWidget);
    });

    testWidgets('renders capacity percentage as "78%"', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.text('78%'), findsOneWidget);
    });

    testWidgets('renders truck utilization labels', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.text('Truck-12'), findsOneWidget);
      expect(find.text('Truck-14'), findsOneWidget);
      expect(find.text('Truck-22'), findsOneWidget);
    });
  });

  group('EdenRouteOptimizationResult — empty edge cases', () {
    testWidgets('empty before+after shows empty state', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.emptyDemo(),
        ),
      );
      expect(find.text('No optimization results'), findsOneWidget);
    });

    testWidgets('empty truckUtilizations hides truck util strip',
        (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: EdenRouteOptimizationData(
            before:
                RouteOptimizationFixtures.demo3Truck().before.take(3).toList(),
            after:
                RouteOptimizationFixtures.demo3Truck().after.take(3).toList(),
            metrics: const EdenRouteOptimizationMetrics(
              totalStopsBefore: 3,
              totalStopsAfter: 3,
              totalMilesBefore: 10,
              totalMilesAfter: 9,
              totalTimeBefore: Duration(hours: 1),
              totalTimeAfter: Duration(minutes: 50),
              capacityUtilizationAfter: 0.5,
            ),
            truckUtilizations: const [],
          ),
        ),
      );
      // No truck-* labels rendered
      expect(find.text('Truck-12'), findsNothing);
    });
  });

  group('EdenRouteOptimizationResult — infeasible stops', () {
    testWidgets('renders infeasible list text when stops marked infeasible',
        (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.textContaining('Infeasible'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenRouteOptimizationResult — driver notes', () {
    testWidgets('null driverNotes hides the notes accordion', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.textContaining('Driver notes'), findsNothing);
    });

    testWidgets('non-null driverNotes renders accordion title',
        (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
          driverNotes: RouteOptimizationFixtures.singleNote(),
        ),
      );
      expect(find.text('Driver notes from Smith'), findsOneWidget);
    });
  });

  group('EdenRouteOptimizationResult — action bar', () {
    testWidgets('both callbacks null → action bar hidden', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
      );
      expect(find.byKey(const Key('route-optimization-accept')), findsNothing);
      expect(find.byKey(const Key('route-optimization-reject')), findsNothing);
    });

    testWidgets('onAccept set → Accept button visible; tap fires callback',
        (tester) async {
      bool accepted = false;
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
          onAccept: () => accepted = true,
        ),
      );
      expect(find.byKey(const Key('route-optimization-accept')), findsOneWidget);
      expect(find.byKey(const Key('route-optimization-reject')), findsNothing);
      await tester.tap(find.byKey(const Key('route-optimization-accept')));
      expect(accepted, isTrue);
    });

    testWidgets('onReject set → Reject button visible; tap fires callback',
        (tester) async {
      bool rejected = false;
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
          onReject: () => rejected = true,
        ),
      );
      expect(find.byKey(const Key('route-optimization-reject')), findsOneWidget);
      await tester.tap(find.byKey(const Key('route-optimization-reject')));
      expect(rejected, isTrue);
    });
  });

  group('EdenRouteOptimizationResult — responsive', () {
    testWidgets('stacks Before+After at 800pt', (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
        width: 800,
      );
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
    });

    testWidgets('iPhone-narrow (390pt) renders without overflow',
        (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.demo3Truck(),
        ),
        width: 390,
      );
      expect(tester.takeException(), isNull);
      // KPI tiles stack vertically below 500pt
      expect(find.text('Stops'), findsOneWidget);
    });
  });

  group('EdenRouteOptimizationResult — over-capacity edge case', () {
    testWidgets('renders over-capacity truck with warning',
        (tester) async {
      await pumpWide(
        tester,
        EdenRouteOptimizationResult(
          data: RouteOptimizationFixtures.overCapacityDemo(),
        ),
      );
      expect(find.text('Truck-A'), findsOneWidget);
      // Warning icon present (over-capacity flag)
      expect(find.byIcon(Icons.warning_rounded), findsAtLeastNWidgets(1));
    });
  });
}

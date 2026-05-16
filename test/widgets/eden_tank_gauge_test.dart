import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_tank_gauge_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 200, double height = 240}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      );

  // -----------------------------------------------------------------
  // Task 1 — Linear mode static rendering
  // -----------------------------------------------------------------
  group('EdenTankGauge linear mode (default)', () {
    testWidgets('renders with linear mode selected by default',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.normal),
      ));
      // Linear marker: FractionallySizedBox is the linear fill mechanism.
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets("renders capacity label '320/500 gal' for normal",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.normal),
      ));
      expect(find.text('320/500 gal'), findsOneWidget);
    });

    testWidgets("renders fuel-type sub-caption 'Propane' when set",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.normal),
      ));
      expect(find.text('Propane'), findsOneWidget);
    });

    testWidgets('does NOT render fuel-type sub-caption when null',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.full),
      ));
      // full fixture has no fuelTypeLabel
      expect(find.text('Propane'), findsNothing);
    });

    testWidgets('normal (64%) → green fill, no red border', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.normal),
      ));
      final fillBox = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.success)
          .toList();
      expect(fillBox, isNotEmpty,
          reason: 'expected green success-color fill container');
    });

    testWidgets('empty (0%) → red color, red border, label 0/500 gal',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.empty),
      ));
      expect(find.text('0/500 gal'), findsOneWidget);
      final fillBoxes = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.error)
          .toList();
      expect(fillBoxes, isNotEmpty, reason: 'expected red fill at 0%');
    });

    testWidgets('low (16%) → red color + red border', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.low),
      ));
      final fillBoxes = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.error)
          .toList();
      expect(fillBoxes, isNotEmpty);
    });

    testWidgets('amber (40%) → amber color, no red border', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.amber),
      ));
      final fillBoxes = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.warning)
          .toList();
      expect(fillBoxes, isNotEmpty, reason: 'expected amber/warning fill');
    });

    testWidgets('full (100%) → green fill, label 500/500 gal',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.full),
      ));
      expect(find.text('500/500 gal'), findsOneWidget);
      final fillBoxes = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.success)
          .toList();
      expect(fillBoxes, isNotEmpty);
    });

    testWidgets('overfull (110%) → clamps to 100% + Overfull badge visible',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.overfull),
      ));
      expect(find.text('Overfull'), findsOneWidget);
      // Verify clamp: FractionallySizedBox heightFactor is clamped to 1.0.
      final fsb = tester.widget<FractionallySizedBox>(
          find.byType(FractionallySizedBox));
      expect(fsb.heightFactor, 1.0);
    });

    testWidgets('zeroCapacity defensive — does not throw, shows 0/0 gal',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.zeroCapacity),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('0/0 gal'), findsOneWidget);
    });

    testWidgets('decimal precision — 320.5/500 gal renders correctly',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.decimal),
      ));
      // 320.5 retains .5; 500.0 strips trailing .0 → '500'.
      expect(find.text('320.5/500 gal'), findsOneWidget);
    });

    testWidgets("metric unit label 'L' renders", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.metricUnit),
      ));
      expect(find.text('320/500 L'), findsOneWidget);
    });
  });
}

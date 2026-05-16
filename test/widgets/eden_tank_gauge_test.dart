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

  // -----------------------------------------------------------------
  // Task 2 — Segmented + dial modes + custom thresholds + adaptive-tier
  // -----------------------------------------------------------------
  group('EdenTankGauge mode switching', () {
    testWidgets('segmented mode renders 5 segment containers',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.normal,
          mode: EdenTankGaugeMode.segmented,
        ),
      ));
      // 5 segments — each keyed by 'eden-tank-segment-{N}-{filled|empty}'.
      var segmentCount = 0;
      for (var i = 0; i < 5; i++) {
        if (find.byKey(ValueKey('eden-tank-segment-$i-filled')).evaluate().isNotEmpty ||
            find.byKey(ValueKey('eden-tank-segment-$i-empty')).evaluate().isNotEmpty) {
          segmentCount++;
        }
      }
      expect(segmentCount, 5);
    });

    testWidgets('dial mode renders a CustomPaint widget', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.normal,
          mode: EdenTankGaugeMode.dial,
        ),
      ));
      // Dial uses CustomPaint with a non-null painter (eden-tank-dial key).
      expect(find.byKey(const ValueKey('eden-tank-dial')), findsOneWidget);
    });

    testWidgets('linear mode explicit → linear visuals (FractionallySizedBox)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.normal,
          mode: EdenTankGaugeMode.linear,
        ),
      ));
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });
  });

  group('EdenTankGauge segmented mode behaviors', () {
    testWidgets('0% fill → no filled segments', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.empty,
          mode: EdenTankGaugeMode.segmented,
        ),
      ));
      // No segments should be filled.
      for (var i = 0; i < 5; i++) {
        expect(
          find.byKey(ValueKey('eden-tank-segment-$i-filled')),
          findsNothing,
          reason: 'segment $i should not be filled at 0%',
        );
      }
    });

    testWidgets('40% fill → 2 of 5 segments filled', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.amber,
          mode: EdenTankGaugeMode.segmented,
        ),
      ));
      var filled = 0;
      for (var i = 0; i < 5; i++) {
        if (find.byKey(ValueKey('eden-tank-segment-$i-filled')).evaluate().isNotEmpty) {
          filled++;
        }
      }
      expect(filled, 2);
    });

    testWidgets('80% fill (400/500) → 4 of 5 segments filled', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeData(capacityGal: 500, currentGal: 400),
          mode: EdenTankGaugeMode.segmented,
        ),
      ));
      var filled = 0;
      for (var i = 0; i < 5; i++) {
        if (find.byKey(ValueKey('eden-tank-segment-$i-filled')).evaluate().isNotEmpty) {
          filled++;
        }
      }
      expect(filled, 4);
    });

    testWidgets('100% fill → all 5 segments filled', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.full,
          mode: EdenTankGaugeMode.segmented,
        ),
      ));
      var filled = 0;
      for (var i = 0; i < 5; i++) {
        if (find.byKey(ValueKey('eden-tank-segment-$i-filled')).evaluate().isNotEmpty) {
          filled++;
        }
      }
      expect(filled, 5);
    });
  });

  group('EdenTankGauge custom thresholds', () {
    testWidgets('lowThresholdPct=0.30 → fill at 25% renders red (now ≤low)',
        (tester) async {
      // 125/500 = 25%. With low=0.30, that's ≤low → red.
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeData(capacityGal: 500, currentGal: 125),
          lowThresholdPct: 0.30,
        ),
      ));
      final reds = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.error)
          .toList();
      expect(reds, isNotEmpty,
          reason: '25% fill with low=0.30 should be red');
    });

    testWidgets('warningThresholdPct=0.70 → fill at 60% renders amber',
        (tester) async {
      // 300/500 = 60%. low=0.20 (default) < 60% ≤ warning=0.70 → amber.
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeData(capacityGal: 500, currentGal: 300),
          warningThresholdPct: 0.70,
        ),
      ));
      final ambers = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenColors.warning)
          .toList();
      expect(ambers, isNotEmpty,
          reason: '60% with warning=0.70 should be amber');
    });
  });

  group('EdenTankGauge adaptive-tier auto-selection', () {
    testWidgets(
        'no mode + Compact tier → defaults to linear (no CustomPaint, no segments)',
        (tester) async {
      // Force compact via EdenAdaptiveLayout.forceCompact: true.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: EdenAdaptiveLayout(
              forceCompact: true,
              compactBuilder: (_) =>
                  const EdenTankGauge(data: EdenTankGaugeFixtures.normal),
            ),
          ),
        ),
      ));
      // Should render linear — FractionallySizedBox present, no dial painter
      // or segment keys.
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(find.byKey(const ValueKey('eden-tank-dial')), findsNothing);
    });

    testWidgets(
        'explicit dial + Compact tier → still renders dial (explicit overrides)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: EdenAdaptiveLayout(
              forceCompact: true,
              compactBuilder: (_) => const EdenTankGauge(
                data: EdenTankGaugeFixtures.normal,
                mode: EdenTankGaugeMode.dial,
              ),
            ),
          ),
        ),
      ));
      expect(find.byKey(const ValueKey('eden-tank-dial')), findsOneWidget);
    });

    testWidgets('no mode + no scope → defaults to linear', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(data: EdenTankGaugeFixtures.normal),
      ));
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(find.byKey(const ValueKey('eden-tank-dial')), findsNothing);
    });
  });

  // -----------------------------------------------------------------
  // Task 3 — iPhone-narrow safety
  // -----------------------------------------------------------------
  group('EdenTankGauge iPhone-narrow safety (390pt)', () {
    testWidgets('linear mode at 80pt column — no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.normal,
          mode: EdenTankGaugeMode.linear,
        ),
        width: 80,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('segmented mode at 200pt — no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.normal,
          mode: EdenTankGaugeMode.segmented,
        ),
        width: 200,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dial mode at 200pt — no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTankGauge(
          data: EdenTankGaugeFixtures.normal,
          mode: EdenTankGaugeMode.dial,
        ),
        width: 200,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

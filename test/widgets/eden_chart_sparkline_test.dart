import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_chart_sparkline_fixtures.dart';

Widget wrap(Widget child, {double width = 300, double height = 40}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Smoke render — existing surface (was untested pre-012-05)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — smoke render', () {
    testWidgets('empty values list renders without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenSparkline(values: [])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('single value renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.singleValue(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('multi-value labTrendHemoglobin renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.labTrendHemoglobin(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('flat-line fixture (maxV == minV) renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.flatLine(),
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Additive params — minValue / maxValue
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — minValue / maxValue overrides', () {
    testWidgets('minValue: 0, maxValue: 100 renders tank-level fixture safely', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.tankLevelHistory(),
        minValue: 0,
        maxValue: 100,
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Additive params — referenceLines
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — referenceLines', () {
    testWidgets('single reference line at y=12.0 renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.labTrendHemoglobin(),
        referenceLines: const [12.0],
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple reference lines (12.0 + 14.0) render without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.labTrendHemoglobin(),
        referenceLines: const [12.0, 14.0],
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('referenceLines defaults to empty list (no exception)', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.labTrendHemoglobin(),
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Additive params — nullablePoints
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — nullablePoints', () {
    testWidgets('nullablePoints=true with NaN gaps renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.withNanGaps(),
        nullablePoints: true,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('nullablePoints=false with NaN values renders without exception (NaN passed through)', (tester) async {
      await tester.pumpWidget(wrap(EdenSparkline(
        values: EdenSparklineFixtures.withNanGaps(),
      )));
      // No test exception (the painter discards NaN frames upstream of
      // canvas operations either way).
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Width semantics
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — width semantics', () {
    testWidgets('width: 80 inside Row renders without exception', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EdenSparkline(values: [1, 2, 3], width: 80, height: 40),
              ],
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('width: null inside Expanded renders without exception', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Row(
              children: [
                Expanded(child: EdenSparkline(values: [1, 2, 3], height: 40)),
              ],
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Composition with EdenKpiTile (obj 012-02)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — composition with EdenKpiTile', () {
    testWidgets('inside EdenKpiTile.trailingSlot renders without exception', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: EdenAggregateKpiStrip(
              tiles: [
                EdenKpiTile(
                  label: 'Sales',
                  displayValue: r'$1,245',
                  trailingSlot: SizedBox(
                    width: 80,
                    height: 24,
                    child: EdenSparkline(
                      values: EdenSparklineFixtures.sales7Day(),
                      height: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Backwards-compat
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSparkline — backwards-compat', () {
    testWidgets('old call site (no new params) renders identically (smoke)', (tester) async {
      await tester.pumpWidget(wrap(const EdenSparkline(values: [1, 2, 3])));
      expect(tester.takeException(), isNull);
    });
  });
}

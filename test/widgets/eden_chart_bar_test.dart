import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_chart_bar_fixtures.dart';

Widget wrap(Widget child, {double width = 400, double height = 300}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Smoke render — existing surface (was untested pre-012-06)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenBarChart — smoke render', () {
    testWidgets('empty series renders without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenBarChart(series: [])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('single series single bar renders without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenBarChart(series: [
        EdenChartSeries(name: 'A', data: [
          EdenChartDataPoint(label: 'X', value: 10),
        ]),
      ])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('retailDailySales (1 series, 7 points) renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fuelByTruck (3 series, 4 weeks) renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.fuelByTruck(),
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Variants — grouped / stacked / horizontal
  // ─────────────────────────────────────────────────────────────────────

  group('EdenBarChart — variants', () {
    testWidgets('stacked=true + medicalClaimsStatus renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        stacked: true,
        series: EdenChartBarFixtures.medicalClaimsStatus(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacked=false (grouped) + medicalClaimsStatus renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.medicalClaimsStatus(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('horizontal=true + tradesRevenueByCategory renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        horizontal: true,
        series: EdenChartBarFixtures.tradesRevenueByCategory(),
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Additive params
  // ─────────────────────────────────────────────────────────────────────

  group('EdenBarChart — additive params', () {
    testWidgets('xAxisLabel: "Day" + showLabels: true → text "Day" found', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
        xAxisLabel: 'Day',
      )));
      expect(find.text('Day'), findsOneWidget);
    });

    testWidgets('yAxisLabel: "Volume" + showLabels: true → text "Volume" found', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
        yAxisLabel: 'Volume',
      )));
      expect(find.text('Volume'), findsOneWidget);
    });

    testWidgets('xAxisLabel + showLabels=false → label NOT found', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
        xAxisLabel: 'Day',
        showLabels: false,
      )));
      expect(find.text('Day'), findsNothing);
    });

    testWidgets('minValue: 0, maxValue: 1000 renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
        minValue: 0,
        maxValue: 1000,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('referenceLines: [800.0] renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
        referenceLines: const [800.0],
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Backwards-compat
  // ─────────────────────────────────────────────────────────────────────

  group('EdenBarChart — backwards-compat', () {
    testWidgets('old call site (no new params) renders identically (smoke)', (tester) async {
      await tester.pumpWidget(wrap(EdenBarChart(
        series: EdenChartBarFixtures.retailDailySales(),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}

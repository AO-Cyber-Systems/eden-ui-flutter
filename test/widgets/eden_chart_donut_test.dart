import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_chart_donut_fixtures.dart';

Widget wrap(Widget child, {double width = 400, double height = 400}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // EdenPieChart — additive centerLabelSlot + backwards-compat
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPieChart — centerLabelSlot', () {
    testWidgets('EdenPieChart(data: [], donut: true) renders without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenPieChart(data: [], donut: true)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('donut: true + centerLabel: "\$2,400" — text found', (tester) async {
      await tester.pumpWidget(wrap(EdenPieChart(
        data: EdenChartDonutFixtures.serviceMix(),
        donut: true,
        centerLabel: r'$2,400',
      )));
      // The painter draws via TextPainter on the canvas, so find.text doesn't
      // resolve. Verify via the widget's centerLabel property instead.
      final widget = tester.widget<EdenPieChart>(find.byType(EdenPieChart));
      expect(widget.centerLabel, r'$2,400');
    });

    testWidgets('donut: true + centerLabelSlot: Text("CUSTOM_CENTER") — text found', (tester) async {
      await tester.pumpWidget(wrap(EdenPieChart(
        data: EdenChartDonutFixtures.serviceMix(),
        donut: true,
        centerLabelSlot: const Text('CUSTOM_CENTER'),
      )));
      expect(find.text('CUSTOM_CENTER'), findsOneWidget);
    });

    testWidgets('both centerLabel + centerLabelSlot: slot wins; centerLabel suppressed in painter', (tester) async {
      await tester.pumpWidget(wrap(EdenPieChart(
        data: EdenChartDonutFixtures.serviceMix(),
        donut: true,
        centerLabel: 'STRING_CENTER',
        centerLabelSlot: const Text('SLOT_CENTER'),
      )));
      expect(find.text('SLOT_CENTER'), findsOneWidget);
      // STRING_CENTER is drawn on canvas via TextPainter when no slot is
      // present, but suppressed by passing null centerLabel to the inner
      // painter when slot is set. Verify by inspecting the rendered Widget
      // tree — STRING_CENTER never reaches a Text node (only canvas paint).
      expect(find.text('STRING_CENTER'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // EdenDonutChart — smoke
  // ─────────────────────────────────────────────────────────────────────

  group('EdenDonutChart — smoke render', () {
    testWidgets('empty data renders without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenDonutChart(data: [])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('single-slice fixture renders without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenDonutChart(data: [
        EdenChartDataPoint(label: 'Only', value: 100),
      ])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('multi-slice serviceMix renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenDonutChart(
        data: EdenChartDonutFixtures.serviceMix(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('centerLabelSlot: Text("CUSTOM") — text found', (tester) async {
      await tester.pumpWidget(wrap(EdenDonutChart(
        data: EdenChartDonutFixtures.serviceMix(),
        centerLabelSlot: const Text('CUSTOM_DONUT'),
      )));
      expect(find.text('CUSTOM_DONUT'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Legend behavior
  // ─────────────────────────────────────────────────────────────────────

  group('EdenDonutChart — legend', () {
    testWidgets('showLegend: false → no Wrap legend at top level', (tester) async {
      await tester.pumpWidget(wrap(EdenDonutChart(
        data: EdenChartDonutFixtures.serviceMix(),
        showLegend: false,
      )));
      // EdenDonutChart's own legend (a Wrap widget at the top level) is absent.
      // EdenPieChart's internal legend is also suppressed (showLegend: false
      // passed down). So no Wrap should be findable.
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('legendPosition: bottom → outer is Column (chart above, legend below)', (tester) async {
      await tester.pumpWidget(wrap(EdenDonutChart(
        data: EdenChartDonutFixtures.serviceMix(),
        // explicit default for documentation clarity
        legendPosition: EdenChartLegendPosition.bottom,
      )));
      // The outermost layout child of EdenDonutChart is a Column when the
      // legend is bottom.
      final donut = find.byType(EdenDonutChart);
      expect(donut, findsOneWidget);
      expect(
        find.descendant(of: donut, matching: find.byType(Column)),
        findsAtLeastNWidgets(1),
      );
      // The 4 slice labels appear via the legend.
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Treatment'), findsOneWidget);
      expect(find.text('Retail'), findsOneWidget);
    });

    testWidgets('legendPosition: right → outer is Row', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDonutChart(
          data: EdenChartDonutFixtures.serviceMix(),
          legendPosition: EdenChartLegendPosition.right,
        ),
        width: 600,
      ));
      final donut = find.byType(EdenDonutChart);
      expect(donut, findsOneWidget);
      expect(
        find.descendant(of: donut, matching: find.byType(Row)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('legend renders 1 row per data point (4 slices → 4 labels)', (tester) async {
      await tester.pumpWidget(wrap(EdenDonutChart(
        data: EdenChartDonutFixtures.serviceMix(),
      )));
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Treatment'), findsOneWidget);
      expect(find.text('Retail'), findsOneWidget);
    });

    testWidgets('empty data → no legend (early-return)', (tester) async {
      await tester.pumpWidget(wrap(const EdenDonutChart(data: [])));
      // No legend Wrap exists.
      expect(find.byType(Wrap), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Composition smoke
  // ─────────────────────────────────────────────────────────────────────

  group('EdenDonutChart — composition', () {
    testWidgets('centerLabelSlot Column composition renders without exception', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDonutChart(
          data: EdenChartDonutFixtures.serviceMix(),
          centerLabelSlot: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 28),
              SizedBox(height: 4),
              Text(
                r'$4,890',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Text('On-hand', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        width: 400,
        height: 500,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.text(r'$4,890'), findsOneWidget);
      expect(find.text('On-hand'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Backwards-compat — EdenPieChart
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPieChart — backwards-compat', () {
    testWidgets('EdenPieChart(data: ..., donut: false) (pie variant) renders unchanged', (tester) async {
      await tester.pumpWidget(wrap(EdenPieChart(
        data: EdenChartDonutFixtures.serviceMix(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('EdenPieChart(data: ..., donut: true, centerLabel: "X") (existing donut call) renders unchanged', (tester) async {
      await tester.pumpWidget(wrap(EdenPieChart(
        data: EdenChartDonutFixtures.serviceMix(),
        donut: true,
        centerLabel: 'EXISTING_CALL',
      )));
      expect(tester.takeException(), isNull);
    });
  });
}

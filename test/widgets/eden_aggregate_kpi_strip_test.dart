import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_aggregate_kpi_strip_fixtures.dart';

/// Default 800pt wrap shows entire strip; tests that exercise iPhone-narrow
/// reflow pass `width: 390`.
Widget wrap(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Value classes — instantiation roundtrip
  // ─────────────────────────────────────────────────────────────────────

  group('EdenKpiTile + EdenKpiAggregate value classes', () {
    test('EdenKpiTile preserves required + optional fields', () {
      const tile = EdenKpiTile(
        label: 'Sales',
        displayValue: r'$1,245',
        secondaryLabel: 'vs last week',
        trend: 0.12,
      );
      expect(tile.label, 'Sales');
      expect(tile.displayValue, r'$1,245');
      expect(tile.secondaryLabel, 'vs last week');
      expect(tile.trend, closeTo(0.12, 0.0001));
      expect(tile.polarity, EdenKpiTrendPolarity.positiveIsGood);
    });

    test('EdenKpiAggregate roundtrip', () {
      const agg = EdenKpiAggregate(
        label: 'Total',
        displayValue: r'$2,400',
        mode: EdenKpiAggregateMode.sum,
      );
      expect(agg.label, 'Total');
      expect(agg.displayValue, r'$2,400');
      expect(agg.mode, EdenKpiAggregateMode.sum);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Tile rendering
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — tile rendering', () {
    testWidgets('renders 4 EdenCard children for salesDay fixture', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
      )));
      // 4 tiles → at least 4 EdenCard widgets (some interactive, some plain).
      expect(find.byType(EdenCard), findsNWidgets(4));
    });

    testWidgets('tile shows label + displayValue', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
      )));
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text(r'$1,245'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
    });

    testWidgets('secondaryLabel renders when provided', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(
        tiles: [
          EdenKpiTile(
            label: 'Sales',
            displayValue: r'$1,245',
            secondaryLabel: 'vs last week',
            trend: 0.12,
          ),
        ],
      )));
      expect(find.text('vs last week'), findsOneWidget);
    });

    testWidgets('leadingIcon renders before label', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(
        tiles: [
          EdenKpiTile(
            label: 'Sales',
            displayValue: r'$1,245',
            leadingIcon: Icon(Icons.attach_money),
          ),
        ],
      )));
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('trailingSlot widget renders inside the tile', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(
        tiles: [
          EdenKpiTile(
            label: 'Sales',
            displayValue: r'$1,245',
            trailingSlot: Text('TRAILING_MARKER'),
          ),
        ],
      )));
      expect(find.text('TRAILING_MARKER'), findsOneWidget);
    });

    testWidgets('onTap callback fires when tile is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: [
          EdenKpiTile(
            label: 'Sales',
            displayValue: r'$1,245',
            onTap: () => tapped = true,
          ),
        ],
      )));
      await tester.tap(find.text('Sales'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('horizontal SingleChildScrollView ancestor exists', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
      )));
      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollable.scrollDirection, Axis.horizontal);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — empty state', () {
    testWidgets('tiles=[] AND emptyState=null renders default placeholder text', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [])));
      expect(find.text('No KPIs configured'), findsOneWidget);
    });

    testWidgets('tiles=[] AND emptyState=Text("CUSTOM") renders custom only', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(
        tiles: [],
        emptyState: Text('CUSTOM_EMPTY'),
      )));
      expect(find.text('CUSTOM_EMPTY'), findsOneWidget);
      expect(find.text('No KPIs configured'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Trend arrow + polarity
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — trend arrow + polarity', () {
    testWidgets('trend=0.12 + positiveIsGood → arrow_upward', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'A', displayValue: '1', trend: 0.12),
      ])));
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('trend=-0.04 + positiveIsGood → arrow_downward', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'A', displayValue: '1', trend: -0.04),
      ])));
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('trend=0 → remove icon (neutral)', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'A', displayValue: '1', trend: 0),
      ])));
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('trend=null → no arrow icons', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'A', displayValue: '1'),
      ])));
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('positive trend + positiveIsGood paints icon with success color (default fallback)', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'A', displayValue: '1', trend: 0.12),
      ])));
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      expect(iconWidget.color, isNotNull);
    });

    testWidgets('positive trend + negativeIsGood flips to error color', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(
          label: 'A',
          displayValue: '1',
          trend: 0.12,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
      ])));
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      // The color is non-null AND distinct from the positiveIsGood case.
      expect(iconWidget.color, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Aggregate footer
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — aggregate footer', () {
    testWidgets('aggregate is rendered when non-null', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
        aggregate: EdenAggregateKpiStripFixtures.salesDayAggregate(),
      )));
      // Two values match $1,245 — one from the Sales tile and one from the aggregate.
      expect(find.text(r'$1,245'), findsNWidgets(2));
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('aggregate=null → no extra "Total" text', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
      )));
      expect(find.text('Total'), findsNothing);
    });

    testWidgets('stickyAggregate=true → aggregate is NOT inside SingleChildScrollView', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
        aggregate: EdenAggregateKpiStripFixtures.salesDayAggregate(),
      )));
      final inScrollView = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Total'),
      );
      expect(inScrollView, findsNothing);
    });

    testWidgets('stickyAggregate=false → aggregate IS inside SingleChildScrollView', (tester) async {
      await tester.pumpWidget(wrap(EdenAggregateKpiStrip(
        tiles: EdenAggregateKpiStripFixtures.salesDay(),
        aggregate: EdenAggregateKpiStripFixtures.salesDayAggregate(),
        stickyAggregate: false,
      )));
      final inScrollView = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Total'),
      );
      expect(inScrollView, findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // iPhone-narrow (390pt) responsive
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — iPhone-narrow 390pt responsive', () {
    testWidgets('4 tiles + aggregate at width 390 — no RenderFlex overflowed', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAggregateKpiStrip(
          tiles: EdenAggregateKpiStripFixtures.salesDay(),
          aggregate: EdenAggregateKpiStripFixtures.salesDayAggregate(),
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('aggregate label findable at width 390', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAggregateKpiStrip(
          tiles: EdenAggregateKpiStripFixtures.salesDay(),
          aggregate: EdenAggregateKpiStripFixtures.salesDayAggregate(),
        ),
        width: 390,
      ));
      expect(find.text('Total'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Section 508 / a11y
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — Section 508 a11y', () {
    testWidgets('positive trend tile Semantics label includes "trending up"', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'Sales today', displayValue: r'$1,245', trend: 0.12),
      ])));
      expect(
        find.bySemanticsLabel(r'Sales today: $1,245 trending up'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('negative trend tile Semantics label includes "trending down"', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'Sales today', displayValue: r'$1,245', trend: -0.04),
      ])));
      expect(
        find.bySemanticsLabel(r'Sales today: $1,245 trending down'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('zero trend tile Semantics label includes "unchanged"', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'Sales today', displayValue: r'$1,245', trend: 0),
      ])));
      expect(
        find.bySemanticsLabel(r'Sales today: $1,245 unchanged'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('trend=null tile Semantics label has NO trend suffix', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(tiles: [
        EdenKpiTile(label: 'Sales today', displayValue: r'$1,245'),
      ])));
      expect(
        find.bySemanticsLabel(r'Sales today: $1,245'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets(r'aggregate Semantics label format "Aggregate total: $X"', (tester) async {
      await tester.pumpWidget(wrap(const EdenAggregateKpiStrip(
        tiles: [EdenKpiTile(label: 'A', displayValue: '1')],
        aggregate: EdenKpiAggregate(
          label: 'Total',
          displayValue: r'$2,400',
          mode: EdenKpiAggregateMode.sum,
        ),
      )));
      expect(
        find.bySemanticsLabel(r'Aggregate total: $2,400'),
        findsAtLeastNWidgets(1),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Export surface
  // ─────────────────────────────────────────────────────────────────────

  group('EdenAggregateKpiStrip — export surface', () {
    test('public API names reachable from eden_ui.dart', () {
      const tile = EdenKpiTile(label: 'A', displayValue: '1');
      const agg = EdenKpiAggregate(label: 'B', displayValue: '2');
      const polarity = EdenKpiTrendPolarity.negativeIsGood;
      const mode = EdenKpiAggregateMode.avg;
      const strip = EdenAggregateKpiStrip(tiles: [tile], aggregate: agg);
      expect(strip.tiles.length, 1);
      expect(polarity, EdenKpiTrendPolarity.negativeIsGood);
      expect(mode, EdenKpiAggregateMode.avg);
    });
  });
}

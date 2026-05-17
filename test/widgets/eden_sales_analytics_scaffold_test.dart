import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_sales_analytics_scaffold_fixtures.dart';

Widget wrap(Widget child, {double width = 1100, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('EdenSalesAnalyticsScaffold — static rendering (sections)', () {
    testWidgets('renders KPI cards from fixture (5 cards)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.text('Gross sales'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Avg basket'), findsOneWidget);
      expect(find.text('Refund rate'), findsOneWidget);
      expect(find.text('Top dept'), findsOneWidget);
    });

    testWidgets('renders trend chart section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      // Default chart type = bar.
      expect(find.byType(EdenBarChart), findsOneWidget);
    });

    testWidgets('renders top products rows (8 from fixture)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.text('Espresso Single'), findsOneWidget);
      expect(find.text('Sparkling Water'), findsOneWidget);
    });

    testWidgets('renders top categories section (4 from fixture)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.text('Hot drinks'), findsAtLeastNWidgets(1));
      expect(find.text('Pastries'), findsOneWidget);
      // 4 LinearProgressIndicators rendered (category shim).
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });
  });

  group('EdenSalesAnalyticsScaffold — KPI delta variants', () {
    testWidgets('positive delta KPI renders an arrow_upward chip',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.byIcon(Icons.arrow_upward), findsAtLeastNWidgets(1));
      expect(find.text('12.0%'), findsOneWidget);
    });

    testWidgets('negative delta KPI renders an arrow_downward chip',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.byIcon(Icons.arrow_downward), findsAtLeastNWidgets(1));
      expect(find.text('3.0%'), findsOneWidget);
    });

    testWidgets('KPI with null delta renders no Chip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.singleKpi(),
        )),
      );
      // singleKpi has 1 KPI with no deltaPct — no delta chips at all.
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('empty kpis list renders empty state in KPI section',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.empty(),
        )),
      );
      expect(find.text('No metrics for this range'), findsOneWidget);
    });
  });

  group('EdenSalesAnalyticsScaffold — chart type switching', () {
    testWidgets('default chart type is bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.byType(EdenBarChart), findsOneWidget);
      expect(find.byType(EdenLineChart), findsNothing);
      expect(find.byType(EdenSparkline), findsNothing);
    });

    testWidgets('trendChartType=line renders EdenLineChart', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
          trendChartType: EdenAnalyticsChartType.line,
        )),
      );
      expect(find.byType(EdenLineChart), findsOneWidget);
      expect(find.byType(EdenBarChart), findsNothing);
    });

    testWidgets('trendChartType=sparkline renders EdenSparkline',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
          trendChartType: EdenAnalyticsChartType.sparkline,
        )),
      );
      expect(find.byType(EdenSparkline), findsOneWidget);
    });

    testWidgets('empty trendSeries renders empty-state placeholder',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.empty(),
        )),
      );
      expect(find.text('No trend data'), findsOneWidget);
    });
  });

  group('EdenSalesAnalyticsScaffold — top product rows', () {
    testWidgets('row 1 rank/name/units/revenue/trend render', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.text('1'), findsAtLeastNWidgets(1)); // rank
      expect(find.text('Espresso Single'), findsOneWidget);
      expect(find.text('142 sold'), findsOneWidget);
    });

    testWidgets('trend=up row renders arrow_upward icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      // 4 'up' rows (Espresso, Cappuccino, Mocha, Cold Brew) + 1 KPI gross
      // sales arrow_upward chip = >= 5.
      expect(find.byIcon(Icons.arrow_upward), findsAtLeastNWidgets(5));
    });

    testWidgets('trend=down row renders arrow_downward icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.byIcon(Icons.arrow_downward), findsAtLeastNWidgets(2));
    });

    testWidgets('trend=flat row renders horizontal_rule icon',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        )),
      );
      expect(find.byIcon(Icons.horizontal_rule), findsAtLeastNWidgets(1));
    });

    testWidgets('empty topProducts renders empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.empty(),
        )),
      );
      expect(find.text('No top products'), findsOneWidget);
    });
  });

  group('EdenSalesAnalyticsScaffold — responsive layout', () {
    testWidgets('width 1100pt → wide row layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        ), width: 1100),
      );
      expect(find.byKey(const ValueKey('eden-analytics-wide-row')),
          findsOneWidget);
    });

    testWidgets('width 800pt → narrow list layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenSalesAnalyticsScaffold(
          data: EdenAnalyticsFixtures.weekOfMay(),
        ), width: 800),
      );
      expect(find.byKey(const ValueKey('eden-analytics-narrow-list')),
          findsOneWidget);
    });
  });

  group('EdenSalesAnalyticsScaffold — iPhone-narrow safety', () {
    testWidgets('390pt renders narrow list layout + no overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdenSalesAnalyticsScaffold(
              data: EdenAnalyticsFixtures.weekOfMay(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('eden-analytics-narrow-list')),
          findsOneWidget);
    });
  });
}

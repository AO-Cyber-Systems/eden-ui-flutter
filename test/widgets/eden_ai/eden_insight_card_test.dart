import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_ai_models_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('eden_ai_models (foundation smoke test)', () {
    test('enum/class types are non-null and publicly importable', () {
      expect(EdenInsightType.summary, isNotNull);
      expect(EdenChartType.bar, isNotNull);
      expect(EdenInsightSeverity.critical.color, const Color(0xFFEF4444));
      expect(EdenAiPersona.operations.displayLabel, 'Operations');
      expect(EdenChatRole.user, isNotNull);
      expect(
          const EdenInsightAction(label: 'Test').label, 'Test');
      expect(EdenAiModelsFixtures.summaryInsight.type,
          EdenInsightType.summary);
    });
  });

  group('EdenInsightCard — summary layout', () {
    testWidgets('renders title + article icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.summaryInsight),
      ));
      expect(find.text('Project Update'), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('renders subtitle when present',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.summaryInsight),
      ));
      expect(find.text('3 tasks remaining'), findsOneWidget);
    });
  });

  group('EdenInsightCard — metric layout', () {
    testWidgets("trend=up renders trending_up icon + green",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.metricInsight),
      ));
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text(r'$12,500'), findsOneWidget);
      expect(find.text('+8%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.trending_up));
      expect(iconWidget.color, const Color(0xFF22C55E));
    });

    testWidgets("trend=down renders trending_down icon + red",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.metricDownInsight),
      ));
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.trending_down));
      expect(iconWidget.color, const Color(0xFFEF4444));
    });

    testWidgets("trend=flat renders trending_flat icon + onSurfaceVariant",
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenInsightCard(
              content: EdenAiModelsFixtures.metricFlatInsight),
        ),
      ));
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.trending_flat));
      expect(iconWidget.color, theme.colorScheme.onSurfaceVariant);
    });
  });

  group('EdenInsightCard — alert layout', () {
    testWidgets("severity=warning renders warning_amber_rounded icon",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.alertInsight),
      ));
      expect(find.text('Permit expiring'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      final iconWidget = tester.widget<Icon>(
          find.byIcon(Icons.warning_amber_rounded));
      expect(iconWidget.color, EdenInsightSeverity.warning.color);
    });

    testWidgets("severity=critical renders error icon",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.alertCriticalInsight),
      ));
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets("severity=info still renders warning_amber_rounded (donor default)",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.alertInfoInsight),
      ));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('EdenInsightCard — suggestion layout', () {
    testWidgets('renders lightbulb_outline icon in gold',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.suggestionInsight),
      ));
      expect(find.text('Try AI summary'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.lightbulb_outline));
      expect(iconWidget.color, const Color(0xFFF59E0B));
    });
  });

  group('EdenInsightCard — chart layout', () {
    testWidgets('bar chart renders title + CustomPaint + 7 labels',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.chartInsight),
      ));
      expect(find.text('Weekly leads'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('line chart renders without exceptions',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.chartLineInsight),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pie chart renders without exceptions',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.chartPieInsight),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenInsightCard — diagram layout', () {
    testWidgets("renders 'Diagram preview' placeholder",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
            content: EdenAiModelsFixtures.diagramInsight),
      ));
      expect(find.text('Workflow'), findsOneWidget);
      expect(find.text('Diagram preview'), findsOneWidget);
    });
  });

  group('EdenInsightCard — actions', () {
    testWidgets('action onTap fires when button tapped',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenInsightCard(
          content: EdenInsightContent(
            id: 'sg2',
            type: EdenInsightType.suggestion,
            title: 'Pick one',
            actions: [
              EdenInsightAction(
                  label: 'View details', onTap: () => tapped = true),
            ],
          ),
        ),
      ));
      await tester.tap(find.text('View details'));
      expect(tapped, isTrue);
    });

    testWidgets("action onTap=null shows 'Coming soon — label' SnackBar",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
          content: EdenInsightContent(
            id: 'sg3',
            type: EdenInsightType.suggestion,
            title: 'Pick one',
            actions: [
              EdenInsightAction(label: 'Acknowledge'),
            ],
          ),
        ),
      ));
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming soon'), findsOneWidget);
      expect(find.textContaining('Acknowledge'), findsWidgets);
    });
  });

  group('EdenInsightCard — compact mode', () {
    testWidgets('compact=true shrinks outer Padding from 12→8',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInsightCard(
          content: EdenAiModelsFixtures.summaryInsight,
          compact: true,
        ),
      ));
      // Find the Padding descendant inside the card whose padding is 8.
      final paddings = tester.widgetList<Padding>(find.descendant(
        of: find.byType(EdenInsightCard),
        matching: find.byType(Padding),
      ));
      expect(
        paddings.any((p) => p.padding == const EdgeInsets.all(8)),
        isTrue,
      );
    });
  });

  group('EdenInsightCard — iPhone-narrow safety', () {
    testWidgets('all 6 layouts render at SizedBox(width: 280) with no overflow',
        (tester) async {
      const layouts = <EdenInsightContent>[
        EdenAiModelsFixtures.summaryInsight,
        EdenAiModelsFixtures.metricInsight,
        EdenAiModelsFixtures.alertInsight,
        EdenAiModelsFixtures.suggestionInsight,
        EdenAiModelsFixtures.chartInsight,
        EdenAiModelsFixtures.diagramInsight,
      ];
      for (final c in layouts) {
        await tester.pumpWidget(wrap(
          SizedBox(width: 280, child: EdenInsightCard(content: c)),
        ));
        expect(tester.takeException(), isNull,
            reason: 'overflow at width 280 for ${c.type}');
      }
    });
  });
}

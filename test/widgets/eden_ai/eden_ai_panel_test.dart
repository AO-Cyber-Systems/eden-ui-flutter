import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_ai_models_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenAiPanel — expanded state', () {
    testWidgets(
        "renders 'AI Insights' header + persona badge + insight cards for non-empty insights",
        (tester) async {
      var toggles = 0;
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [
            EdenAiModelsFixtures.summaryInsight,
            EdenAiModelsFixtures.metricInsight,
          ],
          persona: EdenAiPersona.operations,
          isExpanded: true,
          onToggle: () => toggles++,
        ),
      ));
      expect(find.text('AI Insights'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.byType(EdenInsightCard), findsNWidgets(2));
      expect(toggles, 0); // onToggle not fired yet
    });

    testWidgets(
        'AnimatedContainer width=320 in expanded state',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.operations,
          isExpanded: true,
          onToggle: () {},
        ),
      ));
      await tester.pumpAndSettle();
      final ac = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first);
      // AnimatedContainer.constraints is a BoxConstraints with maxWidth==width.
      expect(ac.constraints?.maxWidth, 320);
    });

    testWidgets('persona icon visible (operations → dashboard)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.operations,
          isExpanded: true,
          onToggle: () {},
        ),
      ));
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });
  });

  group('EdenAiPanel — collapsed state', () {
    testWidgets(
        "renders chevron_left + rotated 'AI' + auto_awesome; no EdenInsightCards",
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.operations,
          isExpanded: false,
          onToggle: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.byType(EdenInsightCard), findsNothing);
    });

    testWidgets('AnimatedContainer width=40 in collapsed state',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.operations,
          isExpanded: false,
          onToggle: () {},
        ),
      ));
      await tester.pumpAndSettle();
      final ac = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first);
      expect(ac.constraints?.maxWidth, 40);
    });
  });

  group('EdenAiPanel — toggle wiring', () {
    testWidgets('tapping chevron_right in expanded state fires onToggle',
        (tester) async {
      var toggles = 0;
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 320,
          height: 200,
          child: EdenAiPanel(
            insights: const [EdenAiModelsFixtures.summaryInsight],
            persona: EdenAiPersona.operations,
            isExpanded: true,
            onToggle: () => toggles++,
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(toggles, 1);
    });

    testWidgets('tapping anywhere in collapsed state fires onToggle',
        (tester) async {
      var toggles = 0;
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 40,
          height: 200,
          child: EdenAiPanel(
            insights: const [EdenAiModelsFixtures.summaryInsight],
            persona: EdenAiPersona.operations,
            isExpanded: false,
            onToggle: () => toggles++,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.auto_awesome));
      expect(toggles, 1);
    });
  });

  group('EdenAiPanel — loading state', () {
    testWidgets('isLoading=true renders 3 shimmer Containers (height 60); no insight cards',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 320,
          height: 400,
          child: EdenAiPanel(
            insights: const [],
            persona: EdenAiPersona.operations,
            isExpanded: true,
            onToggle: () {},
            isLoading: true,
          ),
        ),
      ));
      // 3 shimmer containers + 0 insight cards.
      expect(find.byType(EdenInsightCard), findsNothing);
      // Count Containers with explicit height=60 in shimmer area.
      final shimmer = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints == const BoxConstraints.tightFor(height: 60));
      expect(shimmer.length, 3);
    });

    testWidgets('isLoading takes priority over insights.isEmpty=false',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 320,
          height: 400,
          child: EdenAiPanel(
            insights: const [EdenAiModelsFixtures.summaryInsight],
            persona: EdenAiPersona.operations,
            isExpanded: true,
            onToggle: () {},
            isLoading: true,
          ),
        ),
      ));
      expect(find.byType(EdenInsightCard), findsNothing);
    });
  });

  group('EdenAiPanel — empty state', () {
    testWidgets("renders 'No insights available' when insights empty + !isLoading",
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 320,
          height: 400,
          child: EdenAiPanel(
            insights: const [],
            persona: EdenAiPersona.operations,
            isExpanded: true,
            onToggle: () {},
          ),
        ),
      ));
      expect(find.text('No insights available'), findsOneWidget);
      // auto_awesome appears in empty state (32px greyed).
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byType(EdenInsightCard), findsNothing);
    });
  });

  group('EdenAiPanel — personas', () {
    testWidgets('fieldTech persona shows engineering icon + Field Tech badge',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.fieldTech,
          isExpanded: true,
          onToggle: () {},
        ),
      ));
      expect(find.byIcon(Icons.engineering), findsOneWidget);
      expect(find.text('Field Tech'), findsOneWidget);
    });

    testWidgets('executive persona shows insights icon + Executive badge',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiPanel(
          insights: const [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.executive,
          isExpanded: true,
          onToggle: () {},
        ),
      ));
      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.text('Executive'), findsOneWidget);
    });
  });

  group('EdenAiPanel — iPhone-narrow safety', () {
    testWidgets(
        'renders 5 insights inside SizedBox(width: 320, height: 600) without overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 320,
          height: 600,
          child: EdenAiPanel(
            insights: const [
              EdenAiModelsFixtures.summaryInsight,
              EdenAiModelsFixtures.metricInsight,
              EdenAiModelsFixtures.alertInsight,
              EdenAiModelsFixtures.suggestionInsight,
              EdenAiModelsFixtures.chartInsight,
            ],
            persona: EdenAiPersona.operations,
            isExpanded: true,
            onToggle: () {},
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

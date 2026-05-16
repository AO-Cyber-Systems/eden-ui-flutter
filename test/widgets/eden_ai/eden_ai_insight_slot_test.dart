import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_ai_models_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenAiInsightSlot — disabled', () {
    testWidgets('enabled=false renders SizedBox.shrink, no EdenAiPanel',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiInsightSlot(
          insights: [EdenAiModelsFixtures.summaryInsight],
          persona: EdenAiPersona.finance,
        ),
      ));
      expect(find.byType(EdenAiPanel), findsNothing);
    });

    testWidgets(
        'enabled=false with isExpanded + onToggle still renders nothing',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAiInsightSlot(
          isExpanded: true,
          onToggle: () {},
          insights: const [EdenAiModelsFixtures.summaryInsight],
        ),
      ));
      expect(find.byType(EdenAiPanel), findsNothing);
    });
  });

  group('EdenAiInsightSlot — enabled', () {
    testWidgets(
        'composes EdenAiPanel with passed insights + persona',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            insights: [EdenAiModelsFixtures.summaryInsight],
            persona: EdenAiPersona.finance,
          ),
        ),
      ));
      expect(find.byType(EdenAiPanel), findsOneWidget);
      final panel = tester.widget<EdenAiPanel>(find.byType(EdenAiPanel));
      expect(panel.insights.length, 1);
      expect(panel.persona, EdenAiPersona.finance);
    });

    testWidgets(
        'persona null defaults to EdenAiPersona.operations',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      final panel = tester.widget<EdenAiPanel>(find.byType(EdenAiPanel));
      expect(panel.persona, EdenAiPersona.operations);
    });

    testWidgets(
        'insights null defaults to const []',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(enabled: true),
        ),
      ));
      final panel = tester.widget<EdenAiPanel>(find.byType(EdenAiPanel));
      expect(panel.insights, isEmpty);
    });

    testWidgets(
        'isExpanded default true',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      final panel = tester.widget<EdenAiPanel>(find.byType(EdenAiPanel));
      expect(panel.isExpanded, isTrue);
    });
  });

  group('EdenAiInsightSlot — toggle behavior', () {
    testWidgets(
        'internal toggle: tapping chevron flips internal expanded state',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      expect(
        tester.widget<EdenAiPanel>(find.byType(EdenAiPanel)).isExpanded,
        isTrue,
      );
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EdenAiPanel>(find.byType(EdenAiPanel)).isExpanded,
        isFalse,
      );
    });

    testWidgets(
        'external isExpanded=false → panel.isExpanded is false',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            isExpanded: false,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      expect(
        tester.widget<EdenAiPanel>(find.byType(EdenAiPanel)).isExpanded,
        isFalse,
      );
    });

    testWidgets(
        'external isExpanded change rebuilds with new value (didUpdateWidget sync)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            isExpanded: false,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            isExpanded: true,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EdenAiPanel>(find.byType(EdenAiPanel)).isExpanded,
        isTrue,
      );
    });

    testWidgets(
        'external onToggle: library does NOT internally setState; consumer owns flip',
        (tester) async {
      var toggleCount = 0;
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 320,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            isExpanded: true,
            onToggle: () => toggleCount++,
            insights: const [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(toggleCount, 1);
      // Internal state didn't auto-flip (no rebuild from parent yet).
      expect(
        tester.widget<EdenAiPanel>(find.byType(EdenAiPanel)).isExpanded,
        isTrue,
      );
    });
  });

  group('EdenAiInsightSlot — iPhone-narrow safety', () {
    testWidgets('enabled=true renders at 280pt sidebar without overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 280,
          height: 400,
          child: EdenAiInsightSlot(
            enabled: true,
            insights: [EdenAiModelsFixtures.summaryInsight],
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

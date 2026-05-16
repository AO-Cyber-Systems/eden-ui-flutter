import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenAiCollapsibleSection', () {
    testWidgets(
        'defaultExpanded=true: renders title + child + auto_awesome icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'Operations Insights',
          child: Text('Insights body'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Operations Insights'), findsOneWidget);
      expect(find.text('Insights body'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    CrossFadeState crossFadeStateOf(WidgetTester tester) {
      return tester
          .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
          .crossFadeState;
    }

    testWidgets("defaultExpanded=false: AnimatedCrossFade is showSecond",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'X',
          defaultExpanded: false,
          child: Text('hidden'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('X'), findsOneWidget);
      expect(crossFadeStateOf(tester), CrossFadeState.showSecond);
    });

    testWidgets('tapping header collapses an expanded section',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'Y',
          child: Text('hidden'),
        ),
      ));
      expect(crossFadeStateOf(tester), CrossFadeState.showFirst);
      await tester.tap(find.text('Y'));
      await tester.pumpAndSettle();
      expect(crossFadeStateOf(tester), CrossFadeState.showSecond);
    });

    testWidgets('tapping header expands a collapsed section',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'Z',
          defaultExpanded: false,
          child: Text('hidden'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(crossFadeStateOf(tester), CrossFadeState.showSecond);
      await tester.tap(find.text('Z'));
      await tester.pumpAndSettle();
      expect(crossFadeStateOf(tester), CrossFadeState.showFirst);
    });

    testWidgets("icon override replaces auto_awesome",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'X',
          icon: Icons.insights,
          child: Text('Y'),
        ),
      ));
      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets(
        'expanded chevron AnimatedRotation has turns 0',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'X',
          child: Text('Y'),
        ),
      ));
      final rot = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation));
      expect(rot.turns, 0.0);
    });

    testWidgets(
        'collapsed chevron AnimatedRotation has turns -0.25',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAiCollapsibleSection(
          title: 'X',
          defaultExpanded: false,
          child: Text('Y'),
        ),
      ));
      final rot = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation));
      expect(rot.turns, -0.25);
    });

    testWidgets(
        'iPhone-narrow: no overflow at SizedBox(width: 390) with long title',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 390,
          child: EdenAiCollapsibleSection(
            title:
                'A very long section title that should ellipsize gracefully on narrow viewports — 60 chars',
            child: Text('Body'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'sidebar-width (280pt) no overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 280,
          child: EdenAiCollapsibleSection(
            title: 'Operations Insights',
            child: Text('Body content here'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

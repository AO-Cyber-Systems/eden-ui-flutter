import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_adaptive_layout_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Future<void> pumpAtSize(WidgetTester tester, Size size, Widget child) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(child));
    await tester.pump();
  }

  group('EdenAdaptiveLayout — tier selection (Material 3 lock E)', () {
    testWidgets('390pt → compactBuilder', (tester) async {
      await pumpAtSize(tester, const Size(390, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
      expect(find.byKey(const ValueKey('medium')), findsNothing);
      expect(find.byKey(const ValueKey('expanded')), findsNothing);
    });

    testWidgets('599pt → compactBuilder (just below 600 boundary)', (tester) async {
      await pumpAtSize(tester, const Size(599, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
    });

    testWidgets('600pt → mediumBuilder (boundary inclusive)', (tester) async {
      await pumpAtSize(tester, const Size(600, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('medium')), findsOneWidget);
    });

    testWidgets('700pt → mediumBuilder (mid Medium tier)', (tester) async {
      await pumpAtSize(tester, const Size(700, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('medium')), findsOneWidget);
    });

    testWidgets('839pt → mediumBuilder (just below 840 boundary)', (tester) async {
      await pumpAtSize(tester, const Size(839, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('medium')), findsOneWidget);
    });

    testWidgets('840pt → expandedBuilder (boundary inclusive)', (tester) async {
      await pumpAtSize(tester, const Size(840, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('expanded')), findsOneWidget);
    });

    testWidgets('1200pt → expandedBuilder', (tester) async {
      await pumpAtSize(tester, const Size(1200, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('expanded')), findsOneWidget);
    });

    testWidgets('1600pt → expandedBuilder (external monitor)', (tester) async {
      await pumpAtSize(tester, const Size(1600, 1000), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('expanded')), findsOneWidget);
    });
  });

  group('EdenAdaptiveLayout — forceCompact invariant (lock E rule 3)', () {
    testWidgets('forceCompact: true at 1200pt → compactBuilder (NOT expanded)', (tester) async {
      await pumpAtSize(tester, const Size(1200, 800), EdenAdaptiveLayout(
        forceCompact: true,
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded')), findsNothing);
    });

    testWidgets('forceCompact: true at 700pt → compactBuilder (NOT medium)', (tester) async {
      await pumpAtSize(tester, const Size(700, 800), EdenAdaptiveLayout(
        forceCompact: true,
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
      expect(find.byKey(const ValueKey('medium')), findsNothing);
    });
  });

  group('EdenAdaptiveLayout — fallback chain (null builders)', () {
    testWidgets('700pt with no medium/expanded → renders compactBuilder', (tester) async {
      await pumpAtSize(tester, const Size(700, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
    });

    testWidgets('1200pt with no medium/expanded → renders compactBuilder', (tester) async {
      await pumpAtSize(tester, const Size(1200, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
    });

    testWidgets('1200pt with medium present + expanded null → renders mediumBuilder', (tester) async {
      await pumpAtSize(tester, const Size(1200, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        mediumBuilder: EdenAdaptiveLayoutFixtures.mediumTagged,
      ));
      expect(find.byKey(const ValueKey('medium')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded')), findsNothing);
    });

    testWidgets('700pt with medium null + expanded present → falls back to compactBuilder (not expanded)', (tester) async {
      await pumpAtSize(tester, const Size(700, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        expandedBuilder: EdenAdaptiveLayoutFixtures.expandedTagged,
      ));
      expect(find.byKey(const ValueKey('compact')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded')), findsNothing);
    });
  });

  group('EdenAdaptiveLayout — unbounded width fallback', () {
    testWidgets('unbounded parent: falls back to MediaQuery (1200pt) and picks expandedBuilder', (tester) async {
      // OverflowBox gives EdenAdaptiveLayout's LayoutBuilder
      // constraints.maxWidth == infinity. The widget then falls back
      // to MediaQuery.of(context).size.width — we set MQ explicitly
      // to 1200pt via a top-level MediaQuery widget. The widget must
      // pick the expanded tier from the MQ fallback.
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                minHeight: 0,
                maxHeight: 200,
                child: EdenAdaptiveLayout(
                  compactBuilder: (_) => const SizedBox(
                    width: 50,
                    height: 50,
                    child: ColoredBox(
                      color: Color(0xFF000000),
                      child: Text('compact'),
                    ),
                  ),
                  expandedBuilder: (_) => const SizedBox(
                    width: 50,
                    height: 50,
                    child: ColoredBox(
                      color: Color(0xFFFFFFFF),
                      child: Text('expanded'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      expect(find.text('expanded'), findsOneWidget);
      expect(find.text('compact'), findsNothing);
    });
  });

  group('EdenAdaptiveTierScope — subtree introspection', () {
    testWidgets('at 390pt non-forced, picked tier is compact', (tester) async {
      EdenAdaptiveTier? observed;
      await pumpAtSize(tester, const Size(390, 800), EdenAdaptiveLayout(
        compactBuilder: (ctx) {
          observed = EdenAdaptiveTierScope.of(ctx);
          return const SizedBox.shrink();
        },
      ));
      expect(observed, EdenAdaptiveTier.compact);
    });

    testWidgets('at 1200pt forceCompact: true, picked tier is compact', (tester) async {
      EdenAdaptiveTier? observed;
      await pumpAtSize(tester, const Size(1200, 800), EdenAdaptiveLayout(
        forceCompact: true,
        compactBuilder: (ctx) {
          observed = EdenAdaptiveTierScope.of(ctx);
          return const SizedBox.shrink();
        },
      ));
      expect(observed, EdenAdaptiveTier.compact);
    });

    testWidgets('at 1200pt non-forced, picked tier is expanded', (tester) async {
      EdenAdaptiveTier? observed;
      await pumpAtSize(tester, const Size(1200, 800), EdenAdaptiveLayout(
        compactBuilder: EdenAdaptiveLayoutFixtures.compactTagged,
        expandedBuilder: (ctx) {
          observed = EdenAdaptiveTierScope.of(ctx);
          return const SizedBox.shrink();
        },
      ));
      expect(observed, EdenAdaptiveTier.expanded);
    });

    testWidgets('maybeOf returns null outside the scope', (tester) async {
      EdenAdaptiveTier? observed = EdenAdaptiveTier.compact;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        observed = EdenAdaptiveTierScope.maybeOf(ctx);
        return const SizedBox.shrink();
      })));
      expect(observed, isNull);
    });
  });

  group('EdenAdaptiveLayout — iPhone-narrow safety', () {
    testWidgets('390pt: minimal compactBuilder renders without overflow', (tester) async {
      await pumpAtSize(tester, const Size(390, 800), EdenAdaptiveLayout(
        compactBuilder: (_) => const Text('hello'),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('hello'), findsOneWidget);
    });
  });
}

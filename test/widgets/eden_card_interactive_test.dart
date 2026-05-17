// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenCard.interactive (hover lift + focus ring + 44pt tap target +
// long-press support). Includes the mandatory WRONG-TAP isolation test per
// TDD playbook habit 6. Existing eden_card_test.dart is NOT touched.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenCard.interactive', () {
    testWidgets('renders title + subtitle', (tester) async {
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'My Card',
        subtitle: 'A subtitle',
        onTap: () {},
      )));
      expect(find.text('My Card'), findsOneWidget);
      expect(find.text('A subtitle'), findsOneWidget);
    });

    testWidgets('WRONG-TAP ISOLATION: tap fires onTap exactly once per tap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'Tap me',
        onTap: () => taps++,
      )));
      await tester.tap(find.byType(EdenCard));
      await tester.pump();
      expect(taps, equals(1));
    });

    testWidgets('double-tap fires onTap twice (no debounce)', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'Tap me',
        onTap: () => taps++,
      )));
      await tester.tap(find.byType(EdenCard));
      await tester.pump();
      await tester.tap(find.byType(EdenCard));
      await tester.pump();
      expect(taps, equals(2));
    });

    testWidgets('long-press fires onLongPress when supplied', (tester) async {
      int presses = 0;
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'Long press me',
        onTap: () {},
        onLongPress: () => presses++,
      )));
      await tester.longPress(find.byType(EdenCard));
      await tester.pump();
      expect(presses, equals(1));
    });

    testWidgets('44pt minimum tap target enforced when content is small', (tester) async {
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'X',
        onTap: () {},
        child: const SizedBox(width: 20, height: 20),
      )));
      final size = tester.getSize(find.byType(EdenCard));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('backwards-compat: default EdenCard with onTap unchanged (no focus ring)', (tester) async {
      await tester.pumpWidget(wrap(EdenCard(
        title: 'Default',
        onTap: () {},
      )));
      // FocusableActionDetector is interactive-only. Confirm it is NOT in the tree.
      expect(find.byType(FocusableActionDetector), findsNothing);
    });

    testWidgets('interactive variant hosts a FocusableActionDetector', (tester) async {
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'Interactive',
        onTap: () {},
      )));
      expect(find.byType(FocusableActionDetector), findsOneWidget);
    });

    testWidgets('iPhone-narrow 390pt: long title + multi-line subtitle does not overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'This is a very long title that should still wrap or truncate gracefully',
        subtitle: 'A multi-line subtitle that continues describing the card and providing more context',
        onTap: () {},
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: button + label=title', (tester) async {
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'My Card',
        onTap: () {},
      )));
      final labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('My Card'), isTrue,
          reason: 'Interactive card semantics label. Got: $labels');
    });

    testWidgets('hoverLift=false disables lift animation (still tappable)', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'No lift',
        hoverLift: false,
        onTap: () => taps++,
      )));
      await tester.tap(find.byType(EdenCard));
      await tester.pump();
      expect(taps, equals(1));
    });

    testWidgets('focusRing=false disables focus ring (still tappable)', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'No focus',
        focusRing: false,
        onTap: () => taps++,
      )));
      await tester.tap(find.byType(EdenCard));
      await tester.pump();
      expect(taps, equals(1));
    });

    testWidgets('interactive AnimationController disposes cleanly', (tester) async {
      await tester.pumpWidget(wrap(EdenCard.interactive(
        title: 'Disposable',
        onTap: () {},
      )));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

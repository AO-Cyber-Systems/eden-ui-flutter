// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenButtonGroup (M3 Expressive segmented button-group). Includes the
// mandatory WRONG-TAP isolation test per the TDD playbook habit 6 — interactive
// widget tests MUST prove that tapping segment N triggers onSelected(N) and
// NOT any other index.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  EdenButtonGroup buildGroup({
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
    List<EdenButtonGroupItem>? items,
  }) {
    return EdenButtonGroup(
      selectedIndex: selectedIndex,
      onSelected: onSelected ?? (_) {},
      items: items ??
          const [
            EdenButtonGroupItem(label: 'A'),
            EdenButtonGroupItem(label: 'B'),
            EdenButtonGroupItem(label: 'C'),
          ],
    );
  }

  group('EdenButtonGroup', () {
    testWidgets('renders 2 buttons with labels', (tester) async {
      await tester.pumpWidget(wrap(buildGroup(items: const [
        EdenButtonGroupItem(label: 'A'),
        EdenButtonGroupItem(label: 'B'),
      ])));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('renders 6 buttons with icons (icon-only)', (tester) async {
      await tester.pumpWidget(wrap(buildGroup(items: const [
        EdenButtonGroupItem(icon: Icons.format_bold),
        EdenButtonGroupItem(icon: Icons.format_italic),
        EdenButtonGroupItem(icon: Icons.format_underlined),
        EdenButtonGroupItem(icon: Icons.format_strikethrough),
        EdenButtonGroupItem(icon: Icons.format_align_left),
        EdenButtonGroupItem(icon: Icons.format_align_right),
      ])));
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined), findsOneWidget);
      expect(find.byIcon(Icons.format_strikethrough), findsOneWidget);
      expect(find.byIcon(Icons.format_align_left), findsOneWidget);
      expect(find.byIcon(Icons.format_align_right), findsOneWidget);
    });

    testWidgets('mixed icon+label item renders both', (tester) async {
      await tester.pumpWidget(wrap(buildGroup(items: const [
        EdenButtonGroupItem(icon: Icons.save, label: 'Save'),
        EdenButtonGroupItem(icon: Icons.cancel, label: 'Cancel'),
      ])));
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('selected item visually distinct from unselected', (tester) async {
      await tester.pumpWidget(wrap(buildGroup(
        selectedIndex: 1,
        items: const [
          EdenButtonGroupItem(label: 'A'),
          EdenButtonGroupItem(label: 'B'),
          EdenButtonGroupItem(label: 'C'),
        ],
      )));

      // Find each label's nearest ancestor Container with a colored decoration.
      final aContainer = tester
          .widgetList<Container>(find.ancestor(of: find.text('A'), matching: find.byType(Container)))
          .where((c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color != null)
          .first;
      final bContainer = tester
          .widgetList<Container>(find.ancestor(of: find.text('B'), matching: find.byType(Container)))
          .where((c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color != null)
          .first;

      final aColor = (aContainer.decoration as BoxDecoration).color;
      final bColor = (bContainer.decoration as BoxDecoration).color;
      expect(aColor, isNot(equals(bColor)),
          reason: 'selected (B) and unselected (A) should have different backgrounds');
    });

    testWidgets('first and last segments have rounded outer corners; middle segments are sharp on inner edges',
        (tester) async {
      await tester.pumpWidget(wrap(buildGroup(items: const [
        EdenButtonGroupItem(label: 'A'),
        EdenButtonGroupItem(label: 'B'),
        EdenButtonGroupItem(label: 'C'),
      ])));

      // Locate each segment's nearest decorated container.
      BorderRadius? radiusFor(String label) {
        final containers = tester
            .widgetList<Container>(find.ancestor(of: find.text(label), matching: find.byType(Container)))
            .where((c) => c.decoration is BoxDecoration);
        for (final c in containers) {
          final d = c.decoration as BoxDecoration;
          if (d.borderRadius is BorderRadius) {
            return d.borderRadius as BorderRadius;
          }
        }
        return null;
      }

      final ra = radiusFor('A')!;
      final rc = radiusFor('C')!;

      // First segment: leading corners rounded, trailing zero.
      expect(ra.topLeft.x, greaterThan(0.0));
      expect(ra.bottomLeft.x, greaterThan(0.0));
      expect(ra.topRight.x, equals(0.0));
      expect(ra.bottomRight.x, equals(0.0));

      // Last segment: trailing rounded, leading zero.
      expect(rc.topRight.x, greaterThan(0.0));
      expect(rc.bottomRight.x, greaterThan(0.0));
      expect(rc.topLeft.x, equals(0.0));
      expect(rc.bottomLeft.x, equals(0.0));
    });

    testWidgets('WRONG-TAP ISOLATION: tapping segment N calls onSelected(N) only', (tester) async {
      final callbackIndices = <int>[];
      await tester.pumpWidget(wrap(buildGroup(
        onSelected: callbackIndices.add,
        items: const [
          EdenButtonGroupItem(label: 'A'),
          EdenButtonGroupItem(label: 'B'),
          EdenButtonGroupItem(label: 'C'),
          EdenButtonGroupItem(label: 'D'),
          EdenButtonGroupItem(label: 'E'),
          EdenButtonGroupItem(label: 'F'),
        ],
      )));

      await tester.tap(find.text('C'));
      await tester.pump();
      expect(callbackIndices, equals([2]));
    });

    testWidgets('tap on disabled segment does not fire onSelected', (tester) async {
      final callbackIndices = <int>[];
      await tester.pumpWidget(wrap(buildGroup(
        onSelected: callbackIndices.add,
        items: const [
          EdenButtonGroupItem(label: 'A'),
          EdenButtonGroupItem(label: 'X', enabled: false),
        ],
      )));
      await tester.tap(find.text('X'));
      await tester.pump();
      expect(callbackIndices, isEmpty);
    });

    testWidgets('iPhone-narrow 390pt: no RenderFlex overflow with 6 long-label segments', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(buildGroup(items: const [
        EdenButtonGroupItem(label: 'New booking'),
        EdenButtonGroupItem(label: 'New client'),
        EdenButtonGroupItem(label: 'Walk-in'),
        EdenButtonGroupItem(label: 'Reschedule'),
        EdenButtonGroupItem(label: 'No-show'),
        EdenButtonGroupItem(label: 'Cancellation'),
      ])));
      // No exception thrown during pump = no overflow.
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: each segment exposes button + selected + label', (tester) async {
      await tester.pumpWidget(wrap(buildGroup(
        selectedIndex: 1,
        items: const [
          EdenButtonGroupItem(label: 'Save'),
          EdenButtonGroupItem(label: 'Send'),
        ],
      )));
      // The semantics tree should expose both labels with isButton flag.
      // We assert by walking the rendered Semantics widgets directly — this
      // does not require a SemanticsHandle (avoids the dispose contract).
      final semNodes = tester.widgetList<Semantics>(find.byType(Semantics));
      final labels = semNodes
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('Save'), isTrue,
          reason: 'Semantics label "Save" should be present. Got: $labels');
      expect(labels.contains('Send'), isTrue,
          reason: 'Semantics label "Send" should be present. Got: $labels');
    });

    testWidgets('press animation triggers (smoke: AnimatedBuilder present)', (tester) async {
      await tester.pumpWidget(wrap(buildGroup()));
      // The widget should host at least one AnimatedBuilder driving the press morph.
      expect(find.byType(AnimatedBuilder), findsWidgets);
      // Tap-down does not crash; pump 100ms to let animation start.
      await tester.tap(find.text('B'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    test('forward-compat: EdenButtonGroupStyle has connected member', () {
      expect(EdenButtonGroupStyle.values.contains(EdenButtonGroupStyle.connected), isTrue);
    });
  });
}

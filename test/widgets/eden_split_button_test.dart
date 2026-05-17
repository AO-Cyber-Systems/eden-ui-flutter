// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenSplitButton (M3 Expressive split-button). Includes the mandatory
// WRONG-ACTION isolation test per TDD playbook habit 6 — primary tap MUST
// fire onPrimary and NOT any menu item's onSelected; menu item tap MUST fire
// that item's onSelected and NOT onPrimary.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  EdenSplitButton build({
    String primaryLabel = 'Save',
    VoidCallback? onPrimary,
    List<EdenSplitMenuItem>? menuItems,
  }) {
    return EdenSplitButton(
      primaryLabel: primaryLabel,
      onPrimary: onPrimary ?? () {},
      menuItems: menuItems ??
          [
            EdenSplitMenuItem(label: 'Save & New', onSelected: () {}),
            EdenSplitMenuItem(label: 'Save & Close', onSelected: () {}),
          ],
    );
  }

  group('EdenSplitButton', () {
    testWidgets('renders primary label + dropdown arrow', (tester) async {
      await tester.pumpWidget(wrap(build()));
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('primary segment tap fires onPrimary', (tester) async {
      var fired = 0;
      await tester.pumpWidget(wrap(build(onPrimary: () => fired++)));
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(fired, equals(1));
    });

    testWidgets('dropdown arrow tap opens menu', (tester) async {
      await tester.pumpWidget(wrap(build()));
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      expect(find.text('Save & New'), findsOneWidget);
      expect(find.text('Save & Close'), findsOneWidget);
    });

    testWidgets('menu item tap fires that item onSelected', (tester) async {
      var fired = 0;
      await tester.pumpWidget(wrap(build(menuItems: [
        EdenSplitMenuItem(label: 'Save & New', onSelected: () => fired++),
        EdenSplitMenuItem(label: 'Save & Close', onSelected: () {}),
      ])));
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & New'));
      await tester.pumpAndSettle();
      expect(fired, equals(1));
    });

    testWidgets('WRONG-ACTION ISOLATION: primary tap fires only onPrimary; menu item tap fires only that item',
        (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(EdenSplitButton(
        primaryLabel: 'Save',
        onPrimary: () => fired.add('primary'),
        menuItems: [
          EdenSplitMenuItem(label: 'Save & New', onSelected: () => fired.add('saveAndNew')),
          EdenSplitMenuItem(label: 'Save & Close', onSelected: () => fired.add('saveAndClose')),
        ],
      )));

      // Primary tap
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(fired, equals(['primary']));
      fired.clear();

      // Menu open + tap 'Save & New'
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & New'));
      await tester.pumpAndSettle();
      expect(fired, equals(['saveAndNew']));
    });

    testWidgets('disabled when onPrimary is null AND all menuItems disabled: taps fire nothing',
        (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(EdenSplitButton(
        primaryLabel: 'Disabled',
        onPrimary: null,
        menuItems: [
          EdenSplitMenuItem(label: 'NoOp', onSelected: () => fired.add('x'), enabled: false),
        ],
      )));
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(fired, isEmpty);
    });

    testWidgets('mixed: onPrimary null but menu items available — arrow still opens menu', (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(EdenSplitButton(
        primaryLabel: 'Send',
        onPrimary: null,
        menuItems: [
          EdenSplitMenuItem(label: 'Schedule', onSelected: () => fired.add('schedule')),
        ],
      )));
      // Primary disabled — tap fires nothing
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(fired, isEmpty);
      // Dropdown still works
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(fired, equals(['schedule']));
    });

    testWidgets('iPhone-narrow 390pt: long primary label ellipsizes — no overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(build(primaryLabel: 'Save and continue to next entry')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled menu item does not fire onSelected', (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(EdenSplitButton(
        primaryLabel: 'Save',
        onPrimary: () {},
        menuItems: [
          EdenSplitMenuItem(label: 'Frozen', onSelected: () => fired.add('frozen'), enabled: false),
          EdenSplitMenuItem(label: 'Active', onSelected: () => fired.add('active')),
        ],
      )));
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frozen'));
      await tester.pumpAndSettle();
      expect(fired, isEmpty);
    });

    testWidgets('semantics: primary label + arrow More actions', (tester) async {
      await tester.pumpWidget(wrap(build(primaryLabel: 'Save')));
      final labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('Save'), isTrue, reason: 'primary label semantics. Got: $labels');
      expect(labels.contains('More actions'), isTrue, reason: 'arrow semantics. Got: $labels');
    });

    testWidgets('showMenu dismissed (tap-outside) fires nothing', (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(EdenSplitButton(
        primaryLabel: 'Save',
        onPrimary: () => fired.add('primary'),
        menuItems: [
          EdenSplitMenuItem(label: 'Item', onSelected: () => fired.add('item')),
        ],
      )));
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      // Tap a corner of the screen to dismiss
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(fired, isEmpty);
    });
  });
}

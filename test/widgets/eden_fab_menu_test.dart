// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenFabMenu (M3 Expressive FAB menu). Includes the mandatory
// WRONG-ACTION isolation test per TDD playbook habit 6 and the stagger
// behavior test (action N becomes visible after action N-1).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // EdenFabMenu wants to live inside a Scaffold so the scrim + overlay flow
  // works naturally with Overlay.of(context).
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Stack(children: [child])));
  }

  group('EdenFabMenu', () {
    testWidgets('closed state: shows primary FAB only', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'New Job', onPressed: () {}),
          EdenFabAction(icon: Icons.assignment_outlined, label: 'New Estimate', onPressed: () {}),
        ],
      )));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('New Job'), findsNothing);
      expect(find.text('New Estimate'), findsNothing);
    });

    testWidgets('tap primary FAB: menu opens, actions visible', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'New Job', onPressed: () {}),
          EdenFabAction(icon: Icons.assignment_outlined, label: 'New Estimate', onPressed: () {}),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New Job'), findsOneWidget);
      expect(find.text('New Estimate'), findsOneWidget);
    });

    testWidgets('open state: primary icon swapped to close icon', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'A', onPressed: () {}),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tap action fires its onPressed AND closes menu', (tester) async {
      var fired = 0;
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'New Job', onPressed: () => fired++),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Job'));
      await tester.pumpAndSettle();
      expect(fired, equals(1));
      // Menu closed: action label not findable.
      expect(find.text('New Job'), findsNothing);
    });

    testWidgets('WRONG-ACTION ISOLATION: tap action[2] fires only that action', (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.looks_one, label: 'A', onPressed: () => fired.add('a')),
          EdenFabAction(icon: Icons.looks_two, label: 'B', onPressed: () => fired.add('b')),
          EdenFabAction(icon: Icons.looks_3, label: 'C', onPressed: () => fired.add('c')),
          EdenFabAction(icon: Icons.looks_4, label: 'D', onPressed: () => fired.add('d')),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(fired, equals(['c']));
    });

    testWidgets('tap outside (on scrim) closes menu', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'A', onPressed: () {}),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      // Tap a corner of the screen (on the scrim, not on FAB)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsNothing);
    });

    testWidgets('tap primary while open closes the menu', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'A', onPressed: () {}),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('action with custom backgroundColor renders with that color', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(
            icon: Icons.check,
            label: 'Green action',
            onPressed: () {},
            backgroundColor: Colors.green,
          ),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      // Walk Material widgets — at least one should have green color.
      final materials = tester.widgetList<Material>(find.byType(Material))
          .where((m) => m.color == Colors.green)
          .toList();
      expect(materials, isNotEmpty);
    });

    testWidgets('iPhone-narrow 390pt: 6 actions with long labels do not overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'Create new salon appointment', onPressed: () {}),
          EdenFabAction(icon: Icons.add, label: 'Create new client record now', onPressed: () {}),
          EdenFabAction(icon: Icons.access_time, label: 'Clock in for next shift', onPressed: () {}),
          EdenFabAction(icon: Icons.event, label: 'Schedule a follow up visit', onPressed: () {}),
          EdenFabAction(icon: Icons.note_add, label: 'New encounter note draft', onPressed: () {}),
          EdenFabAction(icon: Icons.flag, label: 'Flag this for supervisor review', onPressed: () {}),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('action has Tooltip widget present', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'New Job', onPressed: () {}, tooltip: 'Create job'),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(Tooltip), findsWidgets);
    });

    testWidgets('semantics: primary FAB + each action exposes label', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        primaryTooltip: 'Open menu',
        actions: [
          EdenFabAction(icon: Icons.work_outline, label: 'New Job', onPressed: () {}),
        ],
      )));
      // Closed — primary label findable
      var labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('Open menu'), isTrue, reason: 'Primary semantics label. Got: $labels');
      // Open — action label findable
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('New Job'), isTrue, reason: 'Action semantics label. Got: $labels');
    });

    testWidgets('stagger: action[0] visible earlier than action[N-1] mid-flight', (tester) async {
      await tester.pumpWidget(wrap(EdenFabMenu(
        primaryIcon: Icons.add,
        actions: [
          EdenFabAction(icon: Icons.looks_one, label: 'A', onPressed: () {}),
          EdenFabAction(icon: Icons.looks_two, label: 'B', onPressed: () {}),
          EdenFabAction(icon: Icons.looks_3, label: 'C', onPressed: () {}),
        ],
      )));
      await tester.tap(find.byIcon(Icons.add));
      // Pump only a short time — let some actions appear but not all stagger has finished.
      await tester.pump(const Duration(milliseconds: 80));

      // Action[0] should be at higher opacity than action[N-1] mid-flight.
      // Use Opacity finders bound by ancestor text findability.
      final opacityA = tester
          .widgetList<Opacity>(find.ancestor(of: find.text('A'), matching: find.byType(Opacity)))
          .first
          .opacity;
      final opacityC = tester
          .widgetList<Opacity>(find.ancestor(of: find.text('C'), matching: find.byType(Opacity)))
          .first
          .opacity;
      expect(opacityA >= opacityC, isTrue,
          reason: 'first action should be at >= opacity than later actions mid-stagger (A=$opacityA C=$opacityC)');
      await tester.pumpAndSettle();
    });
  });
}

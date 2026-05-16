import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_blocking_alerts_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenBlockingAlerts', () {
    testWidgets('empty alerts list renders only SizedBox.shrink',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenBlockingAlerts(alerts: <EdenBlockingAlertData>[]),
      ));
      // No header text.
      expect(find.textContaining('blocked item'), findsNothing);
      // No alert icon.
      expect(find.byIcon(Icons.warning_rounded), findsNothing);
    });

    testWidgets('1 alert → header reads "1 blocked item" (singular)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [EdenBlockingAlertsFixtures.redAlert()]),
      ));
      expect(find.text('1 blocked item'), findsOneWidget);
    });

    testWidgets('2 alerts → header reads "2 blocked items" (plural)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(1, 1)),
      ));
      expect(find.text('2 blocked items'), findsOneWidget);
    });

    testWidgets('5 alerts → header reads "5 blocked items"',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(3, 2)),
      ));
      expect(find.text('5 blocked items'), findsOneWidget);
    });

    testWidgets('all-amber list tints header text amber',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(0, 2)),
      ));
      final header = tester.widget<Text>(find.text('2 blocked items'));
      expect(header.style?.color, Colors.amber);
    });

    testWidgets('mixed list (1 red + 1 amber) tints header red (priority)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(1, 1)),
      ));
      final header = tester.widget<Text>(find.text('2 blocked items'));
      expect(header.style?.color, Colors.red);
    });

    testWidgets('all-red list tints header red',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(3, 0)),
      ));
      final header = tester.widget<Text>(find.text('3 blocked items'));
      expect(header.style?.color, Colors.red);
    });

    testWidgets('3-alert expanded view shows all 3 task labels',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(3, 0)),
      ));
      expect(find.textContaining('Install HVAC'), findsOneWidget);
      expect(find.textContaining('Install electrical panel'), findsNWidgets(2));
    });

    testWidgets('tapping header collapses then re-expands the alerts list',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(
            alerts: EdenBlockingAlertsFixtures.mixedList(2, 0)),
      ));
      // Initially expanded.
      expect(find.textContaining('Install HVAC'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Collapse.
      await tester.tap(find.text('2 blocked items'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Install HVAC'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Expand again.
      await tester.tap(find.text('2 blocked items'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Install HVAC'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets(
        'single-alert view does NOT render expand/collapse chevron',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [EdenBlockingAlertsFixtures.redAlert()]),
      ));
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets(
        'tapping header in single-alert view does NOT collapse',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [EdenBlockingAlertsFixtures.redAlert()]),
      ));
      await tester.tap(find.text('1 blocked item'));
      await tester.pumpAndSettle();
      // Alert body still visible (task — context line).
      expect(find.textContaining('Install HVAC'), findsOneWidget);
    });

    testWidgets('alert with 2 actions renders 2 OutlinedButtons',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [
          EdenBlockingAlertsFixtures.redAlert(actions: [
            EdenBlockingAction(label: 'View Permit', onPressed: () {}),
            EdenBlockingAction(label: 'Notify Inspector', onPressed: () {}),
          ]),
        ]),
      ));
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.text('View Permit'), findsOneWidget);
      expect(find.text('Notify Inspector'), findsOneWidget);
    });

    testWidgets('tapping an action OutlinedButton fires its onPressed callback',
        (tester) async {
      var notified = false;
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [
          EdenBlockingAlertsFixtures.redAlert(actions: [
            EdenBlockingAction(
                label: 'Notify Inspector',
                onPressed: () => notified = true),
          ]),
        ]),
      ));
      await tester.tap(find.text('Notify Inspector'));
      expect(notified, isTrue);
    });

    testWidgets('alert with empty actions list renders 0 OutlinedButtons',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [EdenBlockingAlertsFixtures.redAlert()]),
      ));
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('each alert displays "task — context" composite line',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenBlockingAlerts(alerts: [
          EdenBlockingAlertsFixtures.redAlert(
              task: 'Install HVAC', context: 'Phase 2'),
        ]),
      ));
      expect(find.text('Install HVAC — Phase 2'), findsOneWidget);
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 390) for 3 alerts each with 2 actions',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 390,
          child: EdenBlockingAlerts(alerts: [
            EdenBlockingAlertsFixtures.redAlert(actions: [
              EdenBlockingAction(label: 'View', onPressed: () {}),
              EdenBlockingAction(label: 'Notify', onPressed: () {}),
            ]),
            EdenBlockingAlertsFixtures.amberAlert(actions: [
              EdenBlockingAction(label: 'View', onPressed: () {}),
              EdenBlockingAction(label: 'Notify', onPressed: () {}),
            ]),
            EdenBlockingAlertsFixtures.redAlert(
              task: 'Install electrical panel',
              context: 'Phase 3',
              reason: 'Material backordered 14 days',
              actions: [
                EdenBlockingAction(label: 'View', onPressed: () {}),
                EdenBlockingAction(label: 'Notify', onPressed: () {}),
              ],
            ),
          ]),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

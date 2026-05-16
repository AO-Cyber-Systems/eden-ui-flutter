// Hand-built tests (no LLM-generated test data) for EdenSchedulerWeekView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_week_view_fixtures.dart';

void main() {
  group('EdenSchedulerWeekView — mode switching', () {
    testWidgets('workWeek mode renders 5 day headers Mon..Fri',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.workWeek,
          events: const [],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      // No weekend in workWeek.
      expect(find.text('Sat'), findsNothing);
      expect(find.text('Sun'), findsNothing);
    });

    testWidgets('week mode renders 7 day headers Sun..Sat', (tester) async {
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.week,
          events: const [],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
    });
  });

  group('EdenSchedulerWeekView — today highlight', () {
    testWidgets('today column has primary-tinted background', (tester) async {
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.workWeek,
          events: const [],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.wed),
        ),
      ));
      // Today's number (13) appears bold + in a primary circle.
      final boldNumbers = tester.widgetList<Text>(find.byType(Text)).where((t) {
        return t.data == '13' &&
            t.style?.fontWeight == FontWeight.w700;
      });
      expect(boldNumbers, isNotEmpty);
    });
  });

  group('EdenSchedulerWeekView — events', () {
    testWidgets('events render on correct day columns', (tester) async {
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.workWeek,
          events: [
            EdenSchedulerWeekViewFixtures.monMorning,
            EdenSchedulerWeekViewFixtures.wedAfternoon,
          ],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      expect(find.text('Mon meeting'), findsOneWidget);
      expect(find.text('Wed call'), findsOneWidget);
    });

    testWidgets('Sunday event renders only in week mode (not workWeek)',
        (tester) async {
      // workWeek mode: Sun is not visible.
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.workWeek,
          events: [EdenSchedulerWeekViewFixtures.sunMorning],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      expect(find.text('Sun service'), findsNothing);
    });

    testWidgets('Sunday event renders in week mode', (tester) async {
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.week,
          events: [EdenSchedulerWeekViewFixtures.sunMorning],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      expect(find.text('Sun service'), findsOneWidget);
    });
  });

  group('EdenSchedulerWeekView — day header tap', () {
    testWidgets('tapping a day header fires onDateSelected', (tester) async {
      DateTime? captured;
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.workWeek,
          events: const [],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
          onDateSelected: (d) => captured = d,
        ),
      ));
      // Tap the "Wed" header.
      await tester.tap(find.text('Wed'));
      expect(captured?.day, 13);
    });
  });

  group('EdenSchedulerWeekView — controller integration', () {
    testWidgets('reads focusedDate from controller', (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.week,
        initialDate: EdenSchedulerWeekViewFixtures.mon,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          controller: c,
          mode: EdenSchedulerWeekMode.workWeek,
          events: [EdenSchedulerWeekViewFixtures.monMorning],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      expect(find.text('Mon meeting'), findsOneWidget);
    });

    testWidgets('rebuilds when controller.setFocusedDate fires',
        (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.week,
        initialDate: EdenSchedulerWeekViewFixtures.mon,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          controller: c,
          mode: EdenSchedulerWeekMode.workWeek,
          events: [EdenSchedulerWeekViewFixtures.monMorning],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
      ));
      // Move to next week.
      c.setFocusedDate(DateTime(2026, 5, 18));
      await tester.pump();
      expect(find.text('Mon meeting'), findsNothing);
    });
  });

  group('EdenSchedulerWeekView — responsive', () {
    testWidgets('390pt narrow week mode renders without overflow',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerWeekViewFixtures.wrap(
        EdenSchedulerWeekView(
          focusedDate: EdenSchedulerWeekViewFixtures.mon,
          mode: EdenSchedulerWeekMode.week,
          events: const [],
          clock: EdenSchedulerWeekViewFixtures.clockOn(
              EdenSchedulerWeekViewFixtures.mon),
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

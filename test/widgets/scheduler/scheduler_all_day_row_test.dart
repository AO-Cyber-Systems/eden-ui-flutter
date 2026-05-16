// Hand-built tests (no LLM-generated test data) for EdenSchedulerAllDayRow.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 800, height: 100, child: child)));

void main() {
  final monWeek = List.generate(
    5,
    (i) => DateTime(2026, 5, 11 + i),
  );

  group('EdenSchedulerAllDayRow', () {
    testWidgets('empty events shows "Notes" label', (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerAllDayRow(
        days: monWeek,
        events: const [],
      )));
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('single all-day event renders title', (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerAllDayRow(
        days: monWeek,
        events: [
          EdenSchedulerEvent(
            id: 'a',
            title: 'Conference',
            start: DateTime(2026, 5, 13),
            end: DateTime(2026, 5, 13),
            allDay: true,
          ),
        ],
      )));
      expect(find.text('Conference'), findsOneWidget);
    });

    testWidgets('non-all-day events are filtered out', (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerAllDayRow(
        days: monWeek,
        events: [
          EdenSchedulerEvent(
            id: 'a',
            title: 'Time-of-day event',
            start: DateTime(2026, 5, 13, 9),
            end: DateTime(2026, 5, 13, 10),
            allDay: false,
          ),
        ],
      )));
      expect(find.text('Time-of-day event'), findsNothing);
      // Notes label still visible since no all-day events.
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('multi-day event spans multiple cells (single bar)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerAllDayRow(
        days: monWeek,
        events: [
          EdenSchedulerEvent(
            id: 'a',
            title: 'Multi-day',
            start: DateTime(2026, 5, 12),
            end: DateTime(2026, 5, 14),
            allDay: true,
          ),
        ],
      )));
      expect(find.text('Multi-day'), findsOneWidget);
    });

    testWidgets('tap fires onEventTap', (tester) async {
      EdenSchedulerEvent? captured;
      await tester.pumpWidget(wrap(EdenSchedulerAllDayRow(
        days: monWeek,
        events: [
          EdenSchedulerEvent(
            id: 'a',
            title: 'Conference',
            start: DateTime(2026, 5, 13),
            end: DateTime(2026, 5, 13),
            allDay: true,
          ),
        ],
        onEventTap: (e) => captured = e,
      )));
      await tester.tap(find.text('Conference'));
      expect(captured?.id, 'a');
    });
  });
}

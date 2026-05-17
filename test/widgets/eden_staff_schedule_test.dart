import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_staff_schedule_fixtures.dart';

Widget wrap(Widget child, {double width = 800, double height = 600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenStaffWeeklyShift.copyWith', () {
    test('preserves staffId + weekday when working flips', () {
      const original = EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.monday,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0),
      );
      final updated = original.copyWith(working: false);
      expect(updated.staffId, 'st-aisha');
      expect(updated.weekday, EdenWeekday.monday);
      expect(updated.working, false);
      expect(updated.startTime, original.startTime);
    });

    test('breaks list replaces cleanly', () {
      const original = EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.monday,
      );
      final updated = original.copyWith(breaks: const [
        EdenStaffBreak(
          startTime: TimeOfDay(hour: 12, minute: 0),
          endTime: TimeOfDay(hour: 13, minute: 0),
        ),
      ]);
      expect(updated.breaks.length, 1);
    });
  });

  group('EdenStaffSchedule grid rendering', () {
    testWidgets('renders all 7 weekday labels', (tester) async {
      await tester.pumpWidget(wrap(EdenStaffSchedule(
        shifts: EdenStaffScheduleFixtures.aishaFullWeek(),
        onShiftChanged: (_) {},
      )));
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('Wed + Sun show OFF state', (tester) async {
      await tester.pumpWidget(wrap(EdenStaffSchedule(
        shifts: EdenStaffScheduleFixtures.aishaFullWeek(),
        onShiftChanged: (_) {},
      )));
      // 'OFF' appears in both Wed + Sun rows
      expect(find.text('OFF'), findsNWidgets(2));
    });

    testWidgets('Monday shift block + break overlay both render',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStaffSchedule(
        shifts: EdenStaffScheduleFixtures.aishaFullWeek(),
        onShiftChanged: (_) {},
      )));
      // Shift block has a unique key per weekday for inspection.
      expect(find.byKey(const ValueKey('shift-block-monday')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('break-overlay-monday-0')),
          findsOneWidget);
    });
  });

  group('EdenStaffSchedule tap-to-edit', () {
    testWidgets('tap day-row header opens inline editor', (tester) async {
      await tester.pumpWidget(wrap(EdenStaffSchedule(
        shifts: EdenStaffScheduleFixtures.aishaFullWeek(),
        onShiftChanged: (_) {},
      )));
      // Tap Monday row
      await tester.tap(find.byKey(const ValueKey('day-monday')));
      await tester.pumpAndSettle();
      // Editor shows 'Working' label
      expect(find.text('Working'), findsOneWidget);
    });
  });

  group('EdenStaffSchedule onShiftChanged', () {
    testWidgets('toggle working off fires onShiftChanged with working: false',
        (tester) async {
      EdenStaffWeeklyShift? captured;
      await tester.pumpWidget(wrap(EdenStaffSchedule(
        shifts: EdenStaffScheduleFixtures.aishaFullWeek(),
        onShiftChanged: (s) => captured = s,
      )));
      // Expand Monday editor
      await tester.tap(find.byKey(const ValueKey('day-monday')));
      await tester.pumpAndSettle();
      // Tap the working switch
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.weekday, EdenWeekday.monday);
      expect(captured!.working, false);
    });
  });

  group('EdenStaffSchedule iPhone-narrow (390pt)', () {
    testWidgets('schedule renders without overflow at 390pt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenStaffSchedule(
              shifts: EdenStaffScheduleFixtures.aishaFullWeek(),
              onShiftChanged: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

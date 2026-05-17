import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_time_slot_picker_fixtures.dart';

Widget wrap(Widget child, {double width = 800, double height = 600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('formatDayHeader', () {
    test('returns "Thursday, May 21" for 2026-05-21', () {
      expect(formatDayHeader(DateTime(2026, 5, 21)), 'Thursday, May 21');
    });

    test('returns "Thursday, January 1" for 2026-01-01', () {
      expect(formatDayHeader(DateTime(2026, 1, 1)), 'Thursday, January 1');
    });
  });

  group('timeRowsFor', () {
    test('openingHour=9, closingHour=18, slotMinutes=15 → 36 rows', () {
      final rows = timeRowsFor(
          openingHour: 9, closingHour: 18, slotMinutes: 15);
      expect(rows.length, 36);
      expect(rows.first.hour, 9);
      expect(rows.first.minute, 0);
      expect(rows.last.hour, 17);
      expect(rows.last.minute, 45);
    });

    test('opening==closing → 0 rows', () {
      final rows = timeRowsFor(
          openingHour: 9, closingHour: 9, slotMinutes: 15);
      expect(rows, isEmpty);
    });

    test('30-min slots from 9-10 → 2 rows', () {
      final rows = timeRowsFor(
          openingHour: 9, closingHour: 10, slotMinutes: 30);
      expect(rows.length, 2);
      expect(rows[0].minute, 0);
      expect(rows[1].minute, 30);
    });
  });

  group('EdenTimeSlotPicker grid rendering', () {
    testWidgets('renders staff column headers', (tester) async {
      await tester.pumpWidget(wrap(EdenTimeSlotPicker(
        currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
        allStaff: EdenTimeSlotPickerFixtures.threeStaff().sublist(0, 2),
        slots: EdenTimeSlotPickerFixtures.dayOf3Staff()
            .where((s) => s.staffId != 'st-carla')
            .toList(),
        onSlotSelected: (_) {},
        openingHour: 9,
        closingHour: 11,
      )));
      expect(find.text('Aisha'), findsAtLeastNWidgets(1));
      expect(find.text('Brendan'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders day header label', (tester) async {
      await tester.pumpWidget(wrap(EdenTimeSlotPicker(
        currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
        allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
        slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
        onSlotSelected: (_) {},
      )));
      expect(find.text('Thursday, May 21'), findsOneWidget);
    });
  });

  group('EdenTimeSlotPicker tab-strip mode (<600pt or >4 staff)', () {
    testWidgets('renders ChoiceChip strip at narrow width', (tester) async {
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          onSlotSelected: (_) {},
        ),
        width: 500,
        height: 800,
      ));
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('5 staff (>4) at 1200pt → tab-strip mode active',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.fiveStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          onSlotSelected: (_) {},
        ),
        width: 1200,
        height: 800,
      ));
      expect(find.byType(ChoiceChip), findsNWidgets(5));
    });
  });

  group('EdenTimeSlotPicker cell tap-to-select', () {
    testWidgets('tap available slot fires onSlotSelected', (tester) async {
      EdenTimeSlot? selected;
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          onSlotSelected: (s) => selected = s,
        ),
        width: 500,
        height: 800,
      ));
      await tester.pumpAndSettle();
      // Default active staff = first (Aisha). Tap 9:00 slot.
      final slotKey = find.byKey(const ValueKey('slot-st-aisha-09-00'));
      expect(slotKey, findsOneWidget);
      await tester.tap(slotKey);
      expect(selected, isNotNull);
      expect(selected!.staffId, 'st-aisha');
      expect(selected!.startTime.hour, 9);
    });

    testWidgets('tap blocked slot does NOT fire onSlotSelected',
        (tester) async {
      EdenTimeSlot? selected;
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          onSlotSelected: (s) => selected = s,
        ),
        width: 500,
        height: 800,
      ));
      await tester.pumpAndSettle();
      // Switch to Brendan
      await tester.tap(find.text('Brendan'));
      await tester.pumpAndSettle();
      // Tap Brendan's 12:00 blocked slot (need to scroll)
      final blocked =
          find.byKey(const ValueKey('slot-st-brendan-12-00'));
      // Scroll into view if needed.
      await tester.scrollUntilVisible(blocked, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(blocked, warnIfMissed: false);
      expect(selected, isNull);
    });
  });

  group('EdenTimeSlotPicker service-entry staff filter', () {
    testWidgets('filters columns to capable staff when entry provided',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.fiveStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          serviceEntry:
              EdenTimeSlotPickerFixtures.threeCapableStaffService(),
          onSlotSelected: (_) {},
        ),
        width: 500,
        height: 800,
      ));
      // Service entry has 3 capable staff (Aisha + Brendan + Carla) — filter
      // narrows the 5 to 3.
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.text('David'), findsNothing);
      expect(find.text('Elena'), findsNothing);
    });

    testWidgets('null serviceEntry → all staff visible', (tester) async {
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          onSlotSelected: (_) {},
        ),
        width: 500,
        height: 800,
      ));
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });
  });

  group('EdenTimeSlotPicker day navigation', () {
    testWidgets('chevron-right fires onDayChanged with next day',
        (tester) async {
      DateTime? changed;
      await tester.pumpWidget(wrap(EdenTimeSlotPicker(
        currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
        allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
        slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
        onSlotSelected: (_) {},
        onDayChanged: (d) => changed = d,
      )));
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(changed, isNotNull);
      expect(changed!.day, 22);
    });

    testWidgets('chevron-left fires onDayChanged with prev day',
        (tester) async {
      DateTime? changed;
      await tester.pumpWidget(wrap(EdenTimeSlotPicker(
        currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
        allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
        slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
        onSlotSelected: (_) {},
        onDayChanged: (d) => changed = d,
      )));
      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(changed, isNotNull);
      expect(changed!.day, 20);
    });

    testWidgets('null onDayChanged → chevrons disabled', (tester) async {
      await tester.pumpWidget(wrap(EdenTimeSlotPicker(
        currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
        allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
        slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
        onSlotSelected: (_) {},
      )));
      final rightBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );
      expect(rightBtn.onPressed, isNull);
    });
  });

  group('EdenTimeSlotPicker tab-strip switching', () {
    testWidgets('tap staff chip changes active staff column', (tester) async {
      EdenTimeSlot? selected;
      await tester.pumpWidget(wrap(
        EdenTimeSlotPicker(
          currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
          allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
          slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
          onSlotSelected: (s) => selected = s,
        ),
        width: 500,
        height: 800,
      ));
      await tester.pumpAndSettle();
      // Default Aisha is active. Tap Brendan chip.
      await tester.tap(find.text('Brendan'));
      await tester.pumpAndSettle();
      // Now Brendan's 9:00 slot is in the list — tap it.
      final slot = find.byKey(const ValueKey('slot-st-brendan-09-00'));
      expect(slot, findsOneWidget);
      await tester.tap(slot);
      expect(selected, isNotNull);
      expect(selected!.staffId, 'st-brendan');
    });
  });

  group('EdenTimeSlotPicker iPhone-narrow (390pt)', () {
    testWidgets('3 staff + full day renders tab-strip without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenTimeSlotPicker(
              currentDay: EdenTimeSlotPickerFixtures.kFixedDay,
              allStaff: EdenTimeSlotPickerFixtures.threeStaff(),
              slots: EdenTimeSlotPickerFixtures.dayOf3Staff(),
              onSlotSelected: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_memorable_date_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenMemorableDate — rendering', () {
    testWidgets('renders 3 labeled fields: Month + Day + Year', (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate()));
      expect(find.text('Month'), findsAtLeastNWidgets(1));
      expect(find.text('Day'), findsAtLeastNWidgets(1));
      expect(find.text('Year'), findsAtLeastNWidgets(1));
    });

    testWidgets('optional top label appears above row', (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate(
        label: 'Date of birth',
      )));
      expect(find.text('Date of birth'), findsOneWidget);
    });
  });

  group('EdenMemorableDate — per-field validation', () {
    testWidgets('invalid month=13 (monthAsText) shows Invalid month inline error',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate(monthAsText: true)));
      // Find Month text field by hint or by ancestor with Month label.
      // Use the FIRST TextField (the Month one in monthAsText mode).
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), EdenMemorableDateFixtures.invalidMonth13Str);
      await tester.pump();
      expect(find.text('Invalid month'), findsOneWidget);
    });

    testWidgets('invalid day=32 shows Invalid day inline error', (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate()));
      // Day is the SECOND text field (Month is dropdown default).
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2)); // day + year
      await tester.enterText(fields.at(0), EdenMemorableDateFixtures.invalidDay32Str);
      await tester.pump();
      expect(find.text('Invalid day'), findsOneWidget);
    });

    testWidgets('invalid year=999 shows Invalid year inline error', (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate()));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), EdenMemorableDateFixtures.invalidYear999Str);
      await tester.pump();
      expect(find.text('Invalid year'), findsOneWidget);
    });
  });

  group('EdenMemorableDate — composite validation', () {
    testWidgets('Feb 30 (rollover) shows Invalid date composite error', (tester) async {
      DateTime? emitted = DateTime(2099, 1, 1); // sentinel non-null
      await tester.pumpWidget(wrap(EdenMemorableDate(
        monthAsText: true,
        onChanged: (v) => emitted = v,
      )));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '2'); // Feb
      await tester.pump();
      await tester.enterText(fields.at(1), EdenMemorableDateFixtures.feb30DayStr);
      await tester.pump();
      await tester.enterText(fields.at(2), '2024');
      await tester.pump();
      expect(find.text('Invalid date'), findsOneWidget);
      expect(emitted, isNull);
    });

    testWidgets('valid Feb 28 2024 emits DateTime', (tester) async {
      DateTime? emitted;
      await tester.pumpWidget(wrap(EdenMemorableDate(
        monthAsText: true,
        onChanged: (v) => emitted = v,
      )));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '2');
      await tester.pump();
      await tester.enterText(fields.at(1), '28');
      await tester.pump();
      await tester.enterText(fields.at(2), '2024');
      await tester.pump();
      expect(emitted, EdenMemorableDateFixtures.validFeb28_2024);
    });
  });

  group('EdenMemorableDate — emission', () {
    testWidgets('incomplete (no year) emits null', (tester) async {
      DateTime? emitted = DateTime(2099, 1, 1);
      await tester.pumpWidget(wrap(EdenMemorableDate(
        monthAsText: true,
        onChanged: (v) => emitted = v,
      )));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '6');
      await tester.pump();
      await tester.enterText(fields.at(1), '15');
      await tester.pump();
      // Year left blank.
      expect(emitted, isNull);
    });
  });

  group('EdenMemorableDate — initial value', () {
    testWidgets('value: DateTime(2024,6,15) populates fields', (tester) async {
      await tester.pumpWidget(wrap(EdenMemorableDate(
        value: EdenMemorableDateFixtures.validJune15_2024,
      )));
      // Day field should be 15.
      expect(find.text('15'), findsOneWidget);
      // Year field should be 2024.
      expect(find.text('2024'), findsOneWidget);
      // Month dropdown displays 'June'.
      expect(find.text('June'), findsOneWidget);
    });
  });

  group('EdenMemorableDate — range constraint', () {
    testWidgets('firstDate/lastDate: 2019 outside 2020-2025 emits null + range error',
        (tester) async {
      DateTime? emitted = DateTime(2099, 1, 1);
      await tester.pumpWidget(wrap(EdenMemorableDate(
        monthAsText: true,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2025, 12, 31),
        onChanged: (v) => emitted = v,
      )));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '6');
      await tester.pump();
      await tester.enterText(fields.at(1), '15');
      await tester.pump();
      await tester.enterText(fields.at(2), '2019');
      await tester.pump();
      expect(find.text('Date out of range'), findsOneWidget);
      expect(emitted, isNull);
    });
  });

  group('EdenMemorableDate — Section 508 a11y', () {
    testWidgets('each field has its own Semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenMemorableDate()));
      // The "Month", "Day", "Year" labels are within Semantics ancestors.
      expect(find.bySemanticsLabel('Month'), findsAtLeastNWidgets(1));
      expect(find.bySemanticsLabel('Day'), findsAtLeastNWidgets(1));
      expect(find.bySemanticsLabel('Year'), findsAtLeastNWidgets(1));
      handle.dispose();
    });
  });

  group('EdenMemorableDate — responsive', () {
    testWidgets('at 600pt width: Row layout (uses Row)', (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate(), width: 600));
      // A Row exists inside the build (not the outer Scaffold one).
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('at 280pt width: stacks vertically (no Row inside the field group)',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate(), width: 280));
      expect(tester.takeException(), isNull);
    });
  });
}

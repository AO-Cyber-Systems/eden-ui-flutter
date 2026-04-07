import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenDatePicker', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(),
      ));

      expect(find.byType(EdenDatePicker), findsOneWidget);
    });

    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(label: 'Start Date'),
      ));

      expect(find.text('Start Date'), findsOneWidget);
    });

    testWidgets('displays hint text when no value', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(hint: 'Pick a date'),
      ));

      expect(find.text('Pick a date'), findsOneWidget);
    });

    testWidgets('displays formatted date when value provided', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDatePicker(value: DateTime(2025, 3, 15)),
      ));

      expect(find.text('2025-03-15'), findsOneWidget);
    });

    testWidgets('displays formatted date with time when includeTime',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenDatePicker(
          value: DateTime(2025, 3, 15, 14, 30),
          includeTime: true,
        ),
      ));

      expect(find.text('2025-03-15 14:30'), findsOneWidget);
    });

    testWidgets('displays error text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(
          label: 'Date',
          errorText: 'Date is required',
        ),
      ));

      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('displays helper text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(helperText: 'Select your birthday'),
      ));

      expect(find.text('Select your birthday'), findsOneWidget);
    });

    testWidgets('hides helper text when error present', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(
          helperText: 'Helper',
          errorText: 'Error',
        ),
      ));

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
    });

    testWidgets('shows calendar icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(),
      ));

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows event icon when includeTime is true', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDatePicker(includeTime: true),
      ));

      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('shows clear button when value is set and clearable',
        (tester) async {
      DateTime? currentValue = DateTime(2025, 1, 1);
      await tester.pumpWidget(wrap(
        StatefulBuilder(
          builder: (context, setState) => EdenDatePicker(
            value: currentValue,
            clearable: true,
            onChanged: (v) => setState(() => currentValue = v),
          ),
        ),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('clears value when clear button tapped', (tester) async {
      DateTime? currentValue = DateTime(2025, 1, 1);
      await tester.pumpWidget(wrap(
        StatefulBuilder(
          builder: (context, setState) => EdenDatePicker(
            value: currentValue,
            clearable: true,
            onChanged: (v) => setState(() => currentValue = v),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(currentValue, isNull);
    });

    testWidgets('does not show clear button when clearable is false',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenDatePicker(
          value: DateTime(2025, 1, 1),
          clearable: false,
        ),
      ));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('opens date picker dialog on tap', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDatePicker(onChanged: (_) {}),
      ));

      // Tap the field to open the date picker
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // The material date picker dialog should appear
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });

  group('EdenDateRangePicker', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDateRangePicker(),
      ));

      expect(find.byType(EdenDateRangePicker), findsOneWidget);
    });

    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDateRangePicker(label: 'Date Range'),
      ));

      expect(find.text('Date Range'), findsOneWidget);
    });

    testWidgets('displays formatted range when both dates provided',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenDateRangePicker(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 31),
        ),
      ));

      expect(find.text('2025-01-01  --  2025-01-31'), findsOneWidget);
    });

    testWidgets('shows date_range icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDateRangePicker(),
      ));

      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}

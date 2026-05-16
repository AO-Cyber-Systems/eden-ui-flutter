import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_meter_reading_entry_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 400, double height = 800}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
      );

  bool submitEnabled(WidgetTester tester) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Record reading'),
    );
    return button.onPressed != null;
  }

  // -----------------------------------------------------------------
  // Task 1 — Form static rendering + validation
  // -----------------------------------------------------------------
  group('EdenMeterReadingEntry static rendering', () {
    testWidgets('renders gallons + source picker + operator + notes + submit',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      expect(find.text('Gallons'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Manual entry'), findsOneWidget);
      expect(find.text('Telemetry'), findsOneWidget);
      expect(find.text('Customer reported'), findsOneWidget);
      expect(find.text('Operator ID'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Record reading'),
          findsOneWidget);
    });

    testWidgets('submit is disabled on mount (gallons + operator both empty)',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('source picker default = manual', (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      final radio = tester.widget<RadioListTile<EdenMeterReadingSource>>(
        find.widgetWithText(RadioListTile<EdenMeterReadingSource>, 'Manual entry'),
      );
      expect(radio.groupValue, EdenMeterReadingSource.manual);
    });

    testWidgets("unit label suffix defaults to 'gal'", (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      expect(find.text('gal'), findsOneWidget);
    });

    testWidgets("unitLabel: 'L' shows 'L' suffix", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMeterReadingEntry(unitLabel: 'L'),
      ));
      expect(find.text('L'), findsOneWidget);
    });
  });

  group('EdenMeterReadingEntry gallons validation', () {
    testWidgets("gallons='320.5' + operator='op-1' → submit enabled",
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(find.widgetWithText(TextField, 'Gallons'), '320.5');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets("gallons='0' + valid operator → submit enabled (zero allowed)",
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(find.widgetWithText(TextField, 'Gallons'), '0');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets("gallons='-5' → submit disabled", (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(find.widgetWithText(TextField, 'Gallons'), '-5');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets("gallons='abc' → submit disabled", (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(find.widgetWithText(TextField, 'Gallons'), 'abc');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets("gallons='1.23456' (5 decimals) → submit disabled",
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(
          find.widgetWithText(TextField, 'Gallons'), '1.23456');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets("gallons='1.2345' (4 decimals) → submit enabled",
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(
          find.widgetWithText(TextField, 'Gallons'), '1.2345');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });
  });

  group('EdenMeterReadingEntry operator ID validation', () {
    testWidgets('valid gallons + empty operator → submit disabled',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(
          find.widgetWithText(TextField, 'Gallons'), '320.5');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('valid gallons + whitespace operator → submit disabled',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(
          find.widgetWithText(TextField, 'Gallons'), '320.5');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), '   ');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets("valid gallons + 'op-1' → submit enabled", (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(
          find.widgetWithText(TextField, 'Gallons'), '320.5');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });
  });

  // Fixtures import sanity check — ensures Fixtures class compiles.
  test('fixture validDraft has gallons 320.5', () {
    expect(EdenMeterReadingEntryFixtures.validDraft.gallons, 320.5);
  });
}

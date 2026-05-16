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

  // -----------------------------------------------------------------
  // Task 2 — Source picker + photo callback flow + timestamp override +
  // submit emission + initialDraft pre-population.
  // -----------------------------------------------------------------
  group('EdenMeterReadingEntry source picker', () {
    testWidgets('tap Telemetry → source becomes telemetry', (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.tap(find.text('Telemetry'));
      await tester.pump();
      final radio = tester.widget<RadioListTile<EdenMeterReadingSource>>(
        find.widgetWithText(
            RadioListTile<EdenMeterReadingSource>, 'Telemetry'),
      );
      expect(radio.groupValue, EdenMeterReadingSource.telemetry);
    });

    testWidgets('tap Customer reported → source becomes customerReported',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.tap(find.text('Customer reported'));
      await tester.pump();
      final radio = tester.widget<RadioListTile<EdenMeterReadingSource>>(
        find.widgetWithText(
            RadioListTile<EdenMeterReadingSource>, 'Customer reported'),
      );
      expect(radio.groupValue, EdenMeterReadingSource.customerReported);
    });

    testWidgets('re-tap Manual entry → back to manual', (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.tap(find.text('Telemetry'));
      await tester.pump();
      await tester.tap(find.text('Manual entry'));
      await tester.pump();
      final radio = tester.widget<RadioListTile<EdenMeterReadingSource>>(
        find.widgetWithText(
            RadioListTile<EdenMeterReadingSource>, 'Manual entry'),
      );
      expect(radio.groupValue, EdenMeterReadingSource.manual);
    });
  });

  group('EdenMeterReadingEntry photo capture flow', () {
    testWidgets(
        'onPhotoPick == null → Capture button disabled', (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Capture photo'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'onPhotoPick returns URL → preview replaces Capture button',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMeterReadingEntry(
        onPhotoPick: EdenMeterReadingEntryFixtures.goodPhotoPick,
      )));
      // Initial: Capture button present, no auth image.
      expect(find.widgetWithText(ElevatedButton, 'Capture photo'),
          findsOneWidget);
      expect(find.byType(EdenAuthenticatedImage), findsNothing);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Capture photo'));
      await tester.pump(); // Process Future
      await tester.pump();
      // Now: Capture button gone, EdenAuthenticatedImage + Remove button.
      expect(find.widgetWithText(ElevatedButton, 'Capture photo'),
          findsNothing);
      expect(find.byType(EdenAuthenticatedImage), findsOneWidget);
      expect(find.text('Remove photo'), findsOneWidget);
    });

    testWidgets('tap Remove photo → resets state', (tester) async {
      await tester.pumpWidget(wrap(EdenMeterReadingEntry(
        onPhotoPick: EdenMeterReadingEntryFixtures.goodPhotoPick,
      )));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Capture photo'));
      await tester.pump();
      await tester.pump();
      // Drag scroll up if necessary — Remove may be off-screen.
      await tester.ensureVisible(find.text('Remove photo'));
      await tester.tap(find.text('Remove photo'));
      await tester.pump();
      expect(find.byType(EdenAuthenticatedImage), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Capture photo'),
          findsOneWidget);
    });

    testWidgets('onPhotoPick returns null → no state change', (tester) async {
      await tester.pumpWidget(wrap(EdenMeterReadingEntry(
        onPhotoPick: EdenMeterReadingEntryFixtures.cancelledPhotoPick,
      )));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Capture photo'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(EdenAuthenticatedImage), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Capture photo'),
          findsOneWidget);
    });
  });

  group('EdenMeterReadingEntry timestamp override', () {
    testWidgets('Override button is wired', (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      expect(find.widgetWithText(TextButton, 'Override'), findsOneWidget);
    });
  });

  group('EdenMeterReadingEntry submit emission', () {
    testWidgets('valid form submit emits EdenMeterReadingDraft with payload',
        (tester) async {
      EdenMeterReadingDraft? emitted;
      await tester.pumpWidget(wrap(EdenMeterReadingEntry(
        onSubmit: (draft) => emitted = draft,
      )));
      await tester.enterText(
          find.widgetWithText(TextField, 'Gallons'), '320.5');
      await tester.tap(find.text('Telemetry'));
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.enterText(
          find.widgetWithText(TextField, 'Notes (optional)'),
          'tank read at 9am');
      await tester.pump();
      await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Record reading'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Record reading'));
      await tester.pump();
      expect(emitted, isNotNull);
      expect(emitted!.gallons, 320.5);
      expect(emitted!.source, EdenMeterReadingSource.telemetry);
      expect(emitted!.operatorId, 'op-1');
      expect(emitted!.notes, 'tank read at 9am');
      expect(emitted!.photoSignedUrl, isNull);
    });

    testWidgets('empty notes → emitted notes is null', (tester) async {
      EdenMeterReadingDraft? emitted;
      await tester.pumpWidget(wrap(EdenMeterReadingEntry(
        onSubmit: (draft) => emitted = draft,
      )));
      await tester.enterText(find.widgetWithText(TextField, 'Gallons'), '100');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Record reading'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Record reading'));
      await tester.pump();
      expect(emitted, isNotNull);
      expect(emitted!.notes, isNull,
          reason: 'empty notes should be normalized to null');
    });

    testWidgets('onSubmit == null → tap does not throw', (tester) async {
      await tester.pumpWidget(wrap(const EdenMeterReadingEntry()));
      await tester.enterText(find.widgetWithText(TextField, 'Gallons'), '100');
      await tester.enterText(
          find.widgetWithText(TextField, 'Operator ID'), 'op-1');
      await tester.pump();
      await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Record reading'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Record reading'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenMeterReadingEntry initialDraft pre-population', () {
    testWidgets('initialDraft pre-fills all fields', (tester) async {
      await tester.pumpWidget(wrap(EdenMeterReadingEntry(
        initialDraft: EdenMeterReadingEntryFixtures.validDraft,
      )));
      expect(find.text('320.5'), findsOneWidget);
      expect(find.text('op-1'), findsOneWidget);
      expect(find.text('tank read at 9am'), findsOneWidget);
      final radio = tester.widget<RadioListTile<EdenMeterReadingSource>>(
        find.widgetWithText(
            RadioListTile<EdenMeterReadingSource>, 'Telemetry'),
      );
      expect(radio.groupValue, EdenMeterReadingSource.telemetry);
    });
  });

  group('EdenMeterReadingEntry iPhone-narrow safety', () {
    testWidgets('390pt — no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMeterReadingEntry(),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_inspection_form_page_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

const _defaultSurfaceSize = Size(900, 1600);

Future<void> pumpAtDefault(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = _defaultSurfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(child);
}

void main() {
  group('EdenInspectionFormPage — composition smoke', () {
    testWidgets('renders form name in AppBar + progress header + Submit',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.singleText())));
      expect(find.text('Quick Inspection'), findsOneWidget);
      expect(find.textContaining('0 of 1'), findsOneWidget);
      expect(find.text('Notes'), findsAtLeastNWidgets(1));
      expect(find.widgetWithText(FilledButton, 'Submit Form'), findsOneWidget);
    });
  });

  group('EdenInspectionFormPage — submitted state', () {
    testWidgets(
        'status: submitted → "Form Submitted" + no submit button',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.submitted())));
      expect(find.text('Form Submitted'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Submit Form'), findsNothing);
    });
  });

  group('EdenInspectionFormPage — progress tracking', () {
    testWidgets('2 required empty → 0 of 2 · 0%', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.twoRequired())));
      expect(find.textContaining('0 of 2'), findsOneWidget);
      expect(find.textContaining('0%'), findsOneWidget);
    });

    testWidgets('fill 1 field → 1 of 2 · 50%', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.twoRequired())));
      await tester.enterText(find.byType(TextFormField).first, 'hello');
      await tester.pumpAndSettle();
      expect(find.textContaining('1 of 2'), findsOneWidget);
    });
  });

  group('EdenInspectionFormPage — text field', () {
    testWidgets('enter text → progress updates', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.singleText())));
      await tester.enterText(find.byType(TextFormField).first, 'hello');
      await tester.pumpAndSettle();
      expect(find.textContaining('1 of 1'), findsOneWidget);
    });
  });

  group('EdenInspectionFormPage — all field types', () {
    testWidgets('all 8 types render without error', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
            form: EdenInspectionFormPageFixtures.allTypes(),
          )));
      expect(find.text('Text fields'), findsOneWidget);
      expect(find.text('Other fields'), findsOneWidget);
      // text, longText, number → 3 TextFormFields.
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
      // boolean
      expect(find.byType(SwitchListTile), findsOneWidget);
      // singleSelect
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      // multiSelect chips (3 options)
      expect(find.byType(FilterChip), findsNWidgets(3));
    });
  });

  group('EdenInspectionFormPage — boolean toggle', () {
    testWidgets('tap switch toggles value', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
            form: EdenInspectionFormPageFixtures.twoRequired(),
          )));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      // After toggle, the boolean counts; expect progress updated.
      expect(find.textContaining('1 of 2'), findsOneWidget);
    });
  });

  group('EdenInspectionFormPage — multiSelect', () {
    testWidgets('chip taps toggle inclusion', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
            form: EdenInspectionFormPageFixtures.allTypes(),
          )));
      await tester.tap(find.widgetWithText(FilterChip, 'Red'));
      await tester.pumpAndSettle();
      final chip = tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Red'));
      expect(chip.selected, isTrue);
    });
  });

  group('EdenInspectionFormPage — photo field', () {
    testWidgets('onCapturePhoto returns sample → field updates',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
            form: EdenInspectionFormPageFixtures.allTypes(),
            onCapturePhoto: EdenInspectionFormPageFixtures.photoSample(),
          )));
      await tester
          .tap(find.byKey(const ValueKey('eden_insp_photo_photo')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Photo captured'), findsOneWidget);
    });

    testWidgets('onCapturePhoto null → SnackBar', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.allTypes())));
      await tester
          .tap(find.byKey(const ValueKey('eden_insp_photo_photo')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Photo capture not configured'),
          findsOneWidget);
    });
  });

  group('EdenInspectionFormPage — Save Draft', () {
    testWidgets('Save Draft fires onSaveDraft + SnackBar', (tester) async {
      final (captured, fn) = EdenInspectionFormPageFixtures.saveRecorder();
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
            form: EdenInspectionFormPageFixtures.singleText(),
            onSaveDraft: fn,
          )));
      await tester.tap(find.widgetWithText(TextButton, 'Save Draft'));
      await tester.pumpAndSettle();
      expect(captured, hasLength(1));
      expect(find.textContaining('Draft saved'), findsOneWidget);
    });

    testWidgets('onSaveDraft null → Save Draft button hidden',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
              form: EdenInspectionFormPageFixtures.singleText())));
      expect(find.widgetWithText(TextButton, 'Save Draft'), findsNothing);
    });
  });

  group('EdenInspectionFormPage — submit gating', () {
    testWidgets(
        'required empty → Submit button disabled; tap label says complete required',
        (tester) async {
      final (captured, fn) = EdenInspectionFormPageFixtures.saveRecorder();
      await pumpAtDefault(
          tester,
          wrap(EdenInspectionFormPage(
            form: EdenInspectionFormPageFixtures.twoRequired(),
            onSubmit: fn,
          )));
      // The submit-area FilledButton uses the "Complete required..." label
      // when not ready; verify it's disabled (onPressed == null).
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
      expect(captured, isEmpty);
    });
  });

  group('EdenInspectionFormPage — iPhone-narrow ≥390pt', () {
    testWidgets('renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(EdenInspectionFormPage(
        form: EdenInspectionFormPageFixtures.allTypes(),
      )));
      expect(find.text('All Types'), findsOneWidget);
    });
  });
}

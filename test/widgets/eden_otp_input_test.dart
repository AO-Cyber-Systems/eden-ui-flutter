import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_phone_input_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenOtpInput', () {
    testWidgets('renders 6 single-character inputs by default',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenOtpInput()));
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('renders N=4 inputs when length=4', (tester) async {
      await tester.pumpWidget(wrap(const EdenOtpInput(length: 4)));
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('auto-advances focus on digit entry', (tester) async {
      await tester.pumpWidget(wrap(const EdenOtpInput()));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.pump();
      // After typing into box 0, focus should be on box 1.
      final secondField = tester.widget<TextField>(fields.at(1));
      expect(secondField.focusNode?.hasFocus, true);
    });

    testWidgets('backspace on empty box moves focus back', (tester) async {
      await tester.pumpWidget(wrap(const EdenOtpInput()));
      final fields = find.byType(TextField);
      // Type one digit so we're at index 1.
      await tester.enterText(fields.at(0), '1');
      await tester.pump();
      // Backspace on the empty box at index 1 should move focus to index 0.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      final firstField = tester.widget<TextField>(fields.at(0));
      expect(firstField.focusNode?.hasFocus, true);
    });

    testWidgets('paste of 6-digit code fills all 6 boxes', (tester) async {
      String? capturedValue;
      await tester.pumpWidget(wrap(EdenOtpInput(
        onChanged: (v) => capturedValue = v,
      )));
      final fields = find.byType(TextField);
      // Simulate paste by entering full string into first box.
      await tester.enterText(
          fields.at(0), EdenOtpInputFixtures.sixDigitCode);
      await tester.pump();
      // Each box should display one digit.
      for (var i = 0; i < 6; i++) {
        final field = tester.widget<TextField>(fields.at(i));
        expect(field.controller?.text,
            EdenOtpInputFixtures.sixDigitCode[i],
            reason: 'Box $i should contain digit ${EdenOtpInputFixtures.sixDigitCode[i]}');
      }
      expect(capturedValue, EdenOtpInputFixtures.sixDigitCode);
    });

    testWidgets('onChanged fires with full string when all boxes are filled',
        (tester) async {
      String? lastValue;
      await tester.pumpWidget(wrap(EdenOtpInput(
        onChanged: (v) => lastValue = v,
      )));
      final fields = find.byType(TextField);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(
            fields.at(i), EdenOtpInputFixtures.sixDigitCode[i]);
        await tester.pump();
      }
      expect(lastValue, EdenOtpInputFixtures.sixDigitCode);
    });

    testWidgets('onSubmit fires only when all boxes are filled',
        (tester) async {
      String? submitted;
      await tester.pumpWidget(wrap(EdenOtpInput(
        onSubmit: (v) => submitted = v,
      )));
      final fields = find.byType(TextField);
      // Fill first 5 only.
      for (var i = 0; i < 5; i++) {
        await tester.enterText(
            fields.at(i), EdenOtpInputFixtures.sixDigitCode[i]);
        await tester.pump();
      }
      expect(submitted, isNull,
          reason: 'onSubmit should not fire until all boxes are filled');
      // Fill last.
      await tester.enterText(fields.at(5), EdenOtpInputFixtures.sixDigitCode[5]);
      await tester.pump();
      expect(submitted, EdenOtpInputFixtures.sixDigitCode);
    });

    testWidgets('iPhone-narrow safe: 6 boxes fit in 390pt without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(const Padding(
        padding: EdgeInsets.all(16),
        child: EdenOtpInput(),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_mfa_hardware_token_fixtures.dart';

Widget wrap(Widget child, {double width = 400}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenMfaHardwareToken — yubikey type', () {
    testWidgets('renders USB icon + Tap your YubiKey + Awaiting tap + Start button',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.yubikey,
      )));
      expect(find.byIcon(Icons.usb), findsOneWidget);
      expect(find.text('Tap your YubiKey'), findsOneWidget);
      expect(find.text('Awaiting tap…'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
    });

    testWidgets('Start tap fires onTouchRequested', (tester) async {
      var fired = false;
      await tester.pumpWidget(wrap(EdenMfaHardwareToken(
        type: EdenMfaTokenType.yubikey,
        onTouchRequested: () => fired = true,
      )));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      expect(fired, isTrue);
    });
  });

  group('EdenMfaHardwareToken — rsaSecurId type', () {
    testWidgets('renders Enter the 6-digit code + EdenOtpInput(length=6) + Submit',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.rsaSecurId,
      )));
      expect(find.text('Enter the 6-digit code from your token'), findsOneWidget);
      final otp = tester.widget<EdenOtpInput>(find.byType(EdenOtpInput));
      expect(otp.length, 6);
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });

    testWidgets('typing 123456 + Submit fires onCodeSubmitted with 123456',
        (tester) async {
      String? submitted;
      await tester.pumpWidget(wrap(EdenMfaHardwareToken(
        type: EdenMfaTokenType.rsaSecurId,
        onCodeSubmitted: (v) => submitted = v,
      )));
      // EdenOtpInput is multi-field; entering text into the EditableTexts.
      final fields = find.byType(EditableText);
      expect(fields, findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        await tester.enterText(
            fields.at(i), EdenMfaHardwareTokenFixtures.rsaCode6[i]);
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump();
      expect(submitted, EdenMfaHardwareTokenFixtures.rsaCode6);
    });

    testWidgets('Submit disabled when only 3 digits entered', (tester) async {
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.rsaSecurId,
      )));
      final fields = find.byType(EditableText);
      for (var i = 0; i < 3; i++) {
        await tester.enterText(
            fields.at(i), EdenMfaHardwareTokenFixtures.partialCode3[i]);
        await tester.pump();
      }
      final submit = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit'));
      expect(submit.onPressed, isNull);
    });
  });

  group('EdenMfaHardwareToken — cacBackup type', () {
    testWidgets('renders Enter your 8-digit backup code + EdenOtpInput(length=8)',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.cacBackup,
      )));
      expect(find.text('Enter your 8-digit backup code'), findsOneWidget);
      final otp = tester.widget<EdenOtpInput>(find.byType(EdenOtpInput));
      expect(otp.length, 8);
    });

    testWidgets('typing 12345678 + Submit fires onCodeSubmitted with 12345678',
        (tester) async {
      String? submitted;
      await tester.pumpWidget(wrap(EdenMfaHardwareToken(
        type: EdenMfaTokenType.cacBackup,
        onCodeSubmitted: (v) => submitted = v,
      )));
      final fields = find.byType(EditableText);
      expect(fields, findsNWidgets(8));
      for (var i = 0; i < 8; i++) {
        await tester.enterText(
            fields.at(i), EdenMfaHardwareTokenFixtures.cacCode8[i]);
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump();
      expect(submitted, EdenMfaHardwareTokenFixtures.cacCode8);
    });
  });

  group('EdenMfaHardwareToken — error display', () {
    testWidgets('errorMessage="Invalid code" renders below', (tester) async {
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.rsaSecurId,
        errorMessage: EdenMfaHardwareTokenFixtures.errorInvalid,
      )));
      expect(find.text(EdenMfaHardwareTokenFixtures.errorInvalid), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('errorMessage=null does NOT render error icon', (tester) async {
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.rsaSecurId,
      )));
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });

  group('EdenMfaHardwareToken — Section 508 a11y', () {
    testWidgets('yubikey Semantics label contains YubiKey tap required',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.yubikey,
      )));
      final semantics = tester.getSemantics(find.byType(EdenMfaHardwareToken));
      expect(semantics.label, contains('YubiKey'));
      handle.dispose();
    });

    testWidgets('rsaSecurId Semantics announces RSA SecurID 6-digit code entry',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.rsaSecurId,
      )));
      final semantics = tester.getSemantics(find.byType(EdenMfaHardwareToken));
      expect(semantics.label, contains('RSA SecurID'));
      expect(semantics.label, contains('6-digit'));
      handle.dispose();
    });

    testWidgets('cacBackup Semantics announces CAC backup 8-digit code entry',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenMfaHardwareToken(
        type: EdenMfaTokenType.cacBackup,
      )));
      final semantics = tester.getSemantics(find.byType(EdenMfaHardwareToken));
      expect(semantics.label, contains('CAC backup'));
      expect(semantics.label, contains('8-digit'));
      handle.dispose();
    });
  });

  group('EdenMfaHardwareToken — iPhone-narrow (390pt) safety', () {
    testWidgets('yubikey renders at 390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMfaHardwareToken(type: EdenMfaTokenType.yubikey),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rsaSecurId renders at 390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMfaHardwareToken(type: EdenMfaTokenType.rsaSecurId),
        width: 390,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('cacBackup renders at 390pt: no overflow (8-digit OTP scrolls horizontally)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMfaHardwareToken(type: EdenMfaTokenType.cacBackup),
        width: 390,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

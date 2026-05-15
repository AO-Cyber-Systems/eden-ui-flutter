import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenPhoneInput', () {
    testWidgets('renders default US country (flag + dial code) and input',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPhoneInput()));
      expect(find.byType(TextField), findsOneWidget);
      // Default US dial code visible in country picker chrome at wide width.
      expect(find.textContaining('+1'), findsOneWidget);
    });

    testWidgets('typing US national number formats as (NNN) NNN-NNNN',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPhoneInput()));
      await tester.enterText(find.byType(TextField), '5551234567');
      await tester.pump();
      expect(find.text('(555) 123-4567'), findsOneWidget);
    });

    testWidgets('onChanged emits E.164 format', (tester) async {
      String? captured;
      await tester.pumpWidget(wrap(EdenPhoneInput(
        onChanged: (v) => captured = v,
      )));
      await tester.enterText(find.byType(TextField), '5551234567');
      await tester.pump();
      expect(captured, '+15551234567');
    });

    testWidgets('switching country to GB updates dial code prefix',
        (tester) async {
      String? captured;
      await tester.pumpWidget(wrap(EdenPhoneInput(
        onChanged: (v) => captured = v,
      )));
      // Open country picker dropdown.
      await tester.tap(find.byKey(const ValueKey('eden_phone_country_picker')));
      await tester.pumpAndSettle();
      // Tap GB.
      await tester.tap(find.text('United Kingdom').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2079460958');
      await tester.pump();
      expect(captured, startsWith('+44'));
    });

    testWidgets('verifyButton=true shows the button and invokes callback',
        (tester) async {
      var verifyCalled = false;
      await tester.pumpWidget(wrap(EdenPhoneInput(
        verifyButton: true,
        onVerifyPressed: () => verifyCalled = true,
      )));
      expect(find.text('Verify'), findsOneWidget);
      await tester.tap(find.text('Verify'));
      await tester.pump();
      expect(verifyCalled, true);
    });

    testWidgets('verifyButton=false hides the button', (tester) async {
      await tester.pumpWidget(wrap(const EdenPhoneInput()));
      expect(find.text('Verify'), findsNothing);
    });

    testWidgets(
        'iPhone-narrow: country picker collapses to flag-only (no dial code inline)',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(const Padding(
        padding: EdgeInsets.all(16),
        child: EdenPhoneInput(),
      )));
      await tester.pump();
      // At < 480pt width, the inline dial code text disappears (still
      // available inside the picker dropdown — not inline in chrome).
      expect(
          find.byKey(const ValueKey('eden_phone_inline_dial_code')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(const Padding(
        padding: EdgeInsets.all(16),
        child: EdenPhoneInput(verifyButton: true),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}

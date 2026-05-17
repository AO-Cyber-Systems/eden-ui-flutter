import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_secret_field_fixtures.dart';

Widget wrap(Widget child, {double width = 400}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenSecretField — baseline (standard mode, backwards compat)', () {
    testWidgets('renders value obscured by default (editable mode)', (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
      )));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('reveal toggle toggles obscureText off', (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
      )));
      // Find the reveal icon (visibility means obscured/show-eye).
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
    });

    testWidgets('onChanged fires on typing (standard mode)', (tester) async {
      String? captured;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: '',
        onChanged: (v) => captured = v,
      )));
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();
      expect(captured, 'hi');
    });

    testWidgets('onCopy callback shows copy button + fires on tap (standard mode)',
        (tester) async {
      var copied = false;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
        onCopy: () => copied = true,
      )));
      expect(find.byIcon(Icons.copy), findsOneWidget);
      await tester.tap(find.byIcon(Icons.copy));
      expect(copied, isTrue);
    });

    testWidgets('clipboardMode defaults to standard when omitted', (tester) async {
      const f = EdenSecretField(value: 'x');
      expect(f.clipboardMode, EdenSecretClipboardMode.standard);
    });

    testWidgets('readOnly mode renders display Text without TextField',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
        readOnly: true,
      )));
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('EdenSecretField — classified mode', () {
    testWidgets('copy button NOT visible in classified mode (even with onCopy)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecretField(
        value: EdenSecretFieldFixtures.cuiSecret,
        clipboardMode: EdenSecretClipboardMode.classified,
        onCopy: () {},
      )));
      // Standard's `Icons.copy` should NOT appear.
      expect(find.byIcon(Icons.copy), findsNothing);
    });

    testWidgets('Semantics announces "Classified — copy disabled"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.cuiSecret,
        clipboardMode: EdenSecretClipboardMode.classified,
      )));
      expect(
        find.bySemanticsLabel('Classified — copy disabled'),
        findsAtLeastNWidgets(1),
      );
      handle.dispose();
    });

    testWidgets('paste-like delta (>4 chars in one tick) fires onPasteFromOutsideWarning',
        (tester) async {
      var warned = false;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: '',
        clipboardMode: EdenSecretClipboardMode.classified,
        onPasteFromOutsideWarning: () => warned = true,
      )));
      await tester.enterText(
        find.byType(TextField),
        EdenSecretFieldFixtures.fivePlusCharDelta, // 6 chars
      );
      await tester.pump();
      expect(warned, isTrue);
    });

    testWidgets('per-keystroke delta (1 char) does NOT fire warning', (tester) async {
      var warned = false;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: '',
        clipboardMode: EdenSecretClipboardMode.classified,
        onPasteFromOutsideWarning: () => warned = true,
      )));
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      expect(warned, isFalse);
    });

    testWidgets('initial mount with non-empty value does NOT fire warning',
        (tester) async {
      var warned = false;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: EdenSecretFieldFixtures.cuiSecret, // long initial value
        clipboardMode: EdenSecretClipboardMode.classified,
        onPasteFromOutsideWarning: () => warned = true,
      )));
      await tester.pump();
      expect(warned, isFalse);
    });

    testWidgets('exactly-4-char delta does NOT fire warning (boundary)',
        (tester) async {
      var warned = false;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: '',
        clipboardMode: EdenSecretClipboardMode.classified,
        onPasteFromOutsideWarning: () => warned = true,
      )));
      await tester.enterText(
        find.byType(TextField),
        EdenSecretFieldFixtures.fourCharDelta,
      );
      await tester.pump();
      expect(warned, isFalse);
    });
  });
}

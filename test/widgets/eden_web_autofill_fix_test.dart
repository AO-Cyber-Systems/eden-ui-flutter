// test/widgets/eden_web_autofill_fix_test.dart
//
// READ THIS BEFORE ADDING A TEST HERE.
//
// WHAT THIS FILE CAN AND CANNOT PROVE
//   `flutter test` runs on the Dart VM. `kIsWeb` is a COMPILE-TIME constant and
//   is false there, and the conditional export in `eden_web_autofill_fix.dart`
//   therefore compiles the STUB, not the web implementation. There is no DOM,
//   no MutationObserver and no element to restyle in this process.
//
//   So this file proves exactly two things:
//     1. The pure restyle PREDICATE -- the decision about which elements the
//        shim is allowed to touch. That is real logic, it is where the
//        dangerous mistakes live (restyling the focused field, or the submit
//        button), and it is genuinely covered below.
//     2. The SHAPE of the API and the non-web no-op contract.
//
//   It does NOT prove that the observer installs, that a collapsed input is
//   actually restyled in a browser, or that a password manager reacts. That
//   half is verified by the recorded real-browser evidence in
//   `.planning/objectives/40-ui-autofill-copypaste/40-19-BROWSER-EVIDENCE.md`,
//   NOT by this suite.
//
//   DO NOT add a test here that appears to cover the DOM behaviour, and do not
//   fake `kIsWeb` to make one possible. An acknowledged gap is worth more than
//   a green check that measures nothing.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(edenResetWebAutofillFixForTest);
  tearDown(edenResetWebAutofillFixForTest);

  group('edenWebAutofillFixShouldRestyle -- the restyle predicate', () {
    // This group is REAL coverage: the predicate is pure Dart and runs
    // identically on the VM and on web.

    test('matches a collapsed, non-focused text input', () {
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'text',
          inlineWidth: '0px',
          inlineHeight: '0px',
        ),
        isTrue,
        reason: 'a 0x0 input is exactly what the engine leaves behind when a '
            'field is not focused, and is the whole reason this shim exists',
      );
    });

    test('matches the collapsed password field -- the field that is the bug',
        () {
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'password',
          inlineWidth: '0px',
          inlineHeight: '0px',
        ),
        isTrue,
      );
    });

    test('accepts the bare "0" the engine writes, not just the "0px" the '
        'CSSOM reads back', () {
      // `_styleAutofillElements()` assigns the string '0'. Browsers normalise
      // that to '0px' on read, but the predicate must not depend on that.
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'input',
          type: 'text',
          inlineWidth: '0',
          inlineHeight: '0',
        ),
        isTrue,
      );
    });

    test('matches when only ONE of the two dimensions is zero', () {
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'text',
          inlineWidth: '819px',
          inlineHeight: '0px',
        ),
        isTrue,
      );
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'text',
          inlineWidth: '0px',
          inlineHeight: '22px',
        ),
        isTrue,
      );
    });

    test('NEVER matches the focused field, which carries real dimensions', () {
      // 819x22 is the measured live geometry of the focused email field
      // (40-19-BROWSER-EVIDENCE.md). Touching it would mean fighting the
      // engine over the field the user is actually typing in.
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'text',
          inlineWidth: '819px',
          inlineHeight: '22px',
        ),
        isFalse,
      );
    });

    test('NEVER matches the hidden submit button, even at 0x0', () {
      // The engine's `.submitBtn` is the SAVE trigger clicked by
      // finishAutofillContext. It must stay 0x0 and offscreen; it is not a
      // fill target.
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'submit',
          inlineWidth: '0px',
          inlineHeight: '0px',
        ),
        isFalse,
      );
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'SUBMIT',
          inlineWidth: '0',
          inlineHeight: '0',
        ),
        isFalse,
        reason: 'the type comparison must be case-insensitive, or a '
            'differently-cased attribute would let the save trigger be '
            'restyled',
      );
    });

    test('NEVER matches an element that is not an input or textarea', () {
      for (final String tag in <String>['DIV', 'FORM', 'SPAN', 'BUTTON']) {
        expect(
          edenWebAutofillFixShouldRestyle(
            tagName: tag,
            type: '',
            inlineWidth: '0px',
            inlineHeight: '0px',
          ),
          isFalse,
          reason: '$tag is never an autofill target',
        );
      }
    });

    test('matches a collapsed textarea, which reports no type at all', () {
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'TEXTAREA',
          type: '',
          inlineWidth: '0px',
          inlineHeight: '0px',
        ),
        isTrue,
      );
    });

    test('an element with NO inline dimensions is left alone', () {
      // Empty means the engine has not collapsed it. Treating "no inline
      // width" as zero would restyle elements the engine never touched.
      expect(
        edenWebAutofillFixShouldRestyle(
          tagName: 'INPUT',
          type: 'text',
          inlineWidth: '',
          inlineHeight: '',
        ),
        isFalse,
      );
    });
  });

  group('the replacement box is non-zero', () {
    // Guards against anyone "simplifying" the constants back toward zero,
    // which would silently reinstate the bug.
    test('width and height are both non-zero CSS lengths', () {
      for (final String value in <String>[
        kEdenWebAutofillFixWidth,
        kEdenWebAutofillFixHeight,
      ]) {
        expect(value.endsWith('px'), isTrue, reason: '$value must be a px length');
        final double? parsed =
            double.tryParse(value.substring(0, value.length - 2));
        expect(parsed, isNotNull, reason: '$value must parse as a number');
        expect(
          parsed,
          greaterThan(0),
          reason: 'a zero-sized replacement box would reinstate the exact bug '
              'this shim exists to fix',
        );
      }
    });
  });

  group('non-web no-op contract (this is the STUB, not the web shim)', () {
    test('install does nothing off web and reports not installed', () {
      expect(edenWebAutofillFixInstalled, isFalse);
      edenInstallWebAutofillFix();
      expect(
        edenWebAutofillFixInstalled,
        isFalse,
        reason: 'off web there is no DOM to observe, so nothing installs',
      );
    });

    test('repeated install calls off web are safe', () {
      // NOTE: this does NOT measure the one-install-per-process latch. That
      // latch lives in eden_web_autofill_fix_web.dart and is unreachable from
      // the VM. All that is asserted here is that the no-op is callable
      // repeatedly without throwing or flipping state.
      edenInstallWebAutofillFix();
      edenInstallWebAutofillFix();
      edenInstallWebAutofillFix();
      expect(edenWebAutofillFixInstalled, isFalse);
    });

    test('the opt-out flag is settable through the barrel export', () {
      // A consumer must be able to write this once, unconditionally, without
      // guarding on kIsWeb -- which is why the stub declares it too.
      expect(edenWebAutofillFixEnabled, isTrue, reason: 'defaults to enabled');
      edenWebAutofillFixEnabled = false;
      expect(edenWebAutofillFixEnabled, isFalse);
      edenInstallWebAutofillFix();
      expect(edenWebAutofillFixInstalled, isFalse);
    });

    test('the test reset restores the default', () {
      edenWebAutofillFixEnabled = false;
      edenResetWebAutofillFixForTest();
      expect(edenWebAutofillFixEnabled, isTrue);
      expect(edenWebAutofillFixInstalled, isFalse);
    });
  });

  group('EdenAutofillScope is unchanged off web', () {
    // The scope now calls edenInstallWebAutofillFix() from initState behind
    // `kIsWeb && widget.enabled`. Off web that branch is dead code, so the
    // point of these tests is that nothing REGRESSED -- not that the install
    // happened.
    testWidgets('still installs an AutofillGroup and installs no shim',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EdenAutofillScope(child: SizedBox.shrink())),
      );

      expect(find.byType(AutofillGroup), findsOneWidget);
      expect(
        edenWebAutofillFixInstalled,
        isFalse,
        reason: 'kIsWeb is a compile-time false here, so the initState branch '
            'is never taken',
      );
    });

    testWidgets('enabled: false is still a pass-through and installs nothing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EdenAutofillScope(enabled: false, child: SizedBox.shrink()),
        ),
      );

      expect(find.byType(AutofillGroup), findsNothing);
      expect(edenWebAutofillFixInstalled, isFalse);
    });

    testWidgets('several nested scopes still mount without throwing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EdenAutofillScope(
            child: EdenAutofillScope(
              child: EdenAutofillScope(child: SizedBox.shrink()),
            ),
          ),
        ),
      );

      expect(find.byType(AutofillGroup), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  // Inspect the CONSTRUCTED widget, not the call site: the whole point of this
  // TRD is that what reaches the real `TextField` is resolved from `purpose`.
  TextField fieldOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  // Deliberately non-const factories. `EdenInput` has a const constructor, so a
  // literal argument would make the conflicting invocation const-evaluable, and
  // the conflict assert would then fire at COMPILE time (a compile error)
  // instead of producing the runtime `AssertionError` that
  // `throwsAssertionError` observes.
  TextInputType rawKeyboard() => TextInputType.number;
  List<String> rawHints() => <String>[AutofillHints.email];
  bool rawObscure() => true;

  group('EdenInput purpose', () {
    testWidgets('purpose: email forwards emailAddress keyboard and email hint first',
        (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.email)),
      );
      final tf = fieldOf(tester);

      expect(
        tf.keyboardType,
        TextInputType.emailAddress,
        reason: 'AutofillHints.email works ONLY with TextInputType.emailAddress '
            '(editable_text.dart:1855-1858). One purpose must resolve both.',
      );
      expect(tf.autofillHints, isNotNull);
      expect(
        tf.autofillHints!.first,
        AutofillHints.email,
        reason: 'iOS and web consume ONLY the first hint '
            '(autofill.dart:688-694), so hint ORDER is load-bearing.',
      );
    });

    testWidgets('purpose: currentPassword obscures AND emits a password-family hint',
        (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.currentPassword)),
      );
      final tf = fieldOf(tester);

      expect(tf.obscureText, isTrue);
      expect(tf.autofillHints, isNotNull);
      expect(
        tf.autofillHints!.first.toLowerCase().contains('password'),
        isTrue,
        reason: 'Web derives DOM type="password" from the HINT STRING, never '
            'from obscureText (text_editing.dart:514-531). An obscured field '
            'without a password-family hint renders as type="text" - the secret '
            'is plaintext in the DOM and 1Password can neither fill nor save it.',
      );
    });

    testWidgets('purpose: telephoneNumber forwards the phone keyboard',
        (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.telephoneNumber)),
      );
      final tf = fieldOf(tester);

      expect(tf.keyboardType, TextInputType.phone);
      expect(tf.autofillHints!.first, AutofillHints.telephoneNumber);
    });

    testWidgets('purpose: personName forwards TextInputType.name', (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.personName)),
      );
      final tf = fieldOf(tester);

      expect(
        tf.keyboardType,
        TextInputType.name,
        reason: 'AutofillHints.name requires TextInputType.name - the coupling '
            'named verbatim in editable_text.dart:1855-1858.',
      );
      expect(tf.autofillHints!.first, AutofillHints.name);
    });

    testWidgets('purpose: none forwards the caller keyboardType untouched',
        (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(keyboardType: TextInputType.number)),
      );

      expect(
        fieldOf(tester).keyboardType,
        TextInputType.number,
        reason: 'The deprecated raw parameters must keep working verbatim for '
            'the 4+ downstream consumers.',
      );
    });

    testWidgets('purpose: none leaves every forwarded field at the bare-TextField default',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenInput()));
      final eden = fieldOf(tester);
      final edenAutocorrect =
          tester.widget<EditableText>(find.byType(EditableText)).autocorrect;

      // Control built in the same test, so this stays true across SDK versions
      // (local 3.41.4 vs CI 3.47.4) rather than hard-coding a default.
      await tester.pumpWidget(wrap(const TextField()));
      final control = fieldOf(tester);
      final controlAutocorrect =
          tester.widget<EditableText>(find.byType(EditableText)).autocorrect;

      expect(
        eden.keyboardType,
        control.keyboardType,
        reason: 'NOTE: TextField itself applies '
            '`keyboardType ?? (maxLines == 1 ? text : multiline)` '
            '(text_field.dart:354), so this is NON-NULL, and '
            'EditableText._inferKeyboardType is unreachable through TextField. '
            'The invariant that matters is "identical to a bare TextField", '
            'i.e. unchanged from before this TRD.',
      );
      expect(eden.keyboardType, isNotNull);
      expect(eden.textInputAction, control.textInputAction);
      expect(eden.textCapitalization, control.textCapitalization);
      // Compared at the RESOLVED EditableText level, not the raw TextField
      // field. `TextField.autocorrect` is non-nullable `bool` (default true) at
      // the declared floor 3.27.0 but nullable (default null) on 3.41.4+, where
      // null means `_inferAutocorrect(autofillHints:)`
      // (editable_text.dart:920). EdenInput must pass a non-null bool to keep
      // compiling at the floor, so the raw fields legitimately differ while the
      // resolved behaviour does not.
      expect(edenAutocorrect, controlAutocorrect);
      expect(eden.enableSuggestions, control.enableSuggestions);
      expect(eden.obscureText, control.obscureText);
      // NOT compared against the control: `TextField.autofillHints` defaults to
      // `const <String>[]` while EdenInput has always forwarded the caller's
      // value verbatim, i.e. null when unset. That divergence PRE-DATES this
      // TRD, and both are treated as "no autofill" by the framework
      // (`autofillHints == null || autofillHints.isEmpty`). The invariant that
      // matters here is "unchanged from before this TRD".
      expect(eden.autofillHints, isNull);
    });

    testWidgets('purpose: searchQuery emits null hints and a search action',
        (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.searchQuery)),
      );
      final tf = fieldOf(tester);

      expect(
        tf.autofillHints,
        isNull,
        reason: 'There is no AutofillHints constant for a search query, and '
            'inventing one would emit an invalid autocomplete token.',
      );
      expect(tf.textInputAction, TextInputAction.search);
    });

    test('combining a purpose with a raw keyboardType trips an assert', () {
      expect(
        () => EdenInput(
          purpose: EdenFieldPurpose.email,
          keyboardType: rawKeyboard(),
        ),
        throwsAssertionError,
      );
      expect(
        () => EdenInput(
          purpose: EdenFieldPurpose.email,
          autofillHints: rawHints(),
        ),
        throwsAssertionError,
      );
      expect(
        () => EdenInput(
          purpose: EdenFieldPurpose.currentPassword,
          obscureText: rawObscure(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('every EdenFieldPurpose value builds without throwing',
        (tester) async {
      for (final purpose in EdenFieldPurpose.values) {
        await tester.pumpWidget(wrap(EdenInput(purpose: purpose)));
        expect(
          tester.takeException(),
          isNull,
          reason: 'EdenInput(purpose: $purpose) threw while building.',
        );

        final tf = fieldOf(tester);
        if (tf.obscureText) {
          expect(
            tf.autofillHints,
            isNotNull,
            reason: 'Obscured purpose $purpose emitted no autofill hint, so web '
                'renders it as DOM type="text" (text_editing.dart:514-531).',
          );
          expect(
            // `AutofillHints.newPassword` is literally 'newPassword', so this
            // must be case-insensitive. What reaches the DOM is the BROWSER
            // token ('new-password' / 'current-password'), and the engine tests
            // THAT for 'password' (text_editing.dart:514-531).
            tf.autofillHints!.first.toLowerCase().contains('password'),
            isTrue,
            reason: 'Obscured purpose $purpose must emit a password-family hint '
                'FIRST - the DOM type derives from the hint string, never from '
                'obscureText (text_editing.dart:514-531).',
          );
        }
      }
    });

    testWidgets('text capitalization and autocorrect are forwarded for purposed fields',
        (tester) async {
      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.personName)),
      );
      var tf = fieldOf(tester);
      expect(tf.textCapitalization, TextCapitalization.words);
      expect(tf.autocorrect, isTrue);
      expect(tf.enableSuggestions, isTrue);

      await tester.pumpWidget(
        wrap(const EdenInput(purpose: EdenFieldPurpose.currentPassword)),
      );
      tf = fieldOf(tester);
      expect(tf.textCapitalization, TextCapitalization.none);
      expect(
        tf.autocorrect,
        isFalse,
        reason: 'A password must never be autocorrected or suggested.',
      );
      expect(tf.enableSuggestions, isFalse);
    });
  });
}

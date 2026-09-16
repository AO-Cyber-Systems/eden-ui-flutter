// Purpose-sweep coverage for TRD 40-09 — the 10 input primitives & wrappers.
//
// These widgets are the building blocks every other Eden widget composes, so a
// wrong purpose here propagates to every consumer. Each case inspects the
// CONSTRUCTED TextField rather than the call site, because the thing under test
// is what actually reaches the framework.
//
// Two traps this file is written around, both documented in 40-RESEARCH.md:
//
//   * Appendix B1 — `TextField` resolves `keyboardType` in its own constructor
//     initializer list (text_field.dart:355), so `_inferKeyboardType` NEVER
//     fires. A field carrying correct hints but no explicit keyboardType still
//     resolves to TextInputType.text and is still broken on iOS. Every hint
//     assertion below is therefore PAIRED with a keyboardType assertion.
//
//   * Appendix A — `copyEnabled` is `!obscureText && !selection.isCollapsed`.
//     Any clipboard-gating assertion must set a NON-COLLAPSED selection first
//     or it passes vacuously for every field. `pasteEnabled` is never asserted:
//     it is false in the test environment regardless of configuration.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_secret_field_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 420}) => MaterialApp(
        home: Scaffold(body: SizedBox(width: width, child: child)),
      );

  /// The one and only TextField in the tree.
  TextField soleField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  /// Locate a field by a distinguishing decoration property rather than by
  /// index — an index-based finder breaks on the next layout change.
  TextField fieldByLabel(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
        description: 'TextField(labelText: "$label")',
      ));

  TextField fieldByHint(WidgetTester tester, String hint) =>
      tester.widget<TextField>(find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
        description: 'TextField(hintText: "$hint")',
      ));

  /// `TextField.autofillHints` defaults to `const <String>[]`, NOT null, so a
  /// field that was never given hints reads as `[]` while a field explicitly
  /// forwarded `EdenFieldSemantics.autofillHints` for a hintless purpose reads
  /// as `null`. Both mean the same thing to the engine — `EditableText` only
  /// builds an `AutofillConfiguration` when the list is non-empty — so assert
  /// on the property that actually matters: no hint reaches the platform.
  Iterable<String> hintsOf(TextField tf) =>
      tf.autofillHints ?? const <String>[];

  const kHintReason =
      'Without an autofillHint web emits autocomplete="on" with no `name` and '
      'no `id` (text_editing.dart:514-531), so a password manager has nothing '
      'to classify the field by.';

  const kKeyboardReason =
      'Appendix B1: TextField resolves keyboardType in its own initializer '
      'list (text_field.dart:355), so _inferKeyboardType NEVER fires. A hint '
      'without the matching keyboardType is still broken on iOS '
      '(editable_text.dart:1855-1858).';

  // ───────────────────────────────────────────────────────────────────────────
  // EdenSearchInput — searchQuery
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenSearchInput — EdenFieldPurpose.searchQuery', () {
    testWidgets('resolves null hints, text keyboard and the SEARCH action',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenSearchInput()));
      final tf = soleField(tester);

      expect(
        hintsOf(tf),
        isEmpty,
        reason: 'There is no AutofillHints constant for a search query, and '
            'inventing one would emit an invalid `autocomplete` token.',
      );
      expect(tf.keyboardType, TextInputType.text, reason: kKeyboardReason);
      expect(
        tf.textInputAction,
        TextInputAction.search,
        reason: 'searchQuery is deliberately NOT `none`: the whole reason it '
            'is a distinct member is the search action key.',
      );
    });

    testWidgets('the search action key still fires onSubmitted',
        (tester) async {
      String? submitted;
      await tester.pumpWidget(wrap(EdenSearchInput(
        onSubmitted: (v) => submitted = v,
      )));

      await tester.enterText(find.byType(TextField), 'tourniquet');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(
        submitted,
        'tourniquet',
        reason: 'Changing textInputAction from the implicit `done` to `search` '
            'must not break the widget Enter-key contract.',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // EdenPhoneInput — telephoneNumber
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenPhoneInput — EdenFieldPurpose.telephoneNumber', () {
    testWidgets('resolves the telephoneNumber hint AND the phone keyboard',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPhoneInput()));
      final tf = soleField(tester);

      expect(tf.autofillHints, isNotNull, reason: kHintReason);
      expect(
        tf.autofillHints!.first,
        AutofillHints.telephoneNumber,
        reason: 'iOS and web consume ONLY the first hint '
            '(autofill.dart:688-694), so hint ORDER is load-bearing.',
      );
      expect(tf.keyboardType, TextInputType.phone, reason: kKeyboardReason);
      expect(tf.autocorrect, isFalse);
      expect(tf.enableSuggestions, isFalse);
    });

    testWidgets('keeps its own national-number mask formatters',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPhoneInput()));
      expect(
        soleField(tester).inputFormatters,
        isNotEmpty,
        reason: 'The purpose supplies hints + keyboard only. Masking stays the '
            "widget's own business.",
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // EdenOtpInput — oneTimeCode
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenOtpInput — EdenFieldPurpose.oneTimeCode', () {
    testWidgets('EVERY box carries oneTimeCode first and a number keyboard',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenOtpInput(length: 6)));

      final boxes = tester.widgetList<TextField>(find.byType(TextField));
      expect(boxes.length, 6);

      for (final tf in boxes) {
        expect(hintsOf(tf), isNotEmpty, reason: kHintReason);
        expect(
          hintsOf(tf).first,
          AutofillHints.oneTimeCode,
          reason: 'iOS surfaces the SMS code above the keyboard purely from '
              'this hint. A box with no purpose would be a false `none`.',
        );
        expect(tf.keyboardType, TextInputType.number, reason: kKeyboardReason);
        expect(
          tf.autocorrect,
          isFalse,
          reason: 'Autocorrecting a one-time code corrupts it.',
        );
        expect(tf.enableSuggestions, isFalse);
      }
    });

    testWidgets('paste distribution across boxes still works', (tester) async {
      String? code;
      await tester.pumpWidget(wrap(EdenOtpInput(
        length: 6,
        onSubmit: (v) => code = v,
      )));

      await tester.enterText(find.byType(TextField).first, '314159');
      await tester.pump();

      expect(
        code,
        '314159',
        reason: 'A full code landing in one box is redistributed by '
            '_handleChange — the behaviour iOS autofill relies on.',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // EdenAddressInput — five purposes, one per field
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenAddressInput — one purpose per address component', () {
    const expected = <String, (String, TextInputType)>{
      'Street address': (
        AutofillHints.streetAddressLine1,
        TextInputType.streetAddress
      ),
      'Apt, suite, etc. (optional)': (
        AutofillHints.streetAddressLine2,
        TextInputType.streetAddress
      ),
      'City': (AutofillHints.addressCity, TextInputType.text),
      'State / region': (AutofillHints.addressState, TextInputType.text),
      'Postal code': (AutofillHints.postalCode, TextInputType.text),
    };

    for (final entry in expected.entries) {
      final label = entry.key;
      final hint = entry.value.$1;
      final keyboard = entry.value.$2;

      testWidgets('"$label" resolves $hint + the matching keyboard',
          (tester) async {
        await tester.pumpWidget(wrap(const EdenAddressInput(
          provider: NoOpMapProvider(),
        )));
        final tf = fieldByLabel(tester, label);

        expect(tf.autofillHints, isNotNull, reason: kHintReason);
        expect(tf.autofillHints!.first, hint);
        expect(tf.keyboardType, keyboard, reason: kKeyboardReason);
      });
    }

    testWidgets('postal code capitalizes — K1A 0B1 must not become k1a 0b1',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenAddressInput(
        provider: NoOpMapProvider(),
      )));
      expect(
        fieldByLabel(tester, 'Postal code').textCapitalization,
        TextCapitalization.characters,
      );
    });

    testWidgets('the five hints are all DISTINCT', (tester) async {
      await tester.pumpWidget(wrap(const EdenAddressInput(
        provider: NoOpMapProvider(),
      )));
      final firsts = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((tf) => tf.autofillHints?.first)
          .toList();

      expect(firsts, hasLength(5));
      expect(
        firsts.toSet(),
        hasLength(5),
        reason: 'Two address fields sharing a hint would emit duplicate DOM '
            'ids (text_editing.dart:514-531) and a password manager would fill '
            'the same value into both.',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // EdenSecretField — currentPassword, WITHOUT regressing clipboard posture
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenSecretField — EdenFieldPurpose.currentPassword', () {
    testWidgets('obscured AND carries a password-family hint', (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
      )));
      final tf = soleField(tester);

      expect(tf.obscureText, isTrue);
      expect(tf.autofillHints, isNotNull, reason: kHintReason);
      expect(
        tf.autofillHints!.first.toLowerCase().contains('password'),
        isTrue,
        reason: 'Web derives DOM type="password" from the HINT STRING, never '
            'from obscureText (text_editing.dart:514-531). An obscured field '
            'without a password-family hint renders as type="text" — the '
            'secret sits in the DOM as plaintext and 1Password can neither '
            'fill nor save it.',
      );
      expect(tf.keyboardType, TextInputType.text, reason: kKeyboardReason);
      expect(tf.autocorrect, isFalse);
      expect(tf.enableSuggestions, isFalse);
    });

    testWidgets('the reveal toggle still un-obscures — the purpose did NOT '
        'freeze obscureText to a constant', (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
      )));

      expect(soleField(tester).obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(
        soleField(tester).obscureText,
        isFalse,
        reason: 'currentPassword.semantics.obscureText is a constant `true`. '
            'It is deliberately NOT forwarded here, because this widget owns '
            'obscuring via its reveal toggle. The hint — not obscureText — is '
            'what buys the DOM password type.',
      );
      // Still hinted after the toggle: the security property is hint-borne.
      expect(
        soleField(tester).autofillHints!.first.toLowerCase().contains('password'),
        isTrue,
      );
    });

    testWidgets('classified mode STILL suppresses copy after the purpose lands',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.cuiSecret,
        onCopy: null,
        clipboardMode: EdenSecretClipboardMode.classified,
      )));

      // MANDATORY: copyEnabled is `!obscureText && !selection.isCollapsed`.
      // Without a real selection this assertion is VACUOUS — it would pass for
      // every field, obscured or not (Appendix A).
      final controller = soleField(tester).controller!;
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 13);
      await tester.pump();

      final state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(
        state.textEditingValue.selection.isCollapsed,
        isFalse,
        reason: 'Guard for the guard: if the selection is collapsed the '
            'copyEnabled assertion below proves nothing.',
      );
      expect(
        state.copyEnabled,
        isFalse,
        reason: 'obscureText: true HARD-DISABLES copy and cut '
            '(editable_text.dart:2641-2646). That is exactly why the standard '
            'mode carries an explicit copy button.',
      );
      expect(state.cutEnabled, isFalse);
    });

    testWidgets('classified mode still announces the disabled affordance',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenSecretField(
        value: EdenSecretFieldFixtures.cuiSecret,
        onCopy: null,
        clipboardMode: EdenSecretClipboardMode.classified,
      )));

      expect(find.byTooltip('Classified — copy disabled'), findsOneWidget);
      expect(
        find.byIcon(Icons.copy),
        findsNothing,
        reason: 'The DoD CUI posture: no copy affordance at all.',
      );
    });

    testWidgets('standard mode keeps its explicit copy button', (tester) async {
      var copied = false;
      await tester.pumpWidget(wrap(EdenSecretField(
        value: EdenSecretFieldFixtures.initialApiKey,
        onCopy: () => copied = true,
      )));

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      expect(
        copied,
        isTrue,
        reason: 'obscureText hard-disables the framework copy path, so this '
            'button is the ONLY route to the clipboard. Removing it would be a '
            'regression, not a simplification.',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // EdenMessageInput — multilineText
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenMessageInput — EdenFieldPurpose.multilineText', () {
    testWidgets('multiline keyboard + newline action, no hints',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMessageInput()));
      final tf = soleField(tester);

      expect(
        hintsOf(tf),
        isEmpty,
        reason: 'There is no autofill token for free-form prose.',
      );
      expect(tf.keyboardType, TextInputType.multiline, reason: kKeyboardReason);
      expect(
        tf.textInputAction,
        TextInputAction.newline,
        reason: 'A chat composer wants Enter to insert a newline. This is why '
            'the composer is multilineText and not `none`.',
      );
      expect(tf.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('Enter is not a submit path; the send button still is',
        (tester) async {
      String? sent;
      await tester.pumpWidget(wrap(EdenMessageInput(
        onSubmit: (v) => sent = v,
      )));

      expect(
        soleField(tester).onSubmitted,
        isNull,
        reason: 'The composer never wired Enter to submit, so resolving '
            'TextInputAction.newline preserves behaviour rather than changing '
            'it.',
      );

      await tester.enterText(find.byType(TextField), 'ready to roll');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sent, 'ready to roll');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Explicit `none` — the decision must be APPLIED, not merely commented
  // ───────────────────────────────────────────────────────────────────────────
  group('explicit EdenFieldPurpose.none fields carry no hints', () {
    testWidgets('EdenMemorableDate — all three M/D/Y components', (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate(monthAsText: true)));

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.length, 3);

      for (final tf in fields) {
        expect(
          hintsOf(tf),
          isEmpty,
          reason: 'AutofillHints.birthday denotes the WHOLE date. Claiming it '
              'on a 2-digit component would be false, and would give all three '
              'DOM elements the same id (text_editing.dart:514-531).',
        );
      }
    });

    testWidgets('EdenMemorableDate keeps the numeric keypad it always had',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMemorableDate(monthAsText: true)));

      for (final hint in const ['MM', 'DD', 'YYYY']) {
        expect(
          fieldByHint(tester, hint).keyboardType,
          TextInputType.number,
          reason: 'none.semantics resolves TextInputType.text, which is why '
              'these fields use a marker comment (shape C) instead of a '
              'semantics spread — spreading it would regress the keypad.',
        );
      }
    });

    testWidgets('EdenCombobox — the type-ahead filter', (tester) async {
      await tester.pumpWidget(wrap(const EdenCombobox<String>(
        options: [
          EdenComboboxOption(value: 'a', label: 'Alpha'),
          EdenComboboxOption(value: 'b', label: 'Bravo'),
        ],
        hint: 'Pick one',
      )));

      expect(
        hintsOf(soleField(tester)),
        isEmpty,
        reason: 'The text typed here is a query against a fixed option list, '
            'never a value a password manager could supply.',
      );
    });

    testWidgets('EdenMultiSelect — the in-overlay filter', (tester) async {
      await tester.pumpWidget(wrap(const EdenMultiSelect<String>(
        options: [
          EdenMultiSelectOption(value: 'a', label: 'Alpha'),
          EdenMultiSelectOption(value: 'b', label: 'Bravo'),
        ],
        hint: 'Pick options',
      )));

      await tester.tap(find.text('Pick options'));
      await tester.pumpAndSettle();

      final search = fieldByHint(tester, 'Search...');
      expect(hintsOf(search), isEmpty);
      expect(
        search.textInputAction,
        isNot(TextInputAction.search),
        reason: 'Deliberately NOT searchQuery: there is nothing to submit, so '
            'a search action key would be misleading.',
      );

      // Close the overlay before teardown. EdenMultiSelect.dispose() calls
      // _removeOverlay(), which calls setState() on a defunct element when the
      // overlay is still open — a PRE-EXISTING widget defect, unrelated to this
      // sweep and deliberately not fixed here (purpose assignment only).
      //
      // The overlay installs a full-screen Positioned.fill tap-outside barrier
      // in front of the trigger, so tap it at the top-left corner rather than
      // hunting the trigger through the barrier.
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Search...',
        ),
        findsNothing,
        reason: 'The overlay must really be closed, not merely assumed closed: '
            'disposing EdenMultiSelect with it open trips a setState-after-'
            'dispose assertion and would fail this test at teardown.',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // EdenSchemaForm — purpose declared once per SCHEMA
  // ───────────────────────────────────────────────────────────────────────────
  group('EdenSchemaForm — schema-declared purposes', () {
    Widget form(
      List<EdenSchemaField> schema, {
      Map<String, dynamic> values = const {},
      Set<String> locked = const {},
    }) =>
        wrap(EdenSchemaForm(
          schema: schema,
          initialValues: values,
          onChanged: (_, __) {},
          onMediaPickRequest: (_) {},
          lockedFieldKeys: locked,
        ));

    testWidgets('a declared purpose wins — text + email resolves BOTH halves',
        (tester) async {
      await tester.pumpWidget(form(const [
        EdenSchemaField(
          key: 'email',
          label: 'Work email',
          type: EdenSchemaFieldType.text,
          purpose: EdenFieldPurpose.email,
        ),
      ]));
      final tf = fieldByHint(tester, 'Work email');

      expect(tf.autofillHints, isNotNull, reason: kHintReason);
      expect(tf.autofillHints!.first, AutofillHints.email);
      expect(
        tf.keyboardType,
        TextInputType.emailAddress,
        reason: 'AutofillHints.email works ONLY with '
            'TextInputType.emailAddress. $kKeyboardReason',
      );
    });

    testWidgets('an undeclared text field stays `none` — no invented claim',
        (tester) async {
      await tester.pumpWidget(form(const [
        EdenSchemaField(
          key: 'title',
          label: 'Title',
          type: EdenSchemaFieldType.text,
        ),
      ]));
      final tf = fieldByHint(tester, 'Title');

      expect(hintsOf(tf), isEmpty);
      expect(
        tf.textCapitalization,
        TextCapitalization.none,
        reason: 'The `none` branch forwards Flutter defaults, so an unpurposed '
            'schema renders byte-identically to before the sweep.',
      );
    });

    testWidgets('number falls back to quantity — keeps its number keyboard',
        (tester) async {
      await tester.pumpWidget(form(const [
        EdenSchemaField(
          key: 'qty',
          label: 'Quantity',
          type: EdenSchemaFieldType.number,
        ),
      ]));
      final tf = fieldByHint(tester, 'Quantity');

      expect(
        tf.keyboardType,
        TextInputType.number,
        reason: 'Leaving `purpose` unset must never downgrade a keyboard this '
            'field type already had.',
      );
      expect(
        hintsOf(tf),
        isEmpty,
        reason: 'A quantity is typed, not filled.',
      );
    });

    testWidgets('mediaUrl falls back to url and stays copyable',
        (tester) async {
      await tester.pumpWidget(form(const [
        EdenSchemaField(
          key: 'hero',
          label: 'Hero image',
          type: EdenSchemaFieldType.mediaUrl,
        ),
      ]));
      final tf = fieldByHint(tester, 'No image selected');

      expect(tf.keyboardType, TextInputType.url, reason: kKeyboardReason);
      expect(hintsOf(tf), isEmpty);
      expect(tf.readOnly, isTrue);
      expect(
        tf.enableInteractiveSelection,
        isNot(false),
        reason: 'Appendix A probe 3: readOnly (not obscured) keeps '
            'copyEnabled == true. Disabling selection here would REMOVE '
            'working copy support.',
      );
    });

    testWidgets('a locked text field keeps the schema purpose', (tester) async {
      await tester.pumpWidget(form(
        const [
          EdenSchemaField(
            key: 'email',
            label: 'Work email',
            type: EdenSchemaFieldType.text,
            purpose: EdenFieldPurpose.email,
          ),
        ],
        locked: const {'email'},
      ));
      final tf = fieldByHint(tester, 'Work email');

      expect(tf.readOnly, isTrue);
      expect(tf.autofillHints!.first, AutofillHints.email);
      expect(tf.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('a read-only locked field is still copyable', (tester) async {
      await tester.pumpWidget(form(
        const [
          EdenSchemaField(
            key: 'slug',
            label: 'Slug',
            type: EdenSchemaFieldType.text,
          ),
        ],
        values: const {'slug': 'field-manual'},
        locked: const {'slug'},
      ));

      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller!;
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.pump();

      final state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.textEditingValue.selection.isCollapsed, isFalse);
      expect(
        state.copyEnabled,
        isTrue,
        reason: 'Appendix A probe 3 — readOnly and not obscured stays '
            'copyable. This is the regression the sweep must NOT introduce.',
      );
    });

    testWidgets('repeater rows are `none`, NOT the parent purpose',
        (tester) async {
      await tester.pumpWidget(form(
        const [
          EdenSchemaField(
            key: 'aliases',
            label: 'Alias',
            type: EdenSchemaFieldType.repeater,
            purpose: EdenFieldPurpose.email,
          ),
        ],
        values: const {
          'aliases': [
            {'value': 'one@example.com'},
            {'value': 'two@example.com'},
          ],
        },
      ));

      final rows = tester.widgetList<TextField>(find.byType(TextField));
      expect(rows.length, 2);
      for (final tf in rows) {
        expect(
          hintsOf(tf),
          isEmpty,
          reason: 'N rows sharing one hint would emit N DOM elements with the '
              'same id/name (text_editing.dart:514-531), and a password '
              'manager filling every row with the same value is worse than '
              'filling none.',
        );
      }
    });
  });
}

// Do NOT regenerate via LLM — hand-built tests for the TRD 40-14 purpose sweep
// (builders, editors & config: the three template-builder panels, the checklist
// builder, the env editor, the branch/label pickers, and the two long-form
// editors).
//
// What these tests are for. Most of a purpose sweep is semantically invisible at
// runtime, so the only assertions worth writing are the ones that would fail if
// the decision were silently undone:
//
//  * For a field assigned `EdenFieldPurpose.none`, that it really carries NO
//    autofill identity — proving the decision was applied, not merely commented.
//  * For the two `multilineText` fields, that the purpose resolved BOTH halves
//    (hints AND keyboardType) and that Enter still inserts a newline.
//  * For the env-var VALUE field, that no password-family hint was ever claimed,
//    and that its clipboard posture is unchanged.
//
// ⚠ B6 (40-RESEARCH.md): `TextField.autofillHints` defaults to `const <String>[]`,
// NOT null. Asserting `== null` fails on correctly-unpurposed fields; asserting
// `!= null` passes on fields carrying no hints at all. Every check below asserts
// EMPTINESS in both directions via [expectNoAutofillIdentity].
//
// ⚠ Appendix A (40-RESEARCH.md): `copyEnabled` is
// `!obscureText && !selection.isCollapsed`, so the clipboard cases set a
// non-collapsed selection first. Without it they would pass vacuously.
// `pasteEnabled` is never asserted — it is false in the test environment
// regardless of configuration.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget wrap(Widget child, {double width = 420, double height = 700}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }

  Finder fieldWithHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
        description: 'TextField(decoration.hintText == "$hint")',
      );

  /// B6: "no autofill identity" is `null` OR empty — never one or the other.
  void expectNoAutofillIdentity(Iterable<String>? hints, {required String why}) {
    expect(
      hints == null || hints.isEmpty,
      isTrue,
      reason: '$why — expected no autofill identity, got $hints. '
          'B6: TextField.autofillHints defaults to const <String>[], not null, '
          'so this asserts emptiness in both directions.',
    );
  }

  TextField fieldOf(WidgetTester tester, Finder f) =>
      tester.widget<TextField>(f);

  // ── eden_template_variables_panel.dart ─────────────────────────────────────

  group('EdenTemplateVariablesPanel — variable filter is none', () {
    setUp(() => EdenTemplateVariablesRegistry.instance.reset());
    tearDown(() => EdenTemplateVariablesRegistry.instance.reset());

    Future<void> pumpPanel(WidgetTester tester) async {
      EdenTemplateVariablesRegistry.instance
        ..register('customer', const ['name', 'email'])
        ..register('company', const ['name']);
      await tester.pumpWidget(wrap(
        EdenTemplateVariablesPanel(onInsertField: (_) {}),
      ));
    }

    testWidgets('carries no autofill identity', (tester) async {
      await pumpPanel(tester);
      final field = fieldOf(tester, fieldWithHint('Search fields…'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'The variables filter is an incremental query over the '
            'already-loaded registry, not a value a password manager holds',
      );
    });

    testWidgets('keeps the plain text keyboard', (tester) async {
      await pumpPanel(tester);
      final field = fieldOf(tester, fieldWithHint('Search fields…'));
      expect(field.keyboardType, TextInputType.text);
    });

    testWidgets('still filters the registry', (tester) async {
      await pumpPanel(tester);
      await tester.enterText(fieldWithHint('Search fields…'), 'email');
      await tester.pump();
      expect(find.text('{{customer.email}}'), findsOneWidget);
      expect(find.text('{{customer.name}}'), findsNothing);
    });
  });

  // ── eden_template_styles_panel.dart ────────────────────────────────────────

  group('EdenTemplateStylesPanel — font-size value is none', () {
    testWidgets('every numeric field carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTemplateStylesPanel(onChangeStyle: (_) {}),
      ));
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty,
          reason: 'the styles panel must render its numeric fields');
      for (final field in fields) {
        expectNoAutofillIdentity(
          field.autofillHints,
          why: 'A font-size style value is authoring content',
        );
      }
    });

    testWidgets('keeps the decimal keyboard `none` must not clobber',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTemplateStylesPanel(onChangeStyle: (_) {}),
      ));
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in fields) {
        expect(
          field.keyboardType,
          const TextInputType.numberWithOptions(decimal: true),
          reason: 'Shape C keeps the widget\'s own keyboard. Spreading '
              'none.semantics here would substitute TextInputType.text and '
              'make a font size awkward to type on mobile.',
        );
      }
    });
  });

  // ── eden_template_layout_panel.dart ────────────────────────────────────────

  group('EdenTemplateLayoutPanel — margin value is none', () {
    testWidgets('every margin field carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTemplateLayoutPanel(onChangeLayout: (_) {}),
      ));
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty,
          reason: 'the layout panel must render its margin fields');
      for (final field in fields) {
        expectNoAutofillIdentity(
          field.autofillHints,
          why: 'A page margin is a measurement the user is authoring',
        );
      }
    });

    testWidgets('keeps the decimal keyboard `none` must not clobber',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTemplateLayoutPanel(onChangeLayout: (_) {}),
      ));
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in fields) {
        expect(
          field.keyboardType,
          const TextInputType.numberWithOptions(decimal: true),
        );
      }
    });
  });

  // ── eden_checklist_builder.dart ────────────────────────────────────────────

  group('EdenChecklistBuilder — note and new-item rows are none', () {
    testWidgets('the per-item note row carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenChecklistBuilder(
          items: [
            EdenChecklistItem(id: 'a', title: 'First', note: 'a note'),
          ],
        ),
      ));
      final field = fieldOf(tester, fieldWithHint('Add a note...'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'A note row is rendered once per checklist item; N rows sharing '
            'one hint would emit N duplicate DOM ids '
            '(text_editing.dart:514-531)',
      );
    });

    testWidgets('the note row keeps maxLines 2 and its multiline keyboard',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenChecklistBuilder(
          items: [
            EdenChecklistItem(id: 'a', title: 'First', note: 'a note'),
          ],
        ),
      ));
      final field = fieldOf(tester, fieldWithHint('Add a note...'));
      expect(field.maxLines, 2);
      expect(
        field.keyboardType,
        TextInputType.multiline,
        reason: 'maxLines != 1 already resolves multiline in TextField\'s own '
            'initializer (text_field.dart:355) — the `none` marker did not '
            'take that away.',
      );
    });

    testWidgets('a repeated note row never shares a hint with its siblings',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenChecklistBuilder(
          items: [
            EdenChecklistItem(id: 'a', title: 'First', note: 'one'),
            EdenChecklistItem(id: 'b', title: 'Second', note: 'two'),
            EdenChecklistItem(id: 'c', title: 'Third', note: 'three'),
          ],
        ),
      ));
      final notes = tester.widgetList<TextField>(fieldWithHint('Add a note...'));
      expect(notes.length, 3, reason: 'three items, three note rows');
      for (final field in notes) {
        expectNoAutofillIdentity(
          field.autofillHints,
          why: 'B7 — repeated rows must not share an autofill hint',
        );
      }
    });

    testWidgets('the new-item field carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenChecklistBuilder(
          items: [EdenChecklistItem(id: 'a', title: 'First')],
        ),
      ));
      await tester.tap(find.text('Add item'));
      await tester.pump();
      final field = fieldOf(tester, fieldWithHint('New item...'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'New checklist item text is authoring content',
      );
    });
  });

  // ── eden_env_editor.dart ───────────────────────────────────────────────────

  group('EdenEnvEditor — key and value are none', () {
    const entries = <EdenEnvEntry>[
      EdenEnvEntry(key: 'DATABASE_URL', value: 'postgres://localhost/app'),
      EdenEnvEntry(key: 'API_TOKEN', value: 'sk-live-abcdef'),
    ];

    testWidgets('every key field carries no autofill identity', (tester) async {
      await tester.pumpWidget(wrap(const EdenEnvEditor(entries: entries)));
      final keys = tester.widgetList<TextField>(fieldWithHint('KEY'));
      expect(keys.length, 2);
      for (final field in keys) {
        expectNoAutofillIdentity(
          field.autofillHints,
          why: 'An env key is a config identifier, and one row per entry means '
              'a shared hint would emit duplicate DOM ids',
        );
      }
    });

    testWidgets('every value field carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenEnvEditor(entries: entries)));
      final values = tester.widgetList<TextField>(fieldWithHint('value'));
      expect(values.length, 2);
      for (final field in values) {
        expectNoAutofillIdentity(
          field.autofillHints,
          why: 'An env value must never be claimed as a credential',
        );
      }
    });

    testWidgets('no value field ever claims a password-family hint',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenEnvEditor(entries: entries)));
      final values = tester.widgetList<TextField>(fieldWithHint('value'));
      for (final field in values) {
        final hints = field.autofillHints ?? const <String>[];
        for (final hint in hints) {
          expect(
            hint.toLowerCase().contains('password'),
            isFalse,
            reason: 'A password-family hint here would make a password manager '
                'offer the user\'s saved LOGIN credentials for an unrelated '
                'config value, and offer to save this one as a login. '
                'B2: match case-insensitively — AutofillHints.newPassword is '
                'camelCase.',
          );
        }
      }
    });

    testWidgets('values stay obscured until revealed', (tester) async {
      await tester.pumpWidget(wrap(const EdenEnvEditor(entries: entries)));
      final values = tester.widgetList<TextField>(fieldWithHint('value'));
      for (final field in values) {
        expect(field.obscureText, isTrue,
            reason: 'the sweep must not change the masking posture');
      }
    });

    testWidgets(
        'copy is framework-disabled while obscured and restored on reveal',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenEnvEditor(entries: entries)));

      Finder firstValueEditable() => find
          .descendant(
            of: fieldWithHint('value').first,
            matching: find.byType(EditableText),
          )
          .first;

      // ⚠ Appendix A: copyEnabled is `!obscureText && !selection.isCollapsed`.
      // Without a NON-COLLAPSED selection this case passes vacuously.
      void select(int extent) {
        tester.widget<EditableText>(firstValueEditable()).controller.selection =
            TextSelection(baseOffset: 0, extentOffset: extent);
      }

      select(8);
      await tester.pump();
      var state = tester.state<EditableTextState>(firstValueEditable());
      expect(state.textEditingValue.selection.isCollapsed, isFalse,
          reason: 'guard: the selection must be real or the next assertion '
              'proves nothing');
      expect(state.copyEnabled, isFalse,
          reason: 'obscureText: true hard-disables copy and cut '
              '(editable_text.dart:2641-2646)');

      await tester.tap(find.byTooltip('Reveal value').first);
      await tester.pump();

      select(8);
      await tester.pump();
      state = tester.state<EditableTextState>(firstValueEditable());
      expect(state.textEditingValue.selection.isCollapsed, isFalse);
      expect(state.copyEnabled, isTrue,
          reason: 'revealing the value restores copy — which is why a `none` '
              'purpose is the right call rather than an obscuring one');
    });
  });

  // ── eden_branch_selector.dart ──────────────────────────────────────────────

  group('EdenBranchSelector — filter and create-name are none', () {
    Future<void> openPopover(WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        EdenBranchSelector(
          currentBranch: 'main',
          branches: const [
            EdenBranch(name: 'main', isDefault: true),
            EdenBranch(name: 'feature/autofill'),
          ],
          showCreateBranch: true,
          onCreateBranch: (_) {},
        ),
      ));
      await tester.tap(find.text('main').first);
      await tester.pumpAndSettle();
    }

    testWidgets('the branch filter carries no autofill identity',
        (tester) async {
      await openPopover(tester);
      final field = fieldOf(tester, fieldWithHint('Filter branches/tags...'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'The branch filter is a query over the loaded ref list',
      );
    });

    testWidgets('the create-branch name carries no autofill identity',
        (tester) async {
      await openPopover(tester);
      final field = fieldOf(tester, fieldWithHint('Create branch...'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'A git ref name is a repository identifier, not personal data',
      );
    });

    testWidgets('neither field autocorrects a case-sensitive git ref',
        (tester) async {
      await openPopover(tester);
      for (final hint in const ['Filter branches/tags...', 'Create branch...']) {
        final field = fieldOf(tester, fieldWithHint(hint));
        expect(
          field.textCapitalization,
          TextCapitalization.none,
          reason: 'Shape C leaves Flutter defaults in place. Spreading '
              'none.semantics would sentence-capitalize "$hint".',
        );
      }
    });
  });

  // ── eden_label_picker.dart ─────────────────────────────────────────────────

  group('EdenLabelPicker — filter and new-label name are none', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenLabelPicker.show(
                context,
                labels: const [
                  EdenLabel(id: '1', name: 'bug', color: Color(0xFFEF4444)),
                  EdenLabel(id: '2', name: 'chore', color: Color(0xFF3B82F6)),
                ],
                onDone: (_) {},
                onCreateNew: (_, __) {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('the label filter carries no autofill identity',
        (tester) async {
      await openSheet(tester);
      final field = fieldOf(tester, fieldWithHint('Filter labels...'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'The label filter is a query over the loaded label list',
      );
    });

    testWidgets('the new-label name carries no autofill identity',
        (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Create new'));
      await tester.pumpAndSettle();
      final field = fieldOf(tester, fieldWithHint('Label name'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'A label name is taxonomy the user is composing',
      );
    });
  });

  // ── eden_rich_text_editor.dart ─────────────────────────────────────────────

  group('EdenRichTextEditor — document body is multilineText', () {
    Future<void> pumpEditor(WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenRichTextEditor(placeholder: 'Write the body…'),
      ));
    }

    testWidgets('resolves the multiline keyboard from the purpose',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write the body…'));
      expect(
        field.keyboardType,
        EdenFieldPurpose.multilineText.semantics.keyboardType,
      );
      expect(field.keyboardType, TextInputType.multiline);
    });

    testWidgets('emits no autofill hints, because prose has no purpose',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write the body…'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'multilineText is typed but deliberately unfilled — there is no '
            'AutofillHints constant for free prose',
      );
    });

    testWidgets('resolves newline, not next, as the Enter action',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write the body…'));
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.textCapitalization, TextCapitalization.sentences);
      expect(field.obscureText, isFalse);
    });

    testWidgets('the purpose resolves the keyboard, NOT the line count',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write the body…'));
      expect(field.maxLines, isNull,
          reason: 'maxLines and expands are the caller\'s business');
      expect(field.expands, isTrue);
    });

    testWidgets('Enter keeps focus instead of moving it', (tester) async {
      await pumpEditor(tester);
      await tester.tap(fieldWithHint('Write the body…'));
      await tester.pump();
      final state = tester.state<EditableTextState>(
        find.descendant(
          of: fieldWithHint('Write the body…'),
          matching: find.byType(EditableText),
        ),
      );
      expect(state.widget.focusNode.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      await tester.pump();
      expect(state.widget.focusNode.hasFocus, isTrue,
          reason: 'a multiline field swallows the newline action; a single-line '
              'one would finalize editing and unfocus');
    });
  });

  // ── eden_markdown_editor.dart ──────────────────────────────────────────────

  group('EdenMarkdownEditor — document body is multilineText', () {
    Future<void> pumpEditor(WidgetTester tester) async {
      await tester.pumpWidget(wrap(const EdenMarkdownEditor()));
    }

    testWidgets('resolves the multiline keyboard from the purpose',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write something...'));
      expect(
        field.keyboardType,
        EdenFieldPurpose.multilineText.semantics.keyboardType,
      );
      expect(field.keyboardType, TextInputType.multiline);
    });

    testWidgets('emits no autofill hints, because prose has no purpose',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write something...'));
      expectNoAutofillIdentity(
        field.autofillHints,
        why: 'multilineText is typed but deliberately unfilled',
      );
    });

    testWidgets('resolves newline, not next, as the Enter action',
        (tester) async {
      await pumpEditor(tester);
      final field = fieldOf(tester, fieldWithHint('Write something...'));
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.textCapitalization, TextCapitalization.sentences);
      expect(field.obscureText, isFalse);
    });

    testWidgets('the purpose resolves the keyboard, NOT the line count',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMarkdownEditor(minLines: 5, maxLines: 9),
      ));
      final field = fieldOf(tester, fieldWithHint('Write something...'));
      expect(field.minLines, 5);
      expect(field.maxLines, 9);
    });

    testWidgets('Enter keeps focus instead of moving it', (tester) async {
      await pumpEditor(tester);
      await tester.tap(fieldWithHint('Write something...'));
      await tester.pump();
      final state = tester.state<EditableTextState>(
        find.descendant(
          of: fieldWithHint('Write something...'),
          matching: find.byType(EditableText),
        ),
      );
      expect(state.widget.focusNode.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      await tester.pump();
      expect(state.widget.focusNode.hasFocus, isTrue,
          reason: 'a multiline field swallows the newline action');
    });
  });
}

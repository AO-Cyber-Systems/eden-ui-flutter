// TRD 40-13 -- process & workflow canvas purpose sweep (11 widgets, 23 field
// sites).
//
// Every field in this TRD's files carries an EXPLICIT EdenFieldPurpose. Almost
// all of them are `none`, and that is the finding, not a shortfall: node names,
// task titles, phase labels, conditions, delays and action config are AUTHORING
// content in a process/workflow definition, not the editing user's own data.
// A password manager has nothing to offer them, and a hint would be a false
// identity that pollutes the DOM `autocomplete` attribute.
//
// Three traps this file is written around:
//
//   1. `_inferKeyboardType` is UNREACHABLE through TextField
//      (material/text_field.dart:355 resolves `keyboardType` in the
//      constructor's initializer list). A field carrying `autofillHints` but no
//      explicit `keyboardType` still resolves to TextInputType.text, so every
//      purposed case below asserts BOTH halves -- hints alone prove nothing.
//
//   2. `TextField.autofillHints` defaults to `const <String>[]`, NOT null
//      (40-RESEARCH.md Appendix B6). Asserting nullness would fail on a
//      correctly-unpurposed field; asserting non-nullness would certify an
//      unpurposed one. Every "no identity" case therefore asserts EMPTINESS.
//
//   3. `copyEnabled` is `!obscureText && !selection.isCollapsed`
//      (editable_text.dart:2641-2646). The clipboard case sets a NON-COLLAPSED
//      selection first; without it the assertion passes for every field,
//      obscured or not, and proves nothing.
//
// `pasteEnabled` is deliberately never asserted -- it is false in the test
// environment regardless of field configuration.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'eden_process_canvas/_fixtures/eden_process_dialog_fixtures.dart';
import 'eden_process_canvas/_fixtures/eden_process_node_fixtures.dart';
import 'eden_workflow_canvas/_fixtures/eden_workflow_action_fixtures.dart'
    show actionNodeContextFixture;
import 'eden_workflow_canvas/_fixtures/eden_workflow_delay_merge_fixtures.dart'
    show delayNodeContextFixture;
import 'eden_workflow_canvas/_fixtures/eden_workflow_flow_node_fixtures.dart'
    show conditionNodeContextFixture;
import 'eden_workflow_canvas/_fixtures/eden_workflow_node_fixtures.dart'
    show customerNameFieldFixture, wrap;

// -- Wrappers ---------------------------------------------------------------

/// Bounded wrapper for the canvas node widgets, which size themselves against
/// their parent.
Widget wrapNode(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 800, height: 600, child: Center(child: child)),
      ),
    );

// -- Finders ----------------------------------------------------------------
//
// Always by a distinguishing property, never `.at(index)` -- an index-based
// finder silently retargets on the next layout change.

Finder byLabel(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
      description: 'TextField(labelText: "$label")',
    );

Finder byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
      description: 'TextField(hintText: "$hint")',
    );

Finder byMaxLines(int maxLines) => find.byWidgetPredicate(
      (w) => w is TextField && w.maxLines == maxLines,
      description: 'TextField(maxLines: $maxLines)',
    );

TextField one(WidgetTester tester, Finder f) {
  expect(f, findsOneWidget, reason: 'expected exactly one match for $f');
  return tester.widget<TextField>(f);
}

List<TextField> allFields(WidgetTester tester) =>
    tester.widgetList<TextField>(find.byType(TextField)).toList();

// -- Shared expectations ----------------------------------------------------

/// Asserts a field claims NO autofill identity.
///
/// Two legitimate resolved shapes, both meaning "nothing to classify by":
///   * `const <String>[]` -- `none` applied as a marker comment only, so the
///     raw `TextField` keeps its own untouched default (Appendix B6).
///   * `null` -- a purpose was SPREAD onto the widget and that purpose is one of
///     the TYPED-BUT-UNFILLED members (multilineText / quantity / searchQuery),
///     whose `autofillHints` is deliberately null; also what a `TextFormField`
///     resolves to.
///
/// Either way the web engine emits `autocomplete="on"` with no `name` and no
/// `id` (text_editing.dart:514-531) -- no purpose is ever CLAIMED. What must
/// never happen on one of these fields is a populated hint list.
void expectNoAutofillIdentity(TextField f, String why) {
  final Iterable<String>? hints = f.autofillHints;
  expect(hints == null || hints.isEmpty, isTrue,
      reason: '$why -- expected no autofill identity, got: $hints');
}

/// A field that is TYPED but deliberately UNFILLED: it must carry the keyboard
/// its purpose resolves AND no autofill identity. Both halves, always
/// (Appendix B1).
void expectUnfilled(TextField f, TextInputType keyboard, String why) {
  expectNoAutofillIdentity(f, why);
  expect(f.keyboardType, keyboard, reason: why);
}

void main() {
  setUp(() {
    EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
    EdenWorkflowActionRegistry.instance.resetToDefaults();
    EdenWorkflowFieldRegistry.instance.reset();
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  // ======================================================================
  // 1 -- EdenProcessTaskEditorDialog (5 field sites, 4 hook instances)
  // ======================================================================

  group('EdenProcessTaskEditorDialog', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(
          task: taskForEditFixture(),
          onUpdate: (_) {},
        ),
      ));
      await openDialog(tester);
    }

    testWidgets('Name -- none: no autofill identity, plain text keyboard',
        (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Name'));
      expectUnfilled(f, TextInputType.text,
          'a task name is authoring content, not the user\'s own data');
    });

    testWidgets(
        'Description -- multilineText: multiline keyboard + newline action',
        (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Description'));
      expectUnfilled(f, TextInputType.multiline,
          'multilineText resolves a multiline keyboard');
      expect(f.textInputAction, TextInputAction.newline,
          reason: 'multilineText resolves TextInputAction.newline; a '
              'maxLines: 2 field already behaved this way '
              '(editable_text.dart:5181-5186), so Enter still inserts a '
              'newline rather than submitting');
      expect(f.textCapitalization, TextCapitalization.sentences,
          reason: 'prose gets sentence capitalization');
      expect(f.maxLines, 2,
          reason: 'multilineText was chosen BECAUSE maxLines > 1');
    });

    testWidgets('Approval role -- none, NOT jobTitle', (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Approval role'));
      expectUnfilled(f, TextInputType.text,
          'the role that approves this task, not the editor\'s own job title');
    });

    testWidgets('Approval user id -- none, NOT username', (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Approval user id'));
      expectUnfilled(f, TextInputType.text,
          'an opaque id for ANOTHER user; username would offer the editor\'s '
          'own saved login');
    });

    testWidgets(
        'all 4 workflow-hook fields -- none, and each KEEPS its number keyboard',
        (tester) async {
      await open(tester);
      const keys = <String>[
        'hook-onCompleteWorkflowId',
        'hook-onBlockedWorkflowId',
        'hook-onNaWorkflowId',
        'hook-onCantDoWorkflowId',
      ];
      for (final key in keys) {
        final f = tester.widget<TextField>(find.byKey(ValueKey(key)));
        expectUnfilled(f, TextInputType.number,
            '$key: a workflow id is an opaque numeric reference, not a '
            'quantity and not user data -- but the number keyboard is '
            'deliberate and must survive the sweep');
      }
    });

    testWidgets('no field in this dialog is obscured', (tester) async {
      await open(tester);
      final fields = allFields(tester);
      expect(fields.length, 8,
          reason: '2 text + 2 approval + 4 hooks; a change here means the '
              'sweep missed a field');
      expect(fields.where((f) => f.obscureText), isEmpty,
          reason: 'obscureText hard-disables copy and cut '
              '(editable_text.dart:2641-2646) and nothing here is a secret');
    });

    testWidgets('Name stays copyable with a real (non-collapsed) selection',
        (tester) async {
      await open(tester);
      final field = one(tester, byLabel('Name'));
      final controller = field.controller!;
      controller.text = 'Verify access';
      // GOTCHA: copyEnabled is `!obscureText && !selection.isCollapsed`.
      // Without this line the assertion below passes for EVERY field and
      // proves nothing (40-RESEARCH.md Appendix A).
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 13);
      await tester.pump();

      final state = tester.state<EditableTextState>(
        find.descendant(
          of: byLabel('Name'),
          matching: find.byType(EditableText),
        ),
      );
      expect(state.textEditingValue.selection.isCollapsed, isFalse,
          reason: 'guard: the selection must really be non-collapsed, or the '
              'next two assertions are vacuous');
      expect(state.copyEnabled, isTrue);
      expect(state.cutEnabled, isTrue);
    });
  });

  // ======================================================================
  // 2 -- EdenProcessTaskGroupEditorDialog (5 field sites)
  // ======================================================================

  group('EdenProcessTaskGroupEditorDialog', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: groupForEditFixture(),
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
    }

    testWidgets('Name -- none', (tester) async {
      await open(tester);
      expectUnfilled(one(tester, byLabel('Name')), TextInputType.text,
          'a task-group name is authoring content');
    });

    testWidgets('Description -- multilineText', (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Description'));
      expectUnfilled(f, TextInputType.multiline, 'maxLines: 2 prose');
      expect(f.textInputAction, TextInputAction.newline);
      expect(f.maxLines, 2);
    });

    testWidgets('all 3 workflow-hook fields -- none, number keyboard kept',
        (tester) async {
      await open(tester);
      const keys = <String>[
        'hook-onAllCompleteWorkflowId',
        'hook-onItemNaWorkflowId',
        'hook-onItemCantDoWorkflowId',
      ];
      for (final key in keys) {
        final f = tester.widget<TextField>(find.byKey(ValueKey(key)));
        expectUnfilled(f, TextInputType.number,
            '$key: opaque numeric workflow reference');
      }
    });

    testWidgets('no field in this dialog is obscured', (tester) async {
      await open(tester);
      final fields = allFields(tester);
      expect(fields.length, 5, reason: 'name + description + 3 hooks');
      expect(fields.where((f) => f.obscureText), isEmpty);
    });
  });

  // ======================================================================
  // 3 -- EdenProcessPhaseEditorDialog (2 field sites)
  // ======================================================================

  group('EdenProcessPhaseEditorDialog', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phaseForEditFixture(),
          onUpdate: (_) {},
        ),
      ));
      await openDialog(tester);
    }

    testWidgets('Name -- none', (tester) async {
      await open(tester);
      expectUnfilled(one(tester, byLabel('Name')), TextInputType.text,
          'a phase name is authoring content');
    });

    testWidgets('Description -- multilineText', (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Description'));
      expectUnfilled(f, TextInputType.multiline, 'maxLines: 2 prose');
      expect(f.textInputAction, TextInputAction.newline);
      expect(f.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('exactly 2 fields, neither obscured', (tester) async {
      await open(tester);
      final fields = allFields(tester);
      expect(fields.length, 2);
      expect(fields.where((f) => f.obscureText), isEmpty);
    });
  });

  // ======================================================================
  // 4 -- Process canvas nodes (6 field sites)
  //
  // Appendix B7: a canvas renders these nodes N times. `element.name` AND
  // `element.id` are both set from the hint string, so ANY hint here would
  // emit N duplicate DOM ids. `none` is the only correct answer.
  // ======================================================================

  group('EdenProcessTaskNode -- inline rename', () {
    Future<void> enterEditMode(WidgetTester tester) async {
      await tester.pumpWidget(wrapNode(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: taskTemplateFixture(id: 100, groupId: 10,
              displayName: 'Verify')},
        ),
      )));
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
    }

    testWidgets('rename field -- none, no duplicate-id hint (B7)',
        (tester) async {
      await enterEditMode(tester);
      expectUnfilled(one(tester, find.byType(TextField)), TextInputType.text,
          'a task node repeats per task on the canvas');
      expect(one(tester, find.byType(TextField)).obscureText, isFalse);
    });

    testWidgets('Enter still commits the rename after the sweep',
        (tester) async {
      Map<String, dynamic>? updates;
      await tester.pumpWidget(wrapNode(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: taskTemplateFixture(id: 100, groupId: 10,
              displayName: 'Verify')},
          onUpdateTask: (_, u) => updates = u,
        ),
      )));
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Verify ID');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(updates?['displayName'], 'Verify ID',
          reason: 'the inline editor commits on Enter through its own Focus '
              'onKeyEvent handler; leaving the widget config untouched (a '
              'marker-comment `none`) is what preserves that');
    });
  });

  group('EdenProcessPhaseNode -- inline rename', () {
    testWidgets('rename field -- none', (tester) async {
      await tester.pumpWidget(wrapNode(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(
          phasesById: {1: phaseFixture(id: 1, displayName: 'Planning')},
        ),
      )));
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();
      expectUnfilled(one(tester, find.byType(TextField)), TextInputType.text,
          'a phase node repeats per phase on the canvas');
    });
  });

  group('EdenProcessTaskGroupNode -- inline rename', () {
    testWidgets('group-header rename field -- none', (tester) async {
      await tester.pumpWidget(wrapNode(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: taskGroupFixture(displayName: 'Inspection')},
        ),
      )));
      await tester.tap(find.text('Inspection'));
      await tester.pumpAndSettle();
      expectUnfilled(one(tester, find.byType(TextField)), TextInputType.text,
          'a task-group node repeats per group on the canvas');
    });
  });

  group('EdenProcessDecisionNode -- inline edit dialog', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(wrapNode(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {
          1: const EdenProcessDecisionConfig(
              id: 1, name: 'Approve?', condition: 'cost > 5000'),
        }),
      )));
      await tester.tap(find.text('Approve?'));
      await tester.pumpAndSettle();
    }

    testWidgets('Decision Name -- none', (tester) async {
      await open(tester);
      expectUnfilled(one(tester, byLabel('Decision Name')), TextInputType.text,
          'a decision name is authoring content, and the node repeats (B7)');
    });

    testWidgets(
        'Condition -- none AND autocorrect/suggestions forced OFF',
        (tester) async {
      await open(tester);
      final f = one(tester, byLabel('Condition (optional)'));
      expectUnfilled(f, TextInputType.text, 'a boolean expression');
      expect(f.autocorrect, isFalse,
          reason: 'an autocorrected expression silently changes the process '
              'branching logic; EdenFieldPurpose.none leaves autocorrect ON, '
              'so it is set explicitly here');
      expect(f.enableSuggestions, isFalse,
          reason: 'same rationale as autocorrect');
    });

    testWidgets('the name field keeps autocorrect ON -- only the expression '
        'box is hardened', (tester) async {
      await open(tester);
      // Appendix B3: `TextField.autocorrect` is `bool?` on 3.41.4 (null means
      // "infer"), though it is a non-nullable `bool` at the declared >=3.27.0
      // floor. So the untouched field reads back as null here, and the honest
      // assertion is "not explicitly disabled" rather than "== true".
      expect(one(tester, byLabel('Decision Name')).autocorrect, isNot(false),
          reason: 'guard: proves the autocorrect:false above is a targeted '
              'decision on the expression box, not a blanket default');
    });
  });

  // ======================================================================
  // 5 -- Workflow canvas nodes (5 field sites)
  // ======================================================================

  group('EdenConditionNode -- popover editor', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(context: conditionNodeContextFixture())),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
    }

    testWidgets('Field box -- none, autocorrect + suggestions OFF',
        (tester) async {
      await open(tester);
      final f = one(tester, byHint('e.g. priority, status, amount'));
      expectUnfilled(f, TextInputType.text,
          'the name of a record field being tested, an expression fragment');
      expect(f.autocorrect, isFalse);
      expect(f.enableSuggestions, isFalse);
    });

    testWidgets('Value box -- none, autocorrect + suggestions OFF',
        (tester) async {
      await open(tester);
      final f = one(tester, byHint('e.g. high, completed, 5000'));
      expectUnfilled(f, TextInputType.text,
          'the literal compared against; its type varies per condition so no '
          'single keyboard or hint is correct');
      expect(f.autocorrect, isFalse);
      expect(f.enableSuggestions, isFalse);
    });

    testWidgets('neither field is obscured', (tester) async {
      await open(tester);
      final fields = allFields(tester);
      expect(fields.length, 2);
      expect(fields.where((f) => f.obscureText), isEmpty);
    });
  });

  group('EdenWorkflowEventBrowser -- search box', () {
    Future<void> open(WidgetTester tester) async {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(onFieldSelected: (_) {})),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('searchQuery -- text keyboard + search action, no identity',
        (tester) async {
      await open(tester);
      final f = one(tester, byHint('Search fields...'));
      expectUnfilled(f, TextInputType.text,
          'searchQuery is typed but deliberately unfilled -- there is no '
          'AutofillHints constant for a search query and inventing one would '
          'emit an invalid autocomplete token');
      expect(f.textInputAction, TextInputAction.search,
          reason: 'the on-screen action key becomes Search; '
              '_finalizeEditing treats search exactly like done '
              '(editable_text.dart:3771-3783), so behaviour is unchanged');
    });

    testWidgets('typing still filters the registry after the sweep',
        (tester) async {
      await open(tester);
      await tester.enterText(byHint('Search fields...'), 'zzz-no-match');
      await tester.pumpAndSettle();
      expect(find.text('APPOINTMENT'), findsNothing,
          reason: 'the live onChanged filter must survive the purpose spread');
    });
  });

  group('EdenDelayNode -- popover editor', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(context: delayNodeContextFixture(minutes: 30))),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
    }

    testWidgets('Minutes -- quantity: number keyboard, no autofill identity',
        (tester) async {
      await open(tester);
      final f = one(tester, find.byType(TextField));
      expectUnfilled(f, TextInputType.number,
          'a whole number of minutes, parsed with int.tryParse');
      expect(f.obscureText, isFalse);
    });

    testWidgets('Save still parses the typed minutes after the sweep',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 30),
          config: EdenDelayNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '45');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.single['delayMinutes'], 45,
          reason: 'the quantity spread must not disturb the parse path');
    });
  });

  group('EdenActionNode -- dynamic config fields', () {
    Future<void> open(WidgetTester tester, {String actionType = 'create_task'}) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(actionType: actionType),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
    }

    testWidgets('text spec -- none, and the text keyboard is preserved',
        (tester) async {
      await open(tester);
      final f = one(tester, byMaxLines(1));
      expectUnfilled(f, TextInputType.text,
          'an action config value whose meaning is decided at runtime by '
          'spec.type; no single hint is true for all of them');
    });

    testWidgets('textarea spec -- none, and the multiline keyboard is preserved',
        (tester) async {
      await open(tester);
      final f = one(tester, byMaxLines(3));
      expectUnfilled(f, TextInputType.multiline,
          'the keyboard is derived from spec.type and must survive the sweep');
    });

    testWidgets('number spec -- none, and the number keyboard is preserved',
        (tester) async {
      EdenWorkflowActionRegistry.instance.register(
        const EdenWorkflowActionType(
          id: 'charge_fee',
          displayName: 'Charge Fee',
          icon: Icons.attach_money,
          fields: [
            EdenWorkflowActionFieldSpec(
              id: 'attempts',
              label: 'Retry attempts',
              type: 'number',
            ),
          ],
        ),
      );
      await open(tester, actionType: 'charge_fee');
      final f = one(tester, find.byType(TextField));
      expectUnfilled(f, TextInputType.number,
          'a number spec keeps its number keyboard; the marker-comment `none` '
          'leaves the widget config byte-identical');
    });

    testWidgets('editing a config field still updates the captured config',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(byMaxLines(1), 'Call the customer');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        (captures.single['config'] as Map<String, dynamic>)['title'],
        'Call the customer',
      );
    });
  });

  // ======================================================================
  // 6 -- Sweep-wide invariant
  // ======================================================================

  group('sweep-wide', () {
    test('every purpose used by TRD 40-13 emits NO autofill hints', () {
      const used = <EdenFieldPurpose>[
        EdenFieldPurpose.none,
        EdenFieldPurpose.multilineText,
        EdenFieldPurpose.quantity,
        EdenFieldPurpose.searchQuery,
      ];
      for (final p in used) {
        expect(p.semantics.autofillHints, isNull,
            reason: '$p must claim no identity -- this sweep is authoring '
                'content only, and a hint on a repeated canvas node would '
                'emit duplicate DOM name/id attributes (Appendix B7)');
        expect(p.semantics.obscureText, isFalse,
            reason: '$p must not obscure -- obscureText hard-disables copy '
                'and cut (editable_text.dart:2641-2646)');
      }
    });

    test('the keyboards this sweep relies on are what the enum resolves', () {
      expect(EdenFieldPurpose.none.semantics.keyboardType, TextInputType.text);
      expect(EdenFieldPurpose.multilineText.semantics.keyboardType,
          TextInputType.multiline);
      expect(EdenFieldPurpose.quantity.semantics.keyboardType,
          TextInputType.number);
      expect(EdenFieldPurpose.searchQuery.semantics.keyboardType,
          TextInputType.text);
      expect(EdenFieldPurpose.multilineText.semantics.textInputAction,
          TextInputAction.newline);
      expect(EdenFieldPurpose.searchQuery.semantics.textInputAction,
          TextInputAction.search);
    });
  });
}

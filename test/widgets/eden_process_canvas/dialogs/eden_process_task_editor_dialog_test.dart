import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_process_dialog_fixtures.dart';

void main() {
  setUp(() {
    EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('EdenProcessTaskEditorDialog', () {
    testWidgets('renders Dialog with title "Edit Task"', (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      expect(find.text('Edit Task'), findsOneWidget);
    });

    testWidgets('Name + Description populated', (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      expect(find.widgetWithText(TextField, 'Verify access'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Confirm the customer signed waiver'),
        findsOneWidget,
      );
    });

    testWidgets('runtime-component dropdown rendered', (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      expect(
        find.byKey(const ValueKey('runtime-component-dropdown')),
        findsOneWidget,
      );
    });

    testWidgets('selecting different runtime component fires onUpdate',
        (tester) async {
      Map<String, dynamic>? updates;
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) =>
            EdenProcessTaskEditorDialog(task: task, onUpdate: (u) => updates = u),
      ));
      await openDialog(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('runtime-component-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('runtime-component-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Form').last);
      await tester.pumpAndSettle();
      expect(updates?['runtimeComponent'], 'form');
    });

    testWidgets('all 9 boolean flag checkboxes rendered', (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      for (final label in [
        'Required',
        'Photo required',
        'Signature required',
        'Approval required',
        'Description required',
        'Attachment required',
        'Allows N/A',
        'Allows blocked',
        'Allows cant-do',
        'Materializes as task',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing label: $label');
      }
    });

    testWidgets('toggling materializesAsTask fires onUpdate with negated value',
        (tester) async {
      Map<String, dynamic>? updates;
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) =>
            EdenProcessTaskEditorDialog(task: task, onUpdate: (u) => updates = u),
      ));
      await openDialog(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('task-checkbox-row-Materializes as task')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-checkbox-row-Materializes as task')));
      await tester.pump();
      expect(updates?['materializesAsTask'], false);
    });

    testWidgets('blockingBehavior dropdown shows 3 default options',
        (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      // Ensure dropdown is in view before tapping.
      await tester.ensureVisible(
        find.byKey(const ValueKey('blocking-behavior-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('blocking-behavior-dropdown')));
      await tester.pumpAndSettle();
      // DropdownButton renders each option twice (in the button + the menu).
      // Without .hitTestable() we'd find both; the menu option is the one
      // we want, found by limiting to findsAtLeastNWidgets.
      expect(find.text('soft'), findsAtLeastNWidgets(1));
      expect(find.text('hard'), findsAtLeastNWidgets(1));
      expect(find.text('none'), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting a different blockingBehavior fires onUpdate',
        (tester) async {
      Map<String, dynamic>? updates;
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) =>
            EdenProcessTaskEditorDialog(task: task, onUpdate: (u) => updates = u),
      ));
      await openDialog(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('blocking-behavior-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('blocking-behavior-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('hard').last);
      await tester.pumpAndSettle();
      expect(updates?['blockingBehavior'], 'hard');
    });

    testWidgets('approvalRole + approvalUserId populated', (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      expect(find.widgetWithText(TextField, 'supervisor'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'user-42'), findsOneWidget);
    });

    testWidgets('4 workflow-hook fields rendered', (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(task: task, onUpdate: (_) {}),
      ));
      await openDialog(tester);
      for (final k in [
        'hook-onCompleteWorkflowId',
        'hook-onBlockedWorkflowId',
        'hook-onNaWorkflowId',
        'hook-onCantDoWorkflowId',
      ]) {
        expect(find.byKey(ValueKey(k)), findsOneWidget);
      }
    });

    testWidgets('entering a workflow id fires onUpdate with int parse',
        (tester) async {
      Map<String, dynamic>? updates;
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) =>
            EdenProcessTaskEditorDialog(task: task, onUpdate: (u) => updates = u),
      ));
      await openDialog(tester);
      await tester.enterText(
          find.byKey(const ValueKey('hook-onNaWorkflowId')), '88');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(updates?['onNaWorkflowId'], 88);
    });

    testWidgets(
        'consumer-provided blockingBehaviorOptions overrides defaults',
        (tester) async {
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskEditorDialog(
          task: task,
          onUpdate: (_) {},
          blockingBehaviorOptions: const ['custom-a', 'custom-b'],
        ),
      ));
      await openDialog(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('blocking-behavior-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('blocking-behavior-dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('custom-a'), findsAtLeastNWidgets(1));
      expect(find.text('custom-b'), findsAtLeastNWidgets(1));
      expect(find.text('soft'), findsNothing);
    });

    testWidgets('Close button pops dialog and saves pending text',
        (tester) async {
      Map<String, dynamic>? updates;
      final task = taskForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) =>
            EdenProcessTaskEditorDialog(task: task, onUpdate: (u) => updates = u),
      ));
      await openDialog(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Verify access'),
          'New name',
      );
      // Do NOT trigger blur; tap Close directly.
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(updates?['displayName'], 'New name');
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

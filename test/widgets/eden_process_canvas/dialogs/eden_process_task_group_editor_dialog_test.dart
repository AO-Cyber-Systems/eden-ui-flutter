import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_process_dialog_fixtures.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('EdenProcessTaskGroupEditorDialog', () {
    testWidgets('renders Dialog with title "Edit Task Group"', (tester) async {
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.text('Edit Task Group'), findsOneWidget);
    });

    testWidgets('Name + Description fields populated', (tester) async {
      final group = groupForEditFixture(
        displayName: 'Inspection',
        description: 'Check the site',
      );
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.widgetWithText(TextField, 'Inspection'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Check the site'), findsOneWidget);
    });

    testWidgets('isCollapsedDefault + isRequired checkboxes rendered',
        (tester) async {
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.text('Collapsed by default'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('toggling isCollapsedDefault fires onUpdate', (tester) async {
      Map<String, dynamic>? updates;
      final group = groupForEditFixture(isCollapsedDefault: false);
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (u) => updates = u,
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      await tester.tap(find.byKey(const ValueKey('group-checkbox-row-Collapsed by default')));
      await tester.pump();
      expect(updates?['isCollapsedDefault'], true);
    });

    testWidgets('template import section hidden when loadTemplates is null',
        (tester) async {
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.text('Import from template'), findsNothing);
    });

    testWidgets('template import dropdown shown when loadTemplates non-null + selecting fires onImportTemplate',
        (tester) async {
      String? imported;
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
          loadTemplates: () async => [
            (id: 't1', name: 'Onboarding template'),
            (id: 't2', name: 'Closeout template'),
          ],
          onImportTemplate: (id) => imported = id,
        ),
      ));
      await openDialog(tester);
      // Wait for FutureBuilder
      await tester.pumpAndSettle();
      expect(find.text('Import from template'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('template-import-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Closeout template').last);
      await tester.pumpAndSettle();
      expect(imported, 't2');
    });

    testWidgets('workflow hook fields populated from group', (tester) async {
      final group = groupForEditFixture(
        onAllCompleteWorkflowId: 42,
      );
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.widgetWithText(TextField, '42'), findsOneWidget);
    });

    testWidgets('entering a numeric hook value fires int? onUpdate',
        (tester) async {
      Map<String, dynamic>? updates;
      final group = groupForEditFixture(onItemNaWorkflowId: null);
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (u) => updates = u,
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      await tester.enterText(
          find.byKey(const ValueKey('hook-onItemNaWorkflowId')), '77');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(updates?['onItemNaWorkflowId'], 77);
    });

    testWidgets('clearing a hook value fires onUpdate with null',
        (tester) async {
      Map<String, dynamic>? updates;
      final group = groupForEditFixture(onAllCompleteWorkflowId: 42);
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (u) => updates = u,
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      await tester.enterText(
          find.byKey(const ValueKey('hook-onAllCompleteWorkflowId')), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(updates?['onAllCompleteWorkflowId'], isNull);
    });

    testWidgets('inline task list renders group.tasks rows', (tester) async {
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.text('Arrive on site'), findsOneWidget);
      expect(find.text('Take photos'), findsOneWidget);
    });

    testWidgets('tap Add Task fires onAddTask with checklist default',
        (tester) async {
      int? addedGroupId;
      Map<String, dynamic>? cfg;
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (id, c) {
            addedGroupId = id;
            cfg = c;
          },
          onDeleteTask: (_) {},
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('add-task-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-task-button')));
      await tester.pump();
      expect(addedGroupId, 10);
      expect(cfg?['runtimeComponent'], 'checklist');
    });

    testWidgets('tap delete on a task fires onDeleteTask', (tester) async {
      int? deleted;
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (id) => deleted = id,
          onEditTask: (_) {},
        ),
      ));
      await openDialog(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('delete-task-101')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-task-101')));
      await tester.pump();
      expect(deleted, 101);
    });

    testWidgets('tap edit on a task fires onEditTask', (tester) async {
      int? edited;
      final group = groupForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessTaskGroupEditorDialog(
          group: group,
          onUpdate: (_) {},
          onAddTask: (_, __) {},
          onDeleteTask: (_) {},
          onEditTask: (id) => edited = id,
        ),
      ));
      await openDialog(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('edit-task-102')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-task-102')));
      await tester.pump();
      expect(edited, 102);
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_process_node_fixtures.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Center(
              child: SizedBox(width: 280, height: 480, child: child),
            ),
          ),
        ),
      );

  group('EdenProcessTaskGroupNode — header', () {
    testWidgets('renders Folder icon when taskGroupTemplateId is null',
        (tester) async {
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsNothing);
    });

    testWidgets('renders menu_book icon when taskGroupTemplateId is set',
        (tester) async {
      final group = groupWithTemplateFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsNothing);
    });

    testWidgets('renders displayName', (tester) async {
      final group = taskGroupFixture(displayName: 'My Group');
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.text('My Group'), findsOneWidget);
    });

    testWidgets('renders task count badge', (tester) async {
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders workflow-hooks Zap icon when any group hook is set',
        (tester) async {
      final group = groupWithHooksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.byIcon(Icons.bolt), findsWidgets);
    });

    testWidgets('hides workflow-hooks Zap icon when all hook fields null',
        (tester) async {
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.byIcon(Icons.bolt), findsNothing);
    });

    testWidgets('tapping edit fires onOpenTaskGroupEditor', (tester) async {
      int? opened;
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onOpenTaskGroupEditor: (id) => opened = id,
        ),
      )));
      await tester.tap(find.byIcon(Icons.edit_outlined), warnIfMissed: false);
      await tester.pump();
      expect(opened, 10);
    });

    testWidgets('tapping delete fires onDeleteTaskGroup', (tester) async {
      int? deleted;
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onDeleteTaskGroup: (id) => deleted = id,
        ),
      )));
      await tester.tap(find.byIcon(Icons.delete_outline).first, warnIfMissed: false);
      await tester.pump();
      expect(deleted, 10);
    });

    testWidgets('renders missing-group fallback when groupsById lookup fails',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture(groupId: 999)),
        config: taskGroupRendererConfigFixture(groupsById: const {}),
      )));
      expect(find.text('Missing group 999'), findsOneWidget);
    });
  });

  group('EdenProcessTaskGroupNode — inline rename header', () {
    testWidgets('tapping displayName enters edit mode', (tester) async {
      final group = taskGroupFixture(displayName: 'Inspection');
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      await tester.tap(find.text('Inspection'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Enter saves new name', (tester) async {
      Map<String, dynamic>? updates;
      int? updatedId;
      final group = taskGroupFixture(displayName: 'Inspection');
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTaskGroup: (id, u) {
            updatedId = id;
            updates = u;
          },
        ),
      )));
      await tester.tap(find.text('Inspection'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Setup');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(updatedId, 10);
      expect(updates?['displayName'], 'Setup');
    });

    testWidgets('Esc cancels without firing onUpdateTaskGroup', (tester) async {
      int callCount = 0;
      final group = taskGroupFixture(displayName: 'Inspection');
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTaskGroup: (_, __) => callCount += 1,
        ),
      )));
      await tester.tap(find.text('Inspection'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New Name');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(callCount, 0);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('EdenProcessTaskGroupNode — expand/collapse', () {
    testWidgets('isCollapsedDefault=false → expanded initially', (tester) async {
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      // Task rows visible.
      expect(find.text('Arrive on site'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('isCollapsedDefault=true → collapsed initially', (tester) async {
      final group = groupWithFiveTasksFixture().copyWithCollapsed();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      // Task rows hidden.
      expect(find.text('Arrive on site'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping chevron toggles expanded state', (tester) async {
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.text('Arrive on site'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      expect(find.text('Arrive on site'), findsNothing);
    });
  });

  group('EdenProcessTaskGroupNode — Add task button', () {
    testWidgets('Add button visible when expanded', (tester) async {
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.text('Add task'), findsOneWidget);
    });

    testWidgets('Add button fires onAddTaskInGroup with checklist default',
        (tester) async {
      int? addedToGroup;
      Map<String, dynamic>? config;
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onAddTaskInGroup: (id, cfg) {
            addedToGroup = id;
            config = cfg;
          },
        ),
      )));
      await tester.tap(find.text('Add task'));
      await tester.pump();
      expect(addedToGroup, 10);
      expect(config?['runtimeComponent'], 'checklist');
    });
  });

  group('EdenProcessTaskGroupNode — inline task rows', () {
    testWidgets('renders each task in sort order with 1-indexed numbering',
        (tester) async {
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('5.'), findsOneWidget);
      expect(find.text('Arrive on site'), findsOneWidget);
      expect(find.text('Wrap up'), findsOneWidget);
    });

    testWidgets('tapping inline toggle fires onUpdateTask with negated value',
        (tester) async {
      int? updatedTaskId;
      Map<String, dynamic>? updates;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTask: (id, u) {
            updatedTaskId = id;
            updates = u;
          },
        ),
      )));

      // First task in fixture has isRequired=true. Tap its Req toggle.
      // The toggles are keyed for identification:
      await tester.tap(find.byKey(const ValueKey('toggle-101-isRequired')));
      await tester.pump();
      expect(updatedTaskId, 101);
      expect(updates?['isRequired'], false);
    });

    testWidgets('tapping task delete fires onDeleteTask', (tester) async {
      int? deletedTaskId;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onDeleteTask: (id) => deletedTaskId = id,
        ),
      )));
      await tester.tap(
        find.byKey(const ValueKey('delete-task-101')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(deletedTaskId, 101);
    });

    testWidgets('tapping task settings fires onOpenTaskEditor',
        (tester) async {
      int? openedTaskId;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onOpenTaskEditor: (id) => openedTaskId = id,
        ),
      )));
      await tester.tap(
        find.byKey(const ValueKey('edit-task-102')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(openedTaskId, 102);
    });

    testWidgets('task-level Zap icon shown when any task workflow hook set',
        (tester) async {
      final group = taskGroupFixture(tasks: [
        taskTemplateFixture(
          id: 200,
          groupId: 10,
          sortOrder: 0,
          onCompleteWorkflowId: 42,
        ),
      ]);
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });

  group('EdenProcessTaskGroupNode — inline task rename', () {
    testWidgets('tapping task name enters edit mode for that task',
        (tester) async {
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      await tester.tap(find.text('Arrive on site'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Enter saves new task name via onUpdateTask', (tester) async {
      int? updatedTaskId;
      Map<String, dynamic>? updates;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTask: (id, u) {
            updatedTaskId = id;
            updates = u;
          },
        ),
      )));
      await tester.tap(find.text('Arrive on site'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Roll in slowly');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(updatedTaskId, 101);
      expect(updates?['displayName'], 'Roll in slowly');
    });
  });

  group('EdenProcessTaskGroupNode — task reorder', () {
    testWidgets(
        'tapping ChevronUp on task at idx=1 fires TWO onUpdateTask calls',
        (tester) async {
      final calls = <(int, Map<String, dynamic>)>[];
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTask: (id, u) => calls.add((id, u)),
        ),
      )));

      await tester.tap(
        find.byKey(const ValueKey('move-up-102')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(calls.length, 2);
      // task 102 moves to sortOrder 0
      expect(calls[0].$1, 102);
      expect(calls[0].$2['sortOrder'], 0);
      // task 101 moves to sortOrder 1
      expect(calls[1].$1, 101);
      expect(calls[1].$2['sortOrder'], 1);
    });

    testWidgets('ChevronUp on first task does not fire callback',
        (tester) async {
      int callCount = 0;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTask: (_, __) => callCount += 1,
        ),
      )));
      // First task button should be disabled/no-op.
      final ironButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('move-up-101')),
      );
      expect(ironButton.onPressed, isNull);
      expect(callCount, 0);
    });

    testWidgets('ChevronDown on last task does not fire callback',
        (tester) async {
      int callCount = 0;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onUpdateTask: (_, __) => callCount += 1,
        ),
      )));
      final ironButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('move-down-105')),
      );
      expect(ironButton.onPressed, isNull);
      expect(callCount, 0);
    });
  });

  group('EdenProcessTaskGroupNode — drag target for task split', () {
    testWidgets('accepts drag data matching task-existing:{id}',
        (tester) async {
      int? splitTaskId;
      int? targetPhaseId;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture(phaseId: 7)),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onSplitTaskToNewGroup: (taskId, phaseId) {
            splitTaskId = taskId;
            targetPhaseId = phaseId;
          },
        ),
      )));

      // Find the DragTarget for task 102, simulate accept.
      final dragTargetFinder =
          find.byKey(const ValueKey('drag-target-task-102'));
      final state = tester.state<EdenProcessTaskGroupNodeDragTargetTestApi>(
        dragTargetFinder,
      );
      state.simulateDrop('task-existing:200');
      await tester.pump();

      expect(splitTaskId, 200);
      // group's processPhaseId is 1 (fixture default for groupWithFiveTasksFixture
      // which uses phaseId: 1).
      expect(targetPhaseId, 1);
    });

    testWidgets('rejects non-task drag data', (tester) async {
      int callCount = 0;
      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(
          groupsById: {10: group},
          onSplitTaskToNewGroup: (_, __) => callCount += 1,
        ),
      )));

      final state = tester.state<EdenProcessTaskGroupNodeDragTargetTestApi>(
        find.byKey(const ValueKey('drag-target-task-102')),
      );
      expect(state.willAccept('phase'), isFalse);
      expect(callCount, 0);
    });
  });

  group('EdenProcessTaskGroupNode — drop-target / selection', () {
    testWidgets('ctx.dropTarget=true uses primary-color border at width=2',
        (tester) async {
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture(), dropTarget: true),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessTaskGroupNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2);
    });

    testWidgets('default border width is 1', (tester) async {
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessTaskGroupNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 1);
    });
  });

  group('EdenProcessNodeRenderer dispatch extension — taskGroup', () {
    testWidgets('returns EdenProcessTaskGroupNode for nodeType=taskGroup',
        (tester) async {
      final group = taskGroupFixture();
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(
        nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(find.byType(EdenProcessTaskGroupNode), findsOneWidget);
    });
  });

  group('EdenProcessTaskGroupNode — iPhone-narrow safe', () {
    testWidgets('renders at 390pt without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final group = groupWithFiveTasksFixture();
      await tester.pumpWidget(wrap(EdenProcessTaskGroupNode(
        context: nodeCtx(taskGroupDiagramNodeFixture()),
        config: taskGroupRendererConfigFixture(groupsById: {10: group}),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}

// Helper extension so groupWithFiveTasksFixture can flip isCollapsedDefault.
extension _CollapsibleCopy on EdenProcessTaskGroup {
  EdenProcessTaskGroup copyWithCollapsed() => EdenProcessTaskGroup(
        id: id,
        processPhaseId: processPhaseId,
        name: name,
        displayName: displayName,
        sortOrder: sortOrder,
        isCollapsedDefault: true,
        isRequired: isRequired,
        taskGroupTemplateId: taskGroupTemplateId,
        linkedTaskTemplateId: linkedTaskTemplateId,
        onAllCompleteWorkflowId: onAllCompleteWorkflowId,
        onItemNaWorkflowId: onItemNaWorkflowId,
        onItemCantDoWorkflowId: onItemCantDoWorkflowId,
        tasks: tasks,
      );
}

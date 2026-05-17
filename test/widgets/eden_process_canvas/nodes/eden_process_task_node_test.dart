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
              child: SizedBox(width: 220, height: 200, child: child),
            ),
          ),
        ),
      );

  setUp(() {
    EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
  });

  group('EdenProcessTaskNode — rendering', () {
    testWidgets('renders task displayName', (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, displayName: 'Verify access');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Verify access'), findsOneWidget);
    });

    testWidgets('renders description when set', (tester) async {
      final task = EdenProcessTaskTemplate(
        id: 100,
        taskGroupId: 10,
        name: 't',
        displayName: 'Verify',
        description: 'Confirm the customer signed waiver',
        sortOrder: 0,
        runtimeComponent: 'checklist',
        runtimeComponentConfig: const {},
        isRequired: true,
        photoRequired: false,
        signatureRequired: false,
        approvalRequired: false,
        descriptionRequired: false,
        attachmentRequired: false,
        allowsNa: true,
        allowsBlocked: false,
        allowsCantDo: false,
        blockingBehavior: 'none',
      );
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Confirm the customer signed waiver'), findsOneWidget);
    });

    testWidgets('renders runtime-component icon for checklist', (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, runtimeComponent: 'checklist');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('renders custom registered runtime icon', (tester) async {
      EdenProcessRuntimeComponentRegistry.instance.register(
        const EdenProcessRuntimeComponentType(
          id: 'custom_thing',
          displayName: 'Custom',
          icon: Icons.star,
        ),
      );
      final task = taskTemplateFixture(id: 100, groupId: 10, runtimeComponent: 'custom_thing');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('defaults to check_box icon for unregistered runtime',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, runtimeComponent: 'no_such');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('renders Photo badge when photoRequired=true', (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, photoRequired: true);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Photo'), findsOneWidget);
    });

    testWidgets('renders Sig badge when signatureRequired=true',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, signatureRequired: true);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Sig'), findsOneWidget);
    });

    testWidgets('renders Approve badge when approvalRequired=true',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, approvalRequired: true);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Approve'), findsOneWidget);
    });

    testWidgets('renders Optional badge when isRequired=false',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, isRequired: false);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('omits Optional badge when isRequired=true', (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, isRequired: true);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Optional'), findsNothing);
    });

    testWidgets('renders missing-task fallback when tasksById lookup fails',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture(taskId: 999)),
        config: taskRendererConfigFixture(tasksById: const {}),
      )));
      expect(find.text('Missing task 999'), findsOneWidget);
    });

    testWidgets('tapping pencil fires onOpenTaskEditor', (tester) async {
      int? opened;
      final task = taskTemplateFixture(id: 100, groupId: 10);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: task},
          onOpenTaskEditor: (id) => opened = id,
        ),
      )));
      await tester.tap(find.byIcon(Icons.edit_outlined), warnIfMissed: false);
      await tester.pump();
      expect(opened, 100);
    });

    testWidgets('tapping trash fires onDeleteTask', (tester) async {
      int? deleted;
      final task = taskTemplateFixture(id: 100, groupId: 10);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: task},
          onDeleteTask: (id) => deleted = id,
        ),
      )));
      await tester.tap(find.byIcon(Icons.delete_outline), warnIfMissed: false);
      await tester.pump();
      expect(deleted, 100);
    });
  });

  group('EdenProcessTaskNode — form-field count badge', () {
    testWidgets('renders "N fields" badge when runtimeComponent=form with fields',
        (tester) async {
      final task = taskWithFormFixture(id: 100, groupId: 10, fieldCount: 4);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('4 fields'), findsOneWidget);
    });

    testWidgets('does NOT render fields badge when runtimeComponent != form',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, runtimeComponent: 'checklist');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.textContaining(' fields'), findsNothing);
    });
  });

  group('EdenProcessTaskNode — Configure Fields button', () {
    testWidgets('Configure Fields button visible for form tasks', (tester) async {
      final task = taskWithFormFixture(id: 100, groupId: 10);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Configure Fields'), findsOneWidget);
    });

    testWidgets('Configure Fields button hidden for non-form tasks',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, runtimeComponent: 'checklist');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.text('Configure Fields'), findsNothing);
    });

    testWidgets('tap Configure Fields fires onOpenTaskFormFieldsEditor',
        (tester) async {
      int? opened;
      final task = taskWithFormFixture(id: 100, groupId: 10);
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: task},
          onOpenTaskFormFieldsEditor: (id) => opened = id,
        ),
      )));
      await tester.tap(find.text('Configure Fields'));
      await tester.pump();
      expect(opened, 100);
    });
  });

  group('EdenProcessTaskNode — inline rename', () {
    testWidgets('tap displayName enters edit mode', (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10, displayName: 'Verify');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Enter saves new name via onUpdateTask', (tester) async {
      int? updatedId;
      Map<String, dynamic>? updates;
      final task = taskTemplateFixture(id: 100, groupId: 10, displayName: 'Verify');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: task},
          onUpdateTask: (id, u) {
            updatedId = id;
            updates = u;
          },
        ),
      )));
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Verify ID');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(updatedId, 100);
      expect(updates?['displayName'], 'Verify ID');
    });

    testWidgets('Esc cancels without firing onUpdateTask', (tester) async {
      int callCount = 0;
      final task = taskTemplateFixture(id: 100, groupId: 10, displayName: 'Verify');
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(
          tasksById: {100: task},
          onUpdateTask: (_, __) => callCount += 1,
        ),
      )));
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(callCount, 0);
    });
  });

  group('EdenProcessNodeRenderer dispatch extension — task', () {
    testWidgets('returns EdenProcessTaskNode for nodeType=task',
        (tester) async {
      final task = taskTemplateFixture(id: 100, groupId: 10);
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(
        nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(find.byType(EdenProcessTaskNode), findsOneWidget);
    });
  });

  group('EdenProcessTaskNode — iPhone-narrow safe', () {
    testWidgets('renders at 390pt without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final task = taskTemplateFixture(
        id: 100,
        groupId: 10,
        displayName: 'Long task name that should ellipsize gracefully at narrow widths',
        isRequired: false,
        photoRequired: true,
        signatureRequired: true,
        approvalRequired: true,
      );
      await tester.pumpWidget(wrap(EdenProcessTaskNode(
        context: nodeCtx(taskDiagramNodeFixture()),
        config: taskRendererConfigFixture(tasksById: {100: task}),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}

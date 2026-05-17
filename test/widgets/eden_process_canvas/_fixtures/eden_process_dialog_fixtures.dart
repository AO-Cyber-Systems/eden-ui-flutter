// Do NOT regenerate via LLM — hand-built fixtures for EdenProcess editor
// dialogs (objective 006 TRD 006-10).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

EdenProcessPhase phaseForEditFixture({
  int id = 1,
  String displayName = 'Planning',
  String? description = 'Initial planning phase',
  String? color = 'blue',
  bool isMilestone = false,
}) =>
    EdenProcessPhase(
      id: id,
      processDefinitionId: 1,
      name: 'planning',
      displayName: displayName,
      description: description,
      sortOrder: 0,
      color: color,
      isRequired: true,
      isMilestone: isMilestone,
      canSkip: false,
      autoAdvance: false,
      runtimeComponent: 'phase_default',
      runtimeComponentConfig: const {},
      allowsScopeChange: false,
      allowsAdHocTasks: false,
      groups: const [],
    );

EdenProcessTaskTemplate _task({
  required int id,
  required int groupId,
  String displayName = 'Task',
  String runtimeComponent = 'checklist',
  bool isRequired = false,
  bool photoRequired = false,
  bool signatureRequired = false,
  bool approvalRequired = false,
  Map<String, dynamic>? runtimeComponentConfig,
}) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 'task_$id',
      displayName: displayName,
      sortOrder: 0,
      runtimeComponent: runtimeComponent,
      runtimeComponentConfig: runtimeComponentConfig ?? const {},
      isRequired: isRequired,
      photoRequired: photoRequired,
      signatureRequired: signatureRequired,
      approvalRequired: approvalRequired,
      descriptionRequired: false,
      attachmentRequired: false,
      allowsNa: true,
      allowsBlocked: false,
      allowsCantDo: false,
      blockingBehavior: 'none',
    );

EdenProcessTaskGroup groupForEditFixture({
  int id = 10,
  int phaseId = 1,
  String displayName = 'Site Inspection',
  String? description = 'Inspect the site',
  bool isCollapsedDefault = false,
  int? onAllCompleteWorkflowId = 100,
  int? onItemNaWorkflowId,
  int? onItemCantDoWorkflowId,
}) =>
    EdenProcessTaskGroup(
      id: id,
      processPhaseId: phaseId,
      name: 'site_inspection',
      displayName: displayName,
      description: description,
      sortOrder: 0,
      isCollapsedDefault: isCollapsedDefault,
      isRequired: true,
      onAllCompleteWorkflowId: onAllCompleteWorkflowId,
      onItemNaWorkflowId: onItemNaWorkflowId,
      onItemCantDoWorkflowId: onItemCantDoWorkflowId,
      tasks: [
        _task(id: 101, groupId: id, displayName: 'Arrive on site'),
        _task(id: 102, groupId: id, displayName: 'Take photos', photoRequired: true),
      ],
    );

EdenProcessTaskTemplate taskForEditFixture({
  int id = 100,
  int groupId = 10,
}) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 'verify_access',
      displayName: 'Verify access',
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
      blockingBehavior: 'soft',
      materializesAsTask: true,
      approvalRole: 'supervisor',
      approvalUserId: 'user-42',
      onCompleteWorkflowId: 10,
      onBlockedWorkflowId: 11,
    );

EdenProcessTaskTemplate formTaskForEditFixture({int id = 200, int groupId = 10}) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 'fill_form',
      displayName: 'Fill form',
      sortOrder: 0,
      runtimeComponent: 'form',
      runtimeComponentConfig: const {
        'fields': [
          {'id': 1, 'label': 'Name'},
          {'id': 2, 'label': 'Email'},
        ],
      },
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

/// Helper that wraps a dialog in a MaterialApp+Scaffold with a single
/// "Open" button. Tapping the button calls `showDialog` with the provided
/// builder. Used by all dialog tests.
Widget dialogTestHarness(Widget Function(BuildContext) builder) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: builder,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

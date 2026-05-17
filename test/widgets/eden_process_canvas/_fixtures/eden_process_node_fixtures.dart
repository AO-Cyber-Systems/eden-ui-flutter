// Do NOT regenerate via LLM — hand-built fixtures for EdenProcessNode widgets.
//
// Used by TRD 006-04 / 006-05 / 006-06 / 006-07 widget tests for the seven
// process node types. Builds `EdenDiagramNode` instances pre-shaped with the
// `data` map keys the renderer dispatches on (`nodeType`, `orphanType`,
// `displayName`, `config`) plus an `EdenDiagramNodeContext` helper.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenDiagramNode startDiagramNodeFixture({String id = 'start'}) => EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.circle,
      x: 0,
      y: 0,
      width: 48,
      height: 48,
      label: 'Start',
      data: const {'nodeType': 'start'},
    );

EdenDiagramNode endDiagramNodeFixture({String id = 'end'}) => EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.circle,
      x: 0,
      y: 0,
      width: 48,
      height: 48,
      label: 'End',
      data: const {'nodeType': 'end'},
    );

EdenDiagramNode phaseOrphanFixture({
  String id = 'orphan-1',
  String displayName = 'New Phase',
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'phase',
        'displayName': displayName,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode taskGroupOrphanFixture({
  String id = 'orphan-2',
  String displayName = 'New Task Group',
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'taskGroup',
        'displayName': displayName,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode decisionOrphanFixture({
  String id = 'orphan-3',
  String displayName = 'New Decision',
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'decision',
        'displayName': displayName,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode taskOrphanFixture({
  String id = 'orphan-4',
  String displayName = 'New Task',
  String? runtimeComponent,
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'task',
        'displayName': displayName,
        'config': <String, dynamic>{
          if (runtimeComponent != null) 'runtimeComponent': runtimeComponent,
        },
      },
    );

EdenDiagramNodeContext nodeCtx(
  EdenDiagramNode node, {
  bool selected = false,
  bool hovered = false,
  bool dropTarget = false,
}) =>
    EdenDiagramNodeContext(
      node: node,
      selected: selected,
      hovered: hovered,
      dropTarget: dropTarget,
    );

// ─────────── Phase-node fixtures (TRD 006-05) ───────────

EdenDiagramNode phaseDiagramNodeFixture({
  int phaseId = 1,
  String displayName = 'Planning',
}) =>
    EdenDiagramNode(
      id: 'phase-$phaseId',
      shape: EdenNodeShape.roundedRect,
      x: 50,
      y: 50,
      width: 240,
      height: 120,
      label: displayName,
      data: {'nodeType': 'phase', 'phaseId': phaseId},
    );

EdenProcessPhase phaseFixture({
  int id = 1,
  String displayName = 'Planning',
  String? color = 'blue',
  bool isMilestone = false,
  List<EdenProcessTaskGroup> groups = const [],
}) =>
    EdenProcessPhase(
      id: id,
      processDefinitionId: 1,
      name: displayName.toLowerCase().replaceAll(' ', '_'),
      displayName: displayName,
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
      groups: groups,
    );

EdenProcessPhase milestonePhaseFixture({int id = 99}) => phaseFixture(
      id: id,
      displayName: 'Final approval',
      color: 'amber',
      isMilestone: true,
    );

EdenProcessTaskGroup _groupFixture({
  required int id,
  required int phaseId,
  required String displayName,
  required int taskCount,
}) {
  return EdenProcessTaskGroup(
    id: id,
    processPhaseId: phaseId,
    name: displayName.toLowerCase().replaceAll(' ', '_'),
    displayName: displayName,
    sortOrder: 0,
    isCollapsedDefault: false,
    isRequired: true,
    tasks: List.generate(
      taskCount,
      (i) => EdenProcessTaskTemplate(
        id: id * 100 + i,
        taskGroupId: id,
        name: 't_$i',
        displayName: 'Task $i',
        sortOrder: i,
        runtimeComponent: 'checklist',
        runtimeComponentConfig: const {},
        isRequired: false,
        photoRequired: false,
        signatureRequired: false,
        approvalRequired: false,
        descriptionRequired: false,
        attachmentRequired: false,
        allowsNa: true,
        allowsBlocked: false,
        allowsCantDo: false,
        blockingBehavior: 'none',
      ),
    ),
  );
}

EdenProcessPhase phaseWithGroupsFixture({
  int phaseId = 1,
  int groupCount = 2,
  int tasksPerGroup = 3,
}) {
  final groups = List.generate(
    groupCount,
    (i) => _groupFixture(
      id: phaseId * 10 + i,
      phaseId: phaseId,
      displayName: 'Group ${i + 1}',
      taskCount: tasksPerGroup,
    ),
  );
  return phaseFixture(id: phaseId, displayName: 'Phase $phaseId', groups: groups);
}

EdenProcessNodeRendererConfig phaseRendererConfigFixture({
  Map<int, EdenProcessPhase>? phasesById,
  Set<int> expanded = const {},
  void Function(int)? onTogglePhaseExpanded,
  void Function(int, Map<String, dynamic>)? onUpdatePhase,
  void Function(int)? onDeletePhase,
  void Function(int)? onOpenPhaseEditor,
}) =>
    EdenProcessNodeRendererConfig(
      phasesById: phasesById ?? const {},
      expandedPhaseIds: expanded,
      onTogglePhaseExpanded: onTogglePhaseExpanded,
      onUpdatePhase: onUpdatePhase,
      onDeletePhase: onDeletePhase,
      onOpenPhaseEditor: onOpenPhaseEditor,
    );

// ─────────── Task-group-node fixtures (TRD 006-06) ───────────

EdenDiagramNode taskGroupDiagramNodeFixture({
  int groupId = 10,
  int phaseId = 1,
  String displayName = 'Site Inspection',
}) =>
    EdenDiagramNode(
      id: 'group-$groupId',
      shape: EdenNodeShape.roundedRect,
      x: 100,
      y: 100,
      width: 260,
      height: 200,
      label: displayName,
      data: {
        'nodeType': 'taskGroup',
        'groupId': groupId,
        'phaseId': phaseId,
      },
    );

EdenProcessTaskTemplate taskTemplateFixture({
  required int id,
  required int groupId,
  String? displayName,
  int sortOrder = 0,
  bool isRequired = false,
  bool photoRequired = false,
  bool signatureRequired = false,
  bool approvalRequired = false,
  String runtimeComponent = 'checklist',
  int? onCompleteWorkflowId,
  int? onBlockedWorkflowId,
  int? onNaWorkflowId,
  int? onCantDoWorkflowId,
}) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 't_$id',
      displayName: displayName ?? 'Task $id',
      sortOrder: sortOrder,
      runtimeComponent: runtimeComponent,
      runtimeComponentConfig: const {},
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
      onCompleteWorkflowId: onCompleteWorkflowId,
      onBlockedWorkflowId: onBlockedWorkflowId,
      onNaWorkflowId: onNaWorkflowId,
      onCantDoWorkflowId: onCantDoWorkflowId,
    );

EdenProcessTaskGroup taskGroupFixture({
  int id = 10,
  int phaseId = 1,
  String displayName = 'Site Inspection',
  bool isCollapsedDefault = false,
  int? taskGroupTemplateId,
  int? onAllCompleteWorkflowId,
  int? onItemNaWorkflowId,
  int? onItemCantDoWorkflowId,
  List<EdenProcessTaskTemplate> tasks = const [],
}) =>
    EdenProcessTaskGroup(
      id: id,
      processPhaseId: phaseId,
      name: displayName.toLowerCase().replaceAll(' ', '_'),
      displayName: displayName,
      sortOrder: 0,
      isCollapsedDefault: isCollapsedDefault,
      isRequired: true,
      taskGroupTemplateId: taskGroupTemplateId,
      onAllCompleteWorkflowId: onAllCompleteWorkflowId,
      onItemNaWorkflowId: onItemNaWorkflowId,
      onItemCantDoWorkflowId: onItemCantDoWorkflowId,
      tasks: tasks,
    );

EdenProcessTaskGroup groupWithFiveTasksFixture({int id = 10, int phaseId = 1}) =>
    taskGroupFixture(
      id: id,
      phaseId: phaseId,
      tasks: [
        taskTemplateFixture(id: 101, groupId: id, sortOrder: 0, displayName: 'Arrive on site', isRequired: true),
        taskTemplateFixture(id: 102, groupId: id, sortOrder: 1, displayName: 'Take photos', photoRequired: true),
        taskTemplateFixture(id: 103, groupId: id, sortOrder: 2, displayName: 'Sign waiver', signatureRequired: true),
        taskTemplateFixture(id: 104, groupId: id, sortOrder: 3, displayName: 'Get approval', approvalRequired: true),
        taskTemplateFixture(id: 105, groupId: id, sortOrder: 4, displayName: 'Wrap up'),
      ],
    );

EdenProcessTaskGroup groupWithTemplateFixture({int id = 10, int phaseId = 1}) =>
    taskGroupFixture(
      id: id,
      phaseId: phaseId,
      displayName: 'Template-derived group',
      taskGroupTemplateId: 999,
    );

EdenProcessTaskGroup groupWithHooksFixture({int id = 10, int phaseId = 1}) =>
    taskGroupFixture(
      id: id,
      phaseId: phaseId,
      onAllCompleteWorkflowId: 1,
      onItemNaWorkflowId: 2,
      onItemCantDoWorkflowId: 3,
    );

EdenProcessNodeRendererConfig taskGroupRendererConfigFixture({
  Map<int, EdenProcessTaskGroup>? groupsById,
  void Function(int, Map<String, dynamic>)? onUpdateTaskGroup,
  void Function(int)? onDeleteTaskGroup,
  void Function(int)? onOpenTaskGroupEditor,
  void Function(int)? onOpenTaskEditor,
  void Function(int, Map<String, dynamic>?)? onAddTaskInGroup,
  void Function(int, Map<String, dynamic>)? onUpdateTask,
  void Function(int)? onDeleteTask,
  void Function(int, int)? onSplitTaskToNewGroup,
}) =>
    EdenProcessNodeRendererConfig(
      groupsById: groupsById ?? const {},
      onUpdateTaskGroup: onUpdateTaskGroup,
      onDeleteTaskGroup: onDeleteTaskGroup,
      onOpenTaskGroupEditor: onOpenTaskGroupEditor,
      onOpenTaskEditor: onOpenTaskEditor,
      onAddTaskInGroup: onAddTaskInGroup,
      onUpdateTask: onUpdateTask,
      onDeleteTask: onDeleteTask,
      onSplitTaskToNewGroup: onSplitTaskToNewGroup,
    );

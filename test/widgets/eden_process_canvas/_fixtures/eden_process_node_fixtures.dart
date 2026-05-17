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

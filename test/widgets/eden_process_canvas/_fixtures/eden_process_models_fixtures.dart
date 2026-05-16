// Do NOT regenerate via LLM — hand-built fixtures for EdenProcessModels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for process-models tests. Stable / deterministic /
/// reviewable. Used across TRDs 01..15 (objective 006 — A4-a Visual Process Canvas).
///
/// Every factory returns a NEW instance per call (no shared mutable state).
/// IDs are deterministic; no random data.

// ─────────── EdenProcessDefinition ───────────

EdenProcessDefinition processDefinitionFixture({
  int id = 1,
  int processTypeId = 10,
  String name = 'work_order',
  String displayName = 'Work Order',
  String? description,
  int version = 1,
  bool isDefault = true,
  bool isActive = true,
  bool isPublished = false,
  bool hasUnpublishedChanges = false,
  EdenProcessConfig? config,
  List<EdenProcessPhase> phases = const [],
}) {
  return EdenProcessDefinition(
    id: id,
    processTypeId: processTypeId,
    name: name,
    displayName: displayName,
    description: description,
    version: version,
    isDefault: isDefault,
    isActive: isActive,
    isPublished: isPublished,
    hasUnpublishedChanges: hasUnpublishedChanges,
    config: config ?? const EdenProcessConfig(),
    phases: phases,
  );
}

// ─────────── EdenProcessPhase ───────────

EdenProcessPhase planningPhaseFixture({
  int id = 1,
  int processDefinitionId = 100,
  String name = 'planning',
  String displayName = 'Planning',
  String? description,
  int sortOrder = 0,
  String? color = '#3B82F6',
  String? icon = 'layers',
  bool isRequired = true,
  bool isMilestone = false,
  bool canSkip = false,
  bool autoAdvance = false,
  String runtimeComponent = 'phase_default',
  Map<String, dynamic> runtimeComponentConfig = const {},
  bool allowsScopeChange = true,
  bool allowsAdHocTasks = true,
  List<EdenProcessTaskGroup> groups = const [],
}) {
  return EdenProcessPhase(
    id: id,
    processDefinitionId: processDefinitionId,
    name: name,
    displayName: displayName,
    description: description,
    sortOrder: sortOrder,
    color: color,
    icon: icon,
    isRequired: isRequired,
    isMilestone: isMilestone,
    canSkip: canSkip,
    autoAdvance: autoAdvance,
    runtimeComponent: runtimeComponent,
    runtimeComponentConfig: runtimeComponentConfig,
    allowsScopeChange: allowsScopeChange,
    allowsAdHocTasks: allowsAdHocTasks,
    groups: groups,
  );
}

EdenProcessPhase executionPhaseFixture({
  int id = 2,
  int processDefinitionId = 100,
  String name = 'execution',
  String displayName = 'Execution',
  int sortOrder = 1,
  String? color = '#10B981',
  bool isMilestone = false,
  List<EdenProcessTaskGroup> groups = const [],
}) {
  return EdenProcessPhase(
    id: id,
    processDefinitionId: processDefinitionId,
    name: name,
    displayName: displayName,
    description: null,
    sortOrder: sortOrder,
    color: color,
    icon: null,
    isRequired: true,
    isMilestone: isMilestone,
    canSkip: false,
    autoAdvance: false,
    runtimeComponent: 'phase_default',
    runtimeComponentConfig: const {},
    allowsScopeChange: true,
    allowsAdHocTasks: true,
    groups: groups,
  );
}

EdenProcessPhase closeoutPhaseFixture({
  int id = 3,
  int processDefinitionId = 100,
  String name = 'closeout',
  String displayName = 'Closeout',
  int sortOrder = 2,
  String? color = '#F59E0B',
  bool isMilestone = true,
  List<EdenProcessTaskGroup> groups = const [],
}) {
  return EdenProcessPhase(
    id: id,
    processDefinitionId: processDefinitionId,
    name: name,
    displayName: displayName,
    description: null,
    sortOrder: sortOrder,
    color: color,
    icon: null,
    isRequired: true,
    isMilestone: isMilestone,
    canSkip: false,
    autoAdvance: false,
    runtimeComponent: 'phase_default',
    runtimeComponentConfig: const {},
    allowsScopeChange: true,
    allowsAdHocTasks: true,
    groups: groups,
  );
}

// ─────────── EdenProcessTaskGroup ───────────

EdenProcessTaskGroup taskGroupFixture({
  int id = 10,
  int processPhaseId = 1,
  String name = 'site_inspection',
  String displayName = 'Site Inspection',
  String? description,
  int sortOrder = 0,
  bool isCollapsedDefault = false,
  bool isRequired = true,
  int? taskGroupTemplateId,
  int? linkedTaskTemplateId,
  int? onAllCompleteWorkflowId,
  int? onItemNaWorkflowId,
  int? onItemCantDoWorkflowId,
  List<EdenProcessTaskTemplate> tasks = const [],
}) {
  return EdenProcessTaskGroup(
    id: id,
    processPhaseId: processPhaseId,
    name: name,
    displayName: displayName,
    description: description,
    sortOrder: sortOrder,
    isCollapsedDefault: isCollapsedDefault,
    isRequired: isRequired,
    taskGroupTemplateId: taskGroupTemplateId,
    linkedTaskTemplateId: linkedTaskTemplateId,
    onAllCompleteWorkflowId: onAllCompleteWorkflowId,
    onItemNaWorkflowId: onItemNaWorkflowId,
    onItemCantDoWorkflowId: onItemCantDoWorkflowId,
    tasks: tasks,
  );
}

EdenProcessTaskGroup taskGroupWithHooksFixture({
  int id = 11,
  int processPhaseId = 1,
}) {
  return EdenProcessTaskGroup(
    id: id,
    processPhaseId: processPhaseId,
    name: 'group_with_hooks',
    displayName: 'Hooks Demo Group',
    description: null,
    sortOrder: 1,
    isCollapsedDefault: false,
    isRequired: true,
    taskGroupTemplateId: null,
    linkedTaskTemplateId: null,
    onAllCompleteWorkflowId: 5,
    onItemNaWorkflowId: 6,
    onItemCantDoWorkflowId: 7,
    tasks: const [],
  );
}

// ─────────── EdenProcessTaskTemplate ───────────

EdenProcessTaskTemplate checklistTaskFixture({
  int id = 100,
  int taskGroupId = 10,
  String name = 'verify_access',
  String displayName = 'Verify site access',
  int sortOrder = 0,
  String runtimeComponent = 'checklist',
  Map<String, dynamic> runtimeComponentConfig = const {},
  bool isRequired = true,
}) {
  return EdenProcessTaskTemplate(
    id: id,
    taskGroupId: taskGroupId,
    name: name,
    displayName: displayName,
    description: null,
    sortOrder: sortOrder,
    runtimeComponent: runtimeComponent,
    runtimeComponentConfig: runtimeComponentConfig,
    isRequired: isRequired,
    photoRequired: false,
    signatureRequired: false,
    approvalRequired: false,
    descriptionRequired: false,
    attachmentRequired: false,
    allowsNa: false,
    allowsBlocked: false,
    allowsCantDo: false,
    blockingBehavior: 'soft',
    materializesAsTask: true,
  );
}

EdenProcessTaskTemplate photoTaskFixture({
  int id = 101,
  int taskGroupId = 10,
}) {
  return EdenProcessTaskTemplate(
    id: id,
    taskGroupId: taskGroupId,
    name: 'photo_capture',
    displayName: 'Photo capture',
    description: null,
    sortOrder: 1,
    runtimeComponent: 'photo_gallery',
    runtimeComponentConfig: const {},
    isRequired: true,
    photoRequired: true,
    signatureRequired: false,
    approvalRequired: false,
    descriptionRequired: false,
    attachmentRequired: false,
    allowsNa: false,
    allowsBlocked: false,
    allowsCantDo: false,
    blockingBehavior: 'soft',
    materializesAsTask: true,
  );
}

EdenProcessTaskTemplate signatureTaskFixture({
  int id = 102,
  int taskGroupId = 10,
}) {
  return EdenProcessTaskTemplate(
    id: id,
    taskGroupId: taskGroupId,
    name: 'sign_off',
    displayName: 'Sign off',
    description: null,
    sortOrder: 2,
    runtimeComponent: 'signature_capture',
    runtimeComponentConfig: const {},
    isRequired: true,
    photoRequired: false,
    signatureRequired: true,
    approvalRequired: false,
    descriptionRequired: false,
    attachmentRequired: false,
    allowsNa: false,
    allowsBlocked: false,
    allowsCantDo: false,
    blockingBehavior: 'soft',
    materializesAsTask: true,
  );
}

EdenProcessTaskTemplate approvalTaskFixture({
  int id = 103,
  int taskGroupId = 10,
}) {
  return EdenProcessTaskTemplate(
    id: id,
    taskGroupId: taskGroupId,
    name: 'approval',
    displayName: 'Approval gate',
    description: null,
    sortOrder: 3,
    runtimeComponent: 'approval_gate',
    runtimeComponentConfig: const {},
    isRequired: true,
    photoRequired: false,
    signatureRequired: false,
    approvalRequired: true,
    descriptionRequired: false,
    attachmentRequired: false,
    allowsNa: false,
    allowsBlocked: false,
    allowsCantDo: false,
    blockingBehavior: 'hard',
    materializesAsTask: true,
    approvalRole: 'supervisor',
    approvalUserId: null,
  );
}

EdenProcessTaskTemplate formTaskFixture({
  int id = 104,
  int taskGroupId = 10,
}) {
  return EdenProcessTaskTemplate(
    id: id,
    taskGroupId: taskGroupId,
    name: 'intake_form',
    displayName: 'Intake form',
    description: null,
    sortOrder: 4,
    runtimeComponent: 'form',
    runtimeComponentConfig: const {
      'fields': [
        {'name': 'site_address', 'type': 'text'},
        {'name': 'access_code', 'type': 'text'},
      ],
    },
    isRequired: true,
    photoRequired: false,
    signatureRequired: false,
    approvalRequired: false,
    descriptionRequired: false,
    attachmentRequired: false,
    allowsNa: false,
    allowsBlocked: false,
    allowsCantDo: false,
    blockingBehavior: 'soft',
    materializesAsTask: true,
  );
}

// ─────────── EdenProcessDecisionConfig ───────────

EdenProcessDecisionConfig decisionFixture({
  int id = 1,
  String name = 'Approval Required?',
  String condition = 'cost > 5000',
}) {
  return EdenProcessDecisionConfig(
    id: id,
    name: name,
    condition: condition,
  );
}

// ─────────── EdenProcessLayoutData / position / saved edge / viewport ───────────

EdenProcessLayoutData layoutDataFixture({
  int version = 1,
  bool autoLayout = false,
  Map<String, EdenProcessNodePosition>? nodes,
  List<EdenProcessSavedEdge> edges = const [],
  EdenProcessViewport? viewport,
}) {
  return EdenProcessLayoutData(
    version: version,
    autoLayout: autoLayout,
    nodes: nodes ??
        {
          'phase-1': const EdenProcessNodePosition(x: 100, y: 50),
          'phase-2': const EdenProcessNodePosition(x: 100, y: 200),
          'phase-3': const EdenProcessNodePosition(x: 100, y: 350),
          'group-10': const EdenProcessNodePosition(x: 350, y: 50),
          'group-11': const EdenProcessNodePosition(x: 350, y: 130),
          'group-12': const EdenProcessNodePosition(x: 350, y: 200),
        },
    edges: edges,
    viewport: viewport,
  );
}

EdenProcessSavedEdge savedEdgeFixture({
  String id = 'edge-1',
  String source = 'phase-1',
  String target = 'phase-2',
  String? sourceHandle,
  String? targetHandle,
}) {
  return EdenProcessSavedEdge(
    id: id,
    source: source,
    target: target,
    sourceHandle: sourceHandle,
    targetHandle: targetHandle,
  );
}

EdenProcessNodePosition positionFixture({
  double x = 100,
  double y = 50,
  bool? expanded,
}) {
  return EdenProcessNodePosition(x: x, y: y, expanded: expanded);
}

// ─────────── EdenProcessValidationIssue ───────────

EdenProcessValidationIssue warningIssueFixture({
  String nodeId = 'orphan-1',
  String message = 'Element not connected',
  String? suggestion,
}) {
  return EdenProcessValidationIssue(
    type: EdenProcessValidationSeverity.warning,
    nodeId: nodeId,
    message: message,
    suggestion: suggestion,
  );
}

EdenProcessValidationIssue errorIssueFixture({
  String nodeId = 'decision-1',
  String message = 'Decision missing branches',
  String? suggestion = 'Connect Yes and No edges to downstream nodes',
}) {
  return EdenProcessValidationIssue(
    type: EdenProcessValidationSeverity.error,
    nodeId: nodeId,
    message: message,
    suggestion: suggestion,
  );
}

// ─────────── Entity-type registry fixtures ───────────

EdenProcessEntityType serviceVisitEntityTypeFixture() {
  return const EdenProcessEntityType(
    id: 'service_visit',
    displayName: 'Service Visit',
    icon: Icons.build,
  );
}

EdenProcessEntityType fuelDeliveryEntityTypeFixture() {
  return const EdenProcessEntityType(
    id: 'fuel_delivery',
    displayName: 'Fuel Delivery',
    icon: Icons.local_shipping,
  );
}

EdenProcessEntityType caseEntityTypeFixture() {
  return const EdenProcessEntityType(
    id: 'case',
    displayName: 'Case',
    icon: Icons.folder,
  );
}

// ─────────── Runtime-component registry fixtures ───────────

EdenProcessRuntimeComponentType customWidgetComponentFixture() {
  return const EdenProcessRuntimeComponentType(
    id: 'custom_widget',
    displayName: 'Custom Widget',
    icon: Icons.extension,
  );
}

// ─────────── Composite — populated definition for system tests ───────────

EdenProcessDefinition populatedProcessFixture() {
  final phase1Groups = [
    taskGroupFixture(
      id: 10,
      processPhaseId: 1,
      displayName: 'Site Inspection',
      sortOrder: 0,
      tasks: [
        checklistTaskFixture(id: 100, taskGroupId: 10, sortOrder: 0),
        photoTaskFixture(id: 101, taskGroupId: 10),
        formTaskFixture(id: 104, taskGroupId: 10),
      ],
    ),
    taskGroupFixture(
      id: 11,
      processPhaseId: 1,
      name: 'permitting',
      displayName: 'Permitting',
      sortOrder: 1,
      tasks: [
        checklistTaskFixture(
          id: 110,
          taskGroupId: 11,
          name: 'check_permits',
          displayName: 'Check required permits',
        ),
      ],
    ),
  ];

  final phase2Groups = [
    taskGroupFixture(
      id: 20,
      processPhaseId: 2,
      name: 'work_execution',
      displayName: 'Work Execution',
      sortOrder: 0,
      tasks: [
        checklistTaskFixture(
          id: 200,
          taskGroupId: 20,
          name: 'execute_steps',
          displayName: 'Execute work steps',
        ),
        photoTaskFixture(id: 201, taskGroupId: 20),
      ],
    ),
    taskGroupFixture(
      id: 21,
      processPhaseId: 2,
      name: 'quality_check',
      displayName: 'Quality Check',
      sortOrder: 1,
      tasks: [
        approvalTaskFixture(id: 210, taskGroupId: 21),
      ],
    ),
  ];

  final phase3Groups = [
    taskGroupFixture(
      id: 30,
      processPhaseId: 3,
      name: 'customer_signoff',
      displayName: 'Customer Sign-off',
      sortOrder: 0,
      tasks: [
        signatureTaskFixture(id: 300, taskGroupId: 30),
      ],
    ),
    taskGroupFixture(
      id: 31,
      processPhaseId: 3,
      name: 'closeout_docs',
      displayName: 'Closeout Documentation',
      sortOrder: 1,
      tasks: [
        checklistTaskFixture(
          id: 310,
          taskGroupId: 31,
          name: 'final_paperwork',
          displayName: 'Final paperwork',
        ),
        photoTaskFixture(id: 311, taskGroupId: 31),
      ],
    ),
  ];

  return EdenProcessDefinition(
    id: 1,
    processTypeId: 10,
    name: 'work_order',
    displayName: 'Work Order',
    description: 'Standard work order process — 3 phases × 2 groups each',
    version: 1,
    isDefault: true,
    isActive: true,
    isPublished: false,
    hasUnpublishedChanges: false,
    config: EdenProcessConfig(
      layout: layoutDataFixture(),
      decisions: [decisionFixture()],
      flowNodes: const {'start': true, 'end': true},
    ),
    phases: [
      planningPhaseFixture(id: 1, processDefinitionId: 1, groups: phase1Groups),
      executionPhaseFixture(id: 2, processDefinitionId: 1, groups: phase2Groups),
      closeoutPhaseFixture(id: 3, processDefinitionId: 1, groups: phase3Groups),
    ],
  );
}

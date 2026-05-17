// Do NOT regenerate via LLM — hand-built fixtures for the composite
// EdenVisualProcessCanvas tests.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenProcessTaskTemplate _task(int id, int groupId, String name) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 't_$id',
      displayName: name,
      sortOrder: 0,
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
    );

EdenProcessTaskGroup _group(
        int id, int phaseId, String name, List<EdenProcessTaskTemplate> tasks) =>
    EdenProcessTaskGroup(
      id: id,
      processPhaseId: phaseId,
      name: 'g_$id',
      displayName: name,
      sortOrder: 0,
      isCollapsedDefault: false,
      isRequired: true,
      tasks: tasks,
    );

EdenProcessPhase _phase(
        int id, String name, List<EdenProcessTaskGroup> groups) =>
    EdenProcessPhase(
      id: id,
      processDefinitionId: 1,
      name: 'p_$id',
      displayName: name,
      sortOrder: 0,
      isRequired: true,
      isMilestone: false,
      canSkip: false,
      autoAdvance: false,
      runtimeComponent: 'phase_default',
      runtimeComponentConfig: const {},
      allowsScopeChange: false,
      allowsAdHocTasks: false,
      groups: groups,
    );

EdenProcessDefinition populatedDefinitionFixture() {
  final phases = <EdenProcessPhase>[];
  for (int p = 1; p <= 3; p++) {
    final groups = <EdenProcessTaskGroup>[];
    for (int g = 1; g <= 2; g++) {
      final groupId = p * 10 + g;
      final tasks = <EdenProcessTaskTemplate>[
        for (int t = 1; t <= 3; t++)
          _task(groupId * 100 + t, groupId, 'Task $p.$g.$t'),
      ];
      groups.add(_group(groupId, p, 'Group $p.$g', tasks));
    }
    phases.add(_phase(p, 'Phase $p', groups));
  }
  return EdenProcessDefinition(
    id: 1,
    processTypeId: 10,
    name: 'populated',
    displayName: 'Populated Process',
    version: 1,
    isDefault: true,
    isActive: true,
    isPublished: false,
    hasUnpublishedChanges: false,
    config: const EdenProcessConfig(
      decisions: [
        EdenProcessDecisionConfig(
          id: 1,
          name: 'Approve?',
          condition: 'cost > 5000',
        ),
      ],
    ),
    phases: phases,
  );
}

EdenProcessDefinition emptyDefinitionFixture() => EdenProcessDefinition(
      id: 1,
      processTypeId: 10,
      name: 'empty',
      displayName: 'Empty',
      version: 1,
      isDefault: true,
      isActive: true,
      isPublished: false,
      hasUnpublishedChanges: false,
      config: const EdenProcessConfig(),
      phases: const [],
    );

EdenProcessDefinition publishedDefinitionFixture() => EdenProcessDefinition(
      id: 1,
      processTypeId: 10,
      name: 'published',
      displayName: 'Published',
      version: 1,
      isDefault: true,
      isActive: true,
      isPublished: true,
      hasUnpublishedChanges: false,
      config: const EdenProcessConfig(),
      phases: [_phase(1, 'Phase', const [])],
    );

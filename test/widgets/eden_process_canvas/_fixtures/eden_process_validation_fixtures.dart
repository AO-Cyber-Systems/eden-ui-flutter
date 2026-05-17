// Do NOT regenerate via LLM — hand-built fixtures for the
// EdenProcessValidator. Each builder produces a (def, nodes, edges) record
// designed to exercise exactly one (or two related) validation rules.

import 'package:eden_ui_flutter/eden_ui.dart';

typedef _ValidationFixture = ({
  EdenProcessDefinition def,
  List<EdenDiagramNode> nodes,
  List<EdenDiagramEdge> edges,
});

EdenProcessDefinition _def({
  List<EdenProcessPhase> phases = const [],
  List<EdenProcessDecisionConfig> decisions = const [],
}) =>
    EdenProcessDefinition(
      id: 1,
      processTypeId: 10,
      name: 'fixture',
      displayName: 'Fixture',
      version: 1,
      isDefault: true,
      isActive: true,
      isPublished: false,
      hasUnpublishedChanges: false,
      config: EdenProcessConfig(decisions: decisions),
      phases: phases,
    );

EdenProcessPhase _phase({
  int id = 1,
  String displayName = 'Phase',
  List<EdenProcessTaskGroup> groups = const [],
}) =>
    EdenProcessPhase(
      id: id,
      processDefinitionId: 1,
      name: 'phase_$id',
      displayName: displayName,
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

EdenProcessTaskGroup _group({
  int id = 10,
  int phaseId = 1,
  String displayName = 'Group',
  List<EdenProcessTaskTemplate> tasks = const [],
}) =>
    EdenProcessTaskGroup(
      id: id,
      processPhaseId: phaseId,
      name: 'group_$id',
      displayName: displayName,
      sortOrder: 0,
      isCollapsedDefault: false,
      isRequired: true,
      tasks: tasks,
    );

EdenProcessTaskTemplate _task({
  required int id,
  int groupId = 10,
  String displayName = 'Task',
}) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 'task_$id',
      displayName: displayName,
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

EdenDiagramNode _startNode() => EdenDiagramNode(
      id: 'start',
      x: 0,
      y: 0,
      data: const {'nodeType': 'start'},
    );

EdenDiagramNode _endNode() => EdenDiagramNode(
      id: 'end',
      x: 0,
      y: 0,
      data: const {'nodeType': 'end'},
    );

EdenDiagramNode _phaseNode(int id, String displayName) => EdenDiagramNode(
      id: 'phase-$id',
      x: 0,
      y: 0,
      label: displayName,
      data: {'nodeType': 'phase', 'phaseId': id},
    );

EdenDiagramNode _groupNode(int id, int phaseId, String displayName) =>
    EdenDiagramNode(
      id: 'group-$id',
      x: 0,
      y: 0,
      label: displayName,
      data: {'nodeType': 'taskGroup', 'groupId': id, 'phaseId': phaseId},
    );

_ValidationFixture validProcessFixture() {
  final phase = _phase(
    id: 1,
    displayName: 'Planning',
    groups: [
      _group(id: 10, phaseId: 1, displayName: 'Setup', tasks: [
        _task(id: 100, groupId: 10),
      ]),
    ],
  );
  return (
    def: _def(phases: [phase]),
    nodes: [_startNode(), _phaseNode(1, 'Planning'), _groupNode(10, 1, 'Setup'), _endNode()],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'group-10'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'end'),
    ],
  );
}

_ValidationFixture processWith3OrphansFixture() {
  final phase = _phase(
    id: 1,
    groups: [
      _group(id: 10, phaseId: 1, tasks: [_task(id: 100, groupId: 10)]),
    ],
  );
  return (
    def: _def(phases: [phase]),
    nodes: [
      _startNode(),
      _phaseNode(1, 'Phase'),
      _groupNode(10, 1, 'Group'),
      _endNode(),
      EdenDiagramNode(
        id: 'orphan-1',
        x: 0,
        y: 0,
        data: const {
          'nodeType': 'orphan',
          'orphanType': 'task',
          'displayName': 'Orphan A',
        },
      ),
      EdenDiagramNode(
        id: 'orphan-2',
        x: 0,
        y: 0,
        data: const {
          'nodeType': 'orphan',
          'orphanType': 'task',
          'displayName': 'Orphan B',
        },
      ),
      EdenDiagramNode(
        id: 'orphan-3',
        x: 0,
        y: 0,
        data: const {
          'nodeType': 'orphan',
          'orphanType': 'phase',
          'displayName': 'Orphan C',
        },
      ),
    ],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'group-10'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'end'),
    ],
  );
}

_ValidationFixture processWithEmptyPhaseFixture() {
  final phase = _phase(id: 1, displayName: 'Empty phase');
  return (
    def: _def(phases: [phase]),
    nodes: [_startNode(), _phaseNode(1, 'Empty phase'), _endNode()],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'end'),
    ],
  );
}

_ValidationFixture processWithEmptyGroupFixture() {
  final phase = _phase(id: 1, groups: [
    _group(id: 10, phaseId: 1, displayName: 'Empty group'),
  ]);
  return (
    def: _def(phases: [phase]),
    nodes: [
      _startNode(),
      _phaseNode(1, 'Phase'),
      _groupNode(10, 1, 'Empty group'),
      _endNode(),
    ],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'group-10'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'end'),
    ],
  );
}

_ValidationFixture processWithDecisionMissingBranchesFixture() {
  final phase = _phase(id: 1, groups: [
    _group(id: 10, phaseId: 1, tasks: [_task(id: 100, groupId: 10)]),
  ]);
  return (
    def: _def(
      phases: [phase],
      decisions: const [
        EdenProcessDecisionConfig(
          id: 7,
          name: 'Approve?',
          condition: 'cost > 5000',
        ),
      ],
    ),
    nodes: [
      _startNode(),
      _phaseNode(1, 'Phase'),
      _groupNode(10, 1, 'Group'),
      _endNode(),
      EdenDiagramNode(
        id: 'decision-7',
        x: 0,
        y: 0,
        label: 'Approve?',
        data: const {'nodeType': 'decision', 'decisionId': 7},
      ),
    ],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'group-10'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'decision-7'),
      // Only yes path connected; no path missing.
      EdenDiagramEdge(
        id: 'e4',
        sourceId: 'decision-7',
        targetId: 'end',
        sourcePortId: 'yes',
      ),
    ],
  );
}

_ValidationFixture processWithDecisionLegacyHandlesFixture() {
  final phase = _phase(id: 1, groups: [
    _group(id: 10, phaseId: 1, tasks: [_task(id: 100, groupId: 10)]),
  ]);
  return (
    def: _def(
      phases: [phase],
      decisions: const [
        EdenProcessDecisionConfig(id: 7, name: 'Approve?', condition: ''),
      ],
    ),
    nodes: [
      _startNode(),
      _phaseNode(1, 'Phase'),
      _groupNode(10, 1, 'Group'),
      _endNode(),
      EdenDiagramNode(
        id: 'decision-7',
        x: 0,
        y: 0,
        label: 'Approve?',
        data: const {'nodeType': 'decision', 'decisionId': 7},
      ),
    ],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'group-10'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'decision-7'),
      // Legacy: no sourcePortId; use sourcePort enum.
      EdenDiagramEdge(
        id: 'e4',
        sourceId: 'decision-7',
        targetId: 'end',
        sourcePort: EdenPortSide.right,
      ),
      EdenDiagramEdge(
        id: 'e5',
        sourceId: 'decision-7',
        targetId: 'phase-1',
        sourcePort: EdenPortSide.bottom,
      ),
    ],
  );
}

_ValidationFixture processWithDisconnectedNodeFixture() {
  final phase = _phase(id: 1, groups: [
    _group(id: 10, phaseId: 1, tasks: [_task(id: 100, groupId: 10)]),
  ]);
  return (
    def: _def(phases: [phase]),
    nodes: [
      _startNode(),
      _phaseNode(1, 'Phase'),
      _groupNode(10, 1, 'Group'),
      _endNode(),
      // Disconnected phase node not referenced by any edge.
      _phaseNode(99, 'Lonely phase'),
    ],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'group-10'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'end'),
    ],
  );
}

_ValidationFixture processWithNoPhasesFixture() {
  return (
    def: _def(phases: const []),
    nodes: [_startNode(), _endNode()],
    edges: [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'end'),
    ],
  );
}

// Do NOT regenerate via LLM — hand-built fixtures for swimlane / free-form
// layouts (objective 006).
//
// Each helper returns a tuple (nodes, edges) that mimics what
// `EdenProcessGraphBuilder.build()` emits for a given shape. Positions are
// arbitrary (0,0) on input; the layout engine is the unit under test and
// computes the final positions.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenDiagramNode _startNode() => EdenDiagramNode(
      id: 'start',
      shape: EdenNodeShape.circle,
      x: 0,
      y: 0,
      width: 48,
      height: 48,
      label: 'Start',
      data: const {'nodeType': 'start'},
    );

EdenDiagramNode _endNode() => EdenDiagramNode(
      id: 'end',
      shape: EdenNodeShape.circle,
      x: 0,
      y: 0,
      width: 48,
      height: 48,
      label: 'End',
      data: const {'nodeType': 'end'},
    );

EdenDiagramNode _phaseNode(int id) => EdenDiagramNode(
      id: 'phase-$id',
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 240,
      height: 120,
      label: 'Phase $id',
      data: {'nodeType': 'phase', 'phaseId': id},
    );

EdenDiagramNode _groupNode(int id, int phaseId, {int taskCount = 0}) =>
    EdenDiagramNode(
      id: 'group-$id',
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 260,
      height: 80,
      label: 'Group $id',
      data: {
        'nodeType': 'taskGroup',
        'groupId': id,
        'phaseId': phaseId,
        'taskCount': taskCount,
      },
    );

EdenDiagramEdge _spineEdge(String src, String tgt) => EdenDiagramEdge(
      id: 'spine-$src-$tgt',
      sourceId: src,
      targetId: tgt,
      data: const {'edgeStyle': 'spine'},
    );

EdenDiagramEdge _fanEdge(String src, String tgt) => EdenDiagramEdge(
      id: 'fan-$src-$tgt',
      sourceId: src,
      targetId: tgt,
      data: const {'edgeStyle': 'autoFan'},
    );

(List<EdenDiagramNode>, List<EdenDiagramEdge>) emptyGraph() => (const [], const []);

(List<EdenDiagramNode>, List<EdenDiagramEdge>) startEndOnlyGraph() {
  final start = _startNode();
  final end = _endNode();
  return ([start, end], [_spineEdge('start', 'end')]);
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) singlePhaseNoGroupsGraph() {
  return (
    [_startNode(), _phaseNode(1), _endNode()],
    [_spineEdge('start', 'phase-1'), _spineEdge('phase-1', 'end')],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) singlePhaseTwoGroupsGraph() {
  return (
    [
      _startNode(),
      _phaseNode(1),
      _groupNode(10, 1),
      _groupNode(11, 1),
      _endNode(),
    ],
    [
      _spineEdge('start', 'phase-1'),
      _fanEdge('phase-1', 'group-10'),
      _fanEdge('phase-1', 'group-11'),
      _spineEdge('phase-1', 'end'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>)
    singlePhaseTwoGroupsVaryingTaskCountGraph() {
  return (
    [
      _startNode(),
      _phaseNode(1),
      _groupNode(10, 1, taskCount: 0),
      _groupNode(11, 1, taskCount: 5),
      _endNode(),
    ],
    [
      _spineEdge('start', 'phase-1'),
      _fanEdge('phase-1', 'group-10'),
      _fanEdge('phase-1', 'group-11'),
      _spineEdge('phase-1', 'end'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) threePhasesEachTwoGroupsGraph() {
  return (
    [
      _startNode(),
      _phaseNode(1),
      _groupNode(10, 1),
      _groupNode(11, 1),
      _phaseNode(2),
      _groupNode(20, 2),
      _groupNode(21, 2),
      _phaseNode(3),
      _groupNode(30, 3),
      _groupNode(31, 3),
      _endNode(),
    ],
    [
      _spineEdge('start', 'phase-1'),
      _fanEdge('phase-1', 'group-10'),
      _fanEdge('phase-1', 'group-11'),
      _spineEdge('phase-1', 'phase-2'),
      _fanEdge('phase-2', 'group-20'),
      _fanEdge('phase-2', 'group-21'),
      _spineEdge('phase-2', 'phase-3'),
      _fanEdge('phase-3', 'group-30'),
      _fanEdge('phase-3', 'group-31'),
      _spineEdge('phase-3', 'end'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) graphWithDecisionAndOrphan() {
  return (
    [
      _startNode(),
      _phaseNode(1),
      _endNode(),
      EdenDiagramNode(
        id: 'decision-7',
        shape: EdenNodeShape.diamond,
        x: 0,
        y: 0,
        width: 140,
        height: 140,
        label: 'Approve?',
        data: const {'nodeType': 'decision', 'decisionId': 7},
      ),
      EdenDiagramNode(
        id: 'orphan-1',
        shape: EdenNodeShape.roundedRect,
        x: 0,
        y: 0,
        width: 180,
        height: 56,
        label: 'Floating',
        data: const {'nodeType': 'orphan', 'orphanType': 'task'},
      ),
    ],
    [
      _spineEdge('start', 'phase-1'),
      _spineEdge('phase-1', 'end'),
    ],
  );
}

// ─────────── Free-form / grid / linear layout fixtures (TRD 006-09) ───────────

EdenDiagramNode _generic(String id) => EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 160,
      height: 80,
      label: id,
      data: const {},
    );

(List<EdenDiagramNode>, List<EdenDiagramEdge>) chainGraph() {
  return (
    [_startNode(), _phaseNode(1), _phaseNode(2), _endNode()],
    [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'phase-2'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-2', targetId: 'end'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) branchingGraph() {
  return (
    [_startNode(), _phaseNode(1), _phaseNode(2), _endNode()],
    [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'start', targetId: 'phase-2'),
      EdenDiagramEdge(id: 'e3', sourceId: 'phase-1', targetId: 'end'),
      EdenDiagramEdge(id: 'e4', sourceId: 'phase-2', targetId: 'end'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) diamondGraph() {
  return (
    [_startNode(), _generic('a'), _generic('b'), _generic('c'), _endNode()],
    [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'a'),
      EdenDiagramEdge(id: 'e2', sourceId: 'a', targetId: 'c'),
      EdenDiagramEdge(id: 'e3', sourceId: 'c', targetId: 'end'),
      EdenDiagramEdge(id: 'e4', sourceId: 'start', targetId: 'b'),
      EdenDiagramEdge(id: 'e5', sourceId: 'b', targetId: 'end'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>) cycleGraph() {
  return (
    [_generic('a'), _generic('b'), _generic('c')],
    [
      EdenDiagramEdge(id: 'e1', sourceId: 'a', targetId: 'b'),
      EdenDiagramEdge(id: 'e2', sourceId: 'b', targetId: 'c'),
      EdenDiagramEdge(id: 'e3', sourceId: 'c', targetId: 'a'),
    ],
  );
}

(List<EdenDiagramNode>, List<EdenDiagramEdge>)
    chainWithDisconnectedOrphanGraph() {
  return (
    [
      _startNode(),
      _phaseNode(1),
      _endNode(),
      _generic('orphan-1'),
    ],
    [
      EdenDiagramEdge(id: 'e1', sourceId: 'start', targetId: 'phase-1'),
      EdenDiagramEdge(id: 'e2', sourceId: 'phase-1', targetId: 'end'),
    ],
  );
}

List<EdenDiagramNode> sixNodesForGrid() =>
    [for (int i = 1; i <= 6; i++) _generic('n$i')];

List<EdenDiagramNode> fourNodesForLinear() =>
    [for (int i = 1; i <= 4; i++) _generic('n$i')];

(List<EdenDiagramNode>, List<EdenDiagramEdge>) graphWithDependencyEdgeMixed() {
  // Group-10 has an autoFan edge (counted) AND a dependency edge (skipped).
  return (
    [
      _startNode(),
      _phaseNode(1),
      _groupNode(10, 1),
      _endNode(),
    ],
    [
      _spineEdge('start', 'phase-1'),
      _fanEdge('phase-1', 'group-10'),
      // A dependency edge that should be skipped by the layout algorithm.
      EdenDiagramEdge(
        id: 'dep-something',
        sourceId: 'start',
        targetId: 'group-10',
        data: const {'edgeStyle': 'dependency'},
      ),
      _spineEdge('phase-1', 'end'),
    ],
  );
}

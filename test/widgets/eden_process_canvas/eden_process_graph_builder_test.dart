import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_models_fixtures.dart';

void main() {
  group('EdenProcessGraphBuilder.build — basic shape', () {
    test('empty definition with start+end emits 2 nodes + 1 spine edge', () {
      final def = processDefinitionFixture(
        phases: const [],
        config: const EdenProcessConfig(flowNodes: {'start': true, 'end': true}),
      );
      final (nodes, edges) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id), ['start', 'end']);
      expect(edges, hasLength(1));
      expect(edges.single.sourceId, 'start');
      expect(edges.single.targetId, 'end');
    });

    test('1-phase definition emits [start, phase-1, end] + 2 spine edges', () {
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
        config: const EdenProcessConfig(flowNodes: {'start': true, 'end': true}),
      );
      final (nodes, edges) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id), ['start', 'phase-1', 'end']);
      expect(edges, hasLength(2));
      expect(edges[0].sourceId, 'start');
      expect(edges[0].targetId, 'phase-1');
      expect(edges[1].sourceId, 'phase-1');
      expect(edges[1].targetId, 'end');
    });

    test('3-phase definition emits 5 nodes + 4 spine edges', () {
      final def = processDefinitionFixture(
        phases: [
          planningPhaseFixture(id: 1),
          executionPhaseFixture(id: 2),
          closeoutPhaseFixture(id: 3),
        ],
        config: const EdenProcessConfig(flowNodes: {'start': true, 'end': true}),
      );
      final (nodes, edges) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id), ['start', 'phase-1', 'phase-2', 'phase-3', 'end']);
      expect(edges, hasLength(4));
    });

    test('phase with 2 groups emits 3 nodes per phase + 2 fan edges', () {
      final def = processDefinitionFixture(
        phases: [
          planningPhaseFixture(
            id: 1,
            groups: [
              taskGroupFixture(id: 10, processPhaseId: 1, sortOrder: 0),
              taskGroupFixture(
                  id: 11,
                  processPhaseId: 1,
                  sortOrder: 1,
                  name: 'g2',
                  displayName: 'G2'),
            ],
          ),
        ],
        config: const EdenProcessConfig(flowNodes: {'start': true, 'end': true}),
      );
      final (nodes, edges) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id),
          containsAll(<String>['start', 'phase-1', 'group-10', 'group-11', 'end']));
      // 2 fan edges + 2 spine edges
      final fanEdges =
          edges.where((e) => e.data['edgeStyle'] == 'autoFan').toList();
      expect(fanEdges, hasLength(2));
    });
  });

  group('EdenProcessGraphBuilder.build — config.flowNodes opt-out', () {
    test('flowNodes start:false omits start node', () {
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
        config: const EdenProcessConfig(flowNodes: {'start': false, 'end': true}),
      );
      final (nodes, _) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id).contains('start'), isFalse);
    });

    test('flowNodes end:false omits end node', () {
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
        config: const EdenProcessConfig(flowNodes: {'start': true, 'end': false}),
      );
      final (nodes, _) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id).contains('end'), isFalse);
    });
  });

  group('EdenProcessGraphBuilder.build — config.decisions', () {
    test('decisions emit decision-N nodes but are NOT auto-connected', () {
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
        config: EdenProcessConfig(
          flowNodes: const {'start': true, 'end': true},
          decisions: [decisionFixture(id: 1)],
        ),
      );
      final (nodes, edges) = EdenProcessGraphBuilder.build(def);
      expect(nodes.map((n) => n.id), contains('decision-1'));
      // No edges connecting to decision-1
      expect(
        edges.where(
            (e) => e.sourceId == 'decision-1' || e.targetId == 'decision-1'),
        isEmpty,
      );
    });
  });

  group('EdenProcessGraphBuilder.build — controller-aware positions', () {
    test('manualPositions override default zero', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.recordManualPosition('phase-1', const Offset(200, 100));
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
      );
      final (nodes, _) =
          EdenProcessGraphBuilder.build(def, controller: ctrl);
      final phase = nodes.firstWhere((n) => n.id == 'phase-1');
      expect(phase.x, 200);
      expect(phase.y, 100);
    });

    test('pendingPositions used when manual is unset', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.setPendingPosition('phase-1', const Offset(300, 50));
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
      );
      final (nodes, _) =
          EdenProcessGraphBuilder.build(def, controller: ctrl);
      final phase = nodes.firstWhere((n) => n.id == 'phase-1');
      expect(phase.x, 300);
      expect(phase.y, 50);
    });

    test('manual takes precedence over pending when both set', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.setPendingPosition('phase-1', const Offset(300, 50));
      ctrl.recordManualPosition('phase-1', const Offset(100, 25));
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
      );
      final (nodes, _) =
          EdenProcessGraphBuilder.build(def, controller: ctrl);
      final phase = nodes.firstWhere((n) => n.id == 'phase-1');
      expect(phase.x, 100);
      expect(phase.y, 25);
    });

    test('without controller, positions default to zero', () {
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
      );
      final (nodes, _) = EdenProcessGraphBuilder.build(def);
      final phase = nodes.firstWhere((n) => n.id == 'phase-1');
      expect(phase.x, 0);
      expect(phase.y, 0);
    });
  });

  group('EdenProcessGraphBuilder.build — edge styling markers', () {
    test('spine edges carry edgeStyle: spine', () {
      final def = processDefinitionFixture(
        phases: [planningPhaseFixture(id: 1)],
        config: const EdenProcessConfig(flowNodes: {'start': true, 'end': true}),
      );
      final (_, edges) = EdenProcessGraphBuilder.build(def);
      for (final e in edges) {
        expect(e.data['edgeStyle'], 'spine');
      }
    });

    test('autoFan edges are dashed', () {
      final def = processDefinitionFixture(
        phases: [
          planningPhaseFixture(
            id: 1,
            groups: [taskGroupFixture(id: 10, processPhaseId: 1)],
          ),
        ],
      );
      final (_, edges) = EdenProcessGraphBuilder.build(def);
      final fan = edges.firstWhere((e) => e.data['edgeStyle'] == 'autoFan');
      expect(fan.style, EdenEdgeStyle.dashed);
    });
  });

  group('EdenProcessGraphBuilder.build — showAllGroups flag', () {
    test('showAllGroups true emits groups for all phases', () {
      final def = processDefinitionFixture(
        phases: [
          planningPhaseFixture(
            id: 1,
            groups: [taskGroupFixture(id: 10, processPhaseId: 1)],
          ),
          executionPhaseFixture(
            id: 2,
            groups: [taskGroupFixture(id: 20, processPhaseId: 2)],
          ),
        ],
      );
      final (nodes, _) =
          EdenProcessGraphBuilder.build(def, showAllGroups: true);
      expect(nodes.map((n) => n.id), containsAll(<String>['group-10', 'group-20']));
    });

    test('showAllGroups false respects controller.expandedPhaseIds', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.togglePhaseExpanded(1);
      final def = processDefinitionFixture(
        phases: [
          planningPhaseFixture(
            id: 1,
            groups: [taskGroupFixture(id: 10, processPhaseId: 1)],
          ),
          executionPhaseFixture(
            id: 2,
            groups: [taskGroupFixture(id: 20, processPhaseId: 2)],
          ),
        ],
      );
      final (nodes, _) = EdenProcessGraphBuilder.build(
        def,
        controller: ctrl,
        showAllGroups: false,
      );
      expect(nodes.map((n) => n.id), contains('group-10'));
      expect(nodes.map((n) => n.id), isNot(contains('group-20')));
    });
  });

  group('EdenProcessAutoEdgeStyle + EdenProcessEdgeStyles helper', () {
    test('enum has 3 values', () {
      expect(EdenProcessAutoEdgeStyle.values, hasLength(3));
    });

    test('user → solid + edgeStyle=user', () {
      final e = EdenProcessEdgeStyles.styledEdge(
        id: 'e',
        sourceId: 'a',
        targetId: 'b',
        style: EdenProcessAutoEdgeStyle.user,
      );
      expect(e.style, EdenEdgeStyle.solid);
      expect(e.data['edgeStyle'], 'user');
    });

    test('autoFan → dashed + edgeStyle=autoFan', () {
      final e = EdenProcessEdgeStyles.styledEdge(
        id: 'e',
        sourceId: 'a',
        targetId: 'b',
        style: EdenProcessAutoEdgeStyle.autoFan,
      );
      expect(e.style, EdenEdgeStyle.dashed);
      expect(e.data['edgeStyle'], 'autoFan');
    });

    test('spine → solid + edgeStyle=spine', () {
      final e = EdenProcessEdgeStyles.styledEdge(
        id: 'e',
        sourceId: 'a',
        targetId: 'b',
        style: EdenProcessAutoEdgeStyle.spine,
      );
      expect(e.style, EdenEdgeStyle.solid);
      expect(e.data['edgeStyle'], 'spine');
    });
  });

  group('EdenProcessLayoutEngine interface + stub subclasses', () {
    test('EdenSwimlaneLayout has id "swimlane"', () {
      expect(const EdenSwimlaneLayout().id, 'swimlane');
    });

    test('EdenFreeFormLayout has id "free_form"', () {
      expect(const EdenFreeFormLayout().id, 'free_form');
    });

    test('EdenGridLayout has id "grid"', () {
      expect(const EdenGridLayout().id, 'grid');
    });

    test('EdenLinearLayout has id "linear"', () {
      expect(const EdenLinearLayout().id, 'linear');
    });

    test('stub applyLayout returns input nodes unchanged', () {
      final nodes = [EdenDiagramNode(id: 'a', x: 0, y: 0)];
      expect(const EdenSwimlaneLayout().applyLayout(nodes, []), nodes);
      expect(const EdenFreeFormLayout().applyLayout(nodes, []), nodes);
      expect(const EdenGridLayout().applyLayout(nodes, []), nodes);
      expect(const EdenLinearLayout().applyLayout(nodes, []), nodes);
    });

    test('stub applyLayout([], []) returns []', () {
      expect(const EdenSwimlaneLayout().applyLayout(const [], const []), isEmpty);
    });
  });
}

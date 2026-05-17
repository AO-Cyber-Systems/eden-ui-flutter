import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_workflow_models_fixtures.dart';

void main() {
  setUp(() {
    EdenWorkflowCategoryRegistry.instance.resetToDefaults();
    EdenWorkflowActionRegistry.instance.resetToDefaults();
  });

  group('EdenWorkflowGraphBuilder.toCanvas — basic shapes', () {
    test('empty definition emits trigger + end (2 nodes, 1 edge)', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithEmptyConditionsAndActionsFixture(),
      );
      expect(nodes.length, 2);
      expect(edges.length, 1);
      expect(nodes[0].id, 'trigger-0');
      expect(nodes[1].id, 'end-0');
      expect(edges[0].sourceId, 'trigger-0');
      expect(edges[0].targetId, 'end-0');
    });

    test('single action — 3 nodes / 2 edges (trigger→action→end)', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleActionFixture(),
      );
      expect(nodes.map((n) => n.id), ['trigger-0', 'action-0', 'end-0']);
      expect(edges.length, 2);
      expect(edges[0].sourceId, 'trigger-0');
      expect(edges[0].targetId, 'action-0');
      expect(edges[1].sourceId, 'action-0');
      expect(edges[1].targetId, 'end-0');
    });

    test('single condition — condition→end edge uses sourceHandle="yes"', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleConditionFixture(),
      );
      expect(nodes.map((n) => n.id), ['trigger-0', 'condition-0', 'end-0']);
      // condition-0 → end-0 must use 'yes' source handle (donor parity)
      final condToEnd = edges.firstWhere(
        (e) => e.sourceId == 'condition-0' && e.targetId == 'end-0',
      );
      expect(condToEnd.data['sourceHandle'], 'yes');
    });

    test('2 conditions + 3 actions — 7 nodes / 6 edges in chained order', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWith2Conditions3ActionsFixture(),
      );
      expect(nodes.map((n) => n.id), [
        'trigger-0',
        'condition-0',
        'condition-1',
        'action-0',
        'action-1',
        'action-2',
        'end-0',
      ]);
      expect(edges.length, 6);
      // Each condition→next edge uses 'yes' handle
      final fromCondEdges = edges.where((e) =>
          e.sourceId == 'condition-0' || e.sourceId == 'condition-1');
      for (final e in fromCondEdges) {
        expect(e.data['sourceHandle'], 'yes');
      }
    });
  });

  group('EdenWorkflowGraphBuilder.toCanvas — node data + ports', () {
    test('trigger node carries triggerType + category + config + nodeType', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithEmptyConditionsAndActionsFixture(),
      );
      final trigger = nodes.firstWhere((n) => n.id == 'trigger-0');
      expect(trigger.data['nodeType'], 'trigger');
      expect(trigger.data['triggerType'], 'entity_created');
      expect(trigger.data['category'], 'appointment');
      expect(trigger.data['config'], isA<Map>());
    });

    test('condition node carries field + operator + value + nodeType', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleConditionFixture(),
      );
      final cond = nodes.firstWhere((n) => n.id == 'condition-0');
      expect(cond.data['nodeType'], 'condition');
      expect(cond.data['field'], 'priority');
      expect(cond.data['operator'], 'equals');
      expect(cond.data['value'], 'high');
    });

    test('action node carries actionType + config + nodeType', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleActionFixture(),
      );
      final act = nodes.firstWhere((n) => n.id == 'action-0');
      expect(act.data['nodeType'], 'action');
      expect(act.data['actionType'], 'send_notification');
      expect(act.data['config'], isA<Map>());
    });

    test('end node carries only nodeType', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithEmptyConditionsAndActionsFixture(),
      );
      final end = nodes.firstWhere((n) => n.id == 'end-0');
      expect(end.data['nodeType'], 'end');
    });

    test('trigger node has 2 source ports (right + bottom)', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithEmptyConditionsAndActionsFixture(),
      );
      final trigger = nodes.firstWhere((n) => n.id == 'trigger-0');
      expect(trigger.ports, isNotNull);
      final sourceIds = trigger.ports!
          .where((p) => p.kind == EdenDiagramPortKind.source)
          .map((p) => p.id)
          .toSet();
      expect(sourceIds, {'right', 'bottom'});
    });

    test('condition node has 2 target ports + yes + no source ports', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleConditionFixture(),
      );
      final cond = nodes.firstWhere((n) => n.id == 'condition-0');
      expect(cond.ports, isNotNull);
      final ids = cond.ports!.map((p) => p.id).toSet();
      expect(ids, containsAll(['top', 'left', 'yes', 'no']));
      final yesPort = cond.ports!.firstWhere((p) => p.id == 'yes');
      expect(yesPort.kind, EdenDiagramPortKind.source);
      final noPort = cond.ports!.firstWhere((p) => p.id == 'no');
      expect(noPort.kind, EdenDiagramPortKind.source);
    });

    test('action node has 2 target ports + 2 source ports (4 total)', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleActionFixture(),
      );
      final act = nodes.firstWhere((n) => n.id == 'action-0');
      expect(act.ports, isNotNull);
      final ids = act.ports!.map((p) => p.id).toSet();
      expect(ids, {'top', 'left', 'right', 'bottom'});
      expect(act.ports!.length, 4);
    });

    test('end node has only target ports (top + left); no source ports', () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithEmptyConditionsAndActionsFixture(),
      );
      final end = nodes.firstWhere((n) => n.id == 'end-0');
      expect(end.ports, isNotNull);
      final sources =
          end.ports!.where((p) => p.kind == EdenDiagramPortKind.source);
      expect(sources, isEmpty);
      final targets = end.ports!
          .where((p) => p.kind == EdenDiagramPortKind.target)
          .map((p) => p.id)
          .toSet();
      expect(targets, {'top', 'left'});
    });
  });

  group('EdenWorkflowGraphBuilder.toCanvas — layout', () {
    test('saved positions are applied to node x/y', () {
      final (nodes, _) =
          EdenWorkflowGraphBuilder.toCanvas(definitionWithSavedLayoutFixture());
      final trigger = nodes.firstWhere((n) => n.id == 'trigger-0');
      expect(trigger.x, 100);
      expect(trigger.y, 100);
      final action0 = nodes.firstWhere((n) => n.id == 'action-0');
      expect(action0.x, 1000);
      expect(action0.y, 0);
    });

    test('without saved layout, EdenFreeFormLayout assigns non-zero positions',
        () {
      final (nodes, _) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWith2Conditions3ActionsFixture(),
      );
      // All nodes should have positions assigned (not (0,0) for everything).
      final positions = nodes.map((n) => (n.x, n.y)).toSet();
      // At least 3 distinct positions for 7 nodes is a sanity floor.
      expect(positions.length, greaterThan(2));
      // Trigger (rank 0) should be at left-most x; end (largest rank) at right-most.
      final trigger = nodes.firstWhere((n) => n.id == 'trigger-0');
      final end = nodes.firstWhere((n) => n.id == 'end-0');
      expect(end.x, greaterThan(trigger.x));
    });

    test('user-drawn edges in canvasLayout.edges are appended (de-dup by id)',
        () {
      final def = EdenWorkflowDefinition(
        id: 99,
        name: 'user_edge',
        version: 1,
        isPublished: false,
        hasUnpublishedChanges: false,
        triggerType: EdenWorkflowTriggerType.manual,
        category: 'task',
        triggerConfig: const {},
        conditions: const [],
        actions: [sendEmailActionFixture()],
        canvasLayout: const EdenWorkflowCanvasLayout(
          version: 1,
          nodes: {
            'trigger-0': EdenProcessNodePosition(x: 0, y: 0),
            'action-0': EdenProcessNodePosition(x: 200, y: 0),
            'end-0': EdenProcessNodePosition(x: 400, y: 0),
          },
          edges: [
            EdenProcessSavedEdge(
              id: 'user-edge-1',
              source: 'trigger-0',
              target: 'end-0',
              sourceHandle: 'bottom',
              targetHandle: 'left',
            ),
          ],
        ),
      );
      final (_, edges) = EdenWorkflowGraphBuilder.toCanvas(def);
      // Auto: trigger→action, action→end. Plus user: trigger→end.
      expect(edges.length, 3);
      final userEdge =
          edges.firstWhere((e) => e.id == 'user-edge-1');
      expect(userEdge.data['sourceHandle'], 'bottom');
      expect(userEdge.data['userDrawn'], isTrue);
    });
  });

  group('EdenWorkflowGraphBuilder.fromCanvas', () {
    test('trigger + end only — returns empty conditions[] + actions[]', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithEmptyConditionsAndActionsFixture(),
      );
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(saveData.conditions, isEmpty);
      expect(saveData.actions, isEmpty);
      expect(saveData.triggerType, EdenWorkflowTriggerType.entity_created);
      expect(saveData.category, 'appointment');
    });

    test('trigger + action + end — returns 1 action / 0 conditions', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleActionFixture(),
      );
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(saveData.conditions, isEmpty);
      expect(saveData.actions.length, 1);
      expect(saveData.actions[0].actionType, 'send_notification');
    });

    test('2 cond + 3 actions — order preserved in execution order', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWith2Conditions3ActionsFixture(),
      );
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(saveData.conditions.length, 2);
      expect(saveData.actions.length, 3);
      expect(saveData.conditions[0].field, 'priority');
      expect(saveData.conditions[1].field, 'amount');
      expect(saveData.actions[0].actionType, 'send_notification');
      expect(saveData.actions[1].actionType, 'create_task');
      expect(saveData.actions[2].actionType, 'send_email');
    });

    test('Yes/No split — BFS prefers Yes branch first', () {
      // Two action branches from a single condition: yes-branch + no-branch.
      // The BFS walk visits the Yes branch's node first.
      final triggerNode = EdenDiagramNode(
        id: 'trigger-0',
        x: 0,
        y: 0,
        data: {
          'nodeType': 'trigger',
          'triggerType': 'entity_created',
          'category': 'appointment',
          'config': const {},
        },
      );
      final condNode = EdenDiagramNode(
        id: 'condition-0',
        x: 200,
        y: 0,
        data: {
          'nodeType': 'condition',
          'field': 'priority',
          'operator': 'equals',
          'value': 'high',
        },
      );
      final yesAction = EdenDiagramNode(
        id: 'action-yes',
        x: 400,
        y: -50,
        data: {
          'nodeType': 'action',
          'actionType': 'send_notification',
          'config': const {},
        },
      );
      final noAction = EdenDiagramNode(
        id: 'action-no',
        x: 400,
        y: 100,
        data: {
          'nodeType': 'action',
          'actionType': 'send_email',
          'config': const {},
        },
      );
      final endNode = EdenDiagramNode(
        id: 'end-0',
        x: 600,
        y: 0,
        data: {'nodeType': 'end'},
      );
      final edges = [
        EdenDiagramEdge(
          id: 'e1',
          sourceId: 'trigger-0',
          targetId: 'condition-0',
          data: {'sourceHandle': 'right'},
        ),
        EdenDiagramEdge(
          id: 'e2',
          sourceId: 'condition-0',
          targetId: 'action-no',
          data: {'sourceHandle': 'no'},
        ),
        EdenDiagramEdge(
          id: 'e3',
          sourceId: 'condition-0',
          targetId: 'action-yes',
          data: {'sourceHandle': 'yes'},
        ),
        EdenDiagramEdge(
          id: 'e4',
          sourceId: 'action-yes',
          targetId: 'end-0',
          data: {'sourceHandle': 'right'},
        ),
        EdenDiagramEdge(
          id: 'e5',
          sourceId: 'action-no',
          targetId: 'end-0',
          data: {'sourceHandle': 'right'},
        ),
      ];
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(
        [triggerNode, condNode, yesAction, noAction, endNode],
        edges,
      );
      // Yes branch visited first, so action-yes (send_notification) appears
      // before action-no (send_email) in actions[].
      expect(saveData.actions.length, 2);
      expect(saveData.actions[0].actionType, 'send_notification');
      expect(saveData.actions[1].actionType, 'send_email');
    });

    test('canvasLayout.nodes keyed by node id with positions', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSavedLayoutFixture(),
      );
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(saveData.canvasLayout.nodes.containsKey('trigger-0'), isTrue);
      expect(saveData.canvasLayout.nodes['trigger-0'],
          isA<EdenProcessNodePosition>());
    });

    test('canvasLayout.edges contains only user-drawn edges', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleActionFixture(),
      );
      // No userEdges passed → canvas layout edges should be empty
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(saveData.canvasLayout.edges, isEmpty);
    });

    test('userEdges arg populates canvasLayout.edges', () {
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(
        definitionWithSingleActionFixture(),
      );
      final userEdge = EdenDiagramEdge(
        id: 'user-extra-1',
        sourceId: 'trigger-0',
        targetId: 'end-0',
        data: const {'sourceHandle': 'bottom', 'targetHandle': 'left'},
      );
      final saveData = EdenWorkflowGraphBuilder.fromCanvas(
        nodes,
        edges,
        userEdges: [userEdge],
      );
      expect(saveData.canvasLayout.edges.length, 1);
      expect(saveData.canvasLayout.edges[0].id, 'user-extra-1');
      expect(saveData.canvasLayout.edges[0].sourceHandle, 'bottom');
    });
  });

  group('EdenWorkflowGraphBuilder — round-trip', () {
    test('toCanvas → fromCanvas preserves conditions[] + actions[]', () {
      final original = definitionWith2Conditions3ActionsFixture();
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(original);
      final back = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(back.triggerType, original.triggerType);
      expect(back.category, original.category);
      expect(back.conditions.length, original.conditions.length);
      for (var i = 0; i < original.conditions.length; i++) {
        expect(back.conditions[i], original.conditions[i]);
      }
      expect(back.actions.length, original.actions.length);
      for (var i = 0; i < original.actions.length; i++) {
        expect(back.actions[i], original.actions[i]);
      }
    });

    test('round-trip preserves triggerConfig', () {
      final original = fullExampleDefinitionFixture();
      final (nodes, edges) = EdenWorkflowGraphBuilder.toCanvas(original);
      final back = EdenWorkflowGraphBuilder.fromCanvas(nodes, edges);
      expect(back.triggerConfig['channel'], 'web');
    });
  });
}

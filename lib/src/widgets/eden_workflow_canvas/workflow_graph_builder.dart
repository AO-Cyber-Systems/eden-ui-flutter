// EdenWorkflowGraphBuilder — bidirectional pure-function converter between
// EdenWorkflowDefinition and (List<EdenDiagramNode>, List<EdenDiagramEdge>).
//
// Algorithm parity: donor `useWorkflowToFlow.ts` (toCanvas) +
// `flowToWorkflowData.ts` (fromCanvas). Ports TS hooks → pure static Dart.
//
// Reuses EdenFreeFormLayout (obj 006 BFS rank) — no Dagre dep.
// Reuses EdenDiagramPort multi-handle node model (obj 006 parity E-5).

import 'dart:ui' show Offset;

import '../eden_diagram/diagram_data.dart';
import '../eden_process_canvas/process_layout_engine.dart'
    show EdenFreeFormLayout;
import '../eden_process_canvas/process_models.dart'
    show EdenProcessNodePosition, EdenProcessSavedEdge;
import 'workflow_action_registry.dart';
import 'workflow_category_registry.dart';
import 'workflow_models.dart';

abstract class EdenWorkflowGraphBuilder {
  EdenWorkflowGraphBuilder._();

  /// Convert an [EdenWorkflowDefinition] into canvas nodes + edges.
  ///
  /// Algorithm (donor parity):
  ///   1. Emit `trigger-0` node.
  ///   2. For each condition[i]: emit `condition-$i` node + edge from prev.
  ///   3. For each action[i]: emit `action-$i` node + edge from prev.
  ///   4. Emit `end-0` + edge from final node.
  ///   5. Append user-drawn edges from `definition.canvasLayout.edges` not
  ///      already in auto-generated edges (de-dup by edge id).
  ///   6. If no saved positions, apply [EdenFreeFormLayout] (BFS rank).
  ///
  /// Edge `data['sourceHandle']` carries the donor's React-Flow handle ids:
  ///   - `'right'` for non-condition→next edges
  ///   - `'yes'` for condition→next edges (Yes-path priority preserved)
  static (List<EdenDiagramNode>, List<EdenDiagramEdge>) toCanvas(
    EdenWorkflowDefinition definition,
  ) {
    final nodes = <EdenDiagramNode>[];
    final edges = <EdenDiagramEdge>[];

    final savedPositions = definition.canvasLayout?.nodes ??
        const <String, EdenProcessNodePosition>{};
    final hasSavedLayout = savedPositions.isNotEmpty;

    Offset positionFor(String nodeId) {
      final saved = savedPositions[nodeId];
      return saved != null ? Offset(saved.x, saved.y) : Offset.zero;
    }

    // 1. Trigger node
    final triggerPos = positionFor('trigger-0');
    nodes.add(EdenDiagramNode(
      id: 'trigger-0',
      x: triggerPos.dx,
      y: triggerPos.dy,
      width: 200,
      height: 80,
      label: _triggerLabel(definition.triggerType, definition.category),
      data: {
        'nodeType': 'trigger',
        'triggerType': definition.triggerType.name,
        'category': definition.category,
        'config': definition.triggerConfig,
      },
      ports: triggerPorts(),
    ));

    var prevNodeId = 'trigger-0';

    // 2. Conditions
    for (var i = 0; i < definition.conditions.length; i++) {
      final cond = definition.conditions[i];
      final id = 'condition-$i';
      final pos = positionFor(id);
      nodes.add(EdenDiagramNode(
        id: id,
        x: pos.dx,
        y: pos.dy,
        width: 160,
        height: 160,
        label: '${cond.field} ${_operatorSymbol(cond.operator)} ${cond.value}',
        data: {
          'nodeType': 'condition',
          'field': cond.field,
          'operator': cond.operator.name,
          'value': cond.value,
        },
        ports: conditionPorts(),
      ));
      edges.add(EdenDiagramEdge(
        id: 'edge-$prevNodeId-$id',
        sourceId: prevNodeId,
        targetId: id,
        data: {
          'sourceHandle':
              prevNodeId.startsWith('condition-') ? 'yes' : 'right',
          'targetHandle': 'top',
        },
      ));
      prevNodeId = id;
    }

    // 3. Actions
    for (var i = 0; i < definition.actions.length; i++) {
      final action = definition.actions[i];
      final id = 'action-$i';
      final pos = positionFor(id);
      nodes.add(EdenDiagramNode(
        id: id,
        x: pos.dx,
        y: pos.dy,
        width: 200,
        height: 80,
        label: _actionLabel(action.actionType),
        data: {
          'nodeType': 'action',
          'actionType': action.actionType,
          'config': action.config,
        },
        ports: actionPorts(),
      ));
      edges.add(EdenDiagramEdge(
        id: 'edge-$prevNodeId-$id',
        sourceId: prevNodeId,
        targetId: id,
        data: {
          'sourceHandle':
              prevNodeId.startsWith('condition-') ? 'yes' : 'right',
          'targetHandle': 'top',
        },
      ));
      prevNodeId = id;
    }

    // 4. End node + edge from final
    const endId = 'end-0';
    final endPos = positionFor(endId);
    nodes.add(EdenDiagramNode(
      id: endId,
      x: endPos.dx,
      y: endPos.dy,
      width: 48,
      height: 48,
      label: 'End',
      data: const {'nodeType': 'end'},
      ports: endPorts(),
    ));
    edges.add(EdenDiagramEdge(
      id: 'edge-$prevNodeId-$endId',
      sourceId: prevNodeId,
      targetId: endId,
      data: {
        'sourceHandle': prevNodeId.startsWith('condition-') ? 'yes' : 'right',
        'targetHandle': 'top',
      },
    ));

    // 5. Append user-drawn edges not already present (de-dup by id)
    if (definition.canvasLayout != null) {
      final autoIds = edges.map((e) => e.id).toSet();
      for (final saved in definition.canvasLayout!.edges) {
        if (!autoIds.contains(saved.id)) {
          edges.add(EdenDiagramEdge(
            id: saved.id,
            sourceId: saved.source,
            targetId: saved.target,
            data: {
              if (saved.sourceHandle != null)
                'sourceHandle': saved.sourceHandle,
              if (saved.targetHandle != null)
                'targetHandle': saved.targetHandle,
              'userDrawn': true,
            },
          ));
        }
      }
    }

    // 6. Auto-layout if no saved positions
    if (!hasSavedLayout) {
      final laidOut = const EdenFreeFormLayout().applyLayout(nodes, edges);
      return (laidOut, edges);
    }
    return (nodes, edges);
  }

  /// Convert canvas nodes + edges back to an [EdenWorkflowSaveData].
  ///
  /// BFS from the trigger node, preferring `sourceHandle` `'yes'` then
  /// `'right'` (donor parity — preserves Yes-path priority through
  /// conditions). Trigger + end nodes are skipped in the conditions/actions
  /// extraction; only condition / action node-types are persisted.
  ///
  /// `userEdges` argument MUST be the user-drawn edge subset (NOT auto-
  /// generated trigger→cond→action ladder edges); these are passed back into
  /// `canvasLayout.edges` for round-trip with the canvas's user-saved edges.
  static EdenWorkflowSaveData fromCanvas(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges, {
    List<EdenDiagramEdge> userEdges = const [],
  }) {
    final triggerNode = nodes.firstWhere(
      (n) => n.data['nodeType'] == 'trigger',
      orElse: () => throw StateError('No trigger node in canvas'),
    );
    final triggerType = EdenWorkflowTriggerType.values.firstWhere(
      (t) => t.name == triggerNode.data['triggerType'],
      orElse: () => EdenWorkflowTriggerType.manual,
    );
    final triggerConfig =
        (triggerNode.data['config'] as Map?)?.cast<String, dynamic>() ??
            const {};
    final category = triggerNode.data['category'] as String? ?? 'appointment';

    // Adjacency: source -> [(target, sourceHandle), ...] — yes/right first.
    final adjacency =
        <String, List<({String target, String? sourceHandle})>>{};
    for (final edge in edges) {
      final handle = edge.data['sourceHandle'] as String?;
      adjacency.putIfAbsent(edge.sourceId, () => []);
      final entry = (target: edge.targetId, sourceHandle: handle);
      if (handle == 'yes' || handle == 'right') {
        adjacency[edge.sourceId]!.insert(0, entry);
      } else {
        adjacency[edge.sourceId]!.add(entry);
      }
    }

    // BFS from trigger
    final visited = <String>{triggerNode.id};
    final visitOrder = <EdenDiagramNode>[];
    final nodeById = {for (final n in nodes) n.id: n};
    final queue = <String>[triggerNode.id];
    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final node = nodeById[currentId];
      if (node != null) {
        final nt = node.data['nodeType'];
        if (nt != 'trigger' && nt != 'end') {
          visitOrder.add(node);
        }
      }
      for (final adj in adjacency[currentId] ?? const []) {
        if (visited.add(adj.target)) queue.add(adj.target);
      }
    }

    final conditions = <EdenWorkflowCondition>[];
    final actions = <EdenWorkflowAction>[];
    for (final node in visitOrder) {
      switch (node.data['nodeType']) {
        case 'condition':
          conditions.add(EdenWorkflowCondition(
            field: node.data['field'] as String,
            operator: EdenWorkflowConditionOperator.values.firstWhere(
              (o) => o.name == node.data['operator'],
              orElse: () => EdenWorkflowConditionOperator.equals,
            ),
            value: node.data['value'],
          ));
          break;
        case 'action':
          actions.add(EdenWorkflowAction(
            actionType: node.data['actionType'] as String,
            config: (node.data['config'] as Map?)?.cast<String, dynamic>() ??
                const {},
          ));
          break;
        // delay / branch / merge / end nodes: not in flat conditions/actions
        // (layout-only; future enhancement could persist them separately).
      }
    }

    // Layout: positions for ALL nodes (incl. trigger/end), user edges only.
    final layoutNodes = <String, EdenProcessNodePosition>{
      for (final n in nodes) n.id: EdenProcessNodePosition(x: n.x, y: n.y),
    };
    final savedEdges = userEdges
        .map((e) => EdenProcessSavedEdge(
              id: e.id,
              source: e.sourceId,
              target: e.targetId,
              sourceHandle: e.data['sourceHandle'] as String?,
              targetHandle: e.data['targetHandle'] as String?,
            ))
        .toList();

    return EdenWorkflowSaveData(
      triggerType: triggerType,
      triggerConfig: triggerConfig,
      category: category,
      conditions: conditions,
      actions: actions,
      canvasLayout: EdenWorkflowCanvasLayout(
        version: 1,
        nodes: layoutNodes,
        edges: savedEdges,
      ),
    );
  }

  // ── Internal helpers ──

  static String _triggerLabel(
    EdenWorkflowTriggerType type,
    String category,
  ) {
    final cat = EdenWorkflowCategoryRegistry.instance
            .lookup(category)
            ?.displayName ??
        category;
    final trig = switch (type) {
      EdenWorkflowTriggerType.scheduled => 'On Schedule',
      EdenWorkflowTriggerType.completed => 'On Completion',
      EdenWorkflowTriggerType.status_change => 'Status Change',
      EdenWorkflowTriggerType.time_based => 'Time-Based',
      EdenWorkflowTriggerType.manual => 'Manual Trigger',
      EdenWorkflowTriggerType.entity_created => 'Entity Created',
    };
    return '$cat: $trig';
  }

  static String _actionLabel(String actionType) {
    return EdenWorkflowActionRegistry.instance
            .lookup(actionType)
            ?.displayName ??
        actionType;
  }

  static String _operatorSymbol(EdenWorkflowConditionOperator op) =>
      switch (op) {
        EdenWorkflowConditionOperator.equals => '=',
        EdenWorkflowConditionOperator.not_equals => '!=',
        EdenWorkflowConditionOperator.greater_than => '>',
        EdenWorkflowConditionOperator.less_than => '<',
        EdenWorkflowConditionOperator.contains => 'contains',
        EdenWorkflowConditionOperator.not_contains => '!contains',
      };

  // ── Port emission helpers (per-node-type canonical layout) ──
  // Trigger: 2 source ports (right, bottom).
  // Condition: 2 target (top, left) + yes (right, green) + no (bottom, red).
  // Action: 2 target (top, left) + 2 source (right, bottom).
  // End: 2 target (top, left); NO source.
  // Branch (TRD 020-05): 2 target + 3 source (right offset 0.33, right-2 0.66, bottom).
  // Merge (TRD 020-05): 3 target (top, left 0.33, left-2 0.66) + 2 source.
  // Delay (TRD 020-05): 2 target + 2 source (same shape as action).
  //
  // Public so toolbox/drop logic (TRD 020-07) can attach the right port list
  // when creating a new node from a toolbox category.

  static List<EdenDiagramPort> triggerPorts() => const [
        EdenDiagramPort(
          id: 'right',
          side: EdenPortSide.right,
          kind: EdenDiagramPortKind.source,
        ),
        EdenDiagramPort(
          id: 'bottom',
          side: EdenPortSide.bottom,
          kind: EdenDiagramPortKind.source,
        ),
      ];

  static List<EdenDiagramPort> conditionPorts() => const [
        EdenDiagramPort(
          id: 'top',
          side: EdenPortSide.top,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left',
          side: EdenPortSide.left,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'yes',
          side: EdenPortSide.right,
          kind: EdenDiagramPortKind.source,
          color: '#10B981',
        ),
        EdenDiagramPort(
          id: 'no',
          side: EdenPortSide.bottom,
          kind: EdenDiagramPortKind.source,
          color: '#EF4444',
        ),
      ];

  static List<EdenDiagramPort> actionPorts() => const [
        EdenDiagramPort(
          id: 'top',
          side: EdenPortSide.top,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left',
          side: EdenPortSide.left,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'right',
          side: EdenPortSide.right,
          kind: EdenDiagramPortKind.source,
        ),
        EdenDiagramPort(
          id: 'bottom',
          side: EdenPortSide.bottom,
          kind: EdenDiagramPortKind.source,
        ),
      ];

  static List<EdenDiagramPort> endPorts() => const [
        EdenDiagramPort(
          id: 'top',
          side: EdenPortSide.top,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left',
          side: EdenPortSide.left,
          kind: EdenDiagramPortKind.target,
        ),
      ];

  /// Branch node ports — 2 target + 3 source (right offset 0.33, right-2 0.66,
  /// bottom). Used when EdenBranchNode is dropped from the toolbox.
  static List<EdenDiagramPort> branchPorts() => const [
        EdenDiagramPort(
          id: 'top',
          side: EdenPortSide.top,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left',
          side: EdenPortSide.left,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'right',
          side: EdenPortSide.right,
          offset: 0.33,
          kind: EdenDiagramPortKind.source,
        ),
        EdenDiagramPort(
          id: 'right-2',
          side: EdenPortSide.right,
          offset: 0.66,
          kind: EdenDiagramPortKind.source,
        ),
        EdenDiagramPort(
          id: 'bottom',
          side: EdenPortSide.bottom,
          kind: EdenDiagramPortKind.source,
        ),
      ];

  /// Merge node ports — 3 target (top, left 0.33, left-2 0.66) + 2 source.
  /// Used when EdenMergeNode is dropped from the toolbox.
  static List<EdenDiagramPort> mergePorts() => const [
        EdenDiagramPort(
          id: 'top',
          side: EdenPortSide.top,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left',
          side: EdenPortSide.left,
          offset: 0.33,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left-2',
          side: EdenPortSide.left,
          offset: 0.66,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'right',
          side: EdenPortSide.right,
          kind: EdenDiagramPortKind.source,
        ),
        EdenDiagramPort(
          id: 'bottom',
          side: EdenPortSide.bottom,
          kind: EdenDiagramPortKind.source,
        ),
      ];

  /// Delay node ports — same shape as action (2 target + 2 source).
  static List<EdenDiagramPort> delayPorts() => const [
        EdenDiagramPort(
          id: 'top',
          side: EdenPortSide.top,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'left',
          side: EdenPortSide.left,
          kind: EdenDiagramPortKind.target,
        ),
        EdenDiagramPort(
          id: 'right',
          side: EdenPortSide.right,
          kind: EdenDiagramPortKind.source,
        ),
        EdenDiagramPort(
          id: 'bottom',
          side: EdenPortSide.bottom,
          kind: EdenDiagramPortKind.source,
        ),
      ];
}

import 'package:flutter/widgets.dart';

import '../eden_diagram/eden_diagram_exports.dart';
import 'process_controller.dart';
import 'process_models.dart';

/// Edge style preset for auto-generated and user-drawn edges (objective 006).
///
/// - `user`: solid, indigo, 2pt — user-drawn edges (donor parity).
/// - `autoFan`: dashed, gray, 1.5pt — auto-generated phase→group fan-out.
/// - `spine`: solid, gray, 2pt — vertical spine connectors (start→phase,
///   phase→phase, lastPhase→end).
enum EdenProcessAutoEdgeStyle { user, autoFan, spine }

/// Helper for building styled edges with the right preset.
class EdenProcessEdgeStyles {
  EdenProcessEdgeStyles._();

  static EdenDiagramEdge styledEdge({
    required String id,
    required String sourceId,
    required String targetId,
    required EdenProcessAutoEdgeStyle style,
    EdenPortSide? sourcePort,
    EdenPortSide? targetPort,
    String? sourcePortId,
    String? targetPortId,
    String? label,
  }) {
    final edgeStyle = switch (style) {
      EdenProcessAutoEdgeStyle.user => EdenEdgeStyle.solid,
      EdenProcessAutoEdgeStyle.autoFan => EdenEdgeStyle.dashed,
      EdenProcessAutoEdgeStyle.spine => EdenEdgeStyle.solid,
    };
    return EdenDiagramEdge(
      id: id,
      sourceId: sourceId,
      targetId: targetId,
      sourcePort: sourcePort ?? EdenPortSide.right,
      targetPort: targetPort ?? EdenPortSide.left,
      sourcePortId: sourcePortId,
      targetPortId: targetPortId,
      style: edgeStyle,
      arrowHead: EdenArrowHead.filledArrow,
      label: label,
      data: {'edgeStyle': style.name},
    );
  }
}

/// Pure function that converts an `EdenProcessDefinition` into eden_diagram
/// `(nodes, edges)` — parity row S-1.
///
/// Mirrors donor `useProcessToFlow.ts`. Node ids match donor format:
///   `start`, `end`, `phase-${id}`, `group-${id}`, `decision-${id}`
/// — required for saved-layout round-trip.
///
/// Auto-generated edges carry `data['edgeStyle']` markers:
///   - `'spine'` for vertical spine (start→phase, phase→phase, lastPhase→end)
///   - `'autoFan'` for phase→group fan-out (dashed)
///
/// When a `controller` is provided, the builder reads
/// `controller.manualPositionFor(id)` and `controller.pendingPositions[id]`
/// to override the default `(0, 0)` position. Manual > pending > zero.
///
/// `showAllGroups` controls whether ALL groups are emitted vs only those
/// whose parent phase is expanded (`controller.expandedPhaseIds`). Default
/// true (matches donor `showAllNodes`).
class EdenProcessGraphBuilder {
  EdenProcessGraphBuilder._();

  static (List<EdenDiagramNode>, List<EdenDiagramEdge>) build(
    EdenProcessDefinition definition, {
    EdenProcessController? controller,
    bool showAllGroups = true,
  }) {
    final nodes = <EdenDiagramNode>[];
    final edges = <EdenDiagramEdge>[];

    Offset positionFor(String nodeId) {
      // Manual > pending > zero (locked test invariant).
      final manual = controller?.manualPositionFor(nodeId);
      if (manual != null) return manual;
      final pending = controller?.pendingPositions[nodeId];
      if (pending != null) return pending;
      return Offset.zero;
    }

    final hasStart = definition.config.flowNodes?['start'] != false;
    final hasEnd = definition.config.flowNodes?['end'] != false;

    // Start node
    if (hasStart) {
      final pos = positionFor('start');
      nodes.add(EdenDiagramNode(
        id: 'start',
        x: pos.dx,
        y: pos.dy,
        width: 48,
        height: 48,
        label: 'Start',
        data: const {'nodeType': 'start'},
      ));
    }

    // Phases (sorted by sortOrder)
    final sortedPhases = [...definition.phases]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (int i = 0; i < sortedPhases.length; i++) {
      final phase = sortedPhases[i];
      final phaseNodeId = 'phase-${phase.id}';
      final pos = positionFor(phaseNodeId);
      nodes.add(EdenDiagramNode(
        id: phaseNodeId,
        x: pos.dx,
        y: pos.dy,
        width: 240,
        height: 120,
        label: phase.displayName,
        color: phase.color,
        data: {
          'nodeType': 'phase',
          'phaseId': phase.id,
        },
      ));

      // Spine edge
      if (i == 0 && hasStart) {
        edges.add(EdenProcessEdgeStyles.styledEdge(
          id: 'edge-start-$phaseNodeId',
          sourceId: 'start',
          targetId: phaseNodeId,
          sourcePort: EdenPortSide.bottom,
          targetPort: EdenPortSide.top,
          style: EdenProcessAutoEdgeStyle.spine,
        ));
      } else if (i > 0) {
        final prev = 'phase-${sortedPhases[i - 1].id}';
        edges.add(EdenProcessEdgeStyles.styledEdge(
          id: 'edge-$prev-$phaseNodeId',
          sourceId: prev,
          targetId: phaseNodeId,
          sourcePort: EdenPortSide.bottom,
          targetPort: EdenPortSide.top,
          style: EdenProcessAutoEdgeStyle.spine,
        ));
      }

      // Group nodes (if showAllGroups OR phase is expanded)
      final shouldEmitGroups = showAllGroups ||
          (controller?.expandedPhaseIds.contains(phase.id) ?? false);
      if (shouldEmitGroups) {
        final sortedGroups = [...phase.groups]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        for (final group in sortedGroups) {
          final groupNodeId = 'group-${group.id}';
          final gpos = positionFor(groupNodeId);
          // Pre-compute task-count-aware group height so non-swimlane
          // layouts (free-form / grid / linear) still allocate enough
          // vertical room for the inline task list inside
          // EdenProcessTaskGroupNode. Swimlane overrides this anyway.
          final groupHeight = 80.0 + group.tasks.length * 32.0;
          nodes.add(EdenDiagramNode(
            id: groupNodeId,
            x: gpos.dx,
            y: gpos.dy,
            width: 260,
            height: groupHeight,
            label: group.displayName,
            data: {
              'nodeType': 'taskGroup',
              'groupId': group.id,
              'phaseId': phase.id,
              // TRD 006-08: swimlane layout uses this to compute group
              // column height (groupBaseHeight + taskCount * taskRowHeight).
              'taskCount': group.tasks.length,
            },
          ));
          edges.add(EdenProcessEdgeStyles.styledEdge(
            id: 'edge-$phaseNodeId-$groupNodeId',
            sourceId: phaseNodeId,
            targetId: groupNodeId,
            sourcePort: EdenPortSide.right,
            targetPort: EdenPortSide.left,
            style: EdenProcessAutoEdgeStyle.autoFan,
          ));
        }
      }
    }

    // Decisions — NOT auto-connected (donor parity; consumer wires via userEdges)
    for (final decision in definition.config.decisions) {
      final id = 'decision-${decision.id}';
      final pos = positionFor(id);
      nodes.add(EdenDiagramNode(
        id: id,
        x: pos.dx,
        y: pos.dy,
        width: 140,
        height: 140,
        label: decision.name,
        shape: EdenNodeShape.diamond,
        data: {
          'nodeType': 'decision',
          'decisionId': decision.id,
          'condition': decision.condition,
        },
        // TRD 006-07 N-6 parity: emit 4 custom ports so the canvas engine
        // routes yes/no/top/left edges to the right anchor with the right
        // color, and saved-layout edges round-trip via sourceHandle/
        // targetHandle ids.
        ports: const [
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
        ],
      ));
    }

    // End node
    if (hasEnd) {
      final pos = positionFor('end');
      nodes.add(EdenDiagramNode(
        id: 'end',
        x: pos.dx,
        y: pos.dy,
        width: 48,
        height: 48,
        label: 'End',
        data: const {'nodeType': 'end'},
      ));

      // Connect last phase → end (or start → end if no phases)
      if (sortedPhases.isNotEmpty) {
        final last = 'phase-${sortedPhases.last.id}';
        edges.add(EdenProcessEdgeStyles.styledEdge(
          id: 'edge-$last-end',
          sourceId: last,
          targetId: 'end',
          sourcePort: EdenPortSide.bottom,
          targetPort: EdenPortSide.top,
          style: EdenProcessAutoEdgeStyle.spine,
        ));
      } else if (hasStart) {
        edges.add(EdenProcessEdgeStyles.styledEdge(
          id: 'edge-start-end',
          sourceId: 'start',
          targetId: 'end',
          sourcePort: EdenPortSide.bottom,
          targetPort: EdenPortSide.top,
          style: EdenProcessAutoEdgeStyle.spine,
        ));
      }
    }

    return (nodes, edges);
  }
}

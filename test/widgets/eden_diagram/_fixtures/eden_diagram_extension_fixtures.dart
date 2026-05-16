// Do NOT regenerate via LLM — hand-built fixtures for EdenDiagram extensions (objective 006).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Two nodes 'a' at (0,0,200,60), 'b' at (300,200,200,60) + edge a→b.
/// Useful for hit-test + custom-renderer tests.
EdenDiagramData simpleTwoNodeDiagramFixture() {
  return EdenDiagramData(
    nodes: [
      EdenDiagramNode(id: 'a', x: 0, y: 0, width: 200, height: 60, label: 'A'),
      EdenDiagramNode(
        id: 'b',
        x: 300,
        y: 200,
        width: 200,
        height: 60,
        label: 'B',
      ),
    ],
    edges: [EdenDiagramEdge(id: 'e1', sourceId: 'a', targetId: 'b')],
  );
}

/// A decision-shaped node with 4 custom ports + 2 sibling target nodes + 2
/// edges with sourcePortId set.
EdenDiagramData decisionWithPortsFixture() {
  return EdenDiagramData(
    nodes: [
      EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        width: 100,
        height: 100,
        label: 'Decision',
        shape: EdenNodeShape.diamond,
        ports: const [
          EdenDiagramPort(
            id: 'top',
            side: EdenPortSide.top,
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
          EdenDiagramPort(
            id: 'left',
            side: EdenPortSide.left,
            kind: EdenDiagramPortKind.target,
          ),
        ],
      ),
      EdenDiagramNode(
        id: 'yes-target',
        x: 300,
        y: 100,
        width: 120,
        height: 60,
        label: 'Yes branch',
      ),
      EdenDiagramNode(
        id: 'no-target',
        x: 100,
        y: 300,
        width: 120,
        height: 60,
        label: 'No branch',
      ),
    ],
    edges: [
      EdenDiagramEdge(
        id: 'e-yes',
        sourceId: 'd',
        targetId: 'yes-target',
        sourcePortId: 'yes',
        targetPort: EdenPortSide.left,
      ),
      EdenDiagramEdge(
        id: 'e-no',
        sourceId: 'd',
        targetId: 'no-target',
        sourcePortId: 'no',
        targetPort: EdenPortSide.top,
      ),
    ],
  );
}

/// 3 overlapping nodes at the same zone to test z-order.
EdenDiagramData overlappingNodesFixture() {
  return EdenDiagramData(
    nodes: [
      EdenDiagramNode(id: 'bottom', x: 100, y: 100, width: 200, height: 200),
      EdenDiagramNode(id: 'middle', x: 100, y: 100, width: 200, height: 200),
      EdenDiagramNode(id: 'top', x: 100, y: 100, width: 200, height: 200),
    ],
    edges: const [],
  );
}

/// Custom-renderer probe — a Container with ValueKey, used for asserting
/// custom-renderer wiring.
Widget probeNodeRenderer(EdenDiagramNodeContext ctx) {
  return Container(
    key: ValueKey('probe-${ctx.node.id}'),
    color: ctx.dropTarget ? Colors.green : Colors.red,
    child: Text(ctx.node.label),
  );
}

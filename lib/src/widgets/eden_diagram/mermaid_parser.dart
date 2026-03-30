import 'diagram_data.dart';

/// Parses a subset of Mermaid flowchart syntax into [EdenDiagramData].
///
/// Supports:
/// - `graph TD`/`TB`/`LR`/`RL` and `flowchart TD`/`TB`/`LR`/`RL` direction
/// - Node shapes: `A[text]` roundedRect, `A(text)` pill, `A{text}` diamond,
///   `A((text))` circle
/// - Edges: `-->` solid arrow, `---` no arrow, `-.->` dashed, `==>` thick
/// - Edge labels: `A -->|label| B`
/// - Simple layered auto-layout via topological sort
class EdenMermaidParser {
  EdenMermaidParser._();

  /// Parse Mermaid source text into an [EdenDiagramData].
  ///
  /// Returns an empty diagram if the source cannot be parsed.
  static EdenDiagramData parse(String source) {
    final lines = source
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('%%'))
        .toList();

    if (lines.isEmpty) return EdenDiagramData();

    // Determine direction from first line
    bool isHorizontal = false;
    int startLine = 0;
    final firstLine = lines.first.toLowerCase();
    if (firstLine.startsWith('graph') || firstLine.startsWith('flowchart')) {
      final parts = firstLine.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        final dir = parts[1].toUpperCase();
        isHorizontal = dir == 'LR' || dir == 'RL';
      }
      startLine = 1;
    }

    final nodes = <String, _ParsedNode>{};
    final edges = <_ParsedEdge>[];

    // Edge pattern: A[label?] --> |edgeLabel?| B[label?]
    final edgePattern = RegExp(
      r'(\w+)(?:\[([^\]]*)\]|\(\(([^)]*)\)\)|\(([^)]*)\)|\{([^}]*)\})?'
      r'\s*'
      r'(-->|---|\.->|-\.->|==>)'
      r'(?:\|([^|]*)\|)?'
      r'\s*'
      r'(\w+)(?:\[([^\]]*)\]|\(\(([^)]*)\)\)|\(([^)]*)\)|\{([^}]*)\})?',
    );

    // Standalone node pattern
    final nodePattern = RegExp(
      r'^(\w+)(?:\[([^\]]*)\]|\(\(([^)]*)\)\)|\(([^)]*)\)|\{([^}]*)\})$',
    );

    for (var i = startLine; i < lines.length; i++) {
      final line = lines[i].replaceFirst(RegExp(r';$'), '').trim();
      if (line.isEmpty) continue;
      if (line.startsWith('subgraph') || line == 'end') continue;

      final edgeMatch = edgePattern.firstMatch(line);
      if (edgeMatch != null) {
        // Groups per node: 1=id, 2=[text], 3=((text)), 4=(text), 5={text}
        final sourceId = edgeMatch.group(1)!;
        final sourceLabel = edgeMatch.group(2) ??
            edgeMatch.group(3) ??
            edgeMatch.group(4) ??
            edgeMatch.group(5);
        final sourceShape = _shapeFromMatch(edgeMatch, isSource: true);

        final edgeType = edgeMatch.group(6)!;
        final edgeLabel = edgeMatch.group(7);

        // Target groups offset by 7: 8=id, 9=[text], 10=((text)), 11=(text), 12={text}
        final targetId = edgeMatch.group(8)!;
        final targetLabel = edgeMatch.group(9) ??
            edgeMatch.group(10) ??
            edgeMatch.group(11) ??
            edgeMatch.group(12);
        final targetShape = _shapeFromMatch(edgeMatch, isSource: false);

        _ensureNode(nodes, sourceId, sourceLabel, sourceShape);
        _ensureNode(nodes, targetId, targetLabel, targetShape);

        edges.add(_ParsedEdge(
          sourceId: sourceId,
          targetId: targetId,
          label: edgeLabel,
          style: _edgeStyle(edgeType),
          hasArrow: edgeType != '---',
        ));
        continue;
      }

      final nodeMatch = nodePattern.firstMatch(line);
      if (nodeMatch != null) {
        final id = nodeMatch.group(1)!;
        final label = nodeMatch.group(2) ??
            nodeMatch.group(3) ??
            nodeMatch.group(4) ??
            nodeMatch.group(5);
        final shape = _shapeFromNodeMatch(nodeMatch);
        _ensureNode(nodes, id, label, shape);
      }
    }

    // Auto-layout
    final layoutNodes = _autoLayout(nodes, edges, isHorizontal);

    return EdenDiagramData(
      nodes: layoutNodes,
      edges: edges.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        return EdenDiagramEdge(
          id: 'e$i',
          sourceId: e.sourceId,
          targetId: e.targetId,
          label: e.label,
          style: e.style,
          arrowHead:
              e.hasArrow ? EdenArrowHead.filledArrow : EdenArrowHead.none,
          sourcePort:
              isHorizontal ? EdenPortSide.right : EdenPortSide.bottom,
          targetPort:
              isHorizontal ? EdenPortSide.left : EdenPortSide.top,
        );
      }).toList(),
    );
  }

  static void _ensureNode(
    Map<String, _ParsedNode> nodes,
    String id,
    String? label,
    EdenNodeShape shape,
  ) {
    if (!nodes.containsKey(id)) {
      nodes[id] = _ParsedNode(id: id, label: label ?? id, shape: shape);
    } else if (label != null && nodes[id]!.label == id) {
      nodes[id] = _ParsedNode(id: id, label: label, shape: shape);
    }
  }

  static EdenNodeShape _shapeFromMatch(
    RegExpMatch match, {
    required bool isSource,
  }) {
    // New group order: [text]=g2, ((text))=g3, (text)=g4, {text}=g5
    final offset = isSource ? 0 : 7;
    if (match.group(2 + offset) != null) return EdenNodeShape.roundedRect; // [text]
    if (match.group(3 + offset) != null) return EdenNodeShape.circle;      // ((text))
    if (match.group(4 + offset) != null) return EdenNodeShape.pill;        // (text)
    if (match.group(5 + offset) != null) return EdenNodeShape.diamond;     // {text}
    return EdenNodeShape.roundedRect;
  }

  static EdenNodeShape _shapeFromNodeMatch(RegExpMatch match) {
    if (match.group(2) != null) return EdenNodeShape.roundedRect; // [text]
    if (match.group(3) != null) return EdenNodeShape.circle;      // ((text))
    if (match.group(4) != null) return EdenNodeShape.pill;        // (text)
    if (match.group(5) != null) return EdenNodeShape.diamond;     // {text}
    return EdenNodeShape.roundedRect;
  }

  static EdenEdgeStyle _edgeStyle(String type) {
    switch (type) {
      case '-.->':
      case '.->':
        return EdenEdgeStyle.dashed;
      default:
        return EdenEdgeStyle.solid;
    }
  }

  /// Simple layered auto-layout using topological sort (Kahn's algorithm).
  static List<EdenDiagramNode> _autoLayout(
    Map<String, _ParsedNode> nodes,
    List<_ParsedEdge> edges,
    bool isHorizontal,
  ) {
    final inDegree = <String, int>{};
    final children = <String, List<String>>{};

    for (final id in nodes.keys) {
      inDegree[id] = 0;
      children[id] = [];
    }

    for (final e in edges) {
      if (nodes.containsKey(e.sourceId) && nodes.containsKey(e.targetId)) {
        children[e.sourceId]!.add(e.targetId);
        inDegree[e.targetId] = (inDegree[e.targetId] ?? 0) + 1;
      }
    }

    final queue = <String>[];
    for (final id in nodes.keys) {
      if (inDegree[id] == 0) queue.add(id);
    }

    final layers = <List<String>>[];
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final layer = List<String>.from(queue);
      layers.add(layer);
      visited.addAll(layer);
      queue.clear();

      for (final id in layer) {
        for (final child in children[id]!) {
          inDegree[child] = (inDegree[child] ?? 1) - 1;
          if (inDegree[child] == 0 && !visited.contains(child)) {
            queue.add(child);
          }
        }
      }
    }

    // Add any remaining nodes (cycles)
    for (final id in nodes.keys) {
      if (!visited.contains(id)) {
        layers.add([id]);
        visited.add(id);
      }
    }

    // Position
    const nodeWidth = 160.0;
    const nodeHeight = 60.0;
    const layerSpacing = 120.0;
    const nodeSpacing = 80.0;

    final result = <EdenDiagramNode>[];

    for (var layerIdx = 0; layerIdx < layers.length; layerIdx++) {
      final layer = layers[layerIdx];
      for (var nodeIdx = 0; nodeIdx < layer.length; nodeIdx++) {
        final parsed = nodes[layer[nodeIdx]]!;
        final double x;
        final double y;

        if (isHorizontal) {
          x = 40 + layerIdx * (nodeWidth + layerSpacing);
          y = 40 + nodeIdx * (nodeHeight + nodeSpacing);
        } else {
          x = 40 + nodeIdx * (nodeWidth + nodeSpacing);
          y = 40 + layerIdx * (nodeHeight + layerSpacing);
        }

        result.add(EdenDiagramNode(
          id: parsed.id,
          label: parsed.label,
          shape: parsed.shape,
          x: x,
          y: y,
          width: nodeWidth,
          height: nodeHeight,
        ));
      }
    }

    return result;
  }
}

class _ParsedNode {
  const _ParsedNode({
    required this.id,
    required this.label,
    required this.shape,
  });

  final String id;
  final String label;
  final EdenNodeShape shape;
}

class _ParsedEdge {
  const _ParsedEdge({
    required this.sourceId,
    required this.targetId,
    this.label,
    this.style = EdenEdgeStyle.solid,
    this.hasArrow = true,
  });

  final String sourceId;
  final String targetId;
  final String? label;
  final EdenEdgeStyle style;
  final bool hasArrow;
}

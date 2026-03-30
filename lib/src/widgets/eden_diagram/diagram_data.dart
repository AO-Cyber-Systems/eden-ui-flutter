import 'dart:convert';
import 'dart:ui';

import 'mermaid_parser.dart';

/// Shape types for diagram nodes.
enum EdenNodeShape { rectangle, roundedRect, diamond, circle, pill, cylinder, hexagon, parallelogram }

/// Port position on a node for edge connections.
enum EdenPortSide { top, right, bottom, left }

/// Line style for edges.
enum EdenEdgeStyle { solid, dashed, dotted }

/// Arrow head style.
enum EdenArrowHead { none, arrow, filledArrow, diamond, circle }

/// A single node in the diagram.
class EdenDiagramNode {
  EdenDiagramNode({
    required this.id,
    this.shape = EdenNodeShape.roundedRect,
    required this.x,
    required this.y,
    this.width = 160,
    this.height = 60,
    this.label = '',
    this.sublabel,
    this.color,
    this.borderColor,
    this.textColor,
    this.icon,
    this.data = const {},
  });

  final String id;
  EdenNodeShape shape;
  double x;
  double y;
  double width;
  double height;
  String label;
  String? sublabel;
  String? color; // hex string e.g. "#3B82F6"
  String? borderColor;
  String? textColor;
  String? icon; // Material icon name hint (for future use)
  Map<String, dynamic> data; // arbitrary user data

  /// Center point of this node.
  Offset get center => Offset(x + width / 2, y + height / 2);

  /// Get connection point for a given port side.
  Offset portOffset(EdenPortSide side) {
    switch (side) {
      case EdenPortSide.top:
        return Offset(x + width / 2, y);
      case EdenPortSide.right:
        return Offset(x + width, y + height / 2);
      case EdenPortSide.bottom:
        return Offset(x + width / 2, y + height);
      case EdenPortSide.left:
        return Offset(x, y + height / 2);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shape': shape.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'label': label,
    if (sublabel != null) 'sublabel': sublabel,
    if (color != null) 'color': color,
    if (borderColor != null) 'borderColor': borderColor,
    if (textColor != null) 'textColor': textColor,
    if (icon != null) 'icon': icon,
    if (data.isNotEmpty) 'data': data,
  };

  factory EdenDiagramNode.fromJson(Map<String, dynamic> json) => EdenDiagramNode(
    id: json['id'] as String,
    shape: EdenNodeShape.values.firstWhere(
      (s) => s.name == json['shape'],
      orElse: () => EdenNodeShape.roundedRect,
    ),
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num?)?.toDouble() ?? 160,
    height: (json['height'] as num?)?.toDouble() ?? 60,
    label: json['label'] as String? ?? '',
    sublabel: json['sublabel'] as String?,
    color: json['color'] as String?,
    borderColor: json['borderColor'] as String?,
    textColor: json['textColor'] as String?,
    icon: json['icon'] as String?,
    data: (json['data'] as Map<String, dynamic>?) ?? {},
  );
}

/// An edge connecting two nodes.
class EdenDiagramEdge {
  EdenDiagramEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.sourcePort = EdenPortSide.right,
    this.targetPort = EdenPortSide.left,
    this.label,
    this.style = EdenEdgeStyle.solid,
    this.arrowHead = EdenArrowHead.filledArrow,
    this.color,
    this.data = const {},
  });

  final String id;
  String sourceId;
  String targetId;
  EdenPortSide sourcePort;
  EdenPortSide targetPort;
  String? label;
  EdenEdgeStyle style;
  EdenArrowHead arrowHead;
  String? color;
  Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'targetId': targetId,
    'sourcePort': sourcePort.name,
    'targetPort': targetPort.name,
    if (label != null) 'label': label,
    'style': style.name,
    'arrowHead': arrowHead.name,
    if (color != null) 'color': color,
    if (data.isNotEmpty) 'data': data,
  };

  factory EdenDiagramEdge.fromJson(Map<String, dynamic> json) => EdenDiagramEdge(
    id: json['id'] as String,
    sourceId: json['sourceId'] as String,
    targetId: json['targetId'] as String,
    sourcePort: EdenPortSide.values.firstWhere(
      (s) => s.name == json['sourcePort'],
      orElse: () => EdenPortSide.right,
    ),
    targetPort: EdenPortSide.values.firstWhere(
      (s) => s.name == json['targetPort'],
      orElse: () => EdenPortSide.left,
    ),
    label: json['label'] as String?,
    style: EdenEdgeStyle.values.firstWhere(
      (s) => s.name == json['style'],
      orElse: () => EdenEdgeStyle.solid,
    ),
    arrowHead: EdenArrowHead.values.firstWhere(
      (s) => s.name == json['arrowHead'],
      orElse: () => EdenArrowHead.filledArrow,
    ),
    color: json['color'] as String?,
    data: (json['data'] as Map<String, dynamic>?) ?? {},
  );
}

/// Top-level diagram data structure — the full document.
class EdenDiagramData {
  EdenDiagramData({
    List<EdenDiagramNode>? nodes,
    List<EdenDiagramEdge>? edges,
    this.title,
  })  : nodes = nodes ?? [],
        edges = edges ?? [];

  final List<EdenDiagramNode> nodes;
  final List<EdenDiagramEdge> edges;
  String? title;

  /// Find a node by ID.
  EdenDiagramNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Find edges connected to a node.
  List<EdenDiagramEdge> edgesForNode(String nodeId) =>
      edges.where((e) => e.sourceId == nodeId || e.targetId == nodeId).toList();

  /// Serialize to JSON string.
  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };

  factory EdenDiagramData.fromJson(Map<String, dynamic> json) => EdenDiagramData(
    title: json['title'] as String?,
    nodes: (json['nodes'] as List<dynamic>?)
        ?.map((n) => EdenDiagramNode.fromJson(n as Map<String, dynamic>))
        .toList() ?? [],
    edges: (json['edges'] as List<dynamic>?)
        ?.map((e) => EdenDiagramEdge.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  factory EdenDiagramData.fromJsonString(String jsonStr) =>
      EdenDiagramData.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  /// Parse a Mermaid flowchart string into an [EdenDiagramData].
  ///
  /// Supports `graph`/`flowchart` with TD/TB/LR/RL direction, node shapes
  /// (`[text]`, `(text)`, `{text}`, `((text))`), edge types (`-->`, `---`,
  /// `-.->`, `==>`), and edge labels (`-->|label|`).
  ///
  /// Returns an empty diagram if the source cannot be parsed.
  factory EdenDiagramData.fromMermaid(String source) =>
      EdenMermaidParser.parse(source);
}

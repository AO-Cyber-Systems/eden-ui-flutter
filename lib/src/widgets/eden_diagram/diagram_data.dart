import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart' show Widget;

import 'mermaid_parser.dart';

/// Shape types for diagram nodes.
enum EdenNodeShape { rectangle, roundedRect, diamond, circle, pill, cylinder, hexagon, parallelogram }

/// Port position on a node for edge connections.
enum EdenPortSide { top, right, bottom, left }

/// Line style for edges.
enum EdenEdgeStyle { solid, dashed, dotted }

/// Arrow head style.
enum EdenArrowHead { none, arrow, filledArrow, diamond, circle }

/// Connection-handle kind for [EdenDiagramPort].
enum EdenDiagramPortKind { source, target, both }

/// A custom connection port on an [EdenDiagramNode] (objective 006, parity E-5).
///
/// Use [EdenDiagramNode.ports] to opt into multi-handle nodes (e.g. a decision
/// node with separate "yes" and "no" output handles). When [EdenDiagramNode.ports]
/// is null, the canvas uses the legacy fixed 4-direction port model via
/// [EdenDiagramNode.portOffset].
///
/// Set [id] to match donor `sourceHandle` / `targetHandle` strings (e.g. `'yes'`,
/// `'no'`, `'top'`, `'left'`) for round-trip with saved layout data.
class EdenDiagramPort {
  const EdenDiagramPort({
    required this.id,
    required this.side,
    this.offset = 0.5,
    required this.kind,
    this.color,
    this.data = const {},
  });

  final String id;
  final EdenPortSide side;
  /// 0..1 normalized position along the side (0.5 = center).
  final double offset;
  final EdenDiagramPortKind kind;
  final String? color;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
        'id': id,
        'side': side.name,
        'offset': offset,
        'kind': kind.name,
        if (color != null) 'color': color,
        if (data.isNotEmpty) 'data': data,
      };

  factory EdenDiagramPort.fromJson(Map<String, dynamic> json) => EdenDiagramPort(
        id: json['id'] as String,
        side: EdenPortSide.values.firstWhere(
          (s) => s.name == json['side'],
          orElse: () => EdenPortSide.top,
        ),
        offset: (json['offset'] as num?)?.toDouble() ?? 0.5,
        kind: EdenDiagramPortKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => EdenDiagramPortKind.source,
        ),
        color: json['color'] as String?,
        data: (json['data'] as Map<String, dynamic>?) ?? const {},
      );

  @override
  bool operator ==(Object other) =>
      other is EdenDiagramPort &&
      other.id == id &&
      other.side == side &&
      other.offset == offset &&
      other.kind == kind &&
      other.color == color;

  @override
  int get hashCode => Object.hash(id, side, offset, kind, color);
}

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
    this.ports,
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
  /// Custom connection ports (objective 006, parity E-5).
  ///
  /// When non-null, the canvas uses these for hit-test, port-dot rendering,
  /// and edge anchor resolution instead of the legacy 4-direction model.
  /// Legacy [portOffset] still returns the fixed 4-direction values when
  /// called directly (back-compat invariant).
  List<EdenDiagramPort>? ports;

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
    if (ports != null && ports!.isNotEmpty)
      'ports': ports!.map((p) => p.toJson()).toList(),
  };

  /// Returns a new instance with selected fields overridden. Used by layout
  /// engines to produce pure-function output (no mutation of input nodes).
  EdenDiagramNode copyWith({
    String? id,
    EdenNodeShape? shape,
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    String? sublabel,
    String? color,
    String? borderColor,
    String? textColor,
    String? icon,
    Map<String, dynamic>? data,
    List<EdenDiagramPort>? ports,
  }) =>
      EdenDiagramNode(
        id: id ?? this.id,
        shape: shape ?? this.shape,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        label: label ?? this.label,
        sublabel: sublabel ?? this.sublabel,
        color: color ?? this.color,
        borderColor: borderColor ?? this.borderColor,
        textColor: textColor ?? this.textColor,
        icon: icon ?? this.icon,
        data: data ?? this.data,
        ports: ports ?? this.ports,
      );

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
    ports: (json['ports'] as List<dynamic>?)
        ?.map((p) => EdenDiagramPort.fromJson(p as Map<String, dynamic>))
        .toList(),
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
    this.sourcePortId,
    this.targetPortId,
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
  /// Custom-port id on source node (objective 006, parity E-5).
  ///
  /// When set AND source node has [EdenDiagramNode.ports], the canvas looks
  /// up the port by id for edge anchor positioning. Falls back to [sourcePort]
  /// when null or when the port id is not found.
  String? sourcePortId;
  /// Custom-port id on target node (objective 006, parity E-5).
  String? targetPortId;
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
    if (sourcePortId != null) 'sourcePortId': sourcePortId,
    if (targetPortId != null) 'targetPortId': targetPortId,
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
    sourcePortId: json['sourcePortId'] as String?,
    targetPortId: json['targetPortId'] as String?,
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

/// Context passed to a [EdenDiagramNodeRenderer] (objective 006).
///
/// Conveys the node + selection / hover / drop-target state. The renderer is
/// responsible for drawing its own selection ring + drop-target ring when
/// using `customNodeRenderer`.
class EdenDiagramNodeContext {
  const EdenDiagramNodeContext({
    required this.node,
    this.selected = false,
    this.hovered = false,
    this.dropTarget = false,
  });

  final EdenDiagramNode node;
  final bool selected;
  final bool hovered;
  final bool dropTarget;
}

/// Signature for custom node rendering (objective 006).
typedef EdenDiagramNodeRenderer = Widget Function(EdenDiagramNodeContext context);

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

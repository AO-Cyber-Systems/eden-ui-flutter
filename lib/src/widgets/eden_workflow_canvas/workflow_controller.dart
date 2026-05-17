// EdenWorkflowController — canvas state manager.
//
// ChangeNotifier-based; canvas listens for state changes and rebuilds.
// Manages nodes + edges + user-drawn edges separately so toLayoutData()
// can persist user edges while auto-edges get recomputed.

import 'package:flutter/foundation.dart';

import '../eden_diagram/diagram_data.dart';
import '../eden_process_canvas/process_models.dart'
    show EdenProcessNodePosition, EdenProcessSavedEdge;
import 'workflow_models.dart';

class EdenWorkflowController extends ChangeNotifier {
  EdenWorkflowController({
    List<EdenDiagramNode>? initialNodes,
    List<EdenDiagramEdge>? initialEdges,
    List<EdenDiagramEdge>? initialUserEdges,
    this.preserveManualPositions = true,
  })  : _nodes = List.of(initialNodes ?? const []),
        _edges = List.of(initialEdges ?? const []),
        _userEdges = List.of(initialUserEdges ?? const []);

  final List<EdenDiagramNode> _nodes;
  final List<EdenDiagramEdge> _edges;
  final List<EdenDiagramEdge> _userEdges;
  final bool preserveManualPositions;

  List<EdenDiagramNode> get nodes => List.unmodifiable(_nodes);
  List<EdenDiagramEdge> get edges => List.unmodifiable(_edges);
  List<EdenDiagramEdge> get userEdges => List.unmodifiable(_userEdges);

  int _idCounter = 0;
  String generateNodeId(String prefix) {
    _idCounter++;
    return '$prefix-$_idCounter';
  }

  void addNode(EdenDiagramNode node) {
    _nodes.add(node);
    notifyListeners();
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    _edges.removeWhere((e) => e.sourceId == id || e.targetId == id);
    _userEdges.removeWhere((e) => e.sourceId == id || e.targetId == id);
    notifyListeners();
  }

  void updateNode(String id, Map<String, dynamic> updates) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final n = _nodes[idx];
    final newData = Map<String, dynamic>.from(n.data)..addAll(updates);
    _nodes[idx] = n.copyWith(data: newData);
    notifyListeners();
  }

  void moveNode(String id, double x, double y) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    _nodes[idx] = _nodes[idx].copyWith(x: x, y: y);
    notifyListeners();
  }

  void addEdge(EdenDiagramEdge edge) {
    _userEdges.add(edge);
    _edges.add(edge);
    notifyListeners();
  }

  void removeEdge(String id) {
    _edges.removeWhere((e) => e.id == id);
    _userEdges.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void replaceAll({
    required List<EdenDiagramNode> nodes,
    required List<EdenDiagramEdge> edges,
    List<EdenDiagramEdge>? userEdges,
  }) {
    _nodes
      ..clear()
      ..addAll(nodes);
    _edges
      ..clear()
      ..addAll(edges);
    _userEdges
      ..clear()
      ..addAll(userEdges ?? const []);
    notifyListeners();
  }

  /// Produces a save-shape layout: positions for ALL nodes + user-drawn
  /// edges only (auto-generated edges are recomputed by graph builder).
  EdenWorkflowCanvasLayout toLayoutData() {
    final layoutNodes = <String, EdenProcessNodePosition>{
      for (final n in _nodes) n.id: EdenProcessNodePosition(x: n.x, y: n.y),
    };
    final savedEdges = _userEdges
        .map((e) => EdenProcessSavedEdge(
              id: e.id,
              source: e.sourceId,
              target: e.targetId,
              sourceHandle: e.data['sourceHandle'] as String?,
              targetHandle: e.data['targetHandle'] as String?,
            ))
        .toList();
    return EdenWorkflowCanvasLayout(
      version: 1,
      nodes: layoutNodes,
      edges: savedEdges,
    );
  }

  void reset() {
    _nodes.clear();
    _edges.clear();
    _userEdges.clear();
    _idCounter = 0;
    notifyListeners();
  }
}

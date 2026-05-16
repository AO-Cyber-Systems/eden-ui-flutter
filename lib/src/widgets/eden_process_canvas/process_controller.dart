import 'package:flutter/widgets.dart';

import '../eden_diagram/eden_diagram_exports.dart';
import 'process_layout_engine.dart';
import 'process_models.dart';

/// State controller for an `EdenVisualProcessCanvas` (objective 006).
///
/// Owns the per-instance canvas state that doesn't belong on the definition:
///   - which phases are expanded
///   - which node is selected
///   - orphan nodes that haven't been linked to the definition yet
///   - user-drawn edges that persist across re-renders
///   - manual node positions (after user drag)
///   - pending positions (for newly created elements before linkage)
///   - which layout engine is active
///
/// Mirrors donor `useProcessToFlow.ts` state hooks; ports to a single
/// ChangeNotifier-driven object. Tests use `addTearDown(controller.dispose)`.
class EdenProcessController extends ChangeNotifier {
  EdenProcessController({
    EdenProcessLayoutEngine? layout,
    this.preserveManualPositions = true,
  }) : _layout = layout ?? const EdenSwimlaneLayout();

  // ─────────── Layout engine ───────────

  EdenProcessLayoutEngine _layout;
  EdenProcessLayoutEngine get layout => _layout;
  set layout(EdenProcessLayoutEngine engine) {
    if (engine.id == _layout.id) return;
    _layout = engine;
    notifyListeners();
  }

  /// When true (default), manual positions override layout-engine positions
  /// during `EdenProcessGraphBuilder.build`. Parity row S-2.
  final bool preserveManualPositions;

  // ─────────── Selection ───────────

  String? _selectedNodeId;
  String? get selectedNodeId => _selectedNodeId;
  void select(String? id) {
    if (id == _selectedNodeId) return;
    _selectedNodeId = id;
    notifyListeners();
  }

  // ─────────── Phase expansion ───────────

  final Set<int> _expandedPhaseIds = <int>{};
  Set<int> get expandedPhaseIds => Set.unmodifiable(_expandedPhaseIds);

  void togglePhaseExpanded(int phaseId) {
    if (_expandedPhaseIds.contains(phaseId)) {
      _expandedPhaseIds.remove(phaseId);
    } else {
      _expandedPhaseIds.add(phaseId);
    }
    notifyListeners();
  }

  // ─────────── Orphans ───────────

  int _orphanCounter = 0;
  final List<EdenDiagramNode> _orphans = [];
  List<EdenDiagramNode> get orphans => List.unmodifiable(_orphans);

  /// Generate a new orphan id (`orphan-1`, `orphan-2`, …).
  String generateOrphanId() => 'orphan-${++_orphanCounter}';

  void addOrphan(EdenDiagramNode node) {
    _orphans.add(node);
    notifyListeners();
  }

  void removeOrphan(String nodeId) {
    final initialOrphanCount = _orphans.length;
    final initialEdgeCount = _userEdges.length;
    _orphans.removeWhere((n) => n.id == nodeId);
    // Cascade: remove user edges referencing this orphan
    _userEdges.removeWhere(
      (e) => e.sourceId == nodeId || e.targetId == nodeId,
    );
    if (_orphans.length != initialOrphanCount ||
        _userEdges.length != initialEdgeCount) {
      notifyListeners();
    }
  }

  // ─────────── User edges ───────────

  final List<EdenDiagramEdge> _userEdges = [];
  List<EdenDiagramEdge> get userEdges => List.unmodifiable(_userEdges);

  void addUserEdge(EdenDiagramEdge edge) {
    // Inject 'edgeStyle': 'user' marker if missing — defensive copy so we
    // don't accidentally mutate a const map.
    if (edge.data['edgeStyle'] == null) {
      final merged = Map<String, dynamic>.of(edge.data);
      merged['edgeStyle'] = 'user';
      edge.data = merged;
    }
    _userEdges.add(edge);
    notifyListeners();
  }

  void removeUserEdge(String edgeId) {
    final initialCount = _userEdges.length;
    _userEdges.removeWhere((e) => e.id == edgeId);
    if (_userEdges.length != initialCount) notifyListeners();
  }

  // ─────────── Manual positions ───────────

  final Map<String, Offset> _manualPositions = {};

  Offset? manualPositionFor(String nodeId) => _manualPositions[nodeId];

  void recordManualPosition(String nodeId, Offset pos) {
    _manualPositions[nodeId] = pos;
    notifyListeners();
  }

  // ─────────── Pending positions ───────────

  final Map<String, Offset> _pendingPositions = {};

  Map<String, Offset> get pendingPositions =>
      Map.unmodifiable(_pendingPositions);

  void setPendingPosition(String nodeId, Offset pos) {
    _pendingPositions[nodeId] = pos;
    notifyListeners();
  }

  void clearPendingPosition(String nodeId) {
    if (_pendingPositions.remove(nodeId) != null) notifyListeners();
  }

  // ─────────── Layout data round-trip ───────────

  /// Extract positions + user-drawn edges + optional viewport into
  /// `EdenProcessLayoutData` for persistence — parity row S-5.
  EdenProcessLayoutData toLayoutData({EdenProcessViewport? viewport}) {
    final positions = <String, EdenProcessNodePosition>{
      for (final entry in _manualPositions.entries)
        entry.key:
            EdenProcessNodePosition(x: entry.value.dx, y: entry.value.dy),
    };
    final savedEdges = _userEdges
        .map((e) => EdenProcessSavedEdge(
              id: e.id,
              source: e.sourceId,
              target: e.targetId,
              sourceHandle: e.sourcePortId,
              targetHandle: e.targetPortId,
            ))
        .toList();
    return EdenProcessLayoutData(
      version: 1,
      autoLayout: false,
      nodes: positions,
      edges: savedEdges,
      viewport: viewport,
    );
  }

  /// Restore positions + user-drawn edges from `EdenProcessLayoutData` —
  /// parity row L-5.
  void fromLayoutData(EdenProcessLayoutData data) {
    _manualPositions.clear();
    for (final entry in data.nodes.entries) {
      _manualPositions[entry.key] = Offset(entry.value.x, entry.value.y);
    }
    _userEdges.clear();
    for (final savedEdge in data.edges) {
      _userEdges.add(EdenDiagramEdge(
        id: savedEdge.id,
        sourceId: savedEdge.source,
        targetId: savedEdge.target,
        sourcePortId: savedEdge.sourceHandle,
        targetPortId: savedEdge.targetHandle,
        style: EdenEdgeStyle.solid,
        data: {'edgeStyle': 'user'},
      ));
    }
    notifyListeners();
  }

  // ─────────── Reset ───────────

  /// Clear all controller state. Use in tests' `setUp()` or to wipe a
  /// canvas between definitions.
  void reset() {
    _selectedNodeId = null;
    _expandedPhaseIds.clear();
    _orphans.clear();
    _userEdges.clear();
    _manualPositions.clear();
    _pendingPositions.clear();
    _orphanCounter = 0;
    notifyListeners();
  }
}

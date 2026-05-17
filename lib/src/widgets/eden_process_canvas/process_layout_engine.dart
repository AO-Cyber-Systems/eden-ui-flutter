import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../eden_diagram/eden_diagram_exports.dart';

/// Pluggable layout strategy for the process canvas (objective 006).
///
/// Concrete subclasses implement [applyLayout] to compute positions for the
/// given nodes. The layout MUST be a pure function — input nodes / edges
/// must NOT be mutated.
///
/// **Real implementations land in TRDs 08 / 09.** TRD 03 ships these
/// subclasses as no-op stubs (returning input unchanged) so the engine
/// interface is locked from Wave 1.
abstract class EdenProcessLayoutEngine {
  const EdenProcessLayoutEngine();

  /// Identifier for telemetry / debug logging / persisted-config purposes.
  String get id;

  /// Apply layout to the given nodes (returning new node instances with
  /// updated positions). Pure function — must NOT mutate input.
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  );
}

/// Swimlane layout: phases as vertical spine left, groups fan right.
///
/// Default layout for `EdenVisualProcessCanvas` per Mark's locked preference.
/// Direct port of donor `applySwimLaneLayout` (layoutEngine.ts:118-216).
///
/// Topology:
/// ```
/// [Start]
///    │
/// [Phase] ─── [Group1 (with inline tasks)]
///    │        [Group2 (with inline tasks)]
///    │
/// [Phase] ─── [Group] ...
///    │
///  [End]
/// ```
///
/// - Groups fan out from their parent phase (parallel, not sequential).
/// - Groups stack vertically in a single column to the right.
/// - Phase is vertically centered relative to its group column.
/// - Decisions + orphans (and any group with no parent edge) drop into a
///   horizontal "other" row below the end node, spaced 250pt apart.
///
/// **Pure function:** input lists are NOT mutated; returns new
/// `EdenDiagramNode` instances for positioned nodes (others passed through
/// unchanged in their input order).
class EdenSwimlaneLayout extends EdenProcessLayoutEngine {
  const EdenSwimlaneLayout();

  static const double _marginX = 50;
  static const double _marginY = 50;
  static const double _phaseX = _marginX;
  static const double _groupX = _phaseX + 340;
  static const double _groupGapY = 30;
  static const double _rowGap = 80;
  static const double _startEndWidth = 48;
  static const double _phaseNodeHeight = 120;
  static const double _groupBaseHeight = 80;
  static const double _taskRowHeight = 32;
  static const double _otherRowSpacing = 250;

  @override
  String get id => 'swimlane';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) {
    if (nodes.isEmpty) return List.of(nodes);

    // Build child→parent from non-dependency edges. Dependency edges (a
    // forward-compat marker) MUST not participate in the parent map.
    final childToParent = <String, String>{};
    for (final e in edges) {
      if (e.data['edgeStyle'] != 'dependency') {
        childToParent[e.targetId] = e.sourceId;
      }
    }

    // Categorize.
    EdenDiagramNode? startNode;
    EdenDiagramNode? endNode;
    final phaseNodes = <EdenDiagramNode>[];
    final groupNodes = <EdenDiagramNode>[];
    final otherNodes = <EdenDiagramNode>[];
    for (final n in nodes) {
      final type = n.data['nodeType'] as String?;
      if (type == 'start') {
        startNode = n;
      } else if (type == 'end') {
        endNode = n;
      } else if (type == 'phase') {
        phaseNodes.add(n);
      } else if (type == 'taskGroup') {
        groupNodes.add(n);
      } else {
        otherNodes.add(n);
      }
    }

    // phase → groups (parented by edge).
    final phaseGroups = <String, List<EdenDiagramNode>>{};
    for (final g in groupNodes) {
      final parent = childToParent[g.id];
      if (parent != null) {
        phaseGroups.putIfAbsent(parent, () => []).add(g);
      } else {
        // Unparented group falls back to the "other" row.
        otherNodes.add(g);
      }
    }

    final positions = <String, Offset>{};
    double currentY = _marginY;

    // Start node.
    if (startNode != null) {
      positions[startNode.id] = const Offset(_phaseX + 100, _marginY);
      currentY += _startEndWidth + _rowGap;
    }

    // Phase rows.
    for (final phaseNode in phaseNodes) {
      final rowTopY = currentY;
      final groups = phaseGroups[phaseNode.id] ?? const <EdenDiagramNode>[];

      double groupColumnY = rowTopY;
      double totalGroupColumnHeight = 0;
      for (final g in groups) {
        positions[g.id] = Offset(_groupX, groupColumnY);
        final taskCount = (g.data['taskCount'] as int?) ?? 0;
        final groupHeight =
            _groupBaseHeight + (taskCount * _taskRowHeight);
        groupColumnY += groupHeight + _groupGapY;
        totalGroupColumnHeight = groupColumnY - rowTopY - _groupGapY;
      }

      final rowHeight = totalGroupColumnHeight > _phaseNodeHeight
          ? totalGroupColumnHeight
          : _phaseNodeHeight;
      final phaseCenterOffset =
          groups.isNotEmpty ? (rowHeight - _phaseNodeHeight) / 2 : 0.0;
      positions[phaseNode.id] = Offset(_phaseX, rowTopY + phaseCenterOffset);

      currentY = rowTopY + rowHeight + _rowGap;
    }

    // End node.
    if (endNode != null) {
      positions[endNode.id] = Offset(_phaseX + 100, currentY);
    }

    // Other nodes — horizontal row 100pt below current Y.
    for (int i = 0; i < otherNodes.length; i++) {
      positions[otherNodes[i].id] =
          Offset(_marginX + i * _otherRowSpacing, currentY + 100);
    }

    // Return new instances with updated positions.
    return nodes.map((n) {
      final pos = positions[n.id];
      return pos == null ? n : n.copyWith(x: pos.dx, y: pos.dy);
    }).toList();
  }
}

/// Free-form layout: graph-based left-to-right flow with column ranks
/// computed from edge dependencies (hand-rolled BFS — no Dagre dep).
///
/// Approximates Dagre's rank-assignment algorithm with a simpler iterate-
/// until-stable longest-path BFS. Not optimal — for dense graphs with many
/// cross-rank edges, edge crossings will be present. Acceptable for v1
/// process-builder workloads (<50 nodes). If you need optimal layouts, the
/// future enhancement is to add a Dagre-equivalent Dart package.
class EdenFreeFormLayout extends EdenProcessLayoutEngine {
  const EdenFreeFormLayout({
    this.colSpacing = 280,
    this.rowSpacing = 140,
    this.originX = 100,
    this.originY = 100,
  });

  final double colSpacing;
  final double rowSpacing;
  final double originX;
  final double originY;

  @override
  String get id => 'free_form';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) {
    if (nodes.isEmpty) return const [];

    // Build adjacency (source → targets).
    final adjacency = <String, List<String>>{};
    for (final e in edges) {
      adjacency.putIfAbsent(e.sourceId, () => []).add(e.targetId);
    }

    // Identify root candidates: prefer 'start' node, else any node with no
    // incoming edge. Fall back to first node if everything has incoming.
    final incoming = <String>{};
    for (final e in edges) {
      incoming.add(e.targetId);
    }
    final roots = <String>[];
    EdenDiagramNode? startNode;
    for (final n in nodes) {
      if (n.data['nodeType'] == 'start') {
        startNode = n;
        break;
      }
    }
    if (startNode != null) {
      roots.add(startNode.id);
    } else {
      for (final n in nodes) {
        if (!incoming.contains(n.id)) roots.add(n.id);
      }
    }
    if (roots.isEmpty) roots.add(nodes.first.id);

    // Longest-path rank assignment, iterate until stable (or cycle bound hit).
    final ranks = <String, int>{};
    for (final r in roots) {
      ranks[r] = 0;
    }
    bool changed = true;
    int iterations = 0;
    const maxIterations = 100;
    while (changed && iterations < maxIterations) {
      changed = false;
      iterations++;
      for (final source in ranks.keys.toList()) {
        final sourceRank = ranks[source]!;
        for (final target in adjacency[source] ?? const <String>[]) {
          final newRank = sourceRank + 1;
          if (newRank > (ranks[target] ?? -1)) {
            ranks[target] = newRank;
            changed = true;
          }
        }
      }
    }

    // Disconnected nodes → rank = maxRank + 1.
    final maxRank =
        ranks.values.isEmpty ? 0 : ranks.values.reduce(math.max);
    final disconnectedRank = maxRank + 1;
    for (final n in nodes) {
      ranks.putIfAbsent(n.id, () => disconnectedRank);
    }

    // Group node ids by rank, preserving input order within rank.
    final byRank = <int, List<String>>{};
    for (final n in nodes) {
      final r = ranks[n.id]!;
      byRank.putIfAbsent(r, () => []).add(n.id);
    }

    // Compute positions.
    final positions = <String, Offset>{};
    for (final entry in byRank.entries) {
      final rank = entry.key;
      final ids = entry.value;
      for (int i = 0; i < ids.length; i++) {
        positions[ids[i]] = Offset(
          originX + rank * colSpacing,
          originY + i * rowSpacing,
        );
      }
    }

    return nodes.map((n) {
      final pos = positions[n.id];
      return pos == null ? n : n.copyWith(x: pos.dx, y: pos.dy);
    }).toList();
  }
}

/// Grid layout: simple N-column wrap.
///
/// Positions nodes at `(col*spacing + startX, row*rowHeight + startY)` where
/// `col = i % columns` and `row = i ~/ columns`.
class EdenGridLayout extends EdenProcessLayoutEngine {
  const EdenGridLayout({
    this.columns = 3,
    this.spacing = 300,
    this.startX = 100,
    this.startY = 100,
    this.rowHeight = 200,
  });

  final int columns;
  final double spacing;
  final double startX;
  final double startY;
  final double rowHeight;

  @override
  String get id => 'grid';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) {
    return [
      for (int i = 0; i < nodes.length; i++)
        nodes[i].copyWith(
          x: (i % columns) * spacing + startX,
          y: (i ~/ columns) * rowHeight + startY,
        ),
    ];
  }
}

/// Linear layout: single horizontal row.
///
/// Positions nodes at `(startX + i*spacing, startY)`.
class EdenLinearLayout extends EdenProcessLayoutEngine {
  const EdenLinearLayout({
    this.spacing = 300,
    this.startX = 100,
    this.startY = 200,
  });

  final double spacing;
  final double startX;
  final double startY;

  @override
  String get id => 'linear';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) {
    return [
      for (int i = 0; i < nodes.length; i++)
        nodes[i].copyWith(x: startX + i * spacing, y: startY),
    ];
  }
}

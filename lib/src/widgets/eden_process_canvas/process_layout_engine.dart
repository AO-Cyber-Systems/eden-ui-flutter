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
/// **Stub today (returns input unchanged); real impl lands in TRD 08.**
class EdenSwimlaneLayout extends EdenProcessLayoutEngine {
  const EdenSwimlaneLayout();

  @override
  String get id => 'swimlane';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) =>
      nodes;
}

/// Free-form layout: graph-based left-to-right flow with column ranks
/// computed from edge dependencies (hand-rolled BFS — no Dagre dep).
///
/// **Stub today (returns input unchanged); real impl lands in TRD 09.**
class EdenFreeFormLayout extends EdenProcessLayoutEngine {
  const EdenFreeFormLayout();

  @override
  String get id => 'free_form';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) =>
      nodes;
}

/// Grid layout: simple N-column wrap.
///
/// **Stub today; real impl lands in TRD 09.**
class EdenGridLayout extends EdenProcessLayoutEngine {
  const EdenGridLayout({this.columns = 3, this.spacing = 300});

  final int columns;
  final double spacing;

  @override
  String get id => 'grid';

  @override
  List<EdenDiagramNode> applyLayout(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) =>
      nodes;
}

/// Linear layout: single horizontal row.
///
/// **Stub today; real impl lands in TRD 09.**
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
  ) =>
      nodes;
}

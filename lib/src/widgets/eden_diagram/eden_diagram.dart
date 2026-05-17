import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'diagram_data.dart';
import 'diagram_painter.dart';

/// Callback when the diagram data changes (node moved, edge added, etc.).
typedef EdenDiagramChanged = void Function(EdenDiagramData data);

/// Interactive diagram tool for the diagram widget.
enum EdenDiagramTool { select, pan, connect }

/// A full interactive diagramming canvas backed by [EdenDiagramData].
///
/// Supports:
/// - Pan and zoom (scroll wheel / pinch)
/// - Drag nodes to reposition
/// - Click to select nodes
/// - Draw edges between port dots
/// - Toolbar for tool selection, zoom, and add node
/// - Delete selected with backspace/delete
/// - Grid background
/// - JSON import/export via [EdenDiagramData]
class EdenDiagram extends StatefulWidget {
  const EdenDiagram({
    super.key,
    required this.data,
    this.onChanged,
    this.readOnly = false,
    this.showToolbar = true,
    this.showMinimap = false,
    this.gridEnabled = true,
    this.interactiveZoom = true,
    this.width,
    this.height,
    this.onDropTargetChanged,
    this.dropTargetNodeId,
    this.customNodeRenderer,
  });

  final EdenDiagramData data;
  final EdenDiagramChanged? onChanged;
  final bool readOnly;
  final bool showToolbar;
  final bool showMinimap;
  final bool gridEnabled;

  /// Whether scroll-wheel events should zoom the diagram.
  /// Set to false when the diagram is embedded inside a scrollable container
  /// (e.g. a chat message list) so scroll events pass through to the parent.
  final bool interactiveZoom;

  final double? width;
  final double? height;

  /// Drop-target callback (objective 006, parity D-2).
  ///
  /// Fires when the canvas detects a drag-over (via `onDragUpdate`) on a
  /// node, with the node id. Fires with null when the drag leaves the node.
  /// De-duplicated — only fires on changes.
  final ValueChanged<String?>? onDropTargetChanged;

  /// External drop-target highlight (objective 006, parity D-2).
  ///
  /// When set, the painter draws a primary-color ring around the node with
  /// the given id. Use together with [onDropTargetChanged].
  final String? dropTargetNodeId;

  /// Custom node renderer (objective 006).
  ///
  /// When non-null, each node is rendered as a consumer Widget via this
  /// callback instead of the built-in CustomPainter shapes. Node bounds
  /// (`x`, `y`, `width`, `height`) still drive layout + hit-test. The
  /// canvas applies pan + zoom to each node's `Positioned` automatically.
  ///
  /// When this is set, the canvas does NOT draw selection / drop-target
  /// rings — the renderer is responsible for visualising those states
  /// using the [EdenDiagramNodeContext] passed in.
  final EdenDiagramNodeRenderer? customNodeRenderer;

  @override
  State<EdenDiagram> createState() => EdenDiagramState();
}

/// Public state for `EdenDiagram` (objective 006).
///
/// Exposed (no underscore) so parent widgets can call `hitTestNode`,
/// `onDragUpdate`, and `onDragLeave` via a `GlobalKey<EdenDiagramState>`.
/// Most consumers do NOT need to access state directly.
class EdenDiagramState extends State<EdenDiagram> {
  EdenDiagramTool _tool = EdenDiagramTool.select;
  String? _selectedNodeId;
  String? _hoveredNodeId;
  String? _draggingNodeId;
  Offset _dragOffset = Offset.zero;

  // Edge drawing state
  String? _edgeSourceNodeId;
  EdenPortSide? _edgeSourcePort;
  String? _edgeSourcePortId;
  Offset? _dragEdgeStart;
  Offset? _dragEdgeEnd;

  // Pan & zoom
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  Offset? _lastPanPosition;

  final FocusNode _focusNode = FocusNode();
  int _idCounter = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Offset _toCanvas(Offset screen) => (screen - _panOffset) / _scale;

  void _notifyChanged() => widget.onChanged?.call(widget.data);

  EdenDiagramNode? _hitTestNode(Offset canvasPos) {
    // Iterate in reverse so topmost (last drawn) node is hit first
    for (int i = widget.data.nodes.length - 1; i >= 0; i--) {
      final node = widget.data.nodes[i];
      final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);
      if (rect.contains(canvasPos)) return node;
    }
    return null;
  }

  /// Public hit-test (objective 006, parity D-1).
  ///
  /// Takes a SCREEN coordinate, converts to canvas (applying pan + zoom),
  /// and returns the topmost node at that position. Returns null when no
  /// node is hit. Respects z-order (later-drawn = topmost).
  EdenDiagramNode? hitTestNode(Offset screenPosition) {
    return _hitTestNode(_toCanvas(screenPosition));
  }

  String? _lastDropTargetId;

  /// Drop-target drag-update (objective 006, parity D-2).
  ///
  /// Call from the parent `DragTarget.onMove` callback with the local
  /// pointer position. The canvas converts to canvas coordinates,
  /// hit-tests, and fires `onDropTargetChanged(nodeId?)` when the hit
  /// changes (de-dup).
  void onDragUpdate(Offset screenPosition) {
    final node = hitTestNode(screenPosition);
    final newId = node?.id;
    if (newId != _lastDropTargetId) {
      _lastDropTargetId = newId;
      widget.onDropTargetChanged?.call(newId);
    }
  }

  /// Drop-target drag-leave (objective 006, parity D-2).
  ///
  /// Call from the parent `DragTarget.onLeave` callback. Clears the drop
  /// target if one was set, firing `onDropTargetChanged(null)` once.
  void onDragLeave() {
    if (_lastDropTargetId != null) {
      _lastDropTargetId = null;
      widget.onDropTargetChanged?.call(null);
    }
  }

  /// Approximate edge hit-test (objective 006, additive in TRD 006-14).
  ///
  /// Takes a SCREEN coordinate and returns the topmost edge whose straight-
  /// line segment from source-port to target-port lies within 8pt of the
  /// canvas-space hit point. Iterates edges in reverse so the most-recently
  /// added edge wins (z-order).
  ///
  /// Approximation: uses point-to-segment distance with the legacy 4-side
  /// `portOffset` lookup. Custom-port edges with `sourcePortId`/`targetPortId`
  /// still resolve via the fallback `sourcePort`/`targetPort` enums; v1
  /// accepts the approximation and treats curved/bezier edges as straight
  /// lines for hit-testing. Good enough for the canvas-composer's
  /// edge-context-menu trigger.
  EdenDiagramEdge? hitTestEdge(Offset screenPosition) {
    final canvasPos = _toCanvas(screenPosition);
    for (int i = widget.data.edges.length - 1; i >= 0; i--) {
      final edge = widget.data.edges[i];
      final source = widget.data.nodeById(edge.sourceId);
      final target = widget.data.nodeById(edge.targetId);
      if (source == null || target == null) continue;
      final start = source.portOffset(edge.sourcePort);
      final end = target.portOffset(edge.targetPort);
      if (_distanceToSegment(canvasPos, start, end) < 8) return edge;
    }
    return null;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) /
        (dx * dx + dy * dy);
    final tClamped = t.clamp(0.0, 1.0);
    final projection = Offset(a.dx + tClamped * dx, a.dy + tClamped * dy);
    return (p - projection).distance;
  }

  /// Hit test for port dots (when a node is hovered/selected).
  ///
  /// Honors `EdenDiagramNode.ports` (objective 006, parity E-5) when non-null;
  /// falls back to the legacy 4-direction model otherwise.
  ({EdenDiagramNode node, EdenPortSide side, String? portId})? _hitTestPort(
      Offset canvasPos) {
    for (final node in widget.data.nodes) {
      if (node.ports != null && node.ports!.isNotEmpty) {
        for (final port in node.ports!) {
          final pos = EdenDiagramPainter.customPortPixelPosition(node, port);
          if ((pos - canvasPos).distance < 10) {
            return (node: node, side: port.side, portId: port.id);
          }
        }
      } else {
        for (final side in EdenPortSide.values) {
          final portPos = node.portOffset(side);
          if ((portPos - canvasPos).distance < 10) {
            return (node: node, side: side, portId: null);
          }
        }
      }
    }
    return null;
  }

  String _nextId() => 'node_${++_idCounter}';

  void _addNode(EdenNodeShape shape) {
    // Place near center of visible area
    final center = _toCanvas(Offset(
      (context.size?.width ?? 400) / 2,
      (context.size?.height ?? 300) / 2,
    ));
    final node = EdenDiagramNode(
      id: _nextId(),
      shape: shape,
      x: center.dx - 80,
      y: center.dy - 30,
      label: 'New Node',
    );
    setState(() {
      widget.data.nodes.add(node);
      _selectedNodeId = node.id;
    });
    _notifyChanged();
  }

  void _deleteSelected() {
    if (_selectedNodeId == null) return;
    setState(() {
      widget.data.nodes.removeWhere((n) => n.id == _selectedNodeId);
      widget.data.edges.removeWhere((e) => e.sourceId == _selectedNodeId || e.targetId == _selectedNodeId);
      _selectedNodeId = null;
    });
    _notifyChanged();
  }

  void _onPointerDown(PointerDownEvent event) {
    _focusNode.requestFocus();
    final canvasPos = _toCanvas(event.localPosition);

    if (_tool == EdenDiagramTool.pan) {
      _lastPanPosition = event.localPosition;
      return;
    }

    if (_tool == EdenDiagramTool.connect && !widget.readOnly) {
      final port = _hitTestPort(canvasPos);
      if (port != null) {
        _edgeSourceNodeId = port.node.id;
        _edgeSourcePort = port.side;
        _edgeSourcePortId = port.portId;
        _dragEdgeStart = _resolvePortPixelPosition(port.node, port.side, port.portId);
        _dragEdgeEnd = _dragEdgeStart;
        return;
      }
    }

    final node = _hitTestNode(canvasPos);
    setState(() {
      _selectedNodeId = node?.id;
      if (node != null && !widget.readOnly) {
        // Check port hit first for edge drawing in select mode
        final port = _hitTestPort(canvasPos);
        if (port != null && port.node.id == node.id) {
          _edgeSourceNodeId = port.node.id;
          _edgeSourcePort = port.side;
          _edgeSourcePortId = port.portId;
          _dragEdgeStart = _resolvePortPixelPosition(port.node, port.side, port.portId);
          _dragEdgeEnd = _dragEdgeStart;
        } else {
          _draggingNodeId = node.id;
          _dragOffset = Offset(canvasPos.dx - node.x, canvasPos.dy - node.y);
        }
      }
    });
  }

  Offset _resolvePortPixelPosition(EdenDiagramNode node, EdenPortSide side, String? portId) {
    if (portId != null && node.ports != null) {
      for (final p in node.ports!) {
        if (p.id == portId) {
          return EdenDiagramPainter.customPortPixelPosition(node, p);
        }
      }
    }
    return node.portOffset(side);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final canvasPos = _toCanvas(event.localPosition);

    if (_tool == EdenDiagramTool.pan && _lastPanPosition != null) {
      setState(() {
        _panOffset += event.localPosition - _lastPanPosition!;
        _lastPanPosition = event.localPosition;
      });
      return;
    }

    // Edge drawing
    if (_edgeSourceNodeId != null) {
      setState(() => _dragEdgeEnd = canvasPos);
      return;
    }

    // Node dragging
    if (_draggingNodeId != null) {
      final node = widget.data.nodeById(_draggingNodeId!);
      if (node != null) {
        setState(() {
          // Snap to grid (20px)
          node.x = ((canvasPos.dx - _dragOffset.dx) / 20).round() * 20.0;
          node.y = ((canvasPos.dy - _dragOffset.dy) / 20).round() * 20.0;
        });
      }
      return;
    }

    // Hover detection
    final node = _hitTestNode(canvasPos);
    if (node?.id != _hoveredNodeId) {
      setState(() => _hoveredNodeId = node?.id);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_edgeSourceNodeId != null) {
      final canvasPos = _toCanvas(event.localPosition);
      final port = _hitTestPort(canvasPos);
      if (port != null && port.node.id != _edgeSourceNodeId) {
        // Create edge
        final edgeId = 'edge_${widget.data.edges.length + 1}';
        widget.data.edges.add(EdenDiagramEdge(
          id: edgeId,
          sourceId: _edgeSourceNodeId!,
          targetId: port.node.id,
          sourcePort: _edgeSourcePort!,
          targetPort: port.side,
          sourcePortId: _edgeSourcePortId,
          targetPortId: port.portId,
        ));
        _notifyChanged();
      }
      setState(() {
        _edgeSourceNodeId = null;
        _edgeSourcePort = null;
        _edgeSourcePortId = null;
        _dragEdgeStart = null;
        _dragEdgeEnd = null;
      });
      return;
    }

    if (_draggingNodeId != null) {
      _notifyChanged();
      setState(() => _draggingNodeId = null);
    }
    _lastPanPosition = null;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!widget.interactiveZoom) return;
    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      final newScale = (_scale * (1 - delta / 500)).clamp(0.25, 3.0);
      // Zoom towards cursor
      final focalPoint = event.localPosition;
      final beforeZoom = (focalPoint - _panOffset) / _scale;
      _scale = newScale;
      final afterZoom = (focalPoint - _panOffset) / _scale;
      setState(() {
        _panOffset += (afterZoom - beforeZoom) * _scale;
      });
    }
  }

  /// Build positioned consumer widgets on top of the CustomPaint when
  /// `customNodeRenderer` is set (objective 006).
  List<Widget> _buildNodeOverlay() {
    final renderer = widget.customNodeRenderer!;
    return [
      for (final node in widget.data.nodes)
        Positioned(
          left: _panOffset.dx + node.x * _scale,
          top: _panOffset.dy + node.y * _scale,
          width: node.width * _scale,
          height: node.height * _scale,
          child: IgnorePointer(
            ignoring: _tool != EdenDiagramTool.select,
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: node.width,
                height: node.height,
                child: renderer(EdenDiagramNodeContext(
                  node: node,
                  selected: node.id == _selectedNodeId,
                  hovered: node.id == _hoveredNodeId,
                  dropTarget: node.id == widget.dropTargetNodeId,
                )),
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (widget.readOnly) return KeyEventResult.ignored;
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _deleteSelected();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: widget.width,
        height: widget.height ?? 500,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Canvas
            Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerSignal: _onPointerSignal,
              child: MouseRegion(
                cursor: _tool == EdenDiagramTool.pan
                    ? SystemMouseCursors.grab
                    : _draggingNodeId != null
                        ? SystemMouseCursors.grabbing
                        : _hoveredNodeId != null
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TransformPainter(
                    data: widget.data,
                    theme: theme,
                    selectedNodeId: _selectedNodeId,
                    hoveredNodeId: _hoveredNodeId,
                    dropTargetNodeId: widget.dropTargetNodeId,
                    dragEdgeStart: _dragEdgeStart,
                    dragEdgeEnd: _dragEdgeEnd,
                    panOffset: _panOffset,
                    scale: _scale,
                    gridEnabled: widget.gridEnabled,
                    drawNodes: widget.customNodeRenderer == null,
                  ),
                ),
              ),
            ),

            // Custom-node overlay (objective 006)
            if (widget.customNodeRenderer != null) ..._buildNodeOverlay(),

            // Toolbar
            if (widget.showToolbar && !widget.readOnly)
              Positioned(
                top: EdenSpacing.space2,
                left: EdenSpacing.space2,
                child: _Toolbar(
                  tool: _tool,
                  onToolChanged: (t) => setState(() => _tool = t),
                  onAddNode: _addNode,
                  onZoomIn: () => setState(() => _scale = (_scale * 1.2).clamp(0.25, 3.0)),
                  onZoomOut: () => setState(() => _scale = (_scale / 1.2).clamp(0.25, 3.0)),
                  onZoomReset: () => setState(() { _scale = 1.0; _panOffset = Offset.zero; }),
                  scale: _scale,
                ),
              ),

            // Zoom indicator
            Positioned(
              bottom: EdenSpacing.space2,
              right: EdenSpacing.space2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                child: Text(
                  '${(_scale * 100).round()}%',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter that applies the pan/zoom transform and delegates to [EdenDiagramPainter].
class _TransformPainter extends CustomPainter {
  _TransformPainter({
    required this.data,
    required this.theme,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.dropTargetNodeId,
    this.dragEdgeStart,
    this.dragEdgeEnd,
    required this.panOffset,
    required this.scale,
    required this.gridEnabled,
    this.drawNodes = true,
  });

  final EdenDiagramData data;
  final ThemeData theme;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final String? dropTargetNodeId;
  final Offset? dragEdgeStart;
  final Offset? dragEdgeEnd;
  final Offset panOffset;
  final double scale;
  final bool gridEnabled;
  final bool drawNodes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    final painter = EdenDiagramPainter(
      data: data,
      theme: theme,
      selectedNodeId: selectedNodeId,
      hoveredNodeId: hoveredNodeId,
      dropTargetNodeId: dropTargetNodeId,
      dragEdgeStart: dragEdgeStart,
      dragEdgeEnd: dragEdgeEnd,
      gridEnabled: gridEnabled,
      drawNodes: drawNodes,
    );
    painter.paint(canvas, size / scale);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TransformPainter oldDelegate) => true;
}

/// Floating toolbar for diagram interaction.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.tool,
    required this.onToolChanged,
    required this.onAddNode,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
    required this.scale,
  });

  final EdenDiagramTool tool;
  final ValueChanged<EdenDiagramTool> onToolChanged;
  final void Function(EdenNodeShape) onAddNode;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: EdenRadii.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.near_me,
            tooltip: 'Select (V)',
            isActive: tool == EdenDiagramTool.select,
            onTap: () => onToolChanged(EdenDiagramTool.select),
          ),
          _ToolButton(
            icon: Icons.open_with,
            tooltip: 'Pan (H)',
            isActive: tool == EdenDiagramTool.pan,
            onTap: () => onToolChanged(EdenDiagramTool.pan),
          ),
          _ToolButton(
            icon: Icons.timeline,
            tooltip: 'Connect (C)',
            isActive: tool == EdenDiagramTool.connect,
            onTap: () => onToolChanged(EdenDiagramTool.connect),
          ),
          _divider(theme),
          _ToolButton(
            icon: Icons.crop_square,
            tooltip: 'Add Rectangle',
            onTap: () => onAddNode(EdenNodeShape.roundedRect),
          ),
          _ToolButton(
            icon: Icons.change_history,
            tooltip: 'Add Diamond',
            onTap: () => onAddNode(EdenNodeShape.diamond),
          ),
          _ToolButton(
            icon: Icons.circle_outlined,
            tooltip: 'Add Circle',
            onTap: () => onAddNode(EdenNodeShape.circle),
          ),
          _divider(theme),
          _ToolButton(icon: Icons.zoom_in, tooltip: 'Zoom In', onTap: onZoomIn),
          _ToolButton(icon: Icons.zoom_out, tooltip: 'Zoom Out', onTap: onZoomOut),
          _ToolButton(icon: Icons.fit_screen, tooltip: 'Reset Zoom', onTap: onZoomReset),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: theme.colorScheme.outlineVariant,
  );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

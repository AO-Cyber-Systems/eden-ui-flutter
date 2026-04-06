import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/colors.dart';
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

  @override
  State<EdenDiagram> createState() => _EdenDiagramState();
}

class _EdenDiagramState extends State<EdenDiagram> {
  EdenDiagramTool _tool = EdenDiagramTool.select;
  String? _selectedNodeId;
  String? _hoveredNodeId;
  String? _draggingNodeId;
  Offset _dragOffset = Offset.zero;

  // Edge drawing state
  String? _edgeSourceNodeId;
  EdenPortSide? _edgeSourcePort;
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

  /// Hit test for port dots (when a node is hovered/selected).
  (EdenDiagramNode, EdenPortSide)? _hitTestPort(Offset canvasPos) {
    for (final node in widget.data.nodes) {
      for (final side in EdenPortSide.values) {
        final portPos = node.portOffset(side);
        if ((portPos - canvasPos).distance < 10) {
          return (node, side);
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
        _edgeSourceNodeId = port.$1.id;
        _edgeSourcePort = port.$2;
        _dragEdgeStart = port.$1.portOffset(port.$2);
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
        if (port != null && port.$1.id == node.id) {
          _edgeSourceNodeId = port.$1.id;
          _edgeSourcePort = port.$2;
          _dragEdgeStart = port.$1.portOffset(port.$2);
          _dragEdgeEnd = _dragEdgeStart;
        } else {
          _draggingNodeId = node.id;
          _dragOffset = Offset(canvasPos.dx - node.x, canvasPos.dy - node.y);
        }
      }
    });
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
      if (port != null && port.$1.id != _edgeSourceNodeId) {
        // Create edge
        final edgeId = 'edge_${widget.data.edges.length + 1}';
        widget.data.edges.add(EdenDiagramEdge(
          id: edgeId,
          sourceId: _edgeSourceNodeId!,
          targetId: port.$1.id,
          sourcePort: _edgeSourcePort!,
          targetPort: port.$2,
        ));
        _notifyChanged();
      }
      setState(() {
        _edgeSourceNodeId = null;
        _edgeSourcePort = null;
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
                    dragEdgeStart: _dragEdgeStart,
                    dragEdgeEnd: _dragEdgeEnd,
                    panOffset: _panOffset,
                    scale: _scale,
                    gridEnabled: widget.gridEnabled,
                  ),
                ),
              ),
            ),

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
    this.dragEdgeStart,
    this.dragEdgeEnd,
    required this.panOffset,
    required this.scale,
    required this.gridEnabled,
  });

  final EdenDiagramData data;
  final ThemeData theme;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final Offset? dragEdgeStart;
  final Offset? dragEdgeEnd;
  final Offset panOffset;
  final double scale;
  final bool gridEnabled;

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
      dragEdgeStart: dragEdgeStart,
      dragEdgeEnd: dragEdgeEnd,
      gridEnabled: gridEnabled,
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

// EdenVisualWorkflowCanvas — composite root for the workflow designer.
//
// Composes EdenDiagram (obj 006) + customNodeRenderer dispatch (Trigger/
// Action/Condition/Branch/Delay/Merge/End) + EdenWorkflowToolbox +
// EdenWorkflowValidationPanel + EdenWorkflowController. Renders an
// iPhone-narrow fallback at <1200pt (workflow designer is desktop/tablet).
//
// Parity rows S-3 / S-4 / S-5 / L-4 / V-3 wiring.

import 'package:flutter/material.dart';

import '../eden_diagram/diagram_data.dart';
import '../eden_diagram/eden_diagram.dart';
import '../eden_process_canvas/process_layout_engine.dart';
import 'eden_workflow_toolbox.dart';
import 'eden_workflow_validation_panel.dart';
import 'nodes/eden_action_node.dart';
import 'nodes/eden_branch_node.dart';
import 'nodes/eden_condition_node.dart';
import 'nodes/eden_delay_node.dart';
import 'nodes/eden_merge_node.dart';
import 'nodes/eden_trigger_node.dart';
import 'nodes/eden_workflow_end_node.dart';
import 'workflow_controller.dart';
import 'workflow_graph_builder.dart';
import 'workflow_models.dart';
import 'workflow_toolbox_item_registry.dart';
import 'workflow_validator.dart';

class EdenVisualWorkflowCanvas extends StatefulWidget {
  const EdenVisualWorkflowCanvas({
    super.key,
    required this.definition,
    this.onSave,
    this.layout = const EdenFreeFormLayout(),
    this.hideToolbox = false,
    this.narrowFallbackThreshold = 1200,
  });

  final EdenWorkflowDefinition definition;
  final ValueChanged<EdenWorkflowSaveData>? onSave;
  final EdenProcessLayoutEngine layout;
  final bool hideToolbox;
  final double narrowFallbackThreshold;

  @override
  State<EdenVisualWorkflowCanvas> createState() =>
      _EdenVisualWorkflowCanvasState();
}

class _EdenVisualWorkflowCanvasState extends State<EdenVisualWorkflowCanvas> {
  late EdenWorkflowController _controller;
  bool _validationPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = EdenWorkflowController();
    _seedFromDefinition();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant EdenVisualWorkflowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.definition != widget.definition) {
      _seedFromDefinition();
    }
  }

  void _seedFromDefinition() {
    final (nodes, edges) =
        EdenWorkflowGraphBuilder.toCanvas(widget.definition);
    _controller.replaceAll(nodes: nodes, edges: edges);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Widget _dispatchNode(EdenDiagramNodeContext ctx) {
    final nodeType = ctx.node.data['nodeType'] as String?;
    switch (nodeType) {
      case 'trigger':
        return EdenTriggerNode(
          context: ctx,
          config: EdenTriggerNodeConfig(
            onUpdate: (updates) =>
                _controller.updateNode(ctx.node.id, updates),
          ),
        );
      case 'condition':
        return EdenConditionNode(
          context: ctx,
          config: EdenConditionNodeConfig(
            onUpdate: (updates) =>
                _controller.updateNode(ctx.node.id, updates),
            onDelete: () => _controller.removeNode(ctx.node.id),
          ),
        );
      case 'action':
        return EdenActionNode(
          context: ctx,
          config: EdenActionNodeConfig(
            onUpdate: (updates) =>
                _controller.updateNode(ctx.node.id, updates),
            onDelete: () => _controller.removeNode(ctx.node.id),
          ),
        );
      case 'delay':
        return EdenDelayNode(
          context: ctx,
          config: EdenDelayNodeConfig(
            onUpdate: (updates) =>
                _controller.updateNode(ctx.node.id, updates),
            onDelete: () => _controller.removeNode(ctx.node.id),
          ),
        );
      case 'branch':
        return EdenBranchNode(
          context: ctx,
          config: EdenBranchNodeConfig(
            onDelete: () => _controller.removeNode(ctx.node.id),
          ),
        );
      case 'merge':
        return EdenMergeNode(
          context: ctx,
          config: EdenMergeNodeConfig(
            onDelete: () => _controller.removeNode(ctx.node.id),
          ),
        );
      case 'end':
        return EdenWorkflowEndNode(context: ctx);
      default:
        return Text('Unknown: ${ctx.node.label}');
    }
  }

  void _handleToolboxAdd(EdenWorkflowToolboxItem item) {
    final id = _controller.generateNodeId(item.nodeType);
    final ports = _portsForNodeType(item.nodeType);
    final origin = _nextNodeOrigin();
    _controller.addNode(EdenDiagramNode(
      id: id,
      x: origin.dx,
      y: origin.dy,
      width: _widthForNodeType(item.nodeType),
      height: _heightForNodeType(item.nodeType),
      label: item.label,
      data: {
        'nodeType': item.nodeType,
        ...item.defaultData,
      },
      ports: ports,
    ));
  }

  List<EdenDiagramPort> _portsForNodeType(String nodeType) {
    switch (nodeType) {
      case 'trigger':
        return EdenWorkflowGraphBuilder.triggerPorts();
      case 'condition':
        return EdenWorkflowGraphBuilder.conditionPorts();
      case 'action':
        return EdenWorkflowGraphBuilder.actionPorts();
      case 'delay':
        return EdenWorkflowGraphBuilder.delayPorts();
      case 'branch':
        return EdenWorkflowGraphBuilder.branchPorts();
      case 'merge':
        return EdenWorkflowGraphBuilder.mergePorts();
      case 'end':
        return EdenWorkflowGraphBuilder.endPorts();
      default:
        return const [];
    }
  }

  double _widthForNodeType(String nodeType) {
    switch (nodeType) {
      case 'end':
        return 48;
      case 'condition':
        return 140;
      case 'branch':
      case 'merge':
        return 160;
      default:
        return 200;
    }
  }

  double _heightForNodeType(String nodeType) {
    switch (nodeType) {
      case 'end':
        return 48;
      case 'condition':
        return 140;
      default:
        return 80;
    }
  }

  Offset _nextNodeOrigin() {
    // Naive: drop new nodes in a column to the right of the right-most node.
    if (_controller.nodes.isEmpty) return const Offset(100, 100);
    final maxX = _controller.nodes
        .map((n) => n.x + n.width)
        .reduce((a, b) => a > b ? a : b);
    return Offset(maxX + 80, 100);
  }

  void _handleSave() {
    final result = EdenWorkflowGraphBuilder.fromCanvas(
      _controller.nodes,
      _controller.edges,
      userEdges: _controller.userEdges,
    );
    widget.onSave?.call(result);
  }

  EdenWorkflowValidationResult _validate() => EdenWorkflowValidator.validate(
        _controller.nodes,
        _controller.edges,
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width < widget.narrowFallbackThreshold) {
      return _NarrowFallback(threshold: widget.narrowFallbackThreshold);
    }

    final result = _validate();
    final summary = result.summary;

    return Stack(
      children: [
        Row(
          children: [
            if (!widget.hideToolbox)
              DragTarget<EdenWorkflowToolboxDragPayload>(
                onAcceptWithDetails: (_) {}, // no-op; canvas handles drops
                builder: (ctx, _, __) => EdenWorkflowToolbox(
                  onAddItem: _handleToolboxAdd,
                ),
              ),
            Expanded(
              child: DragTarget<EdenWorkflowToolboxDragPayload>(
                onAcceptWithDetails: (details) {
                  final item = EdenWorkflowToolboxItemRegistry.instance
                      .lookup(details.data.itemId);
                  if (item != null) _handleToolboxAdd(item);
                },
                builder: (ctx, candidate, __) {
                  final data = EdenDiagramData(
                    nodes: List.of(_controller.nodes),
                    edges: List.of(_controller.edges),
                  );
                  return EdenDiagram(
                    data: data,
                    customNodeRenderer: _dispatchNode,
                    showToolbar: false,
                  );
                },
              ),
            ),
          ],
        ),
        // Top toolbar: Save + Validation badge
        Positioned(
          top: 8,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onSave != null) ...[
                FilledButton.icon(
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.tonalIcon(
                onPressed: () => setState(
                  () => _validationPanelOpen = !_validationPanelOpen,
                ),
                icon: Icon(
                  result.isValid
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 16,
                ),
                label: Text(
                  result.isValid
                      ? 'Valid${summary.warnings > 0 ? ' (${summary.warnings})' : ''}'
                      : '${summary.errors} error${summary.errors == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
        ),
        if (_validationPanelOpen)
          Positioned(
            top: 56,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: EdenWorkflowValidationPanel(
                result: result,
                onClose: () => setState(() => _validationPanelOpen = false),
              ),
            ),
          ),
      ],
    );
  }
}

class _NarrowFallback extends StatelessWidget {
  const _NarrowFallback({required this.threshold});
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tablet_mac,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Workflow designer requires tablet/desktop width',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch to a wider screen (≥${threshold.toInt()}pt) or use the mobile workflow list view.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

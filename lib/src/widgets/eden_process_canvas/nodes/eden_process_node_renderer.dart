import 'package:flutter/material.dart';

import '../../eden_diagram/eden_diagram_exports.dart';
import 'eden_process_end_node.dart';
import 'eden_process_orphan_node.dart';
import 'eden_process_start_node.dart';

/// Per-node callbacks aggregated for [EdenProcessNodeRenderer.dispatch].
///
/// TRDs 006-05/006-06/006-07 extend this additively with phase / taskGroup /
/// task callbacks. TRD 006-14 (`EdenVisualProcessCanvas`) composes the full
/// config from its props.
class EdenProcessNodeRendererConfig {
  const EdenProcessNodeRendererConfig({
    this.onDeleteOrphan,
  });

  /// Fires with the orphan node's id when its delete affordance is invoked.
  final void Function(String nodeId)? onDeleteOrphan;
}

/// Central dispatcher used by `EdenDiagram.customNodeRenderer` to route a
/// node-context to the correct process-canvas node widget.
///
/// Switches on `ctx.node.data['nodeType']`. Unknown / missing types render a
/// loud red-bordered fallback so missing cases surface during development.
class EdenProcessNodeRenderer {
  EdenProcessNodeRenderer._();

  static Widget dispatch(
    EdenDiagramNodeContext ctx, {
    EdenProcessNodeRendererConfig? config,
  }) {
    final nodeType = ctx.node.data['nodeType'] as String?;
    switch (nodeType) {
      case 'start':
        return EdenProcessStartNode(context: ctx);
      case 'end':
        return EdenProcessEndNode(context: ctx);
      case 'orphan':
        return EdenProcessOrphanNode(
          context: ctx,
          onDelete: config?.onDeleteOrphan,
        );
      default:
        return _UnknownNodeFallback(label: ctx.node.label);
    }
  }
}

class _UnknownNodeFallback extends StatelessWidget {
  const _UnknownNodeFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          label.isEmpty ? 'unknown' : label,
          style: const TextStyle(fontSize: 10),
        ),
      );
}

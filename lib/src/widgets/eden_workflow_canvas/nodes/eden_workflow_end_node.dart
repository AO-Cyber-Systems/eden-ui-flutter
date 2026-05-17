// EdenWorkflowEndNode — workflow termination marker (donor EndNode.tsx parity).
//
// 48x48 red circular node with Stop/Square icon. NO popover, NO delete
// button (End is uniquely required — workflow needs a defined end).
// Target-only ports (top, left). 43 LOC donor; this widget is similarly
// small.
//
// Parity row N-7.

import 'package:flutter/material.dart';

import '../../eden_diagram/diagram_data.dart';

class EdenWorkflowEndNode extends StatelessWidget {
  const EdenWorkflowEndNode({super.key, required this.context});

  final EdenDiagramNodeContext context;

  @override
  Widget build(BuildContext bcontext) {
    final theme = Theme.of(bcontext);
    final isSelected = context.selected;
    final isDropTarget = context.dropTarget;

    return SizedBox(
      width: 48,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(
            color: isDropTarget
                ? theme.colorScheme.tertiary
                : isSelected
                    ? theme.colorScheme.primary
                    : Colors.red.shade400,
            width: (isSelected || isDropTarget) ? 2.5 : 2,
          ),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x14000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.stop,
          size: 20,
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../eden_diagram/eden_diagram_exports.dart';

/// Process-flow End node — parity row N-2.
///
/// 48×48 red circle with a filled Square (stop) icon. Renders inside an
/// `EdenDiagram`'s `customNodeRenderer` Stack overlay. Sizing comes from the
/// parent `Positioned` box.
///
/// Selection ring drawn here when `context.selected == true`.
class EdenProcessEndNode extends StatelessWidget {
  const EdenProcessEndNode({super.key, required this.context});

  final EdenDiagramNodeContext context;

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // donor color — keep until token system has equivalent (EndNode.tsx bg-red-500)
        color: Colors.red.shade500,
        border: context.selected
            ? Border.all(color: Colors.red.shade300, width: 3)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.stop, color: Colors.white, size: 22),
      ),
    );
  }
}

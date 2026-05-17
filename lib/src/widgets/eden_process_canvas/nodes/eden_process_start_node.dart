import 'package:flutter/material.dart';

import '../../eden_diagram/eden_diagram_exports.dart';

/// Process-flow Start node — parity row N-1.
///
/// 48×48 green circle with a Play icon. Renders inside an `EdenDiagram`'s
/// `customNodeRenderer` Stack overlay. Sizing comes from the parent
/// `Positioned` box; this widget fills it.
///
/// Selection ring drawn here (not in the canvas painter) when
/// `context.selected == true`.
class EdenProcessStartNode extends StatelessWidget {
  const EdenProcessStartNode({super.key, required this.context});

  final EdenDiagramNodeContext context;

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // donor color — keep until token system has equivalent (StartNode.tsx bg-green-500)
        color: Colors.green.shade500,
        border: context.selected
            ? Border.all(color: Colors.green.shade300, width: 3)
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
        child: Padding(
          // Donor uses ml-0.5 to optically center the Play triangle inside its circle.
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.play_arrow, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

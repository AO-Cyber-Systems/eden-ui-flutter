// EdenBranchNode — workflow parallel-split node (donor BranchNode.tsx parity).
//
// Gray card, 140pt min width. GitFork icon ("call_split" Material equivalent),
// "BRANCH" uppercase label, "Split" subtitle. No popover editor (presentational
// only). Hover-show delete button on desktop; always-shown on touch.
//
// Ports (emitted at graph-builder level when this node type is dropped from
// toolbox — TRD 020-05 graph builder extension): 2 target (top, left) +
// 3 source (right offset 0.33, right-2 offset 0.66, bottom).
//
// Parity row N-3.

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../eden_diagram/diagram_data.dart';

class EdenBranchNodeConfig {
  const EdenBranchNodeConfig({this.onDelete});
  final VoidCallback? onDelete;
}

class EdenBranchNode extends StatefulWidget {
  const EdenBranchNode({
    super.key,
    required this.context,
    this.config = const EdenBranchNodeConfig(),
  });

  final EdenDiagramNodeContext context;
  final EdenBranchNodeConfig config;

  @override
  State<EdenBranchNode> createState() => _EdenBranchNodeState();
}

class _EdenBranchNodeState extends State<EdenBranchNode> {
  bool _hovered = false;

  bool get _isTouchPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.context.selected;
    final isDropTarget = widget.context.dropTarget;
    final showDelete = _hovered || _isTouchPlatform;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(
                color: isDropTarget
                    ? theme.colorScheme.tertiary
                    : isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade400,
                width: (isSelected || isDropTarget) ? 2.5 : 2,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6,
                  color: Color(0x14000000),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.call_split,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BRANCH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Split',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDelete && widget.config.onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.config.onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade400, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

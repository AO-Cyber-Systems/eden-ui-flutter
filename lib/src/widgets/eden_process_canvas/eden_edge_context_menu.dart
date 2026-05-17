import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/radii.dart';

/// Context menu shown when the user right-clicks (or long-presses) an edge.
///
/// Single hard-coded `Delete Connection` action. Same dismissal semantics
/// as [EdenNodeContextMenu]: click-outside backdrop, Esc, and tapping the
/// action all fire `onClose`.
class EdenEdgeContextMenu extends StatelessWidget {
  const EdenEdgeContextMenu({
    super.key,
    required this.onDelete,
    required this.onClose,
  });

  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('edge-context-menu-dismiss-backdrop'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
            ),
          ),
          Material(
            elevation: 4,
            color: theme.colorScheme.surface,
            borderRadius: EdenRadii.borderRadiusMd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160),
              child: InkWell(
                key: const ValueKey('edge-delete-action'),
                onTap: () {
                  onDelete();
                  onClose();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delete Connection',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
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

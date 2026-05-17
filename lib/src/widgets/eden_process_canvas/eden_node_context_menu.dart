import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/radii.dart';

/// A single action entry in [EdenNodeContextMenu].
///
/// Vertical-agnostic: the canvas composer (TRD 006-14) builds these lists
/// per node type. Set [destructive] to render in `theme.colorScheme.error`.
/// Set [submenuItems] to render a nested submenu inline-expanded below the
/// parent on tap (tap parent → toggle expansion; tap child → fire `onTap`
/// AND close the parent menu via the consumer's `onClose`).
class EdenNodeContextMenuAction {
  const EdenNodeContextMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.submenuItems,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  final List<EdenNodeContextMenuAction>? submenuItems;
}

/// Context menu shown when the user right-clicks (or long-presses) a node.
///
/// **Positionless:** the widget itself doesn't position; consumers wrap it
/// in `Positioned(left: x, top: y, child: ...)` inside an `Overlay` /
/// `Stack` of their choice.
///
/// Dismissal: click-outside (transparent full-screen GestureDetector under
/// the menu fires `onClose`); Esc key (Focus-driven keyboard handler);
/// tapping a leaf action also fires `onClose` after its own `onTap`.
class EdenNodeContextMenu extends StatefulWidget {
  const EdenNodeContextMenu({
    super.key,
    required this.actions,
    required this.onClose,
  });

  final List<EdenNodeContextMenuAction> actions;
  final VoidCallback onClose;

  @override
  State<EdenNodeContextMenu> createState() => _EdenNodeContextMenuState();
}

class _EdenNodeContextMenuState extends State<EdenNodeContextMenu> {
  final Map<String, bool> _expandedSubmenus = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('node-context-menu-dismiss-backdrop'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
            ),
          ),
          Material(
            elevation: 4,
            color: theme.colorScheme.surface,
            borderRadius: EdenRadii.borderRadiusMd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in widget.actions) _buildItem(action, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(EdenNodeContextMenuAction action, ThemeData theme) {
    final hasSubmenu =
        action.submenuItems != null && action.submenuItems!.isNotEmpty;
    final isExpanded = _expandedSubmenus[action.label] ?? false;
    final color = action.destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          key: ValueKey('action-${action.label}'),
          onTap: () {
            if (hasSubmenu) {
              setState(() => _expandedSubmenus[action.label] = !isExpanded);
            } else {
              action.onTap();
              widget.onClose();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(action.icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.label,
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ),
                if (hasSubmenu)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        if (hasSubmenu && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final sub in action.submenuItems!) _buildItem(sub, theme),
              ],
            ),
          ),
      ],
    );
  }
}

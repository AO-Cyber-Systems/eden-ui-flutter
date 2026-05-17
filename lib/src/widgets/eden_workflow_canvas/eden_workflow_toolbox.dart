// EdenWorkflowToolbox — left-rail toolbox for the workflow canvas.
//
// Iterates EdenWorkflowToolboxItemRegistry; renders items grouped by category
// (trigger / condition / action / flow). Each item is Draggable<payload>
// AND tappable for fallback click-to-add. Parity rows T-1 / T-2 / T-3.

import 'package:flutter/material.dart';

import 'workflow_toolbox_item_registry.dart';

class EdenWorkflowToolbox extends StatelessWidget {
  const EdenWorkflowToolbox({
    super.key,
    this.onAddItem,
    this.width = 208,
  });

  /// Click-to-add fallback callback. Drag/drop integration is handled by the
  /// host canvas via DragTarget; this callback is for accessibility +
  /// non-drag interaction.
  final ValueChanged<EdenWorkflowToolboxItem>? onAddItem;

  final double width;

  static const List<({String id, String label})> _categories = [
    (id: 'trigger', label: 'TRIGGERS'),
    (id: 'condition', label: 'CONDITIONS'),
    (id: 'action', label: 'ACTIONS'),
    (id: 'flow', label: 'FLOW CONTROL'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registry = EdenWorkflowToolboxItemRegistry.instance;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Text(
              'ADD ELEMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final cat in _categories) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...registry.byCategory(cat.id).map(
                        (item) => _ToolboxTile(
                          item: item,
                          onTap: onAddItem,
                        ),
                      ),
                ],
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Click or drag to add elements',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolboxTile extends StatelessWidget {
  const _ToolboxTile({required this.item, this.onTap});

  final EdenWorkflowToolboxItem item;
  final ValueChanged<EdenWorkflowToolboxItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Draggable<EdenWorkflowToolboxDragPayload>(
      data: EdenWorkflowToolboxDragPayload(itemId: item.id),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(blurRadius: 8, color: Color(0x14000000)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 16),
              const SizedBox(width: 6),
              Text(item.label),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTile(context, theme),
      ),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!.call(item),
        child: _buildTile(context, theme),
      ),
    );
  }

  Widget _buildTile(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Icon(
            Icons.add,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

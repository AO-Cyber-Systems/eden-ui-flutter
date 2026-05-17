import 'package:flutter/material.dart';

import 'template_models.dart';

/// Default placeholder rendering for a template block on the canvas —
/// parity row C-7.
///
/// Consumers override per block-type by setting
/// [EdenTemplateBlockDescriptor.placeholderBuilder] in the registry.
/// When the descriptor's `placeholderBuilder` is null, the canvas falls
/// back to this widget.
///
/// Label resolution chain:
/// 1. `block.content['label']` (String)
/// 2. `block.content['text']` (String)
/// 3. `descriptor.displayName`
class EdenTemplateBlockPlaceholder extends StatelessWidget {
  const EdenTemplateBlockPlaceholder({
    super.key,
    required this.block,
    required this.descriptor,
    this.onEdit,
    this.onDelete,
    this.showDragHandle = true,
  });

  final EdenTemplateBlock block;
  final EdenTemplateBlockDescriptor descriptor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDragHandle;

  String _resolveLabel() {
    final label = block.content['label'];
    if (label is String && label.isNotEmpty) return label;
    final text = block.content['text'];
    if (text is String && text.isNotEmpty) return text;
    return descriptor.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _resolveLabel();
    final subtext = onDelete == null
        ? '${descriptor.displayName} — click to edit, drag to reorder'
        : '${descriptor.displayName} — click to edit, X to remove';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          Icon(
            descriptor.icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Delete block',
              onPressed: onDelete,
            ),
          if (showDragHandle)
            Icon(
              Icons.drag_indicator,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

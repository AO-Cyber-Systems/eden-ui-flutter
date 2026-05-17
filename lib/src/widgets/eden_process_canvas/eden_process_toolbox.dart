import 'package:flutter/material.dart';

import '../../tokens/radii.dart';

/// Drag payload emitted by `EdenProcessToolbox` items and accepted by the
/// canvas composer's `DragTarget<EdenProcessDragPayload>` (TRD 006-14).
///
/// `dragType` is the type-discriminator (e.g. `'task'`, `'taskGroup'`,
/// `'phase'`, `'decision'`, `'templateGroup'`, or any custom string from a
/// consumer-defined toolbox item). `config` carries optional construction
/// hints (e.g. `{'runtimeComponent': 'photo_gallery'}` for a task; or
/// `{'templateId': 42}` for a template).
class EdenProcessDragPayload {
  const EdenProcessDragPayload({required this.dragType, this.config});

  final String dragType;
  final Map<String, dynamic>? config;
}

/// A single draggable / tappable entry in [EdenProcessToolbox].
///
/// Vertical-extensible: consumers register additional items per category
/// (e.g. a "Field" vertical adds a "Photo gallery" task variant).
class EdenProcessToolboxItem {
  const EdenProcessToolboxItem({
    required this.dragType,
    required this.label,
    required this.icon,
    this.description,
    this.color,
    this.taskConfig,
  });

  final String dragType;
  final String label;
  final IconData icon;
  final String? description;
  final Color? color;
  final Map<String, dynamic>? taskConfig;
}

/// A category section in [EdenProcessToolbox] containing one or more items.
class EdenProcessToolboxCategory {
  const EdenProcessToolboxCategory({
    required this.key,
    required this.label,
    required this.items,
  });

  final String key;
  final String label;
  final List<EdenProcessToolboxItem> items;
}

/// A template entry rendered in the dedicated `TEMPLATES` section.
class EdenProcessToolboxTemplate {
  const EdenProcessToolboxTemplate({
    required this.id,
    required this.name,
    this.workCategoryId,
    this.taskCount = 0,
  });

  final int id;
  final String name;
  final int? workCategoryId;
  final int taskCount;
}

/// Drag-from-palette rail on the left side of `EdenVisualProcessCanvas`.
///
/// Parity rows: T-1 (categorized draggable items), T-2 (templates section
/// with recommended badge), T-3 (click-to-add fallback for touch / a11y).
///
/// Drag data is `EdenProcessDragPayload`. Canvas DragTarget unifies item +
/// template + custom-vertical drops behind one type. Click-fallback fires
/// `onAddNode(dragType, taskConfig)` for items and `onTemplateSelected(id)`
/// for templates.
class EdenProcessToolbox extends StatelessWidget {
  const EdenProcessToolbox({
    super.key,
    this.categories = const [],
    this.templates = const [],
    this.recommendedWorkCategoryId,
    required this.onAddNode,
    this.onTemplateSelected,
  });

  final List<EdenProcessToolboxCategory> categories;
  final List<EdenProcessToolboxTemplate> templates;
  final int? recommendedWorkCategoryId;
  final void Function(String dragType, Map<String, dynamic>? config) onAddNode;
  final void Function(int templateId)? onTemplateSelected;

  /// Library-default categories when consumer doesn't supply any. Mirrors
  /// donor `Toolbox.tsx`'s baseline structure + tasks rows.
  static const List<EdenProcessToolboxCategory> defaultCategories = [
    EdenProcessToolboxCategory(
      key: 'structure',
      label: 'Structure',
      items: [
        EdenProcessToolboxItem(
          dragType: 'phase',
          label: 'Phase',
          icon: Icons.layers,
          description: 'A stage in your process',
        ),
      ],
    ),
    EdenProcessToolboxCategory(
      key: 'task',
      label: 'Tasks',
      items: [
        EdenProcessToolboxItem(
          dragType: 'task',
          label: 'Task',
          icon: Icons.check_box,
          description: 'Drop on a task to group them',
        ),
      ],
    ),
  ];

  List<EdenProcessToolboxCategory> get _effectiveCategories =>
      categories.isEmpty ? defaultCategories : categories;

  List<EdenProcessToolboxTemplate> get _sortedTemplates {
    if (recommendedWorkCategoryId == null) return templates;
    final matching = templates
        .where((t) => t.workCategoryId == recommendedWorkCategoryId)
        .toList();
    final others = templates
        .where((t) => t.workCategoryId != recommendedWorkCategoryId)
        .toList();
    return [...matching, ...others];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 208,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADD ELEMENTS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final category in _effectiveCategories) ...[
              Text(
                category.label.toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              for (final item in category.items)
                _ToolboxItem(
                  key: ValueKey('toolbox-item-${item.dragType}-${item.label}'),
                  item: item,
                  onTap: () => onAddNode(item.dragType, item.taskConfig),
                ),
              const SizedBox(height: 12),
            ],
            if (templates.isNotEmpty) ...[
              Text(
                'TEMPLATES',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              for (final template in _sortedTemplates)
                _TemplateItem(
                  key: ValueKey('toolbox-template-${template.id}'),
                  template: template,
                  isRecommended: recommendedWorkCategoryId != null &&
                      template.workCategoryId == recommendedWorkCategoryId,
                  onTap: () => onTemplateSelected?.call(template.id),
                ),
              const SizedBox(height: 12),
            ],
            Text(
              'Drop tasks on each other to group',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolboxItem extends StatelessWidget {
  const _ToolboxItem({super.key, required this.item, required this.onTap});

  final EdenProcessToolboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Draggable<EdenProcessDragPayload>(
        data: EdenProcessDragPayload(
          dragType: item.dragType,
          config: item.taskConfig,
        ),
        feedback: Material(
          elevation: 4,
          color: Colors.transparent,
          child: _itemCard(theme, opacity: 0.8),
        ),
        childWhenDragging:
            Opacity(opacity: 0.4, child: _itemCard(theme)),
        child: InkWell(onTap: onTap, child: _itemCard(theme)),
      ),
    );
  }

  Widget _itemCard(ThemeData theme, {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: EdenRadii.borderRadiusSm,
          border: Border.all(
            color: item.color ?? theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: EdenRadii.borderRadiusSm,
              ),
              child: Icon(
                item.icon,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.add,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  const _TemplateItem({
    super.key,
    required this.template,
    required this.isRecommended,
    required this.onTap,
  });

  final EdenProcessToolboxTemplate template;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Draggable<EdenProcessDragPayload>(
        data: EdenProcessDragPayload(
          dragType: 'templateGroup',
          config: {'templateId': template.id},
        ),
        feedback: Material(
          elevation: 4,
          color: Colors.transparent,
          child: Opacity(opacity: 0.8, child: _card(theme)),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: _card(theme)),
        child: InkWell(onTap: onTap, child: _card(theme)),
      ),
    );
  }

  Widget _card(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isRecommended ? Colors.blue.shade50 : theme.colorScheme.surface,
        borderRadius: EdenRadii.borderRadiusSm,
        border: Border.all(
          color: isRecommended
              ? Colors.blue.shade300
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: const Icon(Icons.menu_book, size: 14, color: Colors.blue),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          borderRadius: EdenRadii.borderRadiusSm,
                        ),
                        child: Text(
                          'rec',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontSize: 8),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${template.taskCount} task${template.taskCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.add,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

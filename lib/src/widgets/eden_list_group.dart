import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single item in an [EdenListGroup].
class EdenListGroupItem {
  const EdenListGroupItem({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.active = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool active;
}

/// Mirrors the eden_list_group / eden_list_group_item Rails components.
///
/// A bordered, vertical list of items used for navigation or grouped content.
class EdenListGroup extends StatelessWidget {
  const EdenListGroup({
    super.key,
    required this.items,
  });

  final List<EdenListGroupItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
            _ListItem(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.item});
  final EdenListGroupItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = item.active
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : null;

    final content = Container(
      color: bg,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      child: Row(
        children: [
          if (item.leading != null) ...[
            item.leading!,
            const SizedBox(width: EdenSpacing.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: item.active ? theme.colorScheme.primary : null,
                    fontWeight: item.active ? FontWeight.w600 : null,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.trailing != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            item.trailing!,
          ],
        ],
      ),
    );

    if (item.onTap != null) {
      return InkWell(onTap: item.onTap, child: content);
    }
    return content;
  }
}

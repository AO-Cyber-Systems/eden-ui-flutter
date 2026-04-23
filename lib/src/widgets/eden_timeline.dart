import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// A single item in a timeline.
class EdenTimelineItemData {
  const EdenTimelineItemData({
    required this.title,
    this.body,
    this.datetime,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? body;
  final String? datetime;
  final IconData? icon;
  final Color? iconColor;
}

/// Mirrors the eden_timeline / eden_timeline_item Rails components.
class EdenTimeline extends StatelessWidget {
  const EdenTimeline({
    super.key,
    required this.items,
  });

  final List<EdenTimelineItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _TimelineEntry(
            item: items[i],
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.item, required this.isLast});

  final EdenTimelineItemData item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = item.iconColor ?? theme.colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.1),
                    border: Border.all(color: theme.colorScheme.surface, width: 3),
                  ),
                  child: Icon(
                    item.icon ?? Icons.circle,
                    size: item.icon != null ? 14 : 8,
                    color: iconColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : EdenSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: theme.textTheme.titleSmall),
                  if (item.datetime != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.datetime!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (item.body != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.body!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

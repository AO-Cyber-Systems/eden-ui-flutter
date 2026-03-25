import 'package:flutter/material.dart';

/// An entry in the activity timeline.
class EdenActivityTimelineEntry {
  const EdenActivityTimelineEntry({
    required this.title,
    this.description,
    this.timestamp,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.status = EdenTimelineEntryStatus.complete,
  });

  final String title;
  final String? description;
  final String? timestamp;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final EdenTimelineEntryStatus status;
}

enum EdenTimelineEntryStatus { complete, current, upcoming }

/// Vertical activity timeline with icons, status colors, and connector lines.
///
/// Extends EdenTimeline with activity-specific features: status-based
/// coloring, icon backgrounds, and timestamps.
///
/// ```dart
/// EdenActivityTimeline(
///   entries: [
///     EdenActivityTimelineEntry(
///       title: 'PO Created',
///       description: 'Purchase order #1234 created by John',
///       timestamp: '2 hours ago',
///       icon: Icons.add_circle,
///       status: EdenTimelineEntryStatus.complete,
///     ),
///     EdenActivityTimelineEntry(
///       title: 'Awaiting Approval',
///       status: EdenTimelineEntryStatus.current,
///       icon: Icons.hourglass_top,
///     ),
///   ],
/// )
/// ```
class EdenActivityTimeline extends StatelessWidget {
  const EdenActivityTimeline({
    super.key,
    required this.entries,
    this.lineColor,
    this.iconSize = 32,
  });

  final List<EdenActivityTimelineEntry> entries;
  final Color? lineColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultLineColor =
        lineColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          _buildEntry(context, entries[i], i, defaultLineColor),
      ],
    );
  }

  Widget _buildEntry(BuildContext context, EdenActivityTimelineEntry entry,
      int index, Color defaultLineColor) {
    final theme = Theme.of(context);
    final isLast = index == entries.length - 1;

    final statusColor = _statusColor(theme, entry.status);
    final bgColor = entry.iconBackgroundColor ??
        statusColor.withValues(alpha: 0.15);
    final fgColor = entry.iconColor ?? statusColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon column with connector
          SizedBox(
            width: iconSize + 16,
            child: Column(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                    border: entry.status == EdenTimelineEntryStatus.current
                        ? Border.all(color: fgColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    entry.icon ?? _defaultIcon(entry.status),
                    size: iconSize * 0.5,
                    color: fgColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: defaultLineColor,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: entry.status ==
                                    EdenTimelineEntryStatus.upcoming
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (entry.timestamp != null)
                        Text(
                          entry.timestamp!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (entry.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.description!,
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

  Color _statusColor(ThemeData theme, EdenTimelineEntryStatus status) {
    switch (status) {
      case EdenTimelineEntryStatus.complete:
        return Colors.green;
      case EdenTimelineEntryStatus.current:
        return theme.colorScheme.primary;
      case EdenTimelineEntryStatus.upcoming:
        return theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }
  }

  IconData _defaultIcon(EdenTimelineEntryStatus status) {
    switch (status) {
      case EdenTimelineEntryStatus.complete:
        return Icons.check;
      case EdenTimelineEntryStatus.current:
        return Icons.circle;
      case EdenTimelineEntryStatus.upcoming:
        return Icons.circle_outlined;
    }
  }
}

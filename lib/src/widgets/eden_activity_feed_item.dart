import 'package:flutter/material.dart';

/// Variant colors for activity feed items.
enum EdenActivityVariant { success, warning, danger, info }

/// A single row in an activity feed.
///
/// Shows an avatar with initials, a rich-text action description
/// (actor + action + entity), and a timestamp. Framework-agnostic —
/// pass data directly, no model dependency.
///
/// ```dart
/// EdenActivityFeedItem(
///   actorName: 'John D.',
///   actorInitials: 'JD',
///   action: 'completed task',
///   entityName: 'Install HVAC Unit',
///   timeAgo: '5 min ago',
///   variant: EdenActivityVariant.success,
///   onTap: () => navigateToTask(taskId),
/// )
/// ```
class EdenActivityFeedItem extends StatelessWidget {
  const EdenActivityFeedItem({
    super.key,
    required this.actorName,
    required this.actorInitials,
    required this.action,
    required this.entityName,
    required this.timeAgo,
    this.variant = EdenActivityVariant.info,
    this.onTap,
  });

  final String actorName;
  final String actorInitials;
  final String action;
  final String entityName;
  final String timeAgo;
  final EdenActivityVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _variantColor(theme, variant);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withValues(alpha: 0.15),
              border: Border.all(
                color: avatarColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                actorInitials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: actorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' $action '),
                      TextSpan(
                        text: entityName,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Color _variantColor(ThemeData theme, EdenActivityVariant variant) {
    switch (variant) {
      case EdenActivityVariant.success:
        return Colors.green;
      case EdenActivityVariant.warning:
        return Colors.orange;
      case EdenActivityVariant.danger:
        return Colors.red;
      case EdenActivityVariant.info:
        return theme.colorScheme.primary;
    }
  }
}

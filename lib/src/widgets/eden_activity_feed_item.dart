import 'package:flutter/material.dart';

/// Severity / category variant for an activity-feed row.
///
/// Drives the avatar tint:
/// - `success` → `Colors.green`
/// - `warning` → `Colors.orange`
/// - `danger` → `Colors.red`
/// - `info` → `theme.colorScheme.primary`
enum EdenActivityVariant { success, warning, danger, info }

/// Pure data for an [EdenActivityFeedItem].
///
/// The library does NOT bind to any vertical-specific entity model — consumers
/// map their domain (e.g. trades `AdminStats.ActivityFeedItem`, medical chart
/// audit row, legal docket entry) to this shape themselves. `actorInitials` is
/// expected to be consumer-computed (the library does not extract initials
/// from `actorName`) so different verticals can apply their own conventions.
class EdenActivityFeedItemData {
  const EdenActivityFeedItemData({
    required this.actorName,
    required this.actorInitials,
    required this.action,
    required this.entityName,
    required this.timeAgo,
    this.variant = EdenActivityVariant.info,
  });

  /// Full display name of the actor.
  final String actorName;

  /// 1-5 character initials shown inside the circular avatar.
  /// Consumer-computed — the library does NOT derive these from [actorName].
  final String actorInitials;

  /// Verb phrase describing the action (e.g. "created", "deleted",
  /// "commented on").
  final String action;

  /// Display name of the entity acted upon (e.g. "Customer #42").
  final String entityName;

  /// Pre-formatted relative timestamp (e.g. "5m ago", "just now",
  /// "yesterday"). The library does not format timestamps — consumers map
  /// their own clock + locale rules.
  final String timeAgo;

  /// Severity tint (see [EdenActivityVariant]).
  final EdenActivityVariant variant;
}

/// Cross-vertical activity-log row.
///
/// Renders a circular initials avatar followed by a RichText composition of
/// `actorName + action + entityName`, a smaller `timeAgo` caption, and an
/// optional `InkWell` tap target.
///
/// Cross-vertical examples:
/// - Trades: admin activity feed.
/// - Salon: booking-history row.
/// - Medical: chart audit log.
/// - Legal: matter timeline.
/// - Government: audit trail.
/// - Retail: transaction history.
///
/// Donor: `trades-flutter/lib/shared/widgets/activity_feed_item.dart` (rebound
/// to library-owned [EdenActivityFeedItemData] + [EdenActivityVariant] per
/// cross-vertical decoupling constraint).
class EdenActivityFeedItem extends StatelessWidget {
  const EdenActivityFeedItem({
    super.key,
    required this.item,
    this.onTap,
  });

  /// Data for the row.
  final EdenActivityFeedItemData item;

  /// Optional tap callback. When non-null the row is wrapped in an [InkWell].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _variantColor(theme, item.variant);

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
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
                item.actorInitials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text content
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
                        text: item.actorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${item.action} '),
                      TextSpan(
                        text: item.entityName,
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
                  item.timeAgo,
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

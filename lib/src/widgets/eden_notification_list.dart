import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Variant for notification icon color.
enum EdenNotificationVariant { info, success, warning, danger, neutral }

/// A single notification item data.
class EdenNotificationItemData {
  const EdenNotificationItemData({
    required this.title,
    this.body,
    this.time,
    this.icon,
    this.read = false,
    this.variant = EdenNotificationVariant.info,
    this.onTap,
  });

  final String title;
  final String? body;
  final String? time;
  final IconData? icon;
  final bool read;
  final EdenNotificationVariant variant;
  final VoidCallback? onTap;
}

/// Mirrors the eden_notification_list / eden_notification_item Rails components.
class EdenNotificationList extends StatelessWidget {
  const EdenNotificationList({
    super.key,
    this.title = 'Notifications',
    required this.notifications,
    this.onMarkAllRead,
    this.onViewAll,
  });

  final String title;
  final List<EdenNotificationItemData> notifications;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = notifications.where((n) => !n.read).length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: Row(
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: EdenRadii.borderRadiusFull,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
                const Spacer(),
                if (onMarkAllRead != null)
                  GestureDetector(
                    onTap: onMarkAllRead,
                    child: Text(
                      'Mark all read',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          // Items
          ...notifications.map((n) => _NotificationItem(data: n)),
          // Footer
          if (onViewAll != null) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            GestureDetector(
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.all(EdenSpacing.space3),
                child: Center(
                  child: Text(
                    'View all notifications',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.data});
  final EdenNotificationItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _variantColors(theme, data.variant);

    final content = Container(
      color: data.read ? null : theme.colorScheme.primary.withValues(alpha: 0.03),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.bg,
            ),
            child: Icon(data.icon ?? Icons.notifications_outlined, size: 16, color: colors.fg),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: data.read ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                if (data.body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.body!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (data.time != null || !data.read) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (data.time != null)
                  Text(data.time!, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                if (!data.read) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (data.onTap != null) {
      return InkWell(onTap: data.onTap, child: content);
    }
    return content;
  }

  _VariantColors _variantColors(ThemeData theme, EdenNotificationVariant variant) {
    switch (variant) {
      case EdenNotificationVariant.info:
        return _VariantColors(theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.primary);
      case EdenNotificationVariant.success:
        return _VariantColors(EdenColors.success.withValues(alpha: 0.1), EdenColors.success);
      case EdenNotificationVariant.warning:
        return _VariantColors(EdenColors.warning.withValues(alpha: 0.1), EdenColors.warning);
      case EdenNotificationVariant.danger:
        return _VariantColors(EdenColors.error.withValues(alpha: 0.1), EdenColors.error);
      case EdenNotificationVariant.neutral:
        return _VariantColors(EdenColors.neutral[200]!, EdenColors.neutral[600]!);
    }
  }
}

class _VariantColors {
  const _VariantColors(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

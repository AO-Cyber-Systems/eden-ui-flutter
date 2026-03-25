import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Data for a conversation list item.
class EdenConversationData {
  const EdenConversationData({
    required this.id,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.avatarInitials,
    this.timestamp,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final String? avatarInitials;
  final String? timestamp;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
}

/// List tile for conversation/channel selection.
class EdenConversationTile extends StatelessWidget {
  const EdenConversationTile({
    super.key,
    required this.data,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  final EdenConversationData data;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = theme.colorScheme.primary.withValues(alpha: 0.08);
    final hoverBg = isDark
        ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
        : EdenColors.neutral[100]!;

    return Material(
      color: isSelected ? selectedBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        hoverColor: hoverBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
          child: Row(
            children: [
              _buildAvatar(theme),
              const SizedBox(width: EdenSpacing.space3),
              Expanded(child: _buildContent(theme, isDark)),
              const SizedBox(width: EdenSpacing.space2),
              _buildTrailing(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (data.avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(data.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        (data.avatarInitials ?? data.title[0]).substring(
          0,
          (data.avatarInitials ?? data.title[0]).length >= 2
              ? 2
              : (data.avatarInitials ?? data.title[0]).length,
        ),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    final hasUnread = data.unreadCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (data.isPinned) ...[
              Icon(
                Icons.push_pin,
                size: 12,
                color: EdenColors.neutral[500],
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (data.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            data.subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (data.timestamp != null)
          Text(
            data.timestamp!,
            style: TextStyle(
              fontSize: 11,
              color: data.unreadCount > 0
                  ? theme.colorScheme.primary
                  : (isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.isMuted) ...[
              Icon(
                Icons.notifications_off_outlined,
                size: 14,
                color: EdenColors.neutral[400],
              ),
              if (data.unreadCount > 0) const SizedBox(width: 6),
            ],
            if (data.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Text(
                  data.unreadCount > 99 ? '99+' : '${data.unreadCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

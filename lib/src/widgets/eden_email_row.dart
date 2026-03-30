import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A list item widget representing an email in an inbox view.
///
/// Displays sender, subject, optional preview, timestamp, and attachment count.
/// Unread emails are visually distinguished with a blue dot and subtle background.
class EdenEmailRow extends StatelessWidget {
  /// Creates an email row widget.
  const EdenEmailRow({
    super.key,
    required this.from,
    required this.subject,
    this.preview,
    this.timestamp,
    this.unread = false,
    this.attachmentCount = 0,
    this.onTap,
  });

  /// The sender's name or email address.
  final String from;

  /// The email subject line.
  final String subject;

  /// Optional preview of the email body.
  final String? preview;

  /// When the email was received.
  final DateTime? timestamp;

  /// Whether the email is unread.
  final bool unread;

  /// Number of attachments on this email.
  final int attachmentCount;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unreadBg = unread
        ? theme.colorScheme.primary.withValues(alpha: 0.03)
        : null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        decoration: BoxDecoration(
          color: unreadBg,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? EdenColors.neutral[800]!
                  : EdenColors.neutral[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unread)
              Padding(
                padding: const EdgeInsets.only(
                  top: 6,
                  right: EdenSpacing.space2,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: EdenColors.info,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          from,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timestamp != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: EdenSpacing.space2),
                          child: Text(
                            _formatTimestamp(timestamp!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: EdenColors.neutral[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EdenColors.neutral[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (attachmentCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: EdenSpacing.space2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? EdenColors.neutral[800]
                        : EdenColors.neutral[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 14,
                        color: EdenColors.neutral[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$attachmentCount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: EdenColors.neutral[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

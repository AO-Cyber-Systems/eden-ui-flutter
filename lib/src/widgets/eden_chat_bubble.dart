import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Who sent the message.
enum EdenChatSender { user, assistant }

/// Mirrors the eden_chat_bubble Rails component.
///
/// A chat message bubble with sender-aware styling.
class EdenChatBubble extends StatelessWidget {
  const EdenChatBubble({
    super.key,
    required this.message,
    this.sender = EdenChatSender.user,
    this.timestamp,
    this.avatar,
  });

  final String message;
  final EdenChatSender sender;
  final String? timestamp;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = sender == EdenChatSender.user;

    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : (isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!);
    final textColor = isUser
        ? Colors.white
        : theme.colorScheme.onSurface;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              timestamp!,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && avatar != null) ...[
            avatar!,
            const SizedBox(width: 8),
          ],
          bubble,
          if (isUser && avatar != null) ...[
            const SizedBox(width: 8),
            avatar!,
          ],
        ],
      ),
    );
  }
}

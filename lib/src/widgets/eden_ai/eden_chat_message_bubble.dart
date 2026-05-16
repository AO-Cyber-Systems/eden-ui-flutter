import 'package:flutter/material.dart';

import 'eden_ai_models.dart';

/// Reusable chat message bubble for the AI chat surface.
///
/// User messages right-aligned on `theme.colorScheme.primary` background;
/// assistant messages left-aligned on `surfaceContainerHighest`. Bubble
/// `maxWidth: 280` so long content wraps inside the chat sheet.
///
/// Donor: `trades-flutter/lib/shared/widgets/eden_agent_chat.dart`
/// (`ChatMessageBubble` extracted to this dedicated file in the library).
class EdenChatMessageBubble extends StatelessWidget {
  const EdenChatMessageBubble({
    super.key,
    required this.message,
  });

  final EdenChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == EdenChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 13,
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'Chat Bubbles',
            child: EdenCard(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                children: [
                  EdenChatBubble(
                    message: 'Hey! Can you help me build a UI component library?',
                    sender: EdenChatSender.user,
                    timestamp: '2:34 PM',
                    avatar: const EdenAvatar(initials: 'JD', size: EdenAvatarSize.sm),
                  ),
                  EdenChatBubble(
                    message: 'Of course! I can help you port the Eden UI design system to Flutter. '
                        'We\'ll start with the design tokens and core components.',
                    sender: EdenChatSender.assistant,
                    timestamp: '2:34 PM',
                    avatar: const EdenAvatar(initials: 'AI', size: EdenAvatarSize.sm),
                  ),
                  EdenChatBubble(
                    message: 'That sounds great. Let\'s start with buttons and cards.',
                    sender: EdenChatSender.user,
                    timestamp: '2:35 PM',
                  ),
                  EdenChatBubble(
                    message: 'Here\'s what I\'ll build:\n'
                        '- EdenButton with 7 variants\n'
                        '- EdenCard with gradient and glass styles\n'
                        '- EdenBadge for status indicators\n\n'
                        'Each component will match your existing Rails design system.',
                    sender: EdenChatSender.assistant,
                    timestamp: '2:35 PM',
                  ),
                ],
              ),
            ),
          ),

          Section(
            title: 'Chat with Avatars & Status',
            child: EdenCard(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                children: const [
                  EdenChatBubble(
                    message: 'Quick question about the project.',
                    sender: EdenChatSender.user,
                    avatar: EdenAvatar(
                      initials: 'JD',
                      size: EdenAvatarSize.sm,
                      status: EdenAvatarStatus.online,
                    ),
                  ),
                  EdenChatBubble(
                    message: 'Sure, ask away!',
                    sender: EdenChatSender.assistant,
                    avatar: EdenAvatar(
                      initials: 'AI',
                      size: EdenAvatarSize.sm,
                      status: EdenAvatarStatus.online,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

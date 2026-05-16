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
          const Section(
            title: 'Chat Bubbles',
            child: EdenCard(
              padding: EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                children: [
                  EdenChatBubble(
                    message: 'Hey! Can you help me build a UI component library?',
                    sender: EdenChatSender.user,
                    timestamp: '2:34 PM',
                    avatar: EdenAvatar(initials: 'JD', size: EdenAvatarSize.sm),
                  ),
                  EdenChatBubble(
                    message: 'Of course! I can help you port the Eden UI design system to Flutter. '
                        'We\'ll start with the design tokens and core components.',
                    sender: EdenChatSender.assistant,
                    timestamp: '2:34 PM',
                    avatar: EdenAvatar(initials: 'AI', size: EdenAvatarSize.sm),
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

          const Section(
            title: 'Chat with Avatars & Status',
            child: EdenCard(
              padding: EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                children: [
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

          const EdenDivider(label: 'EdenInsightCard — Phase 1 (objective 003)'),
          const Section(
            title: '6 insight layouts',
            child: Column(
              children: [
                EdenInsightCard(
                  content: EdenInsightContent(
                    id: 's',
                    type: EdenInsightType.summary,
                    title: 'Project Update',
                    subtitle: '3 tasks remaining',
                  ),
                ),
                EdenInsightCard(
                  content: EdenInsightContent(
                    id: 'm',
                    type: EdenInsightType.metric,
                    title: 'Revenue',
                    data: {
                      'value': r'$12,500',
                      'trend': 'up',
                      'change': '+8%',
                    },
                  ),
                ),
                EdenInsightCard(
                  content: EdenInsightContent(
                    id: 'a',
                    type: EdenInsightType.alert,
                    title: 'Permit expiring',
                    severity: EdenInsightSeverity.warning,
                  ),
                ),
                EdenInsightCard(
                  content: EdenInsightContent(
                    id: 'sg',
                    type: EdenInsightType.suggestion,
                    title: 'Try AI summary',
                    subtitle:
                        'Daily highlights of activity across all projects.',
                    actions: [
                      EdenInsightAction(label: 'View details'),
                      EdenInsightAction(label: 'Dismiss'),
                    ],
                  ),
                ),
                EdenInsightCard(
                  content: EdenInsightContent(
                    id: 'c',
                    type: EdenInsightType.chart,
                    title: 'Weekly leads',
                    chartType: EdenChartType.bar,
                    data: {
                      'values': [30, 60, 45, 80, 55, 70, 40],
                      'labels': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                    },
                  ),
                ),
                EdenInsightCard(
                  content: EdenInsightContent(
                    id: 'd',
                    type: EdenInsightType.diagram,
                    title: 'Workflow',
                  ),
                ),
              ],
            ),
          ),
          const Section(
            title: 'Compact mode (sidebar layout @ 280pt)',
            child: SizedBox(
              width: 280,
              child: Column(
                children: [
                  EdenInsightCard(
                    compact: true,
                    content: EdenInsightContent(
                      id: 's2',
                      type: EdenInsightType.summary,
                      title: 'Project Update',
                      subtitle: '3 tasks remaining',
                    ),
                  ),
                  EdenInsightCard(
                    compact: true,
                    content: EdenInsightContent(
                      id: 'a2',
                      type: EdenInsightType.alert,
                      title: 'Permit expiring',
                      severity: EdenInsightSeverity.critical,
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

import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _aiPanelExpanded = true;
  EdenAiPersona _aiPanelPersona = EdenAiPersona.operations;
  bool _aiPanelLoading = false;
  bool _aiPanelEmpty = false;

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

          const EdenDivider(label: 'EdenAiPanel — Phase 1 (objective 003)'),
          Section(
            title: 'Live AI panel (toggle + persona swap + loading + empty)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    EdenButton(
                      label: _aiPanelExpanded ? 'Collapse' : 'Expand',
                      variant: EdenButtonVariant.secondary,
                      onPressed: () => setState(
                          () => _aiPanelExpanded = !_aiPanelExpanded),
                    ),
                    EdenButton(
                      label: _aiPanelLoading ? 'Stop loading' : 'Loading',
                      variant: EdenButtonVariant.secondary,
                      onPressed: () => setState(
                          () => _aiPanelLoading = !_aiPanelLoading),
                    ),
                    EdenButton(
                      label: _aiPanelEmpty ? 'Show insights' : 'Empty',
                      variant: EdenButtonVariant.secondary,
                      onPressed: () =>
                          setState(() => _aiPanelEmpty = !_aiPanelEmpty),
                    ),
                    DropdownButton<EdenAiPersona>(
                      value: _aiPanelPersona,
                      onChanged: (p) =>
                          setState(() => _aiPanelPersona = p!),
                      items: EdenAiPersona.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.displayLabel),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Host page content placeholder\n\n'
                              'EdenAiPanel renders on the right and tracks the consumer-owned expanded flag.',
                            ),
                          ),
                        ),
                      ),
                      EdenAiPanel(
                        insights: _aiPanelEmpty
                            ? const <EdenInsightContent>[]
                            : const [
                                EdenInsightContent(
                                  id: 's',
                                  type: EdenInsightType.summary,
                                  title: 'Project Update',
                                  subtitle: '3 tasks remaining',
                                ),
                                EdenInsightContent(
                                  id: 'm',
                                  type: EdenInsightType.metric,
                                  title: 'Revenue',
                                  data: <String, dynamic>{
                                    'value': r'$12,500',
                                    'trend': 'up',
                                    'change': '+8%',
                                  },
                                ),
                                EdenInsightContent(
                                  id: 'a',
                                  type: EdenInsightType.alert,
                                  title: 'Permit expiring',
                                  severity: EdenInsightSeverity.warning,
                                ),
                                EdenInsightContent(
                                  id: 'sg',
                                  type: EdenInsightType.suggestion,
                                  title: 'Try AI summary',
                                ),
                              ],
                        persona: _aiPanelPersona,
                        isExpanded: _aiPanelExpanded,
                        onToggle: () => setState(
                            () => _aiPanelExpanded = !_aiPanelExpanded),
                        isLoading: _aiPanelLoading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

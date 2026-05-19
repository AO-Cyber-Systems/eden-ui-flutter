import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
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

  EdenAiPersona _chatPersona = EdenAiPersona.operations;

  Stream<EdenChatStreamChunk> _mockSendMessage(EdenChatRequest req) async* {
    // Hand-built mock: 4 content chunks + done, at ~150ms intervals.
    const chunks = ['Sure — ', 'I can help ', 'with that. ', 'Here is the plan.'];
    for (final c in chunks) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      yield EdenChatStreamChunk(
          type: EdenChatChunkType.content, content: c);
    }
    yield const EdenChatStreamChunk(type: EdenChatChunkType.done);
  }

  Future<String> _mockCreateConversation({
    required String personaId,
    required String title,
  }) async {
    return 'demo-conv-1';
  }

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
                    Expanded(
                      child: DropdownButton<EdenAiPersona>(
                        isExpanded: true,
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

          const EdenDivider(label: 'EdenAgentChat — Phase 1 (objective 003)'),
          Section(
            title: 'Tap the FAB to open the chat sheet',
            child: SizedBox(
              height: 220,
              child: Scaffold(
                body: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Host page content. Tap the gold sparkle FAB to open the '
                    'EdenAgentChat modal. Streaming response is mocked locally '
                    '(150ms intervals); production wires sendMessage + '
                    'createConversation to AODex/AOSentry via callback.',
                  ),
                ),
                floatingActionButton: EdenAgentChatFab(
                  activePersona: _chatPersona,
                  onPersonaChanged: (p) =>
                      setState(() => _chatPersona = p),
                  sendMessage: _mockSendMessage,
                  createConversation: _mockCreateConversation,
                  pageContext: 'Catalog demo',
                  entityLabel: 'Customer #42',
                ),
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Objective 008 Wave 4 (TRD 008-08) — cross-vertical AI surface
          // demos. Fixtures from lib/dev_app/_sample_data/.
          // ----------------------------------------------------------------
          const EdenDivider(label: 'Cross-vertical AI surface — Obj 008'),
          const Section(
            title: 'EdenInsightCard · Metric layout (3 verticals)',
            child: _InsightRow(<EdenInsightContent>[
              TradesScenarios.revenueInsight,
              GovScenarios.backlogInsight,
            ]),
          ),
          const Section(
            title: 'EdenInsightCard · Chart layout (Salon bar / Fuel bar / Gov line)',
            child: _InsightRow(<EdenInsightContent>[
              SalonScenarios.bookingTrendInsight,
              FuelScenarios.fuelConsumptionInsight,
              GovScenarios.approvalRateInsight,
            ]),
          ),
          const Section(
            title: 'EdenInsightCard · Alert layout',
            child: _InsightRow(<EdenInsightContent>[
              TradesScenarios.permitExpiringInsight,
              SalonScenarios.productLowStockInsight,
              FuelScenarios.tankLowStockInsight,
              MedicalScenarios.readmissionRiskInsight,
              GovScenarios.slaBreachInsight,
            ]),
          ),
          const Section(
            title: 'EdenInsightCard · Suggestion layout',
            child: _InsightRow(<EdenInsightContent>[
              TradesScenarios.lookAheadRoutingInsight,
              SalonScenarios.rebookSuggestionInsight,
            ]),
          ),
          const Section(
            title: 'EdenInsightCard · Summary layout',
            child: _InsightRow(<EdenInsightContent>[
              MedicalScenarios.labResultsInsight,
            ]),
          ),

          const EdenDivider(label: 'EdenAiPanel — per-persona vertical content'),
          const Section(
            title: 'Persona-driven insights (live)',
            child: _PerPersonaAiPanelDemo(),
          ),

          const EdenDivider(label: 'EdenAiCollapsibleSection'),
          const Section(
            title: 'Three collapsible blocks: Insights / Activity / Suggestions',
            child: _CollapsibleSectionsDemo(),
          ),

          const EdenDivider(label: 'EdenPersonaSelector — live wire-up'),
          const Section(
            title: 'Switch persona; downstream label updates',
            child: _LivePersonaSelectorDemo(),
          ),

          const EdenDivider(label: 'EdenAgentChat FAB — per-vertical preset'),
          const Section(
            title: 'Pick a vertical → FAB streams a vertical-flavored reply',
            child: _PerVerticalChatFabDemo(),
          ),

          const EdenDivider(label: 'EdenAiInsightSlot — enabled toggle'),
          const Section(
            title: 'Toggle the slot; panel mounts/unmounts beneath',
            child: _AiInsightSlotToggleDemo(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Objective 008 Wave 4 (TRD 008-08) — cross-vertical AI surface demos.
// Demo-only; no library widget changes.
// =============================================================================

class _InsightRow extends StatelessWidget {
  const _InsightRow(this.insights);
  final List<EdenInsightContent> insights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: 280,
          child: EdenInsightCard(content: insights[i]),
        ),
      ),
    );
  }
}

class _PerPersonaAiPanelDemo extends StatefulWidget {
  const _PerPersonaAiPanelDemo();
  @override
  State<_PerPersonaAiPanelDemo> createState() => _PerPersonaAiPanelDemoState();
}

class _PerPersonaAiPanelDemoState extends State<_PerPersonaAiPanelDemo> {
  EdenAiPersona _persona = EdenAiPersona.operations;
  bool _expanded = true;

  List<EdenInsightContent> _insightsFor(EdenAiPersona p) {
    switch (p) {
      case EdenAiPersona.fieldTech:
        return const <EdenInsightContent>[
          TradesScenarios.lookAheadRoutingInsight,
          TradesScenarios.permitExpiringInsight,
        ];
      case EdenAiPersona.finance:
        return const <EdenInsightContent>[
          TradesScenarios.revenueInsight,
          FuelScenarios.fuelConsumptionInsight,
        ];
      case EdenAiPersona.operations:
        return const <EdenInsightContent>[
          FuelScenarios.tankLowStockInsight,
          GovScenarios.slaBreachInsight,
          MedicalScenarios.readmissionRiskInsight,
        ];
      case EdenAiPersona.executive:
        return const <EdenInsightContent>[
          GovScenarios.backlogInsight,
          GovScenarios.approvalRateInsight,
          SalonScenarios.bookingTrendInsight,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final insights = _insightsFor(_persona);
    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('Persona: '),
                    Expanded(
                      child: DropdownButton<EdenAiPersona>(
                        isExpanded: true,
                        value: _persona,
                        onChanged: (p) {
                          if (p != null) setState(() => _persona = p);
                        },
                        items: <DropdownMenuItem<EdenAiPersona>>[
                          for (final p in EdenAiPersona.values)
                            DropdownMenuItem<EdenAiPersona>(
                              value: p,
                              child: Text(p.displayLabel),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Showing ${insights.length} insights tuned to '
                  '${_persona.displayLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          EdenAiPanel(
            persona: _persona,
            insights: insights,
            isExpanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSectionsDemo extends StatelessWidget {
  const _CollapsibleSectionsDemo();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        EdenAiCollapsibleSection(
          title: 'Insights',
          child: Column(
            children: <Widget>[
              for (final i in <EdenInsightContent>[
                TradesScenarios.revenueInsight,
                GovScenarios.slaBreachInsight,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EdenInsightCard(content: i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        EdenAiCollapsibleSection(
          title: 'Recent activity',
          child: Column(
            children: <Widget>[
              for (final a
                  in CrossCuttingFixtures.mixedActivityFeed.take(3))
                EdenActivityFeedItem(item: a),
            ],
          ),
        ),
        const SizedBox(height: 8),
        EdenAiCollapsibleSection(
          title: 'Suggestions',
          child: Column(
            children: <Widget>[
              for (final i in <EdenInsightContent>[
                TradesScenarios.lookAheadRoutingInsight,
                SalonScenarios.rebookSuggestionInsight,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EdenInsightCard(content: i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LivePersonaSelectorDemo extends StatefulWidget {
  const _LivePersonaSelectorDemo();
  @override
  State<_LivePersonaSelectorDemo> createState() =>
      _LivePersonaSelectorDemoState();
}

class _LivePersonaSelectorDemoState extends State<_LivePersonaSelectorDemo> {
  EdenAiPersona _persona = EdenAiPersona.fieldTech;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        EdenPersonaSelector(
          activePersona: _persona,
          onChanged: (p) => setState(() => _persona = p),
        ),
        const SizedBox(height: 12),
        Text(
          'Selected: ${_persona.displayLabel} — ${_persona.description}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PerVerticalChatFabDemo extends StatefulWidget {
  const _PerVerticalChatFabDemo();
  @override
  State<_PerVerticalChatFabDemo> createState() =>
      _PerVerticalChatFabDemoState();
}

class _PerVerticalChatFabDemoState extends State<_PerVerticalChatFabDemo> {
  String _vertical = 'trades';
  EdenAiPersona _persona = EdenAiPersona.operations;

  String _replyFor(String v) {
    switch (v) {
      case 'salon':
        return 'Marisol has a 11:30 opening for color today. '
            'Want me to confirm?';
      case 'fuel':
        return 'Truck T7 is 18 min out. ETA 9:42am for Northpoint Diesel.';
      case 'medical':
        return 'Dr. Patel sees you next Thursday at 2pm. '
            'Bring your medication list.';
      case 'gov':
        return 'Case CCM-2026-0427 is queued for Tier-3 review. '
            'Avg wait is 4 business days.';
      case 'trades':
      default:
        return 'Job #2871 is scheduled for tomorrow 8am. '
            'Alice has truck 47.';
    }
  }

  Stream<EdenChatStreamChunk> _send(EdenChatRequest req) async* {
    final reply = _replyFor(_vertical);
    // Stream the reply in 12-char chunks at 150ms each.
    var i = 0;
    while (i < reply.length) {
      final end = (i + 12 < reply.length) ? i + 12 : reply.length;
      yield EdenChatStreamChunk(
        type: EdenChatChunkType.content,
        content: reply.substring(i, end),
      );
      i = end;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    yield const EdenChatStreamChunk(type: EdenChatChunkType.done);
  }

  Future<String> _create({
    required String personaId,
    required String title,
  }) async =>
      'demo-conv-$_vertical';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('Vertical: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _vertical,
                  onChanged: (v) {
                    if (v != null) setState(() => _vertical = v);
                  },
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                        value: 'trades', child: Text('Trades')),
                    DropdownMenuItem<String>(
                        value: 'salon', child: Text('Salon')),
                    DropdownMenuItem<String>(
                        value: 'fuel', child: Text('Fuel')),
                    DropdownMenuItem<String>(
                        value: 'medical', child: Text('Medical')),
                    DropdownMenuItem<String>(
                        value: 'gov', child: Text('Gov')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Tap the FAB to open EdenAgentChat. Replies are mocked '
                  'with vertical-specific stream content. Current preview:\n\n'
                  '"${_replyFor(_vertical)}"',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              floatingActionButton: EdenAgentChatFab(
                activePersona: _persona,
                onPersonaChanged: (p) => setState(() => _persona = p),
                sendMessage: _send,
                createConversation: _create,
                pageContext: '$_vertical demo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightSlotToggleDemo extends StatefulWidget {
  const _AiInsightSlotToggleDemo();
  @override
  State<_AiInsightSlotToggleDemo> createState() =>
      _AiInsightSlotToggleDemoState();
}

class _AiInsightSlotToggleDemoState extends State<_AiInsightSlotToggleDemo> {
  bool _enabled = true;
  final EdenAiPersona _persona = EdenAiPersona.operations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Switch(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(width: 8),
            Text(_enabled ? 'AI insights ON' : 'AI insights OFF'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: EdenAiInsightSlot(
            enabled: _enabled,
            persona: _persona,
            insights: const <EdenInsightContent>[
              TradesScenarios.revenueInsight,
              FuelScenarios.tankLowStockInsight,
            ],
          ),
        ),
      ],
    );
  }
}

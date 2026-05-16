// Do NOT regenerate via LLM — hand-built fixtures for eden_ai models.
//
// Hand-coded EdenInsightContent / EdenChatMessage samples shared by Wave 3
// AI-surface tests (003-10 EdenInsightCard, 003-11 EdenAiPanel, 003-14
// EdenAgentChat, 003-15 EdenAiInsightSlot).
//
// Add new fixtures by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenAiModelsFixtures {
  EdenAiModelsFixtures._();

  static const EdenInsightContent summaryInsight = EdenInsightContent(
    id: 's1',
    type: EdenInsightType.summary,
    title: 'Project Update',
    subtitle: '3 tasks remaining',
  );

  static const EdenInsightContent metricInsight = EdenInsightContent(
    id: 'm1',
    type: EdenInsightType.metric,
    title: 'Revenue',
    data: <String, dynamic>{
      'value': r'$12,500',
      'trend': 'up',
      'change': '+8%',
    },
  );

  static const EdenInsightContent metricDownInsight = EdenInsightContent(
    id: 'm2',
    type: EdenInsightType.metric,
    title: 'Pipeline',
    data: <String, dynamic>{
      'value': '24',
      'trend': 'down',
      'change': '-3%',
    },
  );

  static const EdenInsightContent metricFlatInsight = EdenInsightContent(
    id: 'm3',
    type: EdenInsightType.metric,
    title: 'Active jobs',
    data: <String, dynamic>{
      'value': '17',
      'trend': 'flat',
      'change': '0%',
    },
  );

  static const EdenInsightContent alertInsight = EdenInsightContent(
    id: 'a1',
    type: EdenInsightType.alert,
    title: 'Permit expiring',
    severity: EdenInsightSeverity.warning,
  );

  static const EdenInsightContent alertCriticalInsight = EdenInsightContent(
    id: 'a2',
    type: EdenInsightType.alert,
    title: 'Site offline',
    severity: EdenInsightSeverity.critical,
  );

  static const EdenInsightContent alertInfoInsight = EdenInsightContent(
    id: 'a3',
    type: EdenInsightType.alert,
    title: 'New SOP available',
    severity: EdenInsightSeverity.info,
  );

  static const EdenInsightContent suggestionInsight = EdenInsightContent(
    id: 'sg1',
    type: EdenInsightType.suggestion,
    title: 'Try AI summary',
  );

  static const EdenInsightContent chartInsight = EdenInsightContent(
    id: 'c1',
    type: EdenInsightType.chart,
    title: 'Weekly leads',
    chartType: EdenChartType.bar,
    data: <String, dynamic>{
      'values': <int>[30, 60, 45, 80, 55, 70, 40],
      'labels': <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    },
  );

  static const EdenInsightContent chartLineInsight = EdenInsightContent(
    id: 'c2',
    type: EdenInsightType.chart,
    title: 'Trend',
    chartType: EdenChartType.line,
    data: <String, dynamic>{
      'values': <int>[10, 22, 18, 31, 28, 45, 60],
    },
  );

  static const EdenInsightContent chartPieInsight = EdenInsightContent(
    id: 'c3',
    type: EdenInsightType.chart,
    title: 'Mix',
    chartType: EdenChartType.pie,
    data: <String, dynamic>{
      'values': <int>[20, 30, 25, 25],
    },
  );

  static const EdenInsightContent diagramInsight = EdenInsightContent(
    id: 'd1',
    type: EdenInsightType.diagram,
    title: 'Workflow',
  );

  static final EdenChatMessage userMessage = EdenChatMessage(
    id: 'u1',
    role: EdenChatRole.user,
    content: 'Hello',
    timestamp: DateTime(2026, 5, 15, 10, 0),
  );

  static final EdenChatMessage assistantMessage = EdenChatMessage(
    id: 'a1',
    role: EdenChatRole.assistant,
    content: 'How can I help?',
    timestamp: DateTime(2026, 5, 15, 10, 1),
    persona: EdenAiPersona.operations,
  );
}

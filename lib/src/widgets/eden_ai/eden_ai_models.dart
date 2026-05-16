// Shared AI-surface domain types for objective 003 Wave 3 widgets.
//
// All types are library-owned (no `package:trades/...` imports) per
// OBJECTIVE.md Constraint 6 (cross-vertical decoupling). Subsequent Wave 3
// widgets (EdenInsightCard, EdenAiPanel, EdenAgentChat, EdenAiInsightSlot,
// EdenPersonaSelector) consume these types.
//
// Donor: `trades-flutter/lib/shared/ai/ai_models.dart` (163 LOC; types renamed
// with the `Eden` prefix and inlined here).

import 'package:flutter/material.dart';

/// Type of AI insight content — determines layout chosen by [EdenInsightCard].
enum EdenInsightType {
  chart,
  diagram,
  summary,
  metric,
  alert,
  suggestion,
}

/// Chart sub-type for [EdenInsightType.chart] content.
enum EdenChartType {
  bar,
  line,
  pie,
  sparkline,
}

/// Severity level for alert-type insights. Enum carries its display label and
/// left-border color via constructor arguments (Dart enums-with-fields).
enum EdenInsightSeverity {
  info('Info', Color(0xFF3B82F6)),
  warning('Warning', Color(0xFFF59E0B)),
  critical('Critical', Color(0xFFEF4444));

  const EdenInsightSeverity(this.displayLabel, this.color);
  final String displayLabel;
  final Color color;
}

/// An action button on an [EdenInsightContent] card. When [onTap] is null,
/// [EdenInsightCard] shows a "Coming soon — $label" SnackBar (donor parity).
class EdenInsightAction {
  const EdenInsightAction({
    required this.label,
    this.icon,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// Rich content model for a single AI insight rendered by [EdenInsightCard].
class EdenInsightContent {
  const EdenInsightContent({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.data = const <String, dynamic>{},
    this.chartType,
    this.severity,
    this.actions = const <EdenInsightAction>[],
  });

  final String id;
  final EdenInsightType type;
  final String title;
  final String? subtitle;

  /// Arbitrary data map — chart values, metric values, etc.
  final Map<String, dynamic> data;
  final EdenChartType? chartType;
  final EdenInsightSeverity? severity;
  final List<EdenInsightAction> actions;
}

/// AI persona — drives chat / insight filtering and persona-selector copy.
///
/// Donor's four canonical personas (fieldTech / finance / operations /
/// executive) are exposed as a sensible cross-vertical default. Downstream
/// apps can map their own role taxonomy onto these four buckets (or wrap the
/// selector with a custom builder for fully bespoke personas).
enum EdenAiPersona {
  fieldTech(
    'Field Tech',
    'On-site technician: equipment, troubleshooting, parts',
    Icons.engineering,
    Color(0xFF3B82F6),
  ),
  finance(
    'Finance',
    'Billing, invoicing, payroll, cost analysis',
    Icons.account_balance,
    Color(0xFF22C55E),
  ),
  operations(
    'Operations',
    'Scheduling, dispatch, resource management',
    Icons.dashboard,
    Color(0xFFF59E0B),
  ),
  executive(
    'Executive',
    'Company-wide metrics, strategy, health',
    Icons.insights,
    Color(0xFF8B5CF6),
  );

  const EdenAiPersona(
    this.displayLabel,
    this.description,
    this.icon,
    this.color,
  );

  final String displayLabel;
  final String description;
  final IconData icon;
  final Color color;
}

/// Role of a single chat message.
enum EdenChatRole { user, assistant, system }

/// A single chat message in the AI agent chat surface.
class EdenChatMessage {
  const EdenChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.persona,
    this.attachments = const <String>[],
  });

  final String id;
  final EdenChatRole role;
  final String content;
  final DateTime timestamp;
  final EdenAiPersona? persona;
  final List<String> attachments;
}

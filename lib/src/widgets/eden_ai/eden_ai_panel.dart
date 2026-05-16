// EdenAiPanel — collapsible right panel for AI insights on desktop / tablet.
//
// Width: 320 expanded / 40 collapsed. Library does NOT enforce viewport-aware
// rendering — consumers must conditionally hide the panel at mobile widths
// (donor's W17-07 convention: mobile uses a bottom sheet instead).

import 'package:flutter/material.dart';

import 'eden_ai_models.dart';
import 'eden_insight_card.dart';

/// Collapsible AI-insight side panel.
///
/// Renders an [AnimatedContainer] that toggles between two widths:
/// - **320 px expanded** — header (persona icon + 'AI Insights' + persona
///   badge + chevron toggle) and a content area showing either a [ListView]
///   of [EdenInsightCard]s in compact mode, an empty state, or a shimmer
///   loading state.
/// - **40 px collapsed** — `Icons.chevron_left` + a `RotatedBox` `'AI'`
///   label + `Icons.auto_awesome`. The whole panel is tappable to expand.
///
/// **Consumer-owned state pattern:** the panel is stateless. The host page
/// tracks `isPanelExpanded` in its own state and provides [onToggle] to
/// receive expand/collapse intent. Mirrors the donor's pattern.
///
/// State priority:
/// 1. [isLoading] → shimmer (3 grey placeholder rectangles), regardless of
///    [insights] count.
/// 2. [insights] empty (and not loading) → empty state with
///    `'No insights available'`.
/// 3. otherwise → `ListView.builder` of compact [EdenInsightCard]s.
///
/// Donor: `trades-flutter/lib/shared/widgets/eden_ai_panel.dart` (renamed
/// from `EdenAIPanel` to `EdenAiPanel` for Dart naming consistency).
class EdenAiPanel extends StatelessWidget {
  const EdenAiPanel({
    super.key,
    required this.insights,
    required this.persona,
    required this.isExpanded,
    required this.onToggle,
    this.isLoading = false,
  });

  /// Insights to display when expanded + not loading + not empty.
  final List<EdenInsightContent> insights;

  /// Active AI persona; drives header icon, badge, and tint.
  final EdenAiPersona persona;

  /// Consumer-owned expanded flag.
  final bool isExpanded;

  /// Callback fired when the user taps the chevron toggle (expanded) or any
  /// part of the collapsed strip.
  final VoidCallback onToggle;

  /// Loading state shows shimmer regardless of [insights] count.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 320 : 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: isExpanded ? _buildExpanded(theme) : _buildCollapsed(theme),
    );
  }

  Widget _buildExpanded(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(persona.icon, size: 18, color: persona.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _PersonaBadge(persona: persona),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(4),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: isLoading
              ? _buildShimmer(theme)
              : insights.isEmpty
                  ? _buildEmpty(theme)
                  : _buildInsightList(),
        ),
      ],
    );
  }

  Widget _buildCollapsed(ThemeData theme) {
    return InkWell(
      onTap: onToggle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chevron_left,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              'AI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(Icons.auto_awesome,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildInsightList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        return EdenInsightCard(content: insights[index], compact: true);
      },
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome,
              size: 32,
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No insights available',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }
}

/// Compact persona badge (icon + label).
class _PersonaBadge extends StatelessWidget {
  const _PersonaBadge({required this.persona});
  final EdenAiPersona persona;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: persona.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        persona.displayLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: persona.color,
        ),
      ),
    );
  }
}

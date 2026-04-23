import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single decision made by an autonomous agent.
class EdenAgentDecision {
  /// Creates an agent decision.
  const EdenAgentDecision({
    required this.timestamp,
    required this.decisionPoint,
    this.optionsConsidered = const [],
    required this.chosenAction,
    this.reasoning,
    this.confidence = 1.0,
  });

  /// When the decision was made.
  final DateTime timestamp;

  /// The question or context that required a decision.
  final String decisionPoint;

  /// Options the agent evaluated.
  final List<String> optionsConsidered;

  /// The action the agent chose.
  final String chosenAction;

  /// Why the agent chose this action.
  final String? reasoning;

  /// Confidence score from 0.0 (low) to 1.0 (high).
  final double confidence;
}

/// A chronological timeline of decisions made by an autonomous agent.
///
/// Each entry shows the decision point, options considered (collapsible),
/// the chosen action highlighted, reasoning text, and a confidence indicator.
class EdenAgentDecisionLog extends StatefulWidget {
  /// Creates a decision log.
  const EdenAgentDecisionLog({
    super.key,
    required this.decisions,
    this.title,
    this.onDecisionTap,
  });

  /// The decisions to display in chronological order.
  final List<EdenAgentDecision> decisions;

  /// Optional title above the log.
  final String? title;

  /// Called when a decision entry is tapped, with its index.
  final ValueChanged<int>? onDecisionTap;

  @override
  State<EdenAgentDecisionLog> createState() => _EdenAgentDecisionLogState();
}

class _EdenAgentDecisionLogState extends State<EdenAgentDecisionLog> {
  final Set<int> _expandedIndices = {};

  void _toggle(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Confidence helpers
  // ---------------------------------------------------------------------------

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return EdenColors.success;
    if (confidence >= 0.5) return EdenColors.warning;
    return EdenColors.error;
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: EdenSpacing.space3),
            ],
            ...List.generate(widget.decisions.length, (i) {
              final isLast = i == widget.decisions.length - 1;
              return _buildEntry(
                context,
                index: i,
                decision: widget.decisions[i],
                isDark: isDark,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context, {
    required int index,
    required EdenAgentDecision decision,
    required bool isDark,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final lineColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final isExpanded = _expandedIndices.contains(index);
    final confidenceColor = _confidenceColor(decision.confidence);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: EdenSpacing.space1),
                  decoration: BoxDecoration(
                    color: confidenceColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: EdenSpacing.space2),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : EdenSpacing.space3),
              child: Material(
                color: Colors.transparent,
                borderRadius: EdenRadii.borderRadiusSm,
                child: InkWell(
                  onTap: () {
                    _toggle(index);
                    widget.onDecisionTap?.call(index);
                  },
                  borderRadius: EdenRadii.borderRadiusSm,
                  child: Padding(
                    padding: const EdgeInsets.all(EdenSpacing.space1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Timestamp + confidence
                        Row(
                          children: [
                            Text(
                              _formatTime(decision.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(width: EdenSpacing.space2),
                            _ConfidenceBadge(
                              label: _confidenceLabel(decision.confidence),
                              color: confidenceColor,
                              value: decision.confidence,
                            ),
                          ],
                        ),

                        const SizedBox(height: EdenSpacing.space1),

                        // Decision point
                        Text(
                          decision.decisionPoint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: EdenSpacing.space1),

                        // Chosen action
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EdenSpacing.space2,
                            vertical: EdenSpacing.space1,
                          ),
                          decoration: BoxDecoration(
                            color: EdenColors.success.withValues(alpha: 0.1),
                            borderRadius: EdenRadii.borderRadiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_forward,
                                  size: 14, color: EdenColors.success),
                              const SizedBox(width: EdenSpacing.space1),
                              Flexible(
                                child: Text(
                                  decision.chosenAction,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: EdenColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expanded details
                        if (isExpanded) ...[
                          // Options considered
                          if (decision.optionsConsidered.isNotEmpty) ...[
                            const SizedBox(height: EdenSpacing.space2),
                            Text(
                              'Options considered:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: EdenSpacing.space1),
                            ...decision.optionsConsidered.map(
                              (option) => Padding(
                                padding: const EdgeInsets.only(
                                    left: EdenSpacing.space2,
                                    bottom: EdenSpacing.space1 / 2),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('•  ',
                                        style: TextStyle(
                                            color: mutedColor,
                                            fontSize: 12)),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: mutedColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Reasoning
                          if (decision.reasoning != null) ...[
                            const SizedBox(height: EdenSpacing.space2),
                            Text(
                              'Reasoning:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: EdenSpacing.space1 / 2),
                            Text(
                              decision.reasoning!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: mutedColor),
                            ),
                          ],
                        ],

                        // Expand/collapse hint
                        if (decision.optionsConsidered.isNotEmpty ||
                            decision.reasoning != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: EdenSpacing.space1),
                            child: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: mutedColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 4,
            child: ClipRRect(
              borderRadius: EdenRadii.borderRadiusFull,
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

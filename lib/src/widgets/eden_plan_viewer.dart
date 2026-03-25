import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Status of a single plan step.
enum EdenPlanStepStatus {
  /// Step has not started yet.
  pending,

  /// Step is currently being executed.
  inProgress,

  /// Step finished successfully.
  complete,

  /// Step was skipped.
  skipped,

  /// Step failed.
  failed,
}

/// A single step in an agent plan.
class EdenPlanStep {
  /// Creates a plan step.
  const EdenPlanStep({
    required this.number,
    required this.title,
    this.description,
    this.estimatedEffort,
    this.status = EdenPlanStepStatus.pending,
    this.dependencies = const [],
    this.substeps = const [],
  });

  /// 1-based step number.
  final int number;

  /// Short title of this step.
  final String title;

  /// Optional longer description.
  final String? description;

  /// Estimated effort label (e.g. "2h", "30m", "S", "M", "L").
  final String? estimatedEffort;

  /// Current status.
  final EdenPlanStepStatus status;

  /// Step numbers this step depends on.
  final List<int> dependencies;

  /// Nested substeps.
  final List<EdenPlanStep> substeps;
}

/// A structured viewer for an agent-generated plan.
///
/// Displays numbered steps with status icons, dependency labels,
/// estimated effort, collapsible substeps, an overall progress bar,
/// and approve/reject action buttons.
class EdenPlanViewer extends StatefulWidget {
  /// Creates a plan viewer.
  const EdenPlanViewer({
    super.key,
    required this.steps,
    this.title,
    this.onStepTap,
    this.onApprove,
    this.onReject,
  });

  /// The plan steps to display.
  final List<EdenPlanStep> steps;

  /// Optional title shown above the plan.
  final String? title;

  /// Called when a step is tapped, with its step number.
  final ValueChanged<int>? onStepTap;

  /// Called when the approve button is pressed.
  final VoidCallback? onApprove;

  /// Called when the reject button is pressed.
  final VoidCallback? onReject;

  @override
  State<EdenPlanViewer> createState() => _EdenPlanViewerState();
}

class _EdenPlanViewerState extends State<EdenPlanViewer> {
  final Set<int> _expandedSteps = {};

  void _toggleStep(int number) {
    setState(() {
      if (_expandedSteps.contains(number)) {
        _expandedSteps.remove(number);
      } else {
        _expandedSteps.add(number);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  double _progressFraction() {
    if (widget.steps.isEmpty) return 0;
    final completed = widget.steps
        .where((s) =>
            s.status == EdenPlanStepStatus.complete ||
            s.status == EdenPlanStepStatus.skipped)
        .length;
    return completed / widget.steps.length;
  }

  int _completedCount() {
    return widget.steps
        .where((s) =>
            s.status == EdenPlanStepStatus.complete ||
            s.status == EdenPlanStepStatus.skipped)
        .length;
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  IconData _statusIcon(EdenPlanStepStatus status) {
    switch (status) {
      case EdenPlanStepStatus.pending:
        return Icons.radio_button_unchecked;
      case EdenPlanStepStatus.inProgress:
        return Icons.play_circle_outline;
      case EdenPlanStepStatus.complete:
        return Icons.check_circle;
      case EdenPlanStepStatus.skipped:
        return Icons.skip_next;
      case EdenPlanStepStatus.failed:
        return Icons.cancel;
    }
  }

  Color _statusColor(EdenPlanStepStatus status) {
    switch (status) {
      case EdenPlanStepStatus.pending:
        return EdenColors.neutral[400]!;
      case EdenPlanStepStatus.inProgress:
        return EdenColors.info;
      case EdenPlanStepStatus.complete:
        return EdenColors.success;
      case EdenPlanStepStatus.skipped:
        return EdenColors.neutral[400]!;
      case EdenPlanStepStatus.failed:
        return EdenColors.error;
    }
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
    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Padding(
        padding: EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + progress
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: EdenSpacing.space2),
            ],

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: EdenRadii.borderRadiusFull,
                    child: LinearProgressIndicator(
                      value: _progressFraction(),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? EdenColors.neutral[700]
                          : EdenColors.neutral[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          EdenColors.success),
                    ),
                  ),
                ),
                SizedBox(width: EdenSpacing.space2),
                Text(
                  '${_completedCount()} / ${widget.steps.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: mutedColor),
                ),
              ],
            ),

            SizedBox(height: EdenSpacing.space4),

            // Step list
            ...widget.steps.map((step) => _buildStep(
                  context,
                  step: step,
                  isDark: isDark,
                  mutedColor: mutedColor,
                  isSubstep: false,
                )),

            // Action buttons
            if (widget.onApprove != null || widget.onReject != null) ...[
              SizedBox(height: EdenSpacing.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onReject != null)
                    _PlanActionButton(
                      label: 'Reject Plan',
                      color: EdenColors.error,
                      onPressed: widget.onReject!,
                      isDark: isDark,
                      filled: false,
                    ),
                  if (widget.onReject != null && widget.onApprove != null)
                    SizedBox(width: EdenSpacing.space2),
                  if (widget.onApprove != null)
                    _PlanActionButton(
                      label: 'Approve Plan',
                      color: EdenColors.success,
                      onPressed: widget.onApprove!,
                      isDark: isDark,
                      filled: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required EdenPlanStep step,
    required bool isDark,
    required Color mutedColor,
    required bool isSubstep,
  }) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(step.status);
    final hasSubsteps = step.substeps.isNotEmpty;
    final isExpanded = _expandedSteps.contains(step.number);

    return Padding(
      padding: EdgeInsets.only(
        left: isSubstep ? EdenSpacing.space6 : 0,
        bottom: EdenSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: EdenRadii.borderRadiusSm,
            child: InkWell(
              onTap: () {
                if (hasSubsteps) {
                  _toggleStep(step.number);
                }
                widget.onStepTap?.call(step.number);
              },
              borderRadius: EdenRadii.borderRadiusSm,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: EdenSpacing.space1,
                  horizontal: EdenSpacing.space1,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status icon
                    Icon(_statusIcon(step.status),
                        size: 18, color: statusColor),
                    SizedBox(width: EdenSpacing.space2),

                    // Step number
                    Text(
                      '${step.number}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(width: EdenSpacing.space2),

                    // Title and meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration:
                                  step.status == EdenPlanStepStatus.skipped
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                          if (step.description != null) ...[
                            SizedBox(height: EdenSpacing.space1 / 2),
                            Text(
                              step.description!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: mutedColor),
                            ),
                          ],
                          if (step.dependencies.isNotEmpty) ...[
                            SizedBox(height: EdenSpacing.space1 / 2),
                            Text(
                              'depends on ${step.dependencies.map((d) => '#$d').join(', ')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Effort badge
                    if (step.estimatedEffort != null) ...[
                      SizedBox(width: EdenSpacing.space2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: EdenSpacing.space2,
                          vertical: EdenSpacing.space1 / 2,
                        ),
                        decoration: BoxDecoration(
                          color: mutedColor.withValues(alpha: 0.12),
                          borderRadius: EdenRadii.borderRadiusSm,
                        ),
                        child: Text(
                          step.estimatedEffort!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ],

                    // Expand/collapse chevron
                    if (hasSubsteps) ...[
                      SizedBox(width: EdenSpacing.space1),
                      Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: mutedColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Substeps
          if (hasSubsteps && isExpanded)
            ...step.substeps.map((sub) => _buildStep(
                  context,
                  step: sub,
                  isDark: isDark,
                  mutedColor: mutedColor,
                  isSubstep: true,
                )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _PlanActionButton extends StatelessWidget {
  const _PlanActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isDark,
    required this.filled,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isDark;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: EdenRadii.borderRadiusSm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: EdenRadii.borderRadiusSm,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          decoration: filled
              ? null
              : BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

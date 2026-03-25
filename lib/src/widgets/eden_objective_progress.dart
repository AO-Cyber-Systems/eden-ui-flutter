import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The state of an individual job within an objective.
enum EdenJobState {
  /// Job has not yet started.
  pending,

  /// Job is currently executing.
  running,

  /// Job finished successfully.
  completed,

  /// Job encountered an error.
  failed,
}

/// Represents the status of a single job in an objective.
class EdenObjectiveJobStatus {
  /// Creates a job status entry.
  const EdenObjectiveJobStatus({
    required this.name,
    required this.state,
  });

  /// The display name of the job.
  final String name;

  /// The current state of the job.
  final EdenJobState state;
}

/// An objective progress card that displays job completion status.
///
/// Shows a progress bar with colored segments representing each job state,
/// and an expandable list of individual jobs with their states.
class EdenObjectiveProgress extends StatelessWidget {
  /// Creates an Eden objective progress card.
  const EdenObjectiveProgress({
    super.key,
    required this.title,
    required this.jobs,
    this.statusLabel,
    this.duration,
    this.expanded = false,
    this.onToggleExpand,
  });

  /// The objective title.
  final String title;

  /// The list of jobs and their states.
  final List<EdenObjectiveJobStatus> jobs;

  /// Optional status label displayed as a badge (e.g. "In Progress", "Blocked").
  final String? statusLabel;

  /// Optional duration string (e.g. "2m 34s").
  final String? duration;

  /// Whether the job list is expanded.
  final bool expanded;

  /// Called when the header is tapped to toggle expansion.
  final VoidCallback? onToggleExpand;

  int get _completedCount =>
      jobs.where((j) => j.state == EdenJobState.completed).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final subtextColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Material(
            color: Colors.transparent,
            borderRadius: EdenRadii.borderRadiusLg,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: EdenRadii.borderRadiusLg,
              child: Padding(
                padding: EdgeInsets.all(EdenSpacing.space4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (statusLabel != null) ...[
                      SizedBox(width: EdenSpacing.space2),
                      _StatusBadge(label: statusLabel!, isDark: isDark),
                    ],
                    SizedBox(width: EdenSpacing.space2),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress bar and summary text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SegmentedProgressBar(jobs: jobs, isDark: isDark),
                SizedBox(height: EdenSpacing.space2),
                Row(
                  children: [
                    Text(
                      '$_completedCount of ${jobs.length} jobs complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    if (duration != null) ...[
                      const Spacer(),
                      Text(
                        duration!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: EdenSpacing.space3),

          // Expanded job list
          if (expanded) ...[
            Divider(
              height: 1,
              color: borderColor,
            ),
            Padding(
              padding: EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < jobs.length; i++) ...[
                    if (i > 0) SizedBox(height: EdenSpacing.space2),
                    _JobRow(job: jobs[i], isDark: isDark),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.isDark,
  });

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? EdenColors.neutral[700]!
        : EdenColors.neutral[200]!;
    final textColor = isDark
        ? EdenColors.neutral[300]!
        : EdenColors.neutral[600]!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.jobs,
    required this.isDark,
  });

  final List<EdenObjectiveJobStatus> jobs;
  final bool isDark;

  Color _colorForState(EdenJobState state) {
    switch (state) {
      case EdenJobState.completed:
        return EdenColors.success;
      case EdenJobState.running:
        return EdenColors.info;
      case EdenJobState.failed:
        return EdenColors.error;
      case EdenJobState.pending:
        return EdenColors.neutral[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const SizedBox(height: 6);
    }

    return ClipRRect(
      borderRadius: EdenRadii.borderRadiusFull,
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            for (int i = 0; i < jobs.length; i++) ...[
              if (i > 0) const SizedBox(width: 1.5),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorForState(jobs[i].state),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.job,
    required this.isDark,
  });

  final EdenObjectiveJobStatus job;
  final bool isDark;

  IconData _iconForState(EdenJobState state) {
    switch (state) {
      case EdenJobState.pending:
        return Icons.circle_outlined;
      case EdenJobState.running:
        return Icons.play_circle;
      case EdenJobState.completed:
        return Icons.check_circle;
      case EdenJobState.failed:
        return Icons.error;
    }
  }

  Color _colorForState(EdenJobState state) {
    switch (state) {
      case EdenJobState.pending:
        return EdenColors.neutral[400]!;
      case EdenJobState.running:
        return EdenColors.info;
      case EdenJobState.completed:
        return EdenColors.success;
      case EdenJobState.failed:
        return EdenColors.error;
    }
  }

  String _labelForState(EdenJobState state) {
    switch (state) {
      case EdenJobState.pending:
        return 'Pending';
      case EdenJobState.running:
        return 'Running';
      case EdenJobState.completed:
        return 'Completed';
      case EdenJobState.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForState(job.state);
    final labelColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Row(
      children: [
        Icon(
          _iconForState(job.state),
          size: 18,
          color: color,
        ),
        SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Text(
            job.name,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: EdenSpacing.space2),
        Text(
          _labelForState(job.state),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

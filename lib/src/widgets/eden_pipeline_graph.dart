import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The execution status of a pipeline job.
enum EdenPipelineJobStatus {
  /// Job is waiting in the queue.
  queued,

  /// Job is currently executing.
  running,

  /// Job completed successfully.
  passed,

  /// Job completed with a failure.
  failed,

  /// Job was canceled.
  canceled,

  /// Job was skipped.
  skipped,

  /// Job requires manual trigger.
  manual,
}

/// A single job within a pipeline stage.
class EdenPipelineJob {
  /// Creates a pipeline job.
  const EdenPipelineJob({
    required this.id,
    required this.name,
    required this.status,
    this.duration,
  });

  /// Unique identifier for the job.
  final String id;

  /// Display name of the job.
  final String name;

  /// Current execution status.
  final EdenPipelineJobStatus status;

  /// Duration of the job execution.
  final Duration? duration;
}

/// A stage in a pipeline containing one or more jobs.
class EdenPipelineStage {
  /// Creates a pipeline stage.
  const EdenPipelineStage({
    required this.name,
    required this.jobs,
  });

  /// Display name of the stage.
  final String name;

  /// Jobs within this stage.
  final List<EdenPipelineJob> jobs;
}

/// A horizontal pipeline graph showing stages and their jobs.
///
/// Each stage is rendered as a vertical column of job nodes, connected by
/// horizontal arrows between stages. Running jobs display an animated pulse.
///
/// ```dart
/// EdenPipelineGraph(
///   stages: [
///     EdenPipelineStage(name: 'Build', jobs: [
///       EdenPipelineJob(id: '1', name: 'compile', status: EdenPipelineJobStatus.passed),
///     ]),
///     EdenPipelineStage(name: 'Test', jobs: [
///       EdenPipelineJob(id: '2', name: 'unit', status: EdenPipelineJobStatus.running),
///       EdenPipelineJob(id: '3', name: 'integration', status: EdenPipelineJobStatus.queued),
///     ]),
///   ],
///   onJobTap: (job) => print(job.name),
/// )
/// ```
class EdenPipelineGraph extends StatefulWidget {
  /// Creates a pipeline graph widget.
  const EdenPipelineGraph({
    super.key,
    required this.stages,
    this.onJobTap,
  });

  /// The pipeline stages to display.
  final List<EdenPipelineStage> stages;

  /// Called when a job node is tapped.
  final ValueChanged<EdenPipelineJob>? onJobTap;

  @override
  State<EdenPipelineGraph> createState() => _EdenPipelineGraphState();
}

class _EdenPipelineGraphState extends State<EdenPipelineGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStageHeaders(theme, isDark),
          const SizedBox(height: EdenSpacing.space2),
          _buildGraph(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildStageHeaders(ThemeData theme, bool isDark) {
    return Row(
      children: [
        for (int i = 0; i < widget.stages.length; i++) ...[
          if (i > 0) const SizedBox(width: EdenSpacing.space8),
          SizedBox(
            width: 140,
            child: Text(
              widget.stages[i].name,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGraph(ThemeData theme, bool isDark) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.stages.length; i++) ...[
            if (i > 0) _buildConnectorArrow(isDark),
            _buildStageColumn(widget.stages[i], theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildStageColumn(
    EdenPipelineStage stage,
    ThemeData theme,
    bool isDark,
  ) {
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < stage.jobs.length; i++) ...[
            if (i > 0) const SizedBox(height: EdenSpacing.space2),
            _buildJobNode(stage.jobs[i], theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildJobNode(
    EdenPipelineJob job,
    ThemeData theme,
    bool isDark,
  ) {
    final statusColor = _jobStatusColor(job.status);
    final isRunning = job.status == EdenPipelineJobStatus.running;

    Widget node = GestureDetector(
      onTap: widget.onJobTap != null ? () => widget.onJobTap!(job) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          borderRadius: EdenRadii.borderRadiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(job.status, statusColor),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    job.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? EdenColors.neutral[200]
                          : EdenColors.neutral[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (job.duration != null)
                    Text(
                      _formatDuration(job.duration!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: EdenColors.neutral[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isRunning) {
      node = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: EdenRadii.borderRadiusMd,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: _pulseAnimation.value * 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: node,
      );
    }

    return node;
  }

  Widget _buildConnectorArrow(bool isDark) {
    final color = isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space3),
      child: SizedBox(
        width: EdenSpacing.space8,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: color,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(EdenPipelineJobStatus status, Color color) {
    switch (status) {
      case EdenPipelineJobStatus.passed:
        return Icon(Icons.check_circle, size: 16, color: color);
      case EdenPipelineJobStatus.failed:
        return Icon(Icons.cancel, size: 16, color: color);
      case EdenPipelineJobStatus.running:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color,
          ),
        );
      case EdenPipelineJobStatus.canceled:
        return Icon(Icons.block, size: 16, color: color);
      case EdenPipelineJobStatus.skipped:
        return Icon(Icons.skip_next, size: 16, color: color);
      case EdenPipelineJobStatus.manual:
        return Icon(Icons.pan_tool, size: 16, color: color);
      case EdenPipelineJobStatus.queued:
        return Icon(Icons.circle_outlined, size: 16, color: color);
    }
  }

  Color _jobStatusColor(EdenPipelineJobStatus status) {
    switch (status) {
      case EdenPipelineJobStatus.passed:
        return EdenColors.success;
      case EdenPipelineJobStatus.failed:
        return EdenColors.error;
      case EdenPipelineJobStatus.running:
        return EdenColors.info;
      case EdenPipelineJobStatus.canceled:
        return EdenColors.neutral[400]!;
      case EdenPipelineJobStatus.skipped:
        return EdenColors.neutral[400]!;
      case EdenPipelineJobStatus.manual:
        return EdenColors.warning;
      case EdenPipelineJobStatus.queued:
        return EdenColors.neutral[500]!;
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

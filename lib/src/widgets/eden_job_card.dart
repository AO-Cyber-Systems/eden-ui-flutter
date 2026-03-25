import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The execution status of a CI/CD job.
enum EdenJobStatus {
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

/// A card widget displaying CI/CD job details with status, duration, and
/// contextual actions.
///
/// Shows the job name, execution status with a colored icon, duration, runner
/// information, and optional retry/manual trigger buttons.
///
/// ```dart
/// EdenJobCard(
///   id: 'job-123',
///   name: 'build:linux',
///   status: EdenJobStatus.failed,
///   duration: Duration(minutes: 3, seconds: 42),
///   runnerName: 'runner-01',
///   isRetryable: true,
///   onRetry: () => retryJob('job-123'),
/// )
/// ```
class EdenJobCard extends StatefulWidget {
  /// Creates a job card widget.
  const EdenJobCard({
    super.key,
    required this.id,
    required this.name,
    required this.status,
    this.duration,
    this.runnerName,
    this.startedAt,
    this.isRetryable = false,
    this.isManual = false,
    this.onTap,
    this.onRetry,
    this.onTrigger,
  });

  /// Unique identifier for the job.
  final String id;

  /// Display name of the job.
  final String name;

  /// Current execution status.
  final EdenJobStatus status;

  /// Duration of the job execution.
  final Duration? duration;

  /// The name of the runner executing this job.
  final String? runnerName;

  /// When the job started.
  final DateTime? startedAt;

  /// Whether this job can be retried.
  final bool isRetryable;

  /// Whether this job requires manual triggering.
  final bool isManual;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Called when the manual trigger button is pressed.
  final VoidCallback? onTrigger;

  @override
  State<EdenJobCard> createState() => _EdenJobCardState();
}

class _EdenJobCardState extends State<EdenJobCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.status == EdenJobStatus.running) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EdenJobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == EdenJobStatus.running &&
        oldWidget.status != EdenJobStatus.running) {
      _pulseController.repeat(reverse: true);
    } else if (widget.status != EdenJobStatus.running &&
        oldWidget.status == EdenJobStatus.running) {
      _pulseController.stop();
      _pulseController.reset();
    }
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
    final statusColor = _statusColor(widget.status);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: isDark ? 0.08 : 0.04),
          border: Border.all(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
          borderRadius: EdenRadii.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark, statusColor),
            const SizedBox(height: EdenSpacing.space3),
            _buildMetadata(theme, isDark),
            if (widget.isRetryable || widget.isManual) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildActions(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color statusColor) {
    return Row(
      children: [
        _buildStatusIcon(statusColor),
        const SizedBox(width: EdenSpacing.space3),
        Expanded(
          child: Text(
            widget.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? EdenColors.neutral[100] : EdenColors.neutral[900],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.duration != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              _formatDuration(widget.duration!),
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: EdenColors.neutral[500],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIcon(Color statusColor) {
    final isRunning = widget.status == EdenJobStatus.running;

    if (isRunning) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: EdenRadii.borderRadiusSm,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: _pulseAnimation.value * 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: statusColor,
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Icon(
        _statusIconData(widget.status),
        size: 18,
        color: statusColor,
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme, bool isDark) {
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: EdenColors.neutral[500],
    );

    return Wrap(
      spacing: EdenSpacing.space4,
      runSpacing: EdenSpacing.space1,
      children: [
        if (widget.runnerName != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dns_outlined, size: 14, color: EdenColors.neutral[400]),
              const SizedBox(width: EdenSpacing.space1),
              Text(widget.runnerName!, style: metaStyle),
            ],
          ),
        if (widget.startedAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 14, color: EdenColors.neutral[400]),
              const SizedBox(width: EdenSpacing.space1),
              Text(_formatTime(widget.startedAt!), style: metaStyle),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 14, color: EdenColors.neutral[400]),
            const SizedBox(width: EdenSpacing.space1),
            Text(widget.id, style: metaStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        if (widget.isRetryable && widget.onRetry != null)
          OutlinedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        if (widget.isRetryable && widget.isManual)
          const SizedBox(width: EdenSpacing.space2),
        if (widget.isManual && widget.onTrigger != null)
          FilledButton.icon(
            onPressed: widget.onTrigger,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Trigger'),
          ),
      ],
    );
  }

  IconData _statusIconData(EdenJobStatus status) {
    switch (status) {
      case EdenJobStatus.passed:
        return Icons.check_circle;
      case EdenJobStatus.failed:
        return Icons.cancel;
      case EdenJobStatus.running:
        return Icons.play_circle;
      case EdenJobStatus.canceled:
        return Icons.block;
      case EdenJobStatus.skipped:
        return Icons.skip_next;
      case EdenJobStatus.manual:
        return Icons.pan_tool;
      case EdenJobStatus.queued:
        return Icons.circle_outlined;
    }
  }

  Color _statusColor(EdenJobStatus status) {
    switch (status) {
      case EdenJobStatus.passed:
        return EdenColors.success;
      case EdenJobStatus.failed:
        return EdenColors.error;
      case EdenJobStatus.running:
        return EdenColors.info;
      case EdenJobStatus.canceled:
        return EdenColors.neutral[400]!;
      case EdenJobStatus.skipped:
        return EdenColors.neutral[400]!;
      case EdenJobStatus.manual:
        return EdenColors.warning;
      case EdenJobStatus.queued:
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

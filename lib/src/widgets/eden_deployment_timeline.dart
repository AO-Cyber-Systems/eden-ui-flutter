import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The status of a deployment.
enum EdenDeploymentStatus {
  /// Deployment completed successfully.
  success,

  /// Deployment failed.
  failure,

  /// Deployment is currently in progress.
  inProgress,

  /// Deployment is pending.
  pending,
}

/// A single deployment entry in the timeline.
class EdenDeployment {
  /// Creates a deployment model.
  const EdenDeployment({
    required this.id,
    required this.sha,
    required this.branch,
    required this.status,
    required this.deployedBy,
    required this.timestamp,
    this.duration,
  });

  /// Unique deployment identifier.
  final String id;

  /// Commit SHA for this deployment.
  final String sha;

  /// Branch deployed from.
  final String branch;

  /// Current deployment status.
  final EdenDeploymentStatus status;

  /// Who triggered the deployment.
  final String deployedBy;

  /// When the deployment was triggered.
  final DateTime timestamp;

  /// Duration of the deployment.
  final Duration? duration;
}

/// A vertical timeline displaying deployment history.
///
/// Each deployment entry shows a status icon, branch/SHA info, deployer,
/// timestamp, and duration. Entries are connected by a vertical line.
///
/// ```dart
/// EdenDeploymentTimeline(
///   deployments: [
///     EdenDeployment(
///       id: 'deploy-1',
///       sha: 'a1b2c3d',
///       branch: 'main',
///       status: EdenDeploymentStatus.success,
///       deployedBy: 'alice',
///       timestamp: DateTime.now(),
///       duration: Duration(minutes: 3),
///     ),
///   ],
///   onDeploymentTap: (d) => print(d.id),
/// )
/// ```
class EdenDeploymentTimeline extends StatefulWidget {
  /// Creates a deployment timeline widget.
  const EdenDeploymentTimeline({
    super.key,
    required this.deployments,
    this.onDeploymentTap,
  });

  /// The deployments to display, in chronological order (newest first).
  final List<EdenDeployment> deployments;

  /// Called when a deployment entry is tapped.
  final ValueChanged<EdenDeployment>? onDeploymentTap;

  @override
  State<EdenDeploymentTimeline> createState() =>
      _EdenDeploymentTimelineState();
}

class _EdenDeploymentTimelineState extends State<EdenDeploymentTimeline>
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
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    final hasInProgress = widget.deployments
        .any((d) => d.status == EdenDeploymentStatus.inProgress);
    if (hasInProgress) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EdenDeploymentTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasInProgress = widget.deployments
        .any((d) => d.status == EdenDeploymentStatus.inProgress);
    if (hasInProgress && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!hasInProgress && _pulseController.isAnimating) {
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

    if (widget.deployments.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rocket_launch_outlined,
              size: 32, color: EdenColors.neutral[400]),
          const SizedBox(height: EdenSpacing.space2),
          Text(
            'No deployments yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: EdenColors.neutral[500],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.deployments.length; i++)
          _buildEntry(i, widget.deployments[i], theme, isDark),
      ],
    );
  }

  Widget _buildEntry(
    int index,
    EdenDeployment deployment,
    ThemeData theme,
    bool isDark,
  ) {
    final isLast = index == widget.deployments.length - 1;
    final statusColor = _statusColor(deployment.status);

    return GestureDetector(
      onTap: widget.onDeploymentTap != null
          ? () => widget.onDeploymentTap!(deployment)
          : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineGutter(
              statusColor,
              isLast,
              isDark,
              deployment.status == EdenDeploymentStatus.inProgress,
            ),
            const SizedBox(width: EdenSpacing.space3),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  bottom: isLast ? 0 : EdenSpacing.space3,
                ),
                padding: const EdgeInsets.all(EdenSpacing.space3),
                decoration: BoxDecoration(
                  color: isDark
                      ? EdenColors.neutral[900]
                      : EdenColors.neutral[50],
                  border: Border.all(
                    color: isDark
                        ? EdenColors.neutral[700]!
                        : EdenColors.neutral[200]!,
                  ),
                  borderRadius: EdenRadii.borderRadiusMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEntryHeader(deployment, theme, isDark, statusColor),
                    const SizedBox(height: EdenSpacing.space2),
                    _buildEntryMeta(deployment, theme, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineGutter(
    Color statusColor,
    bool isLast,
    bool isDark,
    bool isInProgress,
  ) {
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          const SizedBox(height: EdenSpacing.space1),
          isInProgress
              ? AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(
                                alpha: _pulseAnimation.value * 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: isDark
                    ? EdenColors.neutral[700]
                    : EdenColors.neutral[300],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryHeader(
    EdenDeployment deployment,
    ThemeData theme,
    bool isDark,
    Color statusColor,
  ) {
    return Row(
      children: [
        Icon(
          _statusIcon(deployment.status),
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? EdenColors.neutral[800]
                      : EdenColors.neutral[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alt_route, size: 12, color: EdenColors.neutral[500]),
                    const SizedBox(width: 4),
                    Text(
                      deployment.branch,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? EdenColors.neutral[200]
                            : EdenColors.neutral[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EdenSpacing.space2),
              Text(
                deployment.sha.length > 8
                    ? deployment.sha.substring(0, 8)
                    : deployment.sha,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: EdenColors.neutral[500],
                ),
              ),
            ],
          ),
        ),
        if (deployment.duration != null)
          Text(
            _formatDuration(deployment.duration!),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              color: EdenColors.neutral[500],
            ),
          ),
      ],
    );
  }

  Widget _buildEntryMeta(
    EdenDeployment deployment,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 13, color: EdenColors.neutral[400]),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          deployment.deployedBy,
          style: theme.textTheme.labelSmall?.copyWith(
            color: EdenColors.neutral[500],
          ),
        ),
        const SizedBox(width: EdenSpacing.space3),
        Icon(Icons.schedule, size: 13, color: EdenColors.neutral[400]),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          _formatDateTime(deployment.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: EdenColors.neutral[500],
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(EdenDeploymentStatus status) {
    switch (status) {
      case EdenDeploymentStatus.success:
        return Icons.check_circle;
      case EdenDeploymentStatus.failure:
        return Icons.cancel;
      case EdenDeploymentStatus.inProgress:
        return Icons.play_circle;
      case EdenDeploymentStatus.pending:
        return Icons.circle_outlined;
    }
  }

  Color _statusColor(EdenDeploymentStatus status) {
    switch (status) {
      case EdenDeploymentStatus.success:
        return EdenColors.success;
      case EdenDeploymentStatus.failure:
        return EdenColors.error;
      case EdenDeploymentStatus.inProgress:
        return EdenColors.info;
      case EdenDeploymentStatus.pending:
        return EdenColors.neutral[400]!;
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

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute';
  }
}

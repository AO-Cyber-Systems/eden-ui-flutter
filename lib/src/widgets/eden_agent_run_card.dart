import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// How the agent run was triggered.
enum EdenAgentTrigger {
  /// Manually started by a user.
  manual,

  /// Started on a cron / schedule.
  scheduled,

  /// Started via an incoming webhook.
  webhook,

  /// Started in response to a system event.
  event,
}

/// Current status of the agent run.
enum EdenAgentRunStatus {
  /// Agent is building a plan.
  planning,

  /// Agent is writing code.
  coding,

  /// Agent is reviewing its changes.
  reviewing,

  /// Agent is deploying artifacts.
  deploying,

  /// Run finished successfully.
  complete,

  /// Run ended with an error.
  failed,
}

/// Snapshot model for an autonomous agent run.
class EdenAgentRun {
  /// Creates an agent run model.
  const EdenAgentRun({
    required this.runId,
    required this.trigger,
    required this.objective,
    required this.status,
    required this.startedAt,
    this.duration,
    this.tokensUsed = 0,
    this.costEstimate = 0.0,
    this.commitsCreated = 0,
    this.prsCreated = 0,
    this.issuesClosed = 0,
  });

  /// Unique identifier for this run.
  final String runId;

  /// How the run was triggered.
  final EdenAgentTrigger trigger;

  /// Natural-language objective the agent is pursuing.
  final String objective;

  /// Current status of the run.
  final EdenAgentRunStatus status;

  /// When the run started.
  final DateTime startedAt;

  /// Elapsed wall-clock duration (null while still running).
  final Duration? duration;

  /// Total LLM tokens consumed so far.
  final int tokensUsed;

  /// Estimated dollar cost so far.
  final double costEstimate;

  /// Number of commits the agent has created.
  final int commitsCreated;

  /// Number of pull requests the agent has opened.
  final int prsCreated;

  /// Number of issues the agent has closed.
  final int issuesClosed;
}

/// A card displaying the status and stats of an autonomous agent run.
///
/// Shows the agent's objective, current status with an animated pulse for
/// in-progress states, a trigger badge, duration, and a stats row summarizing
/// commits, PRs, issues, tokens, and cost.
class EdenAgentRunCard extends StatefulWidget {
  /// Creates an agent run card.
  const EdenAgentRunCard({
    super.key,
    required this.run,
    this.onTap,
    this.onCancel,
    this.onRetry,
  });

  /// The agent run data to display.
  final EdenAgentRun run;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the cancel button is pressed (shown for in-progress runs).
  final VoidCallback? onCancel;

  /// Called when the retry button is pressed (shown for failed runs).
  final VoidCallback? onRetry;

  @override
  State<EdenAgentRunCard> createState() => _EdenAgentRunCardState();
}

class _EdenAgentRunCardState extends State<EdenAgentRunCard>
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
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant EdenAgentRunCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run.status != widget.run.status) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (_isInProgress) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  bool get _isInProgress {
    switch (widget.run.status) {
      case EdenAgentRunStatus.planning:
      case EdenAgentRunStatus.coding:
      case EdenAgentRunStatus.reviewing:
      case EdenAgentRunStatus.deploying:
        return true;
      case EdenAgentRunStatus.complete:
      case EdenAgentRunStatus.failed:
        return false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  IconData _statusIcon() {
    switch (widget.run.status) {
      case EdenAgentRunStatus.planning:
        return Icons.psychology_outlined;
      case EdenAgentRunStatus.coding:
        return Icons.code;
      case EdenAgentRunStatus.reviewing:
        return Icons.rate_review_outlined;
      case EdenAgentRunStatus.deploying:
        return Icons.rocket_launch_outlined;
      case EdenAgentRunStatus.complete:
        return Icons.check_circle_outlined;
      case EdenAgentRunStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _statusColor() {
    switch (widget.run.status) {
      case EdenAgentRunStatus.planning:
        return EdenColors.info;
      case EdenAgentRunStatus.coding:
        return EdenColors.purple;
      case EdenAgentRunStatus.reviewing:
        return EdenColors.warning;
      case EdenAgentRunStatus.deploying:
        return EdenColors.blue;
      case EdenAgentRunStatus.complete:
        return EdenColors.success;
      case EdenAgentRunStatus.failed:
        return EdenColors.error;
    }
  }

  String _statusLabel() {
    switch (widget.run.status) {
      case EdenAgentRunStatus.planning:
        return 'Planning';
      case EdenAgentRunStatus.coding:
        return 'Coding';
      case EdenAgentRunStatus.reviewing:
        return 'Reviewing';
      case EdenAgentRunStatus.deploying:
        return 'Deploying';
      case EdenAgentRunStatus.complete:
        return 'Complete';
      case EdenAgentRunStatus.failed:
        return 'Failed';
    }
  }

  String _triggerLabel() {
    switch (widget.run.trigger) {
      case EdenAgentTrigger.manual:
        return 'Manual';
      case EdenAgentTrigger.scheduled:
        return 'Scheduled';
      case EdenAgentTrigger.webhook:
        return 'Webhook';
      case EdenAgentTrigger.event:
        return 'Event';
    }
  }

  IconData _triggerIcon() {
    switch (widget.run.trigger) {
      case EdenAgentTrigger.manual:
        return Icons.touch_app_outlined;
      case EdenAgentTrigger.scheduled:
        return Icons.schedule;
      case EdenAgentTrigger.webhook:
        return Icons.webhook_outlined;
      case EdenAgentTrigger.event:
        return Icons.bolt_outlined;
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

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
    return tokens.toString();
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
    final statusColor = _statusColor();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: EdenRadii.borderRadiusLg,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: EdenRadii.borderRadiusLg,
          child: Padding(
            padding: EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: status icon + label, trigger badge
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isInProgress
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Icon(
                            _statusIcon(),
                            size: 20,
                            color: statusColor,
                          ),
                        );
                      },
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    Text(
                      _statusLabel(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    _TriggerBadge(
                      label: _triggerLabel(),
                      icon: _triggerIcon(),
                      isDark: isDark,
                    ),
                  ],
                ),

                SizedBox(height: EdenSpacing.space3),

                // Objective
                Text(
                  widget.run.objective,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: EdenSpacing.space3),

                // Duration
                if (widget.run.duration != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: EdenSpacing.space3),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 14, color: mutedColor),
                        SizedBox(width: EdenSpacing.space1),
                        Text(
                          _formatDuration(widget.run.duration!),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: mutedColor),
                        ),
                      ],
                    ),
                  ),

                // Stats row
                Wrap(
                  spacing: EdenSpacing.space3,
                  runSpacing: EdenSpacing.space2,
                  children: [
                    _StatChip(
                      icon: Icons.commit,
                      value: '${widget.run.commitsCreated}',
                      label: 'commits',
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.call_merge,
                      value: '${widget.run.prsCreated}',
                      label: 'PRs',
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.task_alt,
                      value: '${widget.run.issuesClosed}',
                      label: 'issues',
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.token_outlined,
                      value: _formatTokens(widget.run.tokensUsed),
                      label: 'tokens',
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.attach_money,
                      value: '\$${widget.run.costEstimate.toStringAsFixed(2)}',
                      label: 'cost',
                      isDark: isDark,
                    ),
                  ],
                ),

                // Action buttons
                if (widget.onCancel != null && _isInProgress ||
                    widget.onRetry != null &&
                        widget.run.status == EdenAgentRunStatus.failed) ...[
                  SizedBox(height: EdenSpacing.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isInProgress && widget.onCancel != null)
                        _ActionButton(
                          label: 'Cancel',
                          icon: Icons.stop_circle_outlined,
                          color: EdenColors.error,
                          onPressed: widget.onCancel!,
                          isDark: isDark,
                        ),
                      if (widget.run.status == EdenAgentRunStatus.failed &&
                          widget.onRetry != null)
                        _ActionButton(
                          label: 'Retry',
                          icon: Icons.replay,
                          color: EdenColors.info,
                          onPressed: widget.onRetry!,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _TriggerBadge extends StatelessWidget {
  const _TriggerBadge({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    return Container(
      padding: EdgeInsets.symmetric(
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
          Icon(icon, size: 12, color: color),
          SizedBox(width: EdenSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: EdenSpacing.space1 / 2),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 11,
            color: color,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: EdenRadii.borderRadiusSm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: EdenRadii.borderRadiusSm,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: EdenSpacing.space1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

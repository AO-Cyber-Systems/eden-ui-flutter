import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The severity of an incident.
enum EdenIncidentSeverity {
  /// Critical — widespread outage or data loss.
  critical,

  /// Major — significant degradation.
  major,

  /// Minor — limited impact.
  minor,
}

/// The lifecycle status of an incident.
enum EdenIncidentStatus {
  /// Incident has been detected but not acknowledged.
  detected,

  /// Incident has been acknowledged by a responder.
  acknowledged,

  /// Incident has been resolved.
  resolved,
}

/// A person assigned to an incident.
class EdenIncidentAssignee {
  /// Creates an incident assignee.
  const EdenIncidentAssignee({
    required this.name,
    required this.initial,
  });

  /// Full name of the assignee.
  final String name;

  /// Single-character initial for the avatar.
  final String initial;
}

/// A model representing an operational incident.
class EdenIncident {
  /// Creates an incident model.
  const EdenIncident({
    required this.id,
    required this.title,
    required this.severity,
    required this.status,
    this.assignees = const [],
    required this.startedAt,
    this.resolvedAt,
    this.duration,
    this.linkedAlerts = 0,
  });

  /// Unique incident identifier.
  final String id;

  /// The incident title.
  final String title;

  /// The severity level.
  final EdenIncidentSeverity severity;

  /// The current status.
  final EdenIncidentStatus status;

  /// People assigned to this incident.
  final List<EdenIncidentAssignee> assignees;

  /// When the incident was first detected.
  final DateTime startedAt;

  /// When the incident was resolved (null if still active).
  final DateTime? resolvedAt;

  /// Duration string (e.g. "2h 15m"). Computed externally or provided.
  final String? duration;

  /// Number of linked monitoring alerts.
  final int linkedAlerts;
}

/// A card widget displaying an incident with severity badge (pulsing for
/// active), status progression, assignee avatars, and duration info.
///
/// ```dart
/// EdenIncidentCard(
///   incident: EdenIncident(
///     id: 'INC-42',
///     title: 'Database connection pool exhausted',
///     severity: EdenIncidentSeverity.critical,
///     status: EdenIncidentStatus.acknowledged,
///     startedAt: DateTime.now().subtract(Duration(hours: 1)),
///     assignees: [EdenIncidentAssignee(name: 'Alice', initial: 'A')],
///     linkedAlerts: 3,
///   ),
///   onTap: () {},
///   onAcknowledge: () {},
/// )
/// ```
class EdenIncidentCard extends StatefulWidget {
  /// Creates an Eden incident card.
  const EdenIncidentCard({
    super.key,
    required this.incident,
    this.onTap,
    this.onAcknowledge,
    this.onResolve,
  });

  /// The incident data to display.
  final EdenIncident incident;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the acknowledge action is triggered.
  final VoidCallback? onAcknowledge;

  /// Callback when the resolve action is triggered.
  final VoidCallback? onResolve;

  @override
  State<EdenIncidentCard> createState() => _EdenIncidentCardState();
}

class _EdenIncidentCardState extends State<EdenIncidentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isActive =>
      widget.incident.status != EdenIncidentStatus.resolved;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EdenIncidentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 1.0;
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
    final incident = widget.incident;
    final severityColor = _severityColor(incident.severity);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[900] : EdenColors.neutral[50],
          border: Border.all(
            color: _isActive
                ? severityColor.withValues(alpha: 0.4)
                : (isDark
                    ? EdenColors.neutral[700]!
                    : EdenColors.neutral[200]!),
          ),
          borderRadius: EdenRadii.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pulsing severity badge
                  _isActive
                      ? AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: _SeverityBadge(
                            severity: incident.severity,
                          ),
                        )
                      : _SeverityBadge(severity: incident.severity),
                  const SizedBox(width: EdenSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          incident.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: EdenSpacing.space1),
                        Row(
                          children: [
                            Text(
                              incident.id,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: EdenColors.neutral[500],
                              ),
                            ),
                            if (incident.linkedAlerts > 0) ...[
                              const SizedBox(width: EdenSpacing.space2),
                              Icon(
                                Icons.link_rounded,
                                size: 12,
                                color: EdenColors.neutral[400],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${incident.linkedAlerts} alert${incident.linkedAlerts != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: EdenColors.neutral[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Duration
                  _DurationDisplay(incident: incident),
                ],
              ),
            ),

            // Status progression
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
              ),
              child: _StatusProgression(status: incident.status),
            ),

            // Footer: assignees + actions
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              child: Row(
                children: [
                  // Assignee avatars
                  if (incident.assignees.isNotEmpty)
                    _AssigneeAvatars(assignees: incident.assignees),
                  const Spacer(),
                  // Actions
                  if (incident.status == EdenIncidentStatus.detected &&
                      widget.onAcknowledge != null)
                    _ActionChip(
                      label: 'Acknowledge',
                      icon: Icons.check_rounded,
                      color: EdenColors.warning,
                      onPressed: widget.onAcknowledge!,
                    ),
                  if (incident.status == EdenIncidentStatus.acknowledged &&
                      widget.onResolve != null)
                    _ActionChip(
                      label: 'Resolve',
                      icon: Icons.check_circle_rounded,
                      color: EdenColors.success,
                      onPressed: widget.onResolve!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(EdenIncidentSeverity severity) {
    return switch (severity) {
      EdenIncidentSeverity.critical => EdenColors.red[500]!,
      EdenIncidentSeverity.major => EdenColors.warning,
      EdenIncidentSeverity.minor => EdenColors.info,
    };
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final EdenIncidentSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (severity) {
      EdenIncidentSeverity.critical => (EdenColors.red[500]!, 'SEV1'),
      EdenIncidentSeverity.major => (EdenColors.warning, 'SEV2'),
      EdenIncidentSeverity.minor => (EdenColors.info, 'SEV3'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DurationDisplay extends StatelessWidget {
  const _DurationDisplay({required this.incident});

  final EdenIncident incident;

  @override
  Widget build(BuildContext context) {
    final isResolved = incident.status == EdenIncidentStatus.resolved;
    final durationText = incident.duration ?? _computeDuration();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isResolved)
              Icon(
                Icons.timer_rounded,
                size: 12,
                color: EdenColors.warning,
              )
            else
              Icon(
                Icons.timer_off_rounded,
                size: 12,
                color: EdenColors.neutral[400],
              ),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              durationText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: isResolved ? EdenColors.neutral[500] : EdenColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          isResolved ? 'Total duration' : 'Ongoing',
          style: TextStyle(
            fontSize: 10,
            color: EdenColors.neutral[400],
          ),
        ),
      ],
    );
  }

  String _computeDuration() {
    final end = incident.resolvedAt ?? DateTime.now();
    final diff = end.difference(incident.startedAt);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }
}

class _StatusProgression extends StatelessWidget {
  const _StatusProgression({required this.status});

  final EdenIncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = EdenIncidentStatus.values;
    final currentIndex = steps.indexOf(status);

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIndex
                    ? EdenColors.success
                    : (isDark
                        ? EdenColors.neutral[700]
                        : EdenColors.neutral[200]),
              ),
            ),
          _StepDot(
            label: steps[i].name,
            isCompleted: i <= currentIndex,
            isCurrent: i == currentIndex,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String label;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? EdenColors.success : EdenColors.neutral[400]!;

    return Tooltip(
      message: label,
      child: Container(
        width: isCurrent ? 12 : 8,
        height: isCurrent ? 12 : 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? color : null,
          border: isCompleted
              ? null
              : Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }
}

class _AssigneeAvatars extends StatelessWidget {
  const _AssigneeAvatars({required this.assignees});

  final List<EdenIncidentAssignee> assignees;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maxShow = 4;
    final visible = assignees.take(maxShow).toList();
    final overflow = assignees.length - maxShow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visible.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i > 0 ? 0 : 0, right: 0),
            child: Transform.translate(
              offset: Offset(-6.0 * i, 0),
              child: Tooltip(
                message: visible[i].name,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      isDark ? EdenColors.neutral[700] : EdenColors.neutral[200],
                  child: Text(
                    visible[i].initial,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? EdenColors.neutral[200]
                          : EdenColors.neutral[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (overflow > 0)
          Transform.translate(
            offset: Offset(-6.0 * visible.length, 0),
            child: CircleAvatar(
              radius: 12,
              backgroundColor:
                  isDark ? EdenColors.neutral[700] : EdenColors.neutral[200],
              child: Text(
                '+$overflow',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: EdenColors.neutral[500],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: EdenRadii.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: EdenRadii.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: EdenSpacing.space1),
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
    );
  }
}

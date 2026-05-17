import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_badge.dart';
import 'eden_stepper.dart';

/// 8-state appointment lifecycle (medical UC-SCH-05).
///
/// Linear forward path: [scheduled] → [confirmed] → [arrived] → [inRoom]
/// → [completed]. Off-path terminals: [noShow], [cancelled], [lateCancel].
///
/// Late-cancel definition (locked): cancelled within 24h of scheduledFor.
/// The widget does NOT compute this — consumer assigns [cancelled] vs
/// [lateCancel] based on its own policy; widget renders distinctly.
enum EdenAppointmentStatus {
  /// Initial state: appointment booked.
  scheduled,

  /// Patient confirmed (auto-reminder reply, portal confirm, etc.).
  confirmed,

  /// Patient checked in at front desk.
  arrived,

  /// Patient roomed (in exam/treatment room).
  inRoom,

  /// Visit complete (terminal-success).
  completed,

  /// Patient did not show; terminal off-path.
  noShow,

  /// Cancelled in advance (>24h before scheduled); terminal off-path.
  cancelled,

  /// Cancelled within 24h of scheduled; terminal off-path with billing
  /// implications distinct from regular [cancelled].
  lateCancel,
}

/// Returns the next linear status, or null if [current] is at the end of
/// the linear path OR is an off-path terminal.
EdenAppointmentStatus? nextLinearStatus(EdenAppointmentStatus current) {
  return switch (current) {
    EdenAppointmentStatus.scheduled => EdenAppointmentStatus.confirmed,
    EdenAppointmentStatus.confirmed => EdenAppointmentStatus.arrived,
    EdenAppointmentStatus.arrived => EdenAppointmentStatus.inRoom,
    EdenAppointmentStatus.inRoom => EdenAppointmentStatus.completed,
    _ => null,
  };
}

/// Whether [status] is terminal — either [EdenAppointmentStatus.completed]
/// (terminal-success on-path) OR any off-path terminal (noShow / cancelled
/// / lateCancel).
bool isTerminalStatus(EdenAppointmentStatus status) =>
    status == EdenAppointmentStatus.noShow ||
    status == EdenAppointmentStatus.cancelled ||
    status == EdenAppointmentStatus.lateCancel ||
    status == EdenAppointmentStatus.completed;

/// A single audit entry in an appointment's status history.
@immutable
class EdenAppointmentStatusEntry {
  const EdenAppointmentStatusEntry({
    required this.status,
    required this.timestamp,
    this.actorName,
    this.notes,
  });

  /// The status transitioned-to at [timestamp].
  final EdenAppointmentStatus status;

  /// When the transition happened.
  final DateTime timestamp;

  /// Who triggered the transition (e.g., 'Front desk',
  /// 'Patient self-service', 'Dr. Smith').
  final String? actorName;

  /// Optional free-form notes attached to the transition.
  final String? notes;
}

/// Aggregate appointment event value class for the status-flow widget.
@immutable
class EdenAppointmentEvent {
  const EdenAppointmentEvent({
    required this.id,
    required this.patientId,
    required this.appointmentId,
    required this.scheduledFor,
    required this.currentStatus,
    this.statusHistory = const [],
    required this.providerName,
    this.locationName,
    required this.visitType,
  });

  /// Stable event id.
  final String id;

  /// HIPAA isolation key.
  final String patientId;

  /// Backend appointment record id.
  final String appointmentId;

  /// Scheduled appointment time.
  final DateTime scheduledFor;

  /// Current status (live state).
  final EdenAppointmentStatus currentStatus;

  /// Chronological history of status transitions (oldest first).
  final List<EdenAppointmentStatusEntry> statusHistory;

  /// Provider display name (e.g., 'Dr. Smith, MD').
  final String providerName;

  /// Optional location/room/clinic suite.
  final String? locationName;

  /// Free-form visit type (e.g., 'Annual physical',
  /// 'Behavioral health follow-up').
  final String visitType;
}

/// Appointment lifecycle widget — UC-SCH-05 no-show + late-cancel tracking.
///
/// Composes [EdenStepper] for the 5-state linear forward path
/// (Scheduled / Confirmed / Arrived / In Room / Completed). Off-path
/// terminals ([EdenAppointmentStatus.noShow], cancelled, lateCancel)
/// render as colored [EdenBadge] pills below a greyed-out stepper.
///
/// Cross-vertical reuse (catalog demonstration only in v1): the same
/// state-machine shape generalizes to trades job tickets, retail order
/// lifecycle, gov case lifecycle. v2 will add a
/// `stateLabels: Map<EdenAppointmentStatus, String>` constructor param
/// for label override.
class EdenAppointmentStatusFlow extends StatelessWidget {
  const EdenAppointmentStatusFlow({
    super.key,
    required this.event,
    this.onStatusAdvance,
    this.onTerminalStateRequest,
    this.showHistory = true,
    this.now,
  });

  /// The appointment event to render.
  final EdenAppointmentEvent event;

  /// Fires when the user taps "Advance to next state". Emitted argument
  /// is the NEXT linear status. Hidden when current status is terminal.
  final ValueChanged<EdenAppointmentStatus>? onStatusAdvance;

  /// Fires when the user selects an off-path terminal status from the
  /// PopupMenuButton. Emitted argument is the selected terminal status.
  final ValueChanged<EdenAppointmentStatus>? onTerminalStateRequest;

  /// Whether to render the status-history list below the stepper.
  final bool showHistory;

  /// Optional deterministic clock for time-since-scheduled checks. In
  /// tests, ALWAYS pass an explicit [now].
  final DateTime? now;

  static const int _lateThresholdMinutes = 15;

  static const List<EdenAppointmentStatus> _linearStates = [
    EdenAppointmentStatus.scheduled,
    EdenAppointmentStatus.confirmed,
    EdenAppointmentStatus.arrived,
    EdenAppointmentStatus.inRoom,
    EdenAppointmentStatus.completed,
  ];

  bool get _isOffPathTerminal =>
      isTerminalStatus(event.currentStatus) &&
      event.currentStatus != EdenAppointmentStatus.completed;

  String _labelFor(EdenAppointmentStatus s) {
    return switch (s) {
      EdenAppointmentStatus.scheduled => 'Scheduled',
      EdenAppointmentStatus.confirmed => 'Confirmed',
      EdenAppointmentStatus.arrived => 'Arrived',
      EdenAppointmentStatus.inRoom => 'In Room',
      EdenAppointmentStatus.completed => 'Completed',
      EdenAppointmentStatus.noShow => 'No-Show',
      EdenAppointmentStatus.cancelled => 'Cancelled',
      EdenAppointmentStatus.lateCancel => 'Late Cancel',
    };
  }

  List<EdenStepItem> _buildSteps() {
    final offPath = _isOffPathTerminal;
    final currentIndex = offPath ? -1 : _linearStates.indexOf(event.currentStatus);
    return _linearStates.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final EdenStepStatus stepStatus;
      if (offPath) {
        stepStatus = EdenStepStatus.upcoming;
      } else if (i < currentIndex) {
        stepStatus = EdenStepStatus.complete;
      } else if (i == currentIndex) {
        stepStatus = event.currentStatus == EdenAppointmentStatus.completed
            ? EdenStepStatus.complete
            : EdenStepStatus.current;
      } else {
        stepStatus = EdenStepStatus.upcoming;
      }
      return EdenStepItem(label: _labelFor(s), status: stepStatus);
    }).toList();
  }

  static String _formatTimestamp(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${pad(t.month)}-${pad(t.day)} '
        '${pad(t.hour)}:${pad(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final offPath = _isOffPathTerminal;
    final clock = now ?? DateTime.now();
    final lateArrivalMinutes = event.currentStatus == EdenAppointmentStatus.arrived
        ? clock.difference(event.scheduledFor).inMinutes
        : null;
    final isLateArrival =
        lateArrivalMinutes != null && lateArrivalMinutes > _lateThresholdMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: EdenSpacing.space3),
        if (offPath)
          Opacity(
            opacity: 0.4,
            child: EdenStepper(steps: _buildSteps()),
          )
        else
          EdenStepper(steps: _buildSteps()),
        if (offPath) ...[
          const SizedBox(height: EdenSpacing.space3),
          _buildTerminalBadge(context),
        ],
        if (isLateArrival) ...[
          const SizedBox(height: EdenSpacing.space2),
          _buildLateArrivalChip(context, lateArrivalMinutes),
        ],
        const SizedBox(height: EdenSpacing.space3),
        _buildActionAffordances(context),
        if (showHistory) ...[
          const SizedBox(height: EdenSpacing.space4),
          _buildHistoryList(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      event.providerName,
      if (event.locationName != null) event.locationName!,
      _formatTimestamp(event.scheduledFor),
    ].join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.visitType,
          style: (theme.textTheme.titleMedium ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space1),
        Text(
          meta,
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalBadge(BuildContext context) {
    final (label, variant) = switch (event.currentStatus) {
      EdenAppointmentStatus.noShow => ('NO SHOW', EdenBadgeVariant.danger),
      EdenAppointmentStatus.lateCancel =>
        ('LATE CANCEL', EdenBadgeVariant.warning),
      EdenAppointmentStatus.cancelled =>
        ('CANCELLED', EdenBadgeVariant.neutral),
      _ => ('', EdenBadgeVariant.neutral),
    };
    return EdenBadge(
      key: const ValueKey('eden-appt-terminal-badge'),
      label: label,
      variant: variant,
      size: EdenBadgeSize.lg,
    );
  }

  Widget _buildLateArrivalChip(BuildContext context, int? minutes) {
    return EdenBadge(
      key: const ValueKey('eden-appt-late-arrival-chip'),
      label: 'Waiting ${minutes ?? 0}m past scheduled time',
      variant: EdenBadgeVariant.warning,
      size: EdenBadgeSize.sm,
    );
  }

  Widget _buildActionAffordances(BuildContext context) {
    final nonTerminal = !isTerminalStatus(event.currentStatus);
    if (!nonTerminal) return const SizedBox.shrink();
    final next = nextLinearStatus(event.currentStatus);
    final children = <Widget>[];
    if (onStatusAdvance != null && next != null) {
      children.add(
        FilledButton.icon(
          key: const ValueKey('eden-appt-advance-button'),
          icon: const Icon(Icons.arrow_forward),
          label: Text('Advance to ${_labelFor(next)}'),
          onPressed: () => onStatusAdvance!(next),
        ),
      );
    }
    if (onTerminalStateRequest != null) {
      children.add(
        PopupMenuButton<EdenAppointmentStatus>(
          key: const ValueKey('eden-appt-terminal-menu'),
          tooltip: 'Mark as terminal state',
          onSelected: onTerminalStateRequest,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: EdenAppointmentStatus.noShow,
              child: Text('Mark as No-Show'),
            ),
            PopupMenuItem(
              value: EdenAppointmentStatus.lateCancel,
              child: Text('Mark as Late Cancel'),
            ),
            PopupMenuItem(
              value: EdenAppointmentStatus.cancelled,
              child: Text('Mark as Cancelled'),
            ),
          ],
          child: OutlinedButton.icon(
            icon: const Icon(Icons.more_horiz),
            label: const Text('Terminal state…'),
            onPressed: null,
          ),
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space2,
      children: children,
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    if (event.statusHistory.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('eden-appt-history-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status history',
          style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        for (final entry in event.statusHistory) ...[
          _buildHistoryRow(context, entry),
          const SizedBox(height: EdenSpacing.space2),
        ],
      ],
    );
  }

  Widget _buildHistoryRow(BuildContext context, EdenAppointmentStatusEntry e) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EdenBadge(
          label: _labelFor(e.status),
          variant: _historyBadgeVariant(e.status),
          size: EdenBadgeSize.sm,
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTimestamp(e.timestamp),
                style: theme.textTheme.bodySmall,
              ),
              if (e.actorName != null)
                Text(
                  'by ${e.actorName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (e.notes != null)
                Padding(
                  padding: const EdgeInsets.only(top: EdenSpacing.space1),
                  child: Text(
                    e.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  EdenBadgeVariant _historyBadgeVariant(EdenAppointmentStatus s) {
    return switch (s) {
      EdenAppointmentStatus.completed => EdenBadgeVariant.success,
      EdenAppointmentStatus.noShow => EdenBadgeVariant.danger,
      EdenAppointmentStatus.lateCancel => EdenBadgeVariant.warning,
      EdenAppointmentStatus.cancelled => EdenBadgeVariant.neutral,
      _ => EdenBadgeVariant.info,
    };
  }
}

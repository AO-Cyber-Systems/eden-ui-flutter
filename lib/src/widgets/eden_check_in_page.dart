// EdenCheckInPage — GPS-aware clock-in / clock-out page composition.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/
// check_in_page.dart (526 LOC). Port strips:
//   - flutter_riverpod (ConsumerStatefulWidget → StatefulWidget; provider
//     reads → constructor props + callback).
//   - package:trades/.../check_in_model.dart → EdenCheckInEvent inlined.
//   - package:trades/shared/widgets/gps_status_indicator.dart → inline
//     `EdenBadge` rows + reuse the objective-002 EdenGpsStatus enum.
//   - `intl` DateFormat.jm() → hand-rolled _formatTime12h (intl not in
//     pubspec.yaml; constraint 12 forbids new pubspec deps).
//
// Library renders the UX; consumer wires GPS acquisition (geolocator etc),
// event persistence, and submission via callback props. ZERO platform-
// plugin imports anywhere in this file.

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_badge.dart';
import 'eden_card.dart';
import 'eden_description_list.dart';
import 'eden_gps_status_indicator.dart';
import 'eden_section_header.dart';
import 'eden_spinner.dart';
import 'map_providers/eden_map_types.dart';

/// Type of a check-in event (clock-in vs clock-out).
enum EdenCheckInEventType { checkIn, checkOut }

/// Appointment metadata rendered in the page's appointment info card.
///
/// Generic across verticals — trades uses [icon] = [Icons.event_available],
/// medical might use [Icons.medical_services_outlined], fuel-driver might
/// use [Icons.local_shipping_outlined]. Caller-supplied; no domain binding.
class EdenCheckInAppointment {
  const EdenCheckInAppointment({
    required this.id,
    required this.title,
    required this.address,
    this.icon = Icons.event_available,
  });

  final String id;
  final String title;
  final String address;
  final IconData icon;
}

/// A single clock-in or clock-out history row.
///
/// **Sort assumption:** [EdenCheckInPage] does NOT sort its [events] list.
/// Consumers should pass events in display order (newest at top of "today's
/// activity" — the page renders them in the order received).
///
/// **[isGeofenceVerified]:** computed by the consumer (e.g. server-side
/// based on lat/lng vs the appointment's geofence). The page renders a
/// "Verified" badge when true; no badge otherwise.
class EdenCheckInEvent {
  const EdenCheckInEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.isGeofenceVerified,
    this.notes,
  });

  final String id;
  final EdenCheckInEventType type;
  final DateTime timestamp;
  final bool isGeofenceVerified;
  final String? notes;
}

/// Payload passed to `onSubmit` when the user taps Check In or Check Out.
///
/// All scalar fields — no DateTime included because the consumer typically
/// stamps the timestamp server-side. If a client-side timestamp is needed,
/// the consumer can read `DateTime.now()` inside their `onSubmit` adapter.
class EdenCheckInSubmission {
  const EdenCheckInSubmission({
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isGeofenceVerified,
    this.notes,
  });

  final EdenCheckInEventType type;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isGeofenceVerified;
  final String? notes;
}

/// GPS-aware clock-in / clock-out page for companion-mode field crew.
///
/// **Composition position:** designed to render inside an
/// `EdenCompanionShell` content slot OR stand alone full-screen on phone
/// widths (≥390pt). The page renders its OWN `Scaffold` + `AppBar`.
///
/// **Transport-agnostic:** all side-effecting capabilities (GPS, persistence,
/// network) arrive via constructor props or callback props. The library
/// imports ZERO platform plugins.
///
/// **Three-state action area:** the page derives its action area from
/// [events]:
///   - empty events → green "Check In" FilledButton.
///   - check-in present, no check-out → orange "Check Out" + banner
///     "Checked in at <time>".
///   - both present → blue "Appointment complete" container.
///
/// **Submit guard:** when [gpsStatus] is [EdenGpsStatus.unavailable],
/// tapping Check In / Check Out shows a SnackBar ("GPS is not available…")
/// and does NOT invoke [onSubmit].
///
/// **`onSubmit: null` semantics:** action buttons are still rendered but
/// disabled (read-only mode). Useful for supervisor "audit trail" views.
class EdenCheckInPage extends StatefulWidget {
  const EdenCheckInPage({
    super.key,
    required this.appointment,
    required this.gpsStatus,
    this.gpsAccuracyMeters,
    this.gpsPosition,
    this.events = const [],
    this.onSubmit,
    this.appBarTitle,
  });

  final EdenCheckInAppointment appointment;
  final EdenGpsStatus gpsStatus;
  final double? gpsAccuracyMeters;
  final EdenLatLng? gpsPosition;
  final List<EdenCheckInEvent> events;
  final Future<void> Function(EdenCheckInSubmission)? onSubmit;
  final String? appBarTitle;

  @override
  State<EdenCheckInPage> createState() => _EdenCheckInPageState();
}

class _EdenCheckInPageState extends State<EdenCheckInPage> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasCheckedIn =>
      widget.events.any((e) => e.type == EdenCheckInEventType.checkIn);
  bool get _hasCheckedOut =>
      widget.events.any((e) => e.type == EdenCheckInEventType.checkOut);

  String _qualityLabel(EdenGpsStatus s) {
    switch (s) {
      case EdenGpsStatus.high:
        return 'High';
      case EdenGpsStatus.moderate:
        return 'Moderate';
      case EdenGpsStatus.poor:
        return 'Poor';
      case EdenGpsStatus.unavailable:
        return 'Unavailable';
    }
  }

  EdenBadgeVariant _badgeVariant(EdenGpsStatus s) {
    switch (s) {
      case EdenGpsStatus.high:
        return EdenBadgeVariant.success;
      case EdenGpsStatus.moderate:
        return EdenBadgeVariant.warning;
      case EdenGpsStatus.poor:
        return EdenBadgeVariant.danger;
      case EdenGpsStatus.unavailable:
        return EdenBadgeVariant.neutral;
    }
  }

  Color _dotColor(EdenGpsStatus s) {
    switch (s) {
      case EdenGpsStatus.high:
        return const Color(0xFF22C55E); // green
      case EdenGpsStatus.moderate:
        return const Color(0xFFF59E0B); // amber
      case EdenGpsStatus.poor:
        return const Color(0xFFEF4444); // red
      case EdenGpsStatus.unavailable:
        return const Color(0xFF6B7280); // grey
    }
  }

  /// Hand-rolled 12h clock formatter — replaces donor's `intl`
  /// `DateFormat.jm()`. Avoids adding `intl` to pubspec (constraint 12).
  String _formatTime12h(DateTime dt) {
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $ampm';
  }

  Future<void> _submitCheckIn(EdenCheckInEventType type) async {
    if (widget.gpsStatus == EdenGpsStatus.unavailable ||
        widget.gpsPosition == null) {
      _showError('GPS is not available. Please enable location services.');
      return;
    }
    if (widget.onSubmit == null) return;

    setState(() => _isSubmitting = true);
    try {
      final notes = _notesController.text.trim();
      final submission = EdenCheckInSubmission(
        type: type,
        latitude: widget.gpsPosition!.lat,
        longitude: widget.gpsPosition!.lng,
        accuracy: widget.gpsAccuracyMeters ?? 0.0,
        isGeofenceVerified: widget.gpsStatus == EdenGpsStatus.high,
        notes: notes.isEmpty ? null : notes,
      );
      await widget.onSubmit!.call(submission);
      if (!mounted) return;
      _notesController.clear();
      _showSuccess(type);
    } catch (e) {
      if (!mounted) return;
      final verb =
          type == EdenCheckInEventType.checkIn ? 'check in' : 'check out';
      _showError('Failed to $verb: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
    ));
  }

  void _showSuccess(EdenCheckInEventType type) {
    final msg = type == EdenCheckInEventType.checkIn
        ? 'Checked in successfully'
        : 'Checked out successfully';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCheckedIn = _hasCheckedIn;
    final hasCheckedOut = _hasCheckedOut;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle ?? 'Check In / Out'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Appointment info card
          EdenCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(widget.appointment.icon,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: EdenSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.appointment.title,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.appointment.address,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          // GPS status card
          EdenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EdenSectionHeader(title: 'Location Status'),
                const SizedBox(height: EdenSpacing.space2),
                EdenDescriptionList(items: [
                  EdenDescriptionItem(
                    label: 'GPS Signal',
                    value: _qualityLabel(widget.gpsStatus),
                    valueWidget: EdenBadge(
                      label: _qualityLabel(widget.gpsStatus),
                      variant: _badgeVariant(widget.gpsStatus),
                    ),
                  ),
                  EdenDescriptionItem(
                    label: 'Accuracy',
                    value: widget.gpsAccuracyMeters != null
                        ? '${widget.gpsAccuracyMeters!.toStringAsFixed(1)}m'
                        : '—',
                    valueWidget: widget.gpsAccuracyMeters != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _dotColor(widget.gpsStatus),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  '${widget.gpsAccuracyMeters!.toStringAsFixed(1)}m'),
                            ],
                          )
                        : const Text('—'),
                  ),
                  EdenDescriptionItem(
                    label: 'Coordinates',
                    value: widget.gpsPosition != null
                        ? '${widget.gpsPosition!.lat.toStringAsFixed(5)}, ${widget.gpsPosition!.lng.toStringAsFixed(5)}'
                        : 'Unknown',
                    valueWidget: Text(
                      widget.gpsPosition != null
                          ? '${widget.gpsPosition!.lat.toStringAsFixed(5)}, ${widget.gpsPosition!.lng.toStringAsFixed(5)}'
                          : 'Unknown',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  EdenDescriptionItem(
                    label: 'Geofence',
                    value: widget.gpsStatus == EdenGpsStatus.high
                        ? 'Within geofence'
                        : 'Outside geofence',
                    valueWidget: EdenBadge(
                      label: widget.gpsStatus == EdenGpsStatus.high
                          ? 'Within geofence'
                          : 'Outside geofence',
                      variant: widget.gpsStatus == EdenGpsStatus.high
                          ? EdenBadgeVariant.success
                          : EdenBadgeVariant.warning,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          // Check-in history card
          if (widget.events.isNotEmpty) ...[
            EdenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EdenSectionHeader(
                    title: "Today's Activity",
                    subtitle:
                        '${widget.events.length} event${widget.events.length == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  for (final event in widget.events) _historyRow(event),
                ],
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
          ],

          // Notes input
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any details about this visit',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          // Action button area (state machine)
          if (_isSubmitting)
            const Center(child: EdenSpinner())
          else if (!hasCheckedIn)
            _checkInButton()
          else if (hasCheckedIn && !hasCheckedOut)
            Column(
              children: [
                _checkedInBanner(),
                const SizedBox(height: EdenSpacing.space3),
                _checkOutButton(),
              ],
            )
          else
            _completeContainer(),
        ],
      ),
    );
  }

  Widget _historyRow(EdenCheckInEvent event) {
    final theme = Theme.of(context);
    final isCheckIn = event.type == EdenCheckInEventType.checkIn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: (isCheckIn
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B))
                .withValues(alpha: 0.15),
            child: Icon(
              isCheckIn ? Icons.login : Icons.logout,
              size: 14,
              color:
                  isCheckIn ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isCheckIn ? 'Checked in' : 'Checked out',
                    style: theme.textTheme.bodyMedium),
                Text(_formatTime12h(event.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (event.isGeofenceVerified)
            const EdenBadge(
                label: 'Verified', variant: EdenBadgeVariant.success),
        ],
      ),
    );
  }

  Widget _checkInButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.onSubmit == null
            ? null
            : () => _submitCheckIn(EdenCheckInEventType.checkIn),
        icon: const Icon(Icons.login),
        label: const Text('Check In'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space4),
        ),
      ),
    );
  }

  Widget _checkOutButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.onSubmit == null
            ? null
            : () => _submitCheckIn(EdenCheckInEventType.checkOut),
        icon: const Icon(Icons.logout),
        label: const Text('Check Out'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space4),
        ),
      ),
    );
  }

  Widget _checkedInBanner() {
    final theme = Theme.of(context);
    final firstCheckIn = widget.events
        .firstWhere((e) => e.type == EdenCheckInEventType.checkIn);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              'Checked in at ${_formatTime12h(firstCheckIn.timestamp)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeContainer() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.done_all, color: Color(0xFF3B82F6)),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text('Appointment complete',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

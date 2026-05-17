// Do NOT regenerate via LLM — hand-built appointment fixtures for EdenAppointmentStatusFlow.
// Realistic-but-fabricated appointment scenarios across medical + cross-vertical contexts.
//
// Synthetic patient identifiers:
//   patient-alpha   — primary medical appointment patient
//   patient-bravo   — no-show scenario
//   patient-charlie — late-cancel + cancelled
//   job-12345       — cross-vertical trades job ticket

import 'package:eden_ui_flutter/src/widgets/eden_appointment_status_flow.dart';

class AppointmentFixtures {
  AppointmentFixtures._();

  /// Currently scheduled (in the future, not yet confirmed).
  static EdenAppointmentEvent scheduledFuture({
    String patientId = 'patient-alpha',
    DateTime? scheduledFor,
  }) {
    final when = scheduledFor ?? DateTime(2026, 6, 15, 14, 0);
    return EdenAppointmentEvent(
      id: 'evt-alpha-001',
      patientId: patientId,
      appointmentId: 'appt-alpha-001',
      scheduledFor: when,
      currentStatus: EdenAppointmentStatus.scheduled,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 17, 9, 0),
          actorName: 'Front desk',
        ),
      ],
      providerName: 'Dr. Smith, MD',
      locationName: 'Main Clinic Suite 200',
      visitType: 'Annual physical',
    );
  }

  /// Arrived on-time (within 15 minutes of scheduled).
  static EdenAppointmentEvent arrivedOnTime({
    String patientId = 'patient-alpha',
  }) {
    final scheduledFor = DateTime(2026, 5, 17, 10, 0);
    return EdenAppointmentEvent(
      id: 'evt-alpha-002',
      patientId: patientId,
      appointmentId: 'appt-alpha-002',
      scheduledFor: scheduledFor,
      currentStatus: EdenAppointmentStatus.arrived,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 10, 9, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 15, 18, 30),
          actorName: 'Patient self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.arrived,
          timestamp: DateTime(2026, 5, 17, 9, 58),
          actorName: 'Front desk',
        ),
      ],
      providerName: 'Dr. Smith, MD',
      locationName: 'Main Clinic Suite 200',
      visitType: 'Behavioral health follow-up',
    );
  }

  /// Arrived late (>15 min after scheduledFor). Used with deterministic
  /// `now` injection to verify the late-arrival warning chip.
  static EdenAppointmentEvent arrivedLate({
    String patientId = 'patient-alpha',
  }) {
    final scheduledFor = DateTime(2026, 5, 17, 10, 0);
    return EdenAppointmentEvent(
      id: 'evt-alpha-003',
      patientId: patientId,
      appointmentId: 'appt-alpha-003',
      scheduledFor: scheduledFor,
      currentStatus: EdenAppointmentStatus.arrived,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 10, 9, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 15, 18, 30),
          actorName: 'Patient self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.arrived,
          timestamp: DateTime(2026, 5, 17, 10, 32),
          actorName: 'Front desk',
        ),
      ],
      providerName: 'Dr. Lee, MD',
      locationName: 'Main Clinic Suite 200',
      visitType: 'Annual physical',
    );
  }

  /// Currently in-room (after arrived).
  static EdenAppointmentEvent inRoom({
    String patientId = 'patient-alpha',
  }) {
    return EdenAppointmentEvent(
      id: 'evt-alpha-004',
      patientId: patientId,
      appointmentId: 'appt-alpha-004',
      scheduledFor: DateTime(2026, 5, 17, 11, 0),
      currentStatus: EdenAppointmentStatus.inRoom,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 10, 9, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 15, 18, 30),
          actorName: 'Patient self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.arrived,
          timestamp: DateTime(2026, 5, 17, 10, 55),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.inRoom,
          timestamp: DateTime(2026, 5, 17, 11, 8),
          actorName: 'Front desk',
        ),
      ],
      providerName: 'Dr. Lee, MD',
      locationName: 'Main Clinic Suite 200',
      visitType: 'Annual physical',
    );
  }

  /// Completed (terminal-success).
  static EdenAppointmentEvent completed({
    String patientId = 'patient-alpha',
  }) {
    return EdenAppointmentEvent(
      id: 'evt-alpha-005',
      patientId: patientId,
      appointmentId: 'appt-alpha-005',
      scheduledFor: DateTime(2026, 5, 16, 14, 0),
      currentStatus: EdenAppointmentStatus.completed,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 9, 9, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 14, 18, 30),
          actorName: 'Patient self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.arrived,
          timestamp: DateTime(2026, 5, 16, 13, 58),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.inRoom,
          timestamp: DateTime(2026, 5, 16, 14, 7),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.completed,
          timestamp: DateTime(2026, 5, 16, 14, 52),
          actorName: 'Dr. Smith',
          notes: 'Visit complete; follow-up in 12 months.',
        ),
      ],
      providerName: 'Dr. Smith, MD',
      locationName: 'Main Clinic Suite 200',
      visitType: 'Annual physical',
    );
  }

  /// No-show terminal state.
  static EdenAppointmentEvent noShow({
    String patientId = 'patient-bravo',
  }) {
    return EdenAppointmentEvent(
      id: 'evt-bravo-001',
      patientId: patientId,
      appointmentId: 'appt-bravo-001',
      scheduledFor: DateTime(2026, 5, 16, 9, 0),
      currentStatus: EdenAppointmentStatus.noShow,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 5, 11, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 14, 9, 0),
          actorName: 'Patient self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.noShow,
          timestamp: DateTime(2026, 5, 16, 9, 30),
          actorName: 'Front desk',
          notes: 'Patient did not arrive, no contact.',
        ),
      ],
      providerName: 'Dr. Smith, MD',
      locationName: 'Main Clinic Suite 200',
      visitType: 'Behavioral health follow-up',
    );
  }

  /// Late-cancel (cancelled within 24h of scheduled). Consumer assigns
  /// late-cancel based on its own policy; widget displays it distinctly.
  static EdenAppointmentEvent lateCancel({
    String patientId = 'patient-charlie',
  }) {
    return EdenAppointmentEvent(
      id: 'evt-charlie-001',
      patientId: patientId,
      appointmentId: 'appt-charlie-001',
      scheduledFor: DateTime(2026, 5, 18, 10, 0),
      currentStatus: EdenAppointmentStatus.lateCancel,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 11, 9, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 16, 18, 0),
          actorName: 'Patient self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.lateCancel,
          timestamp: DateTime(2026, 5, 17, 21, 0),
          actorName: 'Patient self-service',
          notes: 'Cancelled via portal 4h before appointment.',
        ),
      ],
      providerName: 'Dr. Patel, ND',
      locationName: 'Wellness Clinic',
      visitType: 'Initial wellness consult',
    );
  }

  /// Cancelled in advance (>24h before scheduled).
  static EdenAppointmentEvent cancelled({
    String patientId = 'patient-charlie',
  }) {
    return EdenAppointmentEvent(
      id: 'evt-charlie-002',
      patientId: patientId,
      appointmentId: 'appt-charlie-002',
      scheduledFor: DateTime(2026, 5, 22, 14, 0),
      currentStatus: EdenAppointmentStatus.cancelled,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 10, 9, 0),
          actorName: 'Front desk',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.cancelled,
          timestamp: DateTime(2026, 5, 15, 11, 0),
          actorName: 'Patient self-service',
          notes: 'Cancelled 5d in advance.',
        ),
      ],
      providerName: 'Dr. Patel, ND',
      locationName: 'Wellness Clinic',
      visitType: 'Initial wellness consult',
    );
  }

  /// Cross-vertical: trades job ticket lifecycle. Same value-class shape;
  /// patientId carries the job id by consumer convention. State labels
  /// remain medical-flavored in v1 (stateLabels override deferred to v2).
  static EdenAppointmentEvent crossVerticalTradesJobTicket({
    String patientId = 'job-12345',
  }) {
    return EdenAppointmentEvent(
      id: 'evt-trades-001',
      patientId: patientId,
      appointmentId: 'job-12345',
      scheduledFor: DateTime(2026, 5, 17, 11, 0),
      currentStatus: EdenAppointmentStatus.arrived,
      statusHistory: [
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.scheduled,
          timestamp: DateTime(2026, 5, 15, 9, 0),
          actorName: 'Dispatch',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.confirmed,
          timestamp: DateTime(2026, 5, 16, 17, 0),
          actorName: 'Customer self-service',
        ),
        EdenAppointmentStatusEntry(
          status: EdenAppointmentStatus.arrived,
          timestamp: DateTime(2026, 5, 17, 11, 5),
          actorName: 'Tech Bob',
          notes: 'On site at customer location.',
        ),
      ],
      providerName: 'Tech Bob',
      locationName: '123 Main St',
      visitType: 'HVAC install',
    );
  }
}

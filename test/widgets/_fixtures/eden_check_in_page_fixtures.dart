// Do NOT regenerate via LLM — hand-built fixtures for EdenCheckInPage.
// Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenCheckInPageFixtures {
  EdenCheckInPageFixtures._();

  static EdenCheckInAppointment apptHvac() => const EdenCheckInAppointment(
        id: 'apt-123',
        title: 'HVAC Repair — Johnson',
        address: '742 Evergreen Terrace',
        icon: Icons.event_available,
      );

  static EdenCheckInAppointment apptMedical() =>
      const EdenCheckInAppointment(
        id: 'apt-med',
        title: 'Wellness Check — Smith',
        address: '14 Park Lane',
        icon: Icons.medical_services_outlined,
      );

  static EdenLatLng sfPos() => const EdenLatLng(lat: 37.7749, lng: -122.4194);

  static EdenCheckInEvent checkInEvent() => EdenCheckInEvent(
        id: 'e1',
        type: EdenCheckInEventType.checkIn,
        timestamp: DateTime(2026, 5, 16, 9, 5),
        isGeofenceVerified: true,
      );

  static EdenCheckInEvent checkOutEvent() => EdenCheckInEvent(
        id: 'e2',
        type: EdenCheckInEventType.checkOut,
        timestamp: DateTime(2026, 5, 16, 11, 30),
        isGeofenceVerified: true,
      );

  static EdenCheckInEvent unverifiedCheckIn() => EdenCheckInEvent(
        id: 'e3',
        type: EdenCheckInEventType.checkIn,
        timestamp: DateTime(2026, 5, 16, 9, 5),
        isGeofenceVerified: false,
      );

  /// Submission recorder.
  static (
    List<EdenCheckInSubmission>,
    Future<void> Function(EdenCheckInSubmission)
  ) recorder() {
    final captured = <EdenCheckInSubmission>[];
    Future<void> submit(EdenCheckInSubmission s) async => captured.add(s);
    return (captured, submit);
  }

  /// Failing submission (always throws).
  static Future<void> Function(EdenCheckInSubmission) failingSubmit(
          String msg) =>
      (_) async => throw Exception(msg);
}

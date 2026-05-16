// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerModels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for scheduler-models tests. Stable / deterministic /
/// reviewable. Used across TRD-01 (models + controller + back-compat).
class EdenSchedulerModelsFixtures {
  EdenSchedulerModelsFixtures._();

  /// Saturday 2026-05-16 09:00 (deterministic "now" for clock injection).
  static final DateTime fixedNow = DateTime(2026, 5, 16, 9, 0);

  /// Monday 2026-05-11 — week-start anchor for the fixed-now week.
  static final DateTime monday = DateTime(2026, 5, 11);

  /// Tuesday 2026-05-12.
  static final DateTime tuesday = DateTime(2026, 5, 12);

  /// Wednesday 2026-05-13.
  static final DateTime wednesday = DateTime(2026, 5, 13);

  /// Sunday 2026-05-17.
  static final DateTime sunday = DateTime(2026, 5, 17);

  /// Event constructed using ONLY back-compat-critical params (id, title,
  /// start, end). MUST keep compiling unchanged across this objective.
  static final EdenSchedulerEvent backCompatEvent = EdenSchedulerEvent(
    id: 'evt-back-compat',
    title: 'Back Compat',
    start: DateTime(2026, 5, 16, 9, 0),
    end: DateTime(2026, 5, 16, 10, 0),
  );

  /// Event with every field populated — legacy fields + new fields.
  static final EdenSchedulerEvent fullEvent = EdenSchedulerEvent(
    id: 'evt-full',
    title: 'Full Event',
    start: DateTime(2026, 5, 16, 9, 0),
    end: DateTime(2026, 5, 16, 10, 0),
    color: const Color(0xFF3B82F6),
    description: 'Full payload',
    assignee: 'Alice',
    status: 'scheduled',
    type: 'maintenance',
    resourceIds: const ['r-47', 'r-12'],
    location: const EdenSchedulerLocation(
      name: 'Site A',
      address: '123 Main St',
      latitude: 33.7490,
      longitude: -84.3880,
    ),
    dispatchIssue: 'Missing helper',
    allDay: false,
    recurrence: EdenSchedulerEventRecurrence.weekly(
      weekdayMask: 1 | 4 | 16, // Mon, Wed, Fri
    ),
    readiness: EdenSchedulerEventReadiness.warning,
  );

  /// Three events on the same day — two overlap (TG-7 conflict layout fodder).
  static final List<EdenSchedulerEvent> threeEventsDay = [
    EdenSchedulerEvent(
      id: 'evt-a',
      title: '9-10 AM',
      start: DateTime(2026, 5, 16, 9, 0),
      end: DateTime(2026, 5, 16, 10, 0),
    ),
    EdenSchedulerEvent(
      id: 'evt-b',
      title: '10-11 AM',
      start: DateTime(2026, 5, 16, 10, 0),
      end: DateTime(2026, 5, 16, 11, 0),
    ),
    EdenSchedulerEvent(
      id: 'evt-c',
      title: '9:30-10:30 AM',
      start: DateTime(2026, 5, 16, 9, 30),
      end: DateTime(2026, 5, 16, 10, 30),
    ),
  ];

  /// Resource fixture — Truck 47, blue tint.
  static const EdenSchedulerResource truck47 = EdenSchedulerResource(
    id: 'r-47',
    name: 'Truck 47',
    color: Color(0xFF3B82F6),
  );

  /// Resource group fixture — Service team.
  static const EdenSchedulerResourceGroup serviceTeam =
      EdenSchedulerResourceGroup(
    id: 'g-svc',
    name: 'Service',
    sortOrder: 0,
  );

  /// Availability block — truck 47 in maintenance 1-3 PM Sat 2026-05-16.
  static final EdenSchedulerAvailabilityBlock truck47Maintenance =
      EdenSchedulerAvailabilityBlock(
    id: 'b-maint-1',
    resourceId: 'r-47',
    start: DateTime(2026, 5, 16, 13, 0),
    end: DateTime(2026, 5, 16, 15, 0),
    kind: EdenSchedulerAvailabilityKind.maintenance,
    label: 'Brake service',
  );

  /// Recurrence — weekly Mon/Wed/Fri.
  static final EdenSchedulerEventRecurrence weeklyMonWedFri =
      EdenSchedulerEventRecurrence.weekly(weekdayMask: 1 | 4 | 16);

  /// Builds an [EdenSchedulerController] with deterministic clock.
  static EdenSchedulerController controllerWith({
    EdenSchedulerView view = EdenSchedulerView.week,
    DateTime? focusedDate,
    DateTime Function()? clock,
  }) {
    return EdenSchedulerController(
      initialView: view,
      initialDate: focusedDate ?? monday,
      clock: clock ?? () => fixedNow,
    );
  }
}

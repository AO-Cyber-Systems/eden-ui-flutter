import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// View modes for [EdenScheduler]. Existing variants (`month`, `week`, `day`)
/// MUST remain at the same identifier (back-compat critical — see
/// `eden_scheduler_back_compat_test.dart`). New variants append below.
///
/// Index map (locked):
/// - 0: month
/// - 1: week
/// - 2: workWeek
/// - 3: day
/// - 4: list
/// - 5: mobile
/// - 6: swimlane
enum EdenSchedulerView {
  /// Monthly calendar grid with event-dot indicators.
  month,

  /// Seven-column time grid (Sun..Sat or week-locale start).
  week,

  /// Five-column time grid (Mon..Fri).
  workWeek,

  /// Single-column time grid for one day.
  day,

  /// Chronological list view (date headers + events).
  list,

  /// Compact mobile day-focused view (truck-chip strip + swipe nav).
  mobile,

  /// Multi-resource swimlane (resource = column, multi-week span).
  swimlane,
}

/// Dispatch-readiness state for an event block (border-color hint).
/// Mirrors donor `DispatchReadiness` (`EnhancedCalendar.tsx:358`).
enum EdenSchedulerEventReadiness { ready, warning, urgent }

/// Kind of [EdenSchedulerAvailabilityBlock]. Mirrors donor `ScheduleBlock.kind`.
enum EdenSchedulerAvailabilityKind { available, blocked, maintenance }

/// Recurrence kind for v1 — none / daily / weekly only. Monthly/yearly
/// deferred to a future objective.
enum EdenSchedulerRecurrenceKind { none, daily, weekly }

/// A location associated with an event. Cross-vertical:
/// - trades: site address + lat/lng,
/// - salon: "Chair 3" (just name),
/// - medical: "Exam Room 4" (just name),
/// - fuel: job-site lat/lng.
@immutable
class EdenSchedulerLocation {
  const EdenSchedulerLocation({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
}

/// A resource (truck, stylist, provider, room, vehicle, etc.) that events can
/// be assigned to. Generic — strip trades-specific fields. Mirrors donor
/// `TruckData`.
@immutable
class EdenSchedulerResource {
  const EdenSchedulerResource({
    required this.id,
    required this.name,
    this.color,
    this.group,
    this.crew,
  });

  final String id;
  final String name;
  final Color? color;
  final EdenSchedulerResourceGroup? group;
  final List<String>? crew;
}

/// A grouping for resources (truck category, salon team, medical specialty,
/// fuel depot). Mirrors donor `TruckCategory`.
@immutable
class EdenSchedulerResourceGroup {
  const EdenSchedulerResourceGroup({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int sortOrder;
}

/// A recurrence rule for events. v1 scope: none / daily / weekly. RRULE
/// expansion beyond weekly is deferred — file a follow-up TRD if a downstream
/// app needs monthly / yearly recurrence.
///
/// Weekday bitmask convention (matches `DateTime.weekday`):
/// - Mon = 1 (bit 0)
/// - Tue = 2 (bit 1)
/// - Wed = 4 (bit 2)
/// - Thu = 8 (bit 3)
/// - Fri = 16 (bit 4)
/// - Sat = 32 (bit 5)
/// - Sun = 64 (bit 6)
@immutable
class EdenSchedulerEventRecurrence {
  const EdenSchedulerEventRecurrence._({
    required this.kind,
    this.weekdayMask = 0,
    this.until,
  });

  factory EdenSchedulerEventRecurrence.none() =>
      const EdenSchedulerEventRecurrence._(kind: EdenSchedulerRecurrenceKind.none);

  factory EdenSchedulerEventRecurrence.daily({DateTime? until}) =>
      EdenSchedulerEventRecurrence._(
        kind: EdenSchedulerRecurrenceKind.daily,
        until: until,
      );

  factory EdenSchedulerEventRecurrence.weekly({
    required int weekdayMask,
    DateTime? until,
  }) =>
      EdenSchedulerEventRecurrence._(
        kind: EdenSchedulerRecurrenceKind.weekly,
        weekdayMask: weekdayMask,
        until: until,
      );

  final EdenSchedulerRecurrenceKind kind;

  /// Bitmask of weekdays this recurrence fires on (only meaningful when
  /// [kind] is [EdenSchedulerRecurrenceKind.weekly]).
  final int weekdayMask;

  /// Inclusive end date (clock semantics: the LAST date that may emit an
  /// occurrence). Null means "no end" (cap externally via the visible range).
  final DateTime? until;

  /// Returns true if [weekday] (1..7, Mon=1) is included in [weekdayMask].
  /// Always false for non-weekly recurrences or out-of-range weekday values.
  bool matchesWeekday(int weekday) {
    if (kind != EdenSchedulerRecurrenceKind.weekly) return false;
    if (weekday < 1 || weekday > 7) return false;
    final bit = 1 << (weekday - 1);
    return (weekdayMask & bit) != 0;
  }
}

/// An availability block for a resource (e.g. truck maintenance window,
/// stylist time-off, provider on-call). Mirrors donor `ScheduleBlock`.
@immutable
class EdenSchedulerAvailabilityBlock {
  const EdenSchedulerAvailabilityBlock({
    required this.id,
    required this.resourceId,
    required this.start,
    required this.end,
    required this.kind,
    this.label,
  });

  final String id;
  final String resourceId;
  final DateTime start;
  final DateTime end;
  final EdenSchedulerAvailabilityKind kind;
  final String? label;
}

/// An event displayed in [EdenScheduler].
///
/// Back-compat: legacy positional/named params (id, title, start, end, color,
/// description, assignee) preserved with identical semantics. New optional
/// params: status, type, resourceIds, location, dispatchIssue, allDay,
/// recurrence, readiness.
@immutable
class EdenSchedulerEvent {
  const EdenSchedulerEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.color,
    this.description,
    this.assignee,
    this.status,
    this.type,
    this.resourceIds,
    this.location,
    this.dispatchIssue,
    this.allDay = false,
    this.recurrence,
    this.readiness,
  });

  /// Unique identifier.
  final String id;

  /// Short title displayed on the event block.
  final String title;

  /// Start date and time.
  final DateTime start;

  /// End date and time.
  final DateTime end;

  /// Accent color for the event block. Falls back to theme primary.
  final Color? color;

  /// Optional longer description shown in day view.
  final String? description;

  /// Optional assignee name used for filtering.
  final String? assignee;

  /// Free-form status string (e.g. trades `'scheduled' | 'in_progress' |
  /// 'completed' | 'cancelled' | 'pending_review'`, salon `'booked' | ...`).
  /// Each vertical owns its taxonomy.
  final String? status;

  /// Free-form event type (e.g. `'service' | 'maintenance' | 'project'`).
  final String? type;

  /// Resource ids this event is assigned to. Generic ids — consumer maps
  /// domain ids (int / uuid / slug) to string at the boundary.
  final List<String>? resourceIds;

  /// Optional location detail (site address, room label, lat/lng).
  final EdenSchedulerLocation? location;

  /// Human-readable string describing a dispatch issue, e.g. "Missing helper".
  /// Renders as a small badge / icon on the event block.
  final String? dispatchIssue;

  /// True when the event has no fixed time-of-day (renders in the all-day row
  /// above the hour grid).
  final bool allDay;

  /// Recurrence rule. Null = single occurrence.
  final EdenSchedulerEventRecurrence? recurrence;

  /// Dispatch-readiness state for border-color hint.
  final EdenSchedulerEventReadiness? readiness;

  /// Duration in minutes.
  int get durationMinutes => end.difference(start).inMinutes;
}

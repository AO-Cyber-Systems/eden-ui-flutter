// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerTimeMath.

import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built DateTime + recurrence fixtures for time-math tests. Stable /
/// deterministic / reviewable. Covers DST, month boundaries, year boundaries,
/// leap day, and the canonical recurrence shapes.
class EdenSchedulerTimeMathFixtures {
  EdenSchedulerTimeMathFixtures._();

  /// US 2026 spring-forward — Sunday 2026-03-08 at 2 AM clock-skip.
  static final DateTime springForward2026 = DateTime(2026, 3, 8, 2);

  /// US 2026 fall-back — Sunday 2026-11-01 at 2 AM clock-repeat.
  static final DateTime fallBack2026 = DateTime(2026, 11, 1, 2);

  /// Month boundary — last day of Jan 2026.
  static final DateTime jan31_2026 = DateTime(2026, 1, 31);

  /// Year boundary — Dec 31 2026.
  static final DateTime dec31_2026 = DateTime(2026, 12, 31);

  /// Leap day fixture — 2024-02-29.
  static final DateTime leapDay = DateTime(2024, 2, 29);

  /// Monday 2026-03-09 (week-start anchor).
  static final DateTime mon2026Mar09 = DateTime(2026, 3, 9);

  /// Tuesday 2026-03-10.
  static final DateTime tue2026Mar10 = DateTime(2026, 3, 10);

  /// Wednesday 2026-03-11.
  static final DateTime wed2026Mar11 = DateTime(2026, 3, 11);

  /// Sunday 2026-03-08 (the spring-forward Sunday).
  static final DateTime sun2026Mar08 = DateTime(2026, 3, 8);

  /// Sunday 2026-03-15 (one week after spring-forward).
  static final DateTime sun2026Mar15 = DateTime(2026, 3, 15);

  /// Event with no recurrence — Mon 2026-03-09 9-10 AM.
  static final EdenSchedulerEvent noRecurrenceEvent = EdenSchedulerEvent(
    id: 'evt-once',
    title: 'One-shot',
    start: DateTime(2026, 3, 9, 9, 0),
    end: DateTime(2026, 3, 9, 10, 0),
  );

  /// Event that recurs daily, no until — starts Mon 2026-03-09 9 AM.
  static final EdenSchedulerEvent dailyEvent = EdenSchedulerEvent(
    id: 'evt-daily',
    title: 'Daily',
    start: DateTime(2026, 3, 9, 9, 0),
    end: DateTime(2026, 3, 9, 10, 0),
    recurrence: EdenSchedulerEventRecurrence.daily(),
  );

  /// Event that recurs daily with until=2026-03-11 (inclusive).
  static final EdenSchedulerEvent dailyUntilEvent = EdenSchedulerEvent(
    id: 'evt-daily-until',
    title: 'Daily 3 days',
    start: DateTime(2026, 3, 9, 9, 0),
    end: DateTime(2026, 3, 9, 10, 0),
    recurrence: EdenSchedulerEventRecurrence.daily(
      until: DateTime(2026, 3, 11),
    ),
  );

  /// Weekly Mon/Wed/Fri at 9 AM, starting Mon 2026-03-09.
  static final EdenSchedulerEvent weeklyMonWedFriEvent = EdenSchedulerEvent(
    id: 'evt-weekly-mwf',
    title: 'Mon/Wed/Fri',
    start: DateTime(2026, 3, 9, 9, 0),
    end: DateTime(2026, 3, 9, 10, 0),
    recurrence: EdenSchedulerEventRecurrence.weekly(
      weekdayMask: 1 | 4 | 16, // Mon, Wed, Fri
    ),
  );

  /// Weekly Sundays at 9 AM, starting Sun 2026-03-08 (DST spring-forward).
  static final EdenSchedulerEvent weeklySunEvent = EdenSchedulerEvent(
    id: 'evt-weekly-sun',
    title: 'Sunday',
    start: DateTime(2026, 3, 8, 9, 0),
    end: DateTime(2026, 3, 8, 10, 0),
    recurrence: EdenSchedulerEventRecurrence.weekly(
      weekdayMask: 64, // Sun
    ),
  );
}

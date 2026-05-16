import 'scheduler_models.dart';

/// Pure-Dart time + date helpers for [EdenScheduler]. Mirrors the donor
/// `yDeltaPxToMinutes` / `addMinutesToTime` / `formatTime` helpers from
/// `EnhancedCalendar.tsx:213-277`.
///
/// All helpers are stateless static methods so they can be invoked from view
/// widgets, drag handlers, and recurrence-expansion code without instantiating
/// anything.
///
/// **Wall-clock semantics.** [addDays] returns the SAME hour/minute on the
/// next calendar day, not 24 hours later. This avoids DST drift that
/// `Duration(days: N)` would introduce (Dart `Duration` is a fixed delta in
/// microseconds and does not respect daylight-saving transitions). For
/// scheduler views, "tomorrow at the same time" means same wall-clock time on
/// the next calendar day — `addDays` preserves that.
class EdenSchedulerTimeMath {
  const EdenSchedulerTimeMath._();

  /// Convert a vertical pixel delta to a 15-minute-snapped minute count.
  /// Mirrors donor `yDeltaPxToMinutes` (`EnhancedCalendar.tsx:213`).
  ///
  /// Returns 0 when [hourHeight] is 0 or negative (defensive guard against
  /// uninitialized layout constraints).
  static int yDeltaPxToMinutes(double deltaPx, double hourHeight) {
    if (hourHeight <= 0) return 0;
    final raw = (deltaPx / hourHeight) * 60;
    return (raw / 15).round() * 15;
  }

  /// Add minutes to an "HH:MM" 24-hour time string. Clamps the result to the
  /// closed interval `[00:00, 23:45]`. Mirrors donor `addMinutesToTime`
  /// (`EnhancedCalendar.tsx:218`).
  ///
  /// Throws [FormatException] on malformed input (missing colon, non-numeric
  /// components). Donor returned a clamped result; we fail-fast (Dart culture).
  static String addMinutesToTime(String time, int minutes) {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Expected HH:MM, got: $time');
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) {
      throw FormatException('Non-numeric HH:MM components: $time');
    }
    final total = h * 60 + m + minutes;
    final clamped = total.clamp(0, 24 * 60 - 15);
    final nh = clamped ~/ 60;
    final nm = clamped % 60;
    return '${nh.toString().padLeft(2, '0')}:'
        '${nm.toString().padLeft(2, '0')}';
  }

  /// Format an "HH:MM" 24-hour time string as "h:mm AM/PM" preserving minutes.
  /// Mirrors donor `formatTime` (`EnhancedCalendar.tsx:268`) — donor fix for
  /// the E11a "9 AM truncation" bug. Returns the empty string for null,
  /// empty, or invalid input.
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length < 2) return '';
    final hour = int.tryParse(parts[0]);
    if (hour == null) return '';
    final minutePart = parts[1].length >= 2 ? parts[1].substring(0, 2) : parts[1];
    if (int.tryParse(minutePart) == null) return '';
    final mStr = minutePart.padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:$mStr $ampm';
  }

  /// Returns [d] with hour/minute/second/ms stripped (date-only).
  static DateTime stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns the Monday of the week containing [d] (Mon = 1 convention
  /// matching `DateTime.weekday`). Wall-clock midnight.
  static DateTime startOfWeek(DateTime d) {
    final stripped = stripTime(d);
    return stripped.subtract(Duration(days: stripped.weekday - 1));
  }

  /// Wall-clock add-days. Preserves hour/min/sec on the resulting date,
  /// avoiding DST drift that `Duration(days: N)` would introduce.
  static DateTime addDays(DateTime d, int days) => DateTime(
        d.year,
        d.month,
        d.day + days,
        d.hour,
        d.minute,
        d.second,
        d.millisecond,
      );

  /// Expand a recurring event into individual occurrences within
  /// `[rangeStart, rangeEnd)`. For each emission day, the occurrence's
  /// year/month/day comes from the cursor while the hour/minute/duration come
  /// from the original event (wall-clock semantics — preserves 9 AM across
  /// DST transitions).
  ///
  /// Occurrence ids are suffixed with `@<iso-date>` for uniqueness. The
  /// original event's id is recoverable by stripping after `@`.
  ///
  /// For non-recurring events (recurrence == null OR kind == none), emits
  /// the event itself iff it overlaps the range.
  ///
  /// Safety bound: emits at most 1000 occurrences per call to guard against
  /// runaway loops if [rangeEnd] is malformed.
  static List<EdenSchedulerEvent> expandRecurrence(
    EdenSchedulerEvent event,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final recurrence = event.recurrence;
    if (recurrence == null ||
        recurrence.kind == EdenSchedulerRecurrenceKind.none) {
      // Single occurrence — emit only if event overlaps the range.
      if (event.start.isBefore(rangeEnd) && event.end.isAfter(rangeStart)) {
        return [event];
      }
      return const [];
    }

    final duration = event.end.difference(event.start);
    final until = recurrence.until;
    // hardEnd is the inclusive end of expansion. For "until", we add one day so
    // an occurrence ON the until date is emitted.
    DateTime hardEnd = rangeEnd;
    if (until != null) {
      final untilExclusive = stripTime(until).add(const Duration(days: 1));
      if (untilExclusive.isBefore(rangeEnd)) hardEnd = untilExclusive;
    }

    final occurrences = <EdenSchedulerEvent>[];
    DateTime cursor = stripTime(event.start);
    final rangeStartDay = stripTime(rangeStart);

    while (cursor.isBefore(hardEnd)) {
      final shouldEmit = switch (recurrence.kind) {
        EdenSchedulerRecurrenceKind.daily => true,
        EdenSchedulerRecurrenceKind.weekly =>
          recurrence.matchesWeekday(cursor.weekday),
        EdenSchedulerRecurrenceKind.none => false,
      };

      if (shouldEmit && !cursor.isBefore(rangeStartDay)) {
        final occStart = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          event.start.hour,
          event.start.minute,
          event.start.second,
        );
        final occEnd = occStart.add(duration);
        occurrences.add(EdenSchedulerEvent(
          id: '${event.id}@${stripTime(cursor).toIso8601String()}',
          title: event.title,
          start: occStart,
          end: occEnd,
          color: event.color,
          description: event.description,
          assignee: event.assignee,
          status: event.status,
          type: event.type,
          resourceIds: event.resourceIds,
          location: event.location,
          dispatchIssue: event.dispatchIssue,
          allDay: event.allDay,
          recurrence: event.recurrence,
          readiness: event.readiness,
        ));
      }

      cursor = addDays(cursor, 1);
      if (occurrences.length > 1000) break;
    }

    return occurrences;
  }
}

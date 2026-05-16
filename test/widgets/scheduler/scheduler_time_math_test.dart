// Hand-built tests (no LLM-generated test data) for EdenSchedulerTimeMath.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_time_math_fixtures.dart';

void main() {
  group('EdenSchedulerTimeMath.yDeltaPxToMinutes', () {
    test('deltaPx=0 → 0 minutes', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(0, 60), 0);
    });
    test('60px at 60ph → 60 minutes', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(60, 60), 60);
    });
    test('30px at 60ph → 30 minutes', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(30, 60), 30);
    });
    test('15px at 60ph → 15 minutes', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(15, 60), 15);
    });
    test('20px at 60ph → 15 minutes (rounds 1.33 → 1 → ×15)', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(20, 60), 15);
    });
    test('22px at 60ph → 15 minutes (22/15 ≈ 1.46 → rounds to 1)', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(22, 60), 15);
    });
    test('23px at 60ph → 30 minutes (23/15 ≈ 1.53 → rounds to 2)', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(23, 60), 30);
    });
    test('-15px (negative delta = drag up) → -15', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(-15, 60), -15);
    });
    test('45px → 45 minutes exact', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(45, 60), 45);
    });
    test('120px → 120 minutes (2 hours)', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(120, 60), 120);
    });
    test('hourHeight=0 guard → 0', () {
      expect(EdenSchedulerTimeMath.yDeltaPxToMinutes(60, 0), 0);
    });
  });

  group('EdenSchedulerTimeMath.addMinutesToTime', () {
    test('09:00 + 30 → 09:30', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('09:00', 30), '09:30');
    });
    test('09:30 + 30 → 10:00', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('09:30', 30), '10:00');
    });
    test('09:30 - 30 → 09:00', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('09:30', -30), '09:00');
    });
    test('09:30 - 90 → 08:00', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('09:30', -90), '08:00');
    });
    test('00:00 - 30 → 00:00 (clamp lower)', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('00:00', -30), '00:00');
    });
    test('23:30 + 30 → 23:45 (clamp upper)', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('23:30', 30), '23:45');
    });
    test('23:45 + 30 → 23:45 (clamp upper, no overflow)', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('23:45', 30), '23:45');
    });
    test('12:00 + 720 → 23:45 (clamp from 24:00)', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('12:00', 720), '23:45');
    });
    test('14:00 + 0 → 14:00 (no-op identity)', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('14:00', 0), '14:00');
    });
    test('00:30 - 60 → 00:00 (negative clamp)', () {
      expect(EdenSchedulerTimeMath.addMinutesToTime('00:30', -60), '00:00');
    });
    test('malformed input throws FormatException', () {
      expect(
        () => EdenSchedulerTimeMath.addMinutesToTime('not-a-time', 30),
        throwsFormatException,
      );
    });
  });

  group('EdenSchedulerTimeMath.formatTime', () {
    test('09:30 → 9:30 AM', () {
      expect(EdenSchedulerTimeMath.formatTime('09:30'), '9:30 AM');
    });
    test('09:00 → 9:00 AM', () {
      expect(EdenSchedulerTimeMath.formatTime('09:00'), '9:00 AM');
    });
    test('12:00 → 12:00 PM (noon)', () {
      expect(EdenSchedulerTimeMath.formatTime('12:00'), '12:00 PM');
    });
    test('12:30 → 12:30 PM', () {
      expect(EdenSchedulerTimeMath.formatTime('12:30'), '12:30 PM');
    });
    test('00:00 → 12:00 AM (midnight)', () {
      expect(EdenSchedulerTimeMath.formatTime('00:00'), '12:00 AM');
    });
    test('00:30 → 12:30 AM', () {
      expect(EdenSchedulerTimeMath.formatTime('00:30'), '12:30 AM');
    });
    test('13:45 → 1:45 PM (preserve minutes — donor E11a fix)', () {
      expect(EdenSchedulerTimeMath.formatTime('13:45'), '1:45 PM');
    });
    test('23:59 → 11:59 PM', () {
      expect(EdenSchedulerTimeMath.formatTime('23:59'), '11:59 PM');
    });
    test('null → empty string', () {
      expect(EdenSchedulerTimeMath.formatTime(null), '');
    });
    test('empty → empty string', () {
      expect(EdenSchedulerTimeMath.formatTime(''), '');
    });
    test('"invalid" → empty string', () {
      expect(EdenSchedulerTimeMath.formatTime('invalid'), '');
    });
  });

  group('EdenSchedulerTimeMath.stripTime', () {
    test('strips H/M/S/MS', () {
      expect(
        EdenSchedulerTimeMath.stripTime(DateTime(2026, 3, 9, 14, 30, 45, 123)),
        DateTime(2026, 3, 9),
      );
    });
    test('idempotent on already-stripped dates', () {
      expect(
        EdenSchedulerTimeMath.stripTime(DateTime(2026, 3, 9)),
        DateTime(2026, 3, 9),
      );
    });
  });

  group('EdenSchedulerTimeMath.startOfWeek', () {
    test('Wed → previous Mon (same week)', () {
      expect(
        EdenSchedulerTimeMath.startOfWeek(DateTime(2026, 3, 11)),
        DateTime(2026, 3, 9),
      );
    });
    test('Sun → previous Mon (start-of-week Mon convention)', () {
      // Sun 2026-03-08 is weekday=7; previous Mon is 2026-03-02.
      expect(
        EdenSchedulerTimeMath.startOfWeek(DateTime(2026, 3, 8)),
        DateTime(2026, 3, 2),
      );
    });
    test('DST spring-forward Sunday → previous Mon (wall-clock)', () {
      expect(
        EdenSchedulerTimeMath.startOfWeek(
          EdenSchedulerTimeMathFixtures.springForward2026,
        ),
        DateTime(2026, 3, 2),
      );
    });
  });

  group('EdenSchedulerTimeMath.addDays (wall-clock)', () {
    test('+1 day on spring-forward Sat preserves wall-clock hour', () {
      final result = EdenSchedulerTimeMath.addDays(
        DateTime(2026, 3, 7, 9, 0),
        1,
      );
      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 8);
      expect(result.hour, 9);
      expect(result.minute, 0);
    });

    test('+1 day across leap day Feb 29 → Mar 1', () {
      final result = EdenSchedulerTimeMath.addDays(
        EdenSchedulerTimeMathFixtures.leapDay,
        1,
      );
      expect(result, DateTime(2024, 3, 1));
    });

    test('+1 day across year boundary Dec 31 → Jan 1', () {
      final result = EdenSchedulerTimeMath.addDays(
        EdenSchedulerTimeMathFixtures.dec31_2026,
        1,
      );
      expect(result, DateTime(2027, 1, 1));
    });

    test('-1 day across month boundary Mar 1 → Feb 28', () {
      final result = EdenSchedulerTimeMath.addDays(DateTime(2026, 3, 1), -1);
      expect(result, DateTime(2026, 2, 28));
    });
  });

  group('EdenSchedulerTimeMath.expandRecurrence', () {
    test('no recurrence + in range → 1 occurrence', () {
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.noRecurrenceEvent,
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 14),
      );
      expect(out.length, 1);
      expect(out.single.id, 'evt-once');
    });

    test('no recurrence + out of range → 0 occurrences', () {
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.noRecurrenceEvent,
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 7),
      );
      expect(out, isEmpty);
    });

    test('recurrence.none() behaves like null', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: DateTime(2026, 3, 9, 9, 0),
        end: DateTime(2026, 3, 9, 10, 0),
        recurrence: EdenSchedulerEventRecurrence.none(),
      );
      final out = EdenSchedulerTimeMath.expandRecurrence(
        e,
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 14),
      );
      expect(out.length, 1);
    });

    test('daily, no until — emits one per day in range [Mon..Fri)', () {
      // Range [Mar 9 Mon, Mar 14 Sat) = 5 days.
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.dailyEvent,
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 14),
      );
      expect(out.length, 5);
      // First occurrence preserves 9 AM wall-clock.
      expect(out.first.start.hour, 9);
      expect(out.first.start.minute, 0);
    });

    test('daily with until=Mar 11 — emits 3 occurrences (Mar 9, 10, 11)', () {
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.dailyUntilEvent,
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 14),
      );
      expect(out.length, 3);
    });

    test('weekly Mon|Wed|Fri across 2 weeks emits 6 occurrences', () {
      // Range [Mar 9 Mon, Mar 23 Mon) = 2 weeks. Mon/Wed/Fri × 2 weeks = 6.
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.weeklyMonWedFriEvent,
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 23),
      );
      expect(out.length, 6);
      // Verify weekday assignment.
      for (final occ in out) {
        expect([1, 3, 5].contains(occ.start.weekday), isTrue,
            reason: 'Expected Mon=1/Wed=3/Fri=5, got weekday=${occ.start.weekday}');
      }
    });

    test('weekly Sun across 2 weeks emits 2 occurrences (Mar 8, 15)', () {
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.weeklySunEvent,
        DateTime(2026, 3, 8),
        DateTime(2026, 3, 22),
      );
      expect(out.length, 2);
      expect(out[0].start.day, 8);
      expect(out[1].start.day, 15);
    });

    test('occurrence id is suffixed with @iso-date for uniqueness', () {
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.dailyEvent,
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 11),
      );
      expect(out.first.id, contains('@'));
      expect(out.first.id, startsWith('evt-daily@'));
    });

    test('DST spring-forward — weekly Sun at 9 AM preserves wall-clock', () {
      final out = EdenSchedulerTimeMath.expandRecurrence(
        EdenSchedulerTimeMathFixtures.weeklySunEvent,
        DateTime(2026, 3, 8),
        DateTime(2026, 3, 22),
      );
      // All emitted occurrences should be at exactly 9:00 wall-clock.
      for (final occ in out) {
        expect(occ.start.hour, 9);
        expect(occ.start.minute, 0);
      }
    });
  });
}

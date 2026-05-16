// Hand-built tests (no LLM-generated test data) for EdenSchedulerEventLayer.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

List<EdenSchedulerEvent> _nEvents(int n, {DateTime? on}) {
  final day = on ?? DateTime(2026, 5, 16);
  return List.generate(n, (i) {
    final hour = 6 + (i % 14);
    final minute = (i * 15) % 60;
    return EdenSchedulerEvent(
      id: 'event-$i',
      title: 'Event $i',
      start: DateTime(day.year, day.month, day.day, hour, minute),
      end: DateTime(day.year, day.month, day.day, hour, minute + 30),
    );
  });
}

void main() {
  setUp(() => EdenSchedulerEventLayer.clearCache());

  group('EdenSchedulerEventLayer.layoutWithCache', () {
    test('returns conflict placements for events', () {
      final placements = EdenSchedulerEventLayer.layoutWithCache(_nEvents(3));
      expect(placements.length, 3);
      for (final id in ['event-0', 'event-1', 'event-2']) {
        expect(placements.containsKey(id), isTrue);
      }
    });

    test('cache hit on second call with same events', () {
      final events = _nEvents(3);
      EdenSchedulerEventLayer.layoutWithCache(events);
      expect(EdenSchedulerEventLayer.computeCalls, 1);
      EdenSchedulerEventLayer.layoutWithCache(events);
      expect(EdenSchedulerEventLayer.computeCalls, 1);
    });

    test('cache miss on different event list', () {
      EdenSchedulerEventLayer.layoutWithCache(_nEvents(3));
      EdenSchedulerEventLayer.layoutWithCache(_nEvents(5));
      expect(EdenSchedulerEventLayer.computeCalls, 2);
    });

    test('below threshold renders all events (no culling)', () {
      // 10 events, threshold 50 — no culling even with viewport set.
      final placements = EdenSchedulerEventLayer.layoutWithCache(
        _nEvents(10),
        cullingThreshold: 50,
        viewportTopY: 0,
        viewportHeight: 60,
      );
      expect(placements.length, 10);
    });

    test('at/above threshold with viewport culls off-screen events', () {
      // 100 events spread 6 AM..8 PM. Viewport y=[600, 660] = 1 hour at 10AM..11AM.
      // slotHeight=60, startHour=6 → y=600 = 4 hours = 10 AM.
      final placements = EdenSchedulerEventLayer.layoutWithCache(
        _nEvents(100),
        cullingThreshold: 50,
        viewportTopY: 240, // 4 hours = 10 AM
        viewportHeight: 60, // 1 hour = 10 AM..11 AM
      );
      expect(placements.length, lessThan(100));
    });
  });

  group('EdenSchedulerEventLayer.expandRecurrenceCached', () {
    test('first call is a miss; second is a hit', () {
      final event = EdenSchedulerEvent(
        id: 'r',
        title: 'Weekly',
        start: DateTime(2026, 5, 11, 9),
        end: DateTime(2026, 5, 11, 10),
        recurrence: EdenSchedulerEventRecurrence.weekly(weekdayMask: 1),
      );
      final start = DateTime(2026, 5, 11);
      final end = DateTime(2026, 5, 25);
      EdenSchedulerEventLayer.expandRecurrenceCached(event, start, end);
      expect(EdenSchedulerEventLayer.recurrenceComputeCalls, 1);
      EdenSchedulerEventLayer.expandRecurrenceCached(event, start, end);
      expect(EdenSchedulerEventLayer.recurrenceComputeCalls, 1);
    });

    test('different range causes a miss', () {
      final event = EdenSchedulerEvent(
        id: 'r',
        title: 'Weekly',
        start: DateTime(2026, 5, 11, 9),
        end: DateTime(2026, 5, 11, 10),
        recurrence: EdenSchedulerEventRecurrence.weekly(weekdayMask: 1),
      );
      EdenSchedulerEventLayer.expandRecurrenceCached(
        event,
        DateTime(2026, 5, 11),
        DateTime(2026, 5, 25),
      );
      EdenSchedulerEventLayer.expandRecurrenceCached(
        event,
        DateTime(2026, 5, 25),
        DateTime(2026, 6, 8),
      );
      expect(EdenSchedulerEventLayer.recurrenceComputeCalls, 2);
    });
  });

  group('EdenSchedulerEventLayer.clearCache', () {
    test('resets compute call counters', () {
      EdenSchedulerEventLayer.layoutWithCache(_nEvents(3));
      expect(EdenSchedulerEventLayer.computeCalls, 1);
      EdenSchedulerEventLayer.clearCache();
      expect(EdenSchedulerEventLayer.computeCalls, 0);
    });
  });

  group('EdenSchedulerEventLayer performance budget', () {
    test('500 events layout completes within 200ms', () {
      final events = _nEvents(500);
      final sw = Stopwatch()..start();
      EdenSchedulerEventLayer.layoutWithCache(events);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });
}

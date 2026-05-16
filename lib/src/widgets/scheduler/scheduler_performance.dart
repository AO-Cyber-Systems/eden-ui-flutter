import 'package:flutter/foundation.dart';

import 'scheduler_conflict_layout.dart';
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';

/// Performance helpers for [EdenScheduler]: viewport culling, conflict-layout
/// memoization, and recurrence-expansion cache (parity rows P-1, P-2).
class EdenSchedulerEventLayer {
  EdenSchedulerEventLayer._();

  /// Default minimum event-count before viewport culling kicks in.
  static const int defaultCullingThreshold = 50;

  /// LRU cap for the conflict-layout cache (per (eventList-fingerprint)).
  static const int _layoutCacheCap = 256;

  /// LRU cap for the recurrence-expansion cache.
  static const int _recurrenceCacheCap = 1024;

  static final Map<String, Map<String, ConflictPlacement>> _layoutCache = {};
  static final List<String> _layoutCacheOrder = [];
  static final Map<String, List<EdenSchedulerEvent>> _recurrenceCache = {};
  static final List<String> _recurrenceCacheOrder = [];

  /// Bumped on every miss. Test-only counter.
  @visibleForTesting
  static int computeCalls = 0;

  /// Bumped on every recurrence-cache miss. Test-only counter.
  @visibleForTesting
  static int recurrenceComputeCalls = 0;

  /// Clear all caches. MUST be called in test `setUp` to avoid cross-test
  /// contamination.
  static void clearCache() {
    _layoutCache.clear();
    _layoutCacheOrder.clear();
    _recurrenceCache.clear();
    _recurrenceCacheOrder.clear();
    computeCalls = 0;
    recurrenceComputeCalls = 0;
  }

  /// Compute layout for [events] with optional viewport culling.
  ///
  /// When `events.length >= cullingThreshold`, events outside
  /// `[viewportTopY, viewportTopY + viewportHeight]` are dropped before
  /// layout. The layout result is memoized via fingerprint
  /// `(eventIds:start:end joined) + viewport`.
  static Map<String, ConflictPlacement> layoutWithCache(
    List<EdenSchedulerEvent> events, {
    int cullingThreshold = defaultCullingThreshold,
    double? viewportTopY,
    double? viewportHeight,
    double slotHeight = 60.0,
    int startHour = 6,
  }) {
    var visible = events;
    if (events.length >= cullingThreshold &&
        viewportTopY != null &&
        viewportHeight != null) {
      final viewportBottomY = viewportTopY + viewportHeight;
      visible = events.where((e) {
        final top = (e.start.hour + e.start.minute / 60.0 - startHour) *
            slotHeight;
        final bottom = (e.end.hour + e.end.minute / 60.0 - startHour) *
            slotHeight;
        return bottom >= viewportTopY && top <= viewportBottomY;
      }).toList();
    }

    final fingerprint = _fingerprint(visible, viewportTopY, viewportHeight);
    final cached = _layoutCache[fingerprint];
    if (cached != null) {
      // Move-to-front in LRU order.
      _layoutCacheOrder.remove(fingerprint);
      _layoutCacheOrder.add(fingerprint);
      return cached;
    }
    computeCalls++;
    final placements = EdenSchedulerConflictLayout.layout(visible);
    _layoutCache[fingerprint] = placements;
    _layoutCacheOrder.add(fingerprint);
    while (_layoutCacheOrder.length > _layoutCacheCap) {
      final oldest = _layoutCacheOrder.removeAt(0);
      _layoutCache.remove(oldest);
    }
    return placements;
  }

  /// Same semantics as [EdenSchedulerTimeMath.expandRecurrence] but cached
  /// per `(event.id + start + end + range)`.
  static List<EdenSchedulerEvent> expandRecurrenceCached(
    EdenSchedulerEvent event,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final key = '${event.id}|${event.start.millisecondsSinceEpoch}|'
        '${event.end.millisecondsSinceEpoch}|'
        '${rangeStart.millisecondsSinceEpoch}|'
        '${rangeEnd.millisecondsSinceEpoch}';
    final cached = _recurrenceCache[key];
    if (cached != null) {
      _recurrenceCacheOrder.remove(key);
      _recurrenceCacheOrder.add(key);
      return cached;
    }
    recurrenceComputeCalls++;
    final result =
        EdenSchedulerTimeMath.expandRecurrence(event, rangeStart, rangeEnd);
    _recurrenceCache[key] = result;
    _recurrenceCacheOrder.add(key);
    while (_recurrenceCacheOrder.length > _recurrenceCacheCap) {
      final oldest = _recurrenceCacheOrder.removeAt(0);
      _recurrenceCache.remove(oldest);
    }
    return result;
  }

  static String _fingerprint(
    List<EdenSchedulerEvent> events,
    double? viewportTopY,
    double? viewportHeight,
  ) {
    final ids = events.map((e) =>
        '${e.id}:${e.start.millisecondsSinceEpoch}:'
        '${e.end.millisecondsSinceEpoch}').join(',');
    return '$ids|$viewportTopY|$viewportHeight';
  }
}

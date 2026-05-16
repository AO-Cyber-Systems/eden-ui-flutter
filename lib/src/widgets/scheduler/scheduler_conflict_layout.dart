import 'scheduler_models.dart';

/// Pure-Dart conflict-layout engine for [EdenScheduler].
///
/// Given a list of events on the same day/column, returns a placement map
/// `{ eventId → ConflictPlacement(columnIndex, groupSize) }` where `groupSize`
/// is the maximum simultaneous overlaps the event participates in. Visual
/// width = `1 / groupSize`; left = `columnIndex / groupSize`.
///
/// Mirrors donor `EnhancedCalendar.tsx` overlap layout. Parity row TG-7.
class EdenSchedulerConflictLayout {
  const EdenSchedulerConflictLayout._();

  /// Compute placements for [events]. Order in result is deterministic
  /// (sorted by start ascending then by id).
  static Map<String, ConflictPlacement> layout(
    List<EdenSchedulerEvent> events,
  ) {
    if (events.isEmpty) return const <String, ConflictPlacement>{};

    final sorted = [...events]..sort((a, b) {
        final s = a.start.compareTo(b.start);
        return s == 0 ? a.id.compareTo(b.id) : s;
      });

    // Greedy first-fit column assignment.
    final columns = <List<EdenSchedulerEvent>>[];
    final colByEventId = <String, int>{};

    for (final e in sorted) {
      var placed = false;
      for (var i = 0; i < columns.length; i++) {
        final col = columns[i];
        if (col.isEmpty || !col.last.end.isAfter(e.start)) {
          col.add(e);
          colByEventId[e.id] = i;
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([e]);
        colByEventId[e.id] = columns.length - 1;
      }
    }

    // Compute groupSize for each event: max overlap chain that includes it.
    final result = <String, ConflictPlacement>{};
    for (final e in sorted) {
      // Find max number of concurrent events at any time the event runs.
      var maxConcurrent = 1;
      for (final other in sorted) {
        if (other.id == e.id) continue;
        if (!other.start.isBefore(e.end) || !e.start.isBefore(other.end)) {
          continue;
        }
        // They overlap. Count all events overlapping at the intersection.
        final intersectStart =
            e.start.isAfter(other.start) ? e.start : other.start;
        final intersectEnd = e.end.isBefore(other.end) ? e.end : other.end;
        final concurrent = sorted.where((x) =>
            x.start.isBefore(intersectEnd) && x.end.isAfter(intersectStart));
        if (concurrent.length > maxConcurrent) {
          maxConcurrent = concurrent.length;
        }
      }
      result[e.id] = ConflictPlacement(
        columnIndex: colByEventId[e.id]!,
        groupSize: maxConcurrent,
      );
    }
    return result;
  }

  /// Returns true if any pair of events in [events] overlap.
  static bool hasConflicts(List<EdenSchedulerEvent> events) {
    final sorted = [...events]..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 0; i + 1 < sorted.length; i++) {
      for (var j = i + 1; j < sorted.length; j++) {
        if (sorted[j].start.isBefore(sorted[i].end)) return true;
      }
    }
    return false;
  }

  /// Count pairs of events that conflict (overlap in time AND share at least
  /// one resourceId OR both lack resourceIds).
  static int conflictPairs(List<EdenSchedulerEvent> events) {
    var count = 0;
    for (var i = 0; i < events.length; i++) {
      for (var j = i + 1; j < events.length; j++) {
        final a = events[i];
        final b = events[j];
        if (!a.start.isBefore(b.end) || !b.start.isBefore(a.end)) continue;
        final aIds = a.resourceIds ?? const <String>[];
        final bIds = b.resourceIds ?? const <String>[];
        if (aIds.isEmpty && bIds.isEmpty) {
          count++;
        } else if (aIds.any(bIds.contains)) {
          count++;
        }
      }
    }
    return count;
  }
}

class ConflictPlacement {
  const ConflictPlacement({
    required this.columnIndex,
    required this.groupSize,
  });

  final int columnIndex;
  final int groupSize;

  double get left => columnIndex / groupSize;
  double get widthFraction => 1.0 / groupSize;

  @override
  String toString() =>
      'ConflictPlacement(columnIndex: $columnIndex, groupSize: $groupSize)';
}

// Hand-built tests (no LLM-generated test data) for EdenSchedulerConflictLayout.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

EdenSchedulerEvent _e(String id, int sh, int sm, int eh, int em) {
  return EdenSchedulerEvent(
    id: id,
    title: id,
    start: DateTime(2026, 5, 16, sh, sm),
    end: DateTime(2026, 5, 16, eh, em),
  );
}

void main() {
  group('EdenSchedulerConflictLayout.layout', () {
    test('empty input returns empty map', () {
      expect(EdenSchedulerConflictLayout.layout(const []), isEmpty);
    });

    test('non-overlapping events all get columnIndex 0', () {
      final placements = EdenSchedulerConflictLayout.layout([
        _e('a', 9, 0, 10, 0),
        _e('b', 10, 0, 11, 0),
        _e('c', 11, 0, 12, 0),
      ]);
      expect(placements['a']!.columnIndex, 0);
      expect(placements['b']!.columnIndex, 0);
      expect(placements['c']!.columnIndex, 0);
    });

    test('two overlapping events occupy column 0 and 1, groupSize=2', () {
      final placements = EdenSchedulerConflictLayout.layout([
        _e('a', 9, 0, 10, 30),
        _e('b', 10, 0, 11, 0),
      ]);
      expect(placements['a']!.columnIndex, 0);
      expect(placements['b']!.columnIndex, 1);
      expect(placements['a']!.groupSize, 2);
      expect(placements['b']!.groupSize, 2);
    });

    test('three concurrent events → groupSize=3 for all', () {
      final placements = EdenSchedulerConflictLayout.layout([
        _e('a', 9, 0, 10, 0),
        _e('b', 9, 15, 10, 15),
        _e('c', 9, 30, 10, 30),
      ]);
      expect(placements['a']!.groupSize, 3);
      expect(placements['b']!.groupSize, 3);
      expect(placements['c']!.groupSize, 3);
    });

    test('placement widthFraction = 1/groupSize', () {
      final placements = EdenSchedulerConflictLayout.layout([
        _e('a', 9, 0, 10, 0),
        _e('b', 9, 30, 10, 30),
      ]);
      expect(placements['a']!.widthFraction, 0.5);
      expect(placements['b']!.widthFraction, 0.5);
      expect(placements['a']!.left, 0);
      expect(placements['b']!.left, 0.5);
    });
  });

  group('EdenSchedulerConflictLayout.hasConflicts', () {
    test('no conflicts on disjoint events', () {
      expect(
        EdenSchedulerConflictLayout.hasConflicts([
          _e('a', 9, 0, 10, 0),
          _e('b', 10, 0, 11, 0),
        ]),
        isFalse,
      );
    });

    test('overlap returns true', () {
      expect(
        EdenSchedulerConflictLayout.hasConflicts([
          _e('a', 9, 0, 10, 30),
          _e('b', 10, 0, 11, 0),
        ]),
        isTrue,
      );
    });
  });

  group('EdenSchedulerConflictLayout.conflictPairs', () {
    test('no conflicts → 0', () {
      expect(
        EdenSchedulerConflictLayout.conflictPairs([
          _e('a', 9, 0, 10, 0),
          _e('b', 10, 0, 11, 0),
        ]),
        0,
      );
    });

    test('one overlapping pair → 1', () {
      expect(
        EdenSchedulerConflictLayout.conflictPairs([
          _e('a', 9, 0, 10, 30),
          _e('b', 10, 0, 11, 0),
        ]),
        1,
      );
    });

    test('three concurrent → 3 pairs', () {
      expect(
        EdenSchedulerConflictLayout.conflictPairs([
          _e('a', 9, 0, 10, 0),
          _e('b', 9, 15, 10, 15),
          _e('c', 9, 30, 10, 30),
        ]),
        3,
      );
    });

    test('events with disjoint resourceIds do NOT count as conflicts', () {
      final aWithR1 = EdenSchedulerEvent(
        id: 'a',
        title: 'a',
        start: DateTime(2026, 5, 16, 9),
        end: DateTime(2026, 5, 16, 10),
        resourceIds: const ['r1'],
      );
      final bWithR2 = EdenSchedulerEvent(
        id: 'b',
        title: 'b',
        start: DateTime(2026, 5, 16, 9, 30),
        end: DateTime(2026, 5, 16, 10, 30),
        resourceIds: const ['r2'],
      );
      expect(
        EdenSchedulerConflictLayout.conflictPairs([aWithR1, bWithR2]),
        0,
      );
    });
  });
}

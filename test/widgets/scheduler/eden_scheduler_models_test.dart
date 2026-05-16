// Hand-built tests (no LLM-generated test data) for EdenSchedulerModels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_models_fixtures.dart';

void main() {
  group('EdenSchedulerEvent — back-compat invariant', () {
    test('zero-extra-fields constructor compiles + exposes legacy fields', () {
      final e = EdenSchedulerEvent(
        id: 'e1',
        title: 'T',
        start: _start,
        end: _end,
      );
      expect(e.id, 'e1');
      expect(e.title, 'T');
      expect(e.start, _start);
      expect(e.end, _end);
      expect(e.color, isNull);
      expect(e.description, isNull);
      expect(e.assignee, isNull);
      // New fields default null / false.
      expect(e.status, isNull);
      expect(e.type, isNull);
      expect(e.resourceIds, isNull);
      expect(e.location, isNull);
      expect(e.dispatchIssue, isNull);
      expect(e.allDay, isFalse);
      expect(e.recurrence, isNull);
      expect(e.readiness, isNull);
    });

    test('legacy 6-named-param constructor still compiles', () {
      final e = EdenSchedulerEvent(
        id: 'e2',
        title: 'T2',
        start: _start,
        end: _end,
        color: Colors.blue,
        description: 'd',
        assignee: 'Alice',
      );
      expect(e.color, Colors.blue);
      expect(e.description, 'd');
      expect(e.assignee, 'Alice');
    });

    test('durationMinutes preserved as end - start in minutes', () {
      expect(EdenSchedulerModelsFixtures.backCompatEvent.durationMinutes, 60);
    });
  });

  group('EdenSchedulerEvent — new fields', () {
    test('status exposed', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        status: 'scheduled',
      );
      expect(e.status, 'scheduled');
    });

    test('type exposed', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        type: 'maintenance',
      );
      expect(e.type, 'maintenance');
    });

    test('resourceIds exposed', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        resourceIds: ['truck-1', 'truck-2'],
      );
      expect(e.resourceIds, ['truck-1', 'truck-2']);
    });

    test('location exposed (composite type)', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        location: const EdenSchedulerLocation(name: 'Site A', address: '123 Main St'),
      );
      expect(e.location, isNotNull);
      expect(e.location!.name, 'Site A');
      expect(e.location!.address, '123 Main St');
      expect(e.location!.latitude, isNull);
      expect(e.location!.longitude, isNull);
    });

    test('dispatchIssue exposed', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        dispatchIssue: 'Missing technician',
      );
      expect(e.dispatchIssue, 'Missing technician');
    });

    test('allDay defaults false; can be set true', () {
      final noAllDay = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
      );
      expect(noAllDay.allDay, isFalse);

      final allDay = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        allDay: true,
      );
      expect(allDay.allDay, isTrue);
    });

    test('recurrence weekly exposed', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        recurrence: EdenSchedulerEventRecurrence.weekly(weekdayMask: 1 | 4 | 16),
      );
      expect(e.recurrence, isNotNull);
      expect(e.recurrence!.kind, EdenSchedulerRecurrenceKind.weekly);
      expect(e.recurrence!.weekdayMask, 1 | 4 | 16);
    });

    test('readiness exposed', () {
      final e = EdenSchedulerEvent(
        id: 'e',
        title: 'T',
        start: _start,
        end: _end,
        readiness: EdenSchedulerEventReadiness.urgent,
      );
      expect(e.readiness, EdenSchedulerEventReadiness.urgent);
    });
  });

  group('EdenSchedulerResource', () {
    test('minimal constructor (id, name, color)', () {
      const r = EdenSchedulerResource(
        id: 'r1',
        name: 'Truck 47',
        color: Colors.blue,
      );
      expect(r.id, 'r1');
      expect(r.name, 'Truck 47');
      expect(r.color, Colors.blue);
      expect(r.group, isNull);
      expect(r.crew, isNull);
    });

    test('full constructor (id, name, color, group, crew)', () {
      const r = EdenSchedulerResource(
        id: 'r1',
        name: 'Truck 47',
        color: Colors.blue,
        group: EdenSchedulerResourceGroup(id: 'g1', name: 'Service'),
        crew: ['Alice', 'Bob'],
      );
      expect(r.group, isNotNull);
      expect(r.group!.id, 'g1');
      expect(r.crew, ['Alice', 'Bob']);
    });
  });

  group('EdenSchedulerResourceGroup', () {
    test('sortOrder defaults to 0', () {
      const g = EdenSchedulerResourceGroup(id: 'g1', name: 'Service');
      expect(g.sortOrder, 0);
    });

    test('sortOrder overridable', () {
      const g = EdenSchedulerResourceGroup(
        id: 'g1',
        name: 'Service',
        sortOrder: 5,
      );
      expect(g.sortOrder, 5);
    });
  });

  group('EdenSchedulerEventReadiness enum', () {
    test('three values: ready, warning, urgent', () {
      expect(EdenSchedulerEventReadiness.values, [
        EdenSchedulerEventReadiness.ready,
        EdenSchedulerEventReadiness.warning,
        EdenSchedulerEventReadiness.urgent,
      ]);
    });
  });

  group('EdenSchedulerAvailabilityBlock', () {
    test('constructs with kind available', () {
      final b = EdenSchedulerAvailabilityBlock(
        id: 'b1',
        resourceId: 'r1',
        start: _start,
        end: _end,
        kind: EdenSchedulerAvailabilityKind.available,
      );
      expect(b.id, 'b1');
      expect(b.resourceId, 'r1');
      expect(b.kind, EdenSchedulerAvailabilityKind.available);
      expect(b.label, isNull);
    });

    test('kind enum has 3 values: available, blocked, maintenance', () {
      expect(EdenSchedulerAvailabilityKind.values, [
        EdenSchedulerAvailabilityKind.available,
        EdenSchedulerAvailabilityKind.blocked,
        EdenSchedulerAvailabilityKind.maintenance,
      ]);
    });
  });

  group('EdenSchedulerEventRecurrence', () {
    test('none() returns kind=none', () {
      final r = EdenSchedulerEventRecurrence.none();
      expect(r.kind, EdenSchedulerRecurrenceKind.none);
      expect(r.weekdayMask, 0);
      expect(r.until, isNull);
    });

    test('daily(until) exposes daily + until', () {
      final r = EdenSchedulerEventRecurrence.daily(until: DateTime(2026, 12, 31));
      expect(r.kind, EdenSchedulerRecurrenceKind.daily);
      expect(r.until, DateTime(2026, 12, 31));
    });

    test('weekly(weekdayMask) exposes weekly + mask + null until', () {
      final r = EdenSchedulerEventRecurrence.weekly(weekdayMask: 1 | 4 | 16);
      expect(r.kind, EdenSchedulerRecurrenceKind.weekly);
      expect(r.weekdayMask, 1 | 4 | 16);
      expect(r.until, isNull);
    });

    test('matchesWeekday(Mon=1) true when mask includes bit 0 (1)', () {
      final r = EdenSchedulerEventRecurrence.weekly(weekdayMask: 1 | 4 | 16);
      expect(r.matchesWeekday(1), isTrue); // Mon
    });

    test('matchesWeekday(Tue=2) false when mask is Mon|Wed|Fri', () {
      final r = EdenSchedulerEventRecurrence.weekly(weekdayMask: 1 | 4 | 16);
      expect(r.matchesWeekday(2), isFalse); // Tue
    });

    test('matchesWeekday false for kind=daily or kind=none', () {
      expect(EdenSchedulerEventRecurrence.none().matchesWeekday(1), isFalse);
      expect(EdenSchedulerEventRecurrence.daily().matchesWeekday(1), isFalse);
    });

    test('matchesWeekday rejects out-of-range weekday values', () {
      final r = EdenSchedulerEventRecurrence.weekly(weekdayMask: 127);
      expect(r.matchesWeekday(0), isFalse);
      expect(r.matchesWeekday(8), isFalse);
    });
  });

  group('EdenSchedulerView enum extension', () {
    test('values.length == 7', () {
      expect(EdenSchedulerView.values.length, 7);
    });

    test('legacy month/week/day identifiers preserved', () {
      expect(EdenSchedulerView.month.name, 'month');
      expect(EdenSchedulerView.week.name, 'week');
      expect(EdenSchedulerView.day.name, 'day');
    });

    test('new identifiers exist: workWeek, list, mobile, swimlane', () {
      expect(EdenSchedulerView.workWeek.name, 'workWeek');
      expect(EdenSchedulerView.list.name, 'list');
      expect(EdenSchedulerView.mobile.name, 'mobile');
      expect(EdenSchedulerView.swimlane.name, 'swimlane');
    });

    test('legacy month/week/day are at index 0/1/3 — preserved enum order', () {
      // Order locked: month, week, workWeek, day, list, mobile, swimlane.
      expect(EdenSchedulerView.values[0], EdenSchedulerView.month);
      expect(EdenSchedulerView.values[1], EdenSchedulerView.week);
      expect(EdenSchedulerView.values[3], EdenSchedulerView.day);
    });
  });
}

final DateTime _start = DateTime(2026, 5, 16, 9, 0);
final DateTime _end = DateTime(2026, 5, 16, 10, 0);

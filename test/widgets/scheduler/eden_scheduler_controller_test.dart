// Hand-built tests (no LLM-generated test data) for EdenSchedulerController.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_models_fixtures.dart';

void main() {
  group('EdenSchedulerController — constructor + state', () {
    test('constructor exposes initialView + stripped initialDate', () {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 16, 14, 30),
      );
      addTearDown(c.dispose);
      expect(c.view, EdenSchedulerView.day);
      expect(c.focusedDate, DateTime(2026, 5, 16));
      expect(c.search, '');
      expect(c.selectedResources, isEmpty);
      expect(c.selectedEventIds, isEmpty);
    });

    test('clock injection makes today deterministic', () {
      final c = EdenSchedulerController(
        clock: () => DateTime(2026, 5, 16, 9),
      );
      addTearDown(c.dispose);
      expect(c.today, DateTime(2026, 5, 16));
    });
  });

  group('EdenSchedulerController — setView', () {
    test('updates view + notifies listeners', () {
      final c = EdenSchedulerController(initialView: EdenSchedulerView.week);
      addTearDown(c.dispose);
      var notifies = 0;
      c.addListener(() => notifies++);
      c.setView(EdenSchedulerView.month);
      expect(c.view, EdenSchedulerView.month);
      expect(notifies, 1);
    });

    test('setView with same value is a no-op (no notify)', () {
      final c = EdenSchedulerController(initialView: EdenSchedulerView.week);
      addTearDown(c.dispose);
      var notifies = 0;
      c.addListener(() => notifies++);
      c.setView(EdenSchedulerView.week);
      expect(notifies, 0);
    });
  });

  group('EdenSchedulerController — navigate', () {
    test('navigate(1) with view=day advances focusedDate by 1 day', () {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      c.navigate(1);
      expect(c.focusedDate, DateTime(2026, 5, 12));
    });

    test('navigate(-1) with view=week steps back 7 days', () {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.week,
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      c.navigate(-1);
      expect(c.focusedDate, DateTime(2026, 5, 4));
    });

    test('navigate(1) with view=month advances focusedDate.month by 1', () {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.month,
        initialDate: DateTime(2026, 5, 15),
      );
      addTearDown(c.dispose);
      c.navigate(1);
      expect(c.focusedDate.year, 2026);
      expect(c.focusedDate.month, 6);
      expect(c.focusedDate.day, 1);
    });

    test('navigate with view=mobile advances by 1 day', () {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.mobile,
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      c.navigate(1);
      expect(c.focusedDate, DateTime(2026, 5, 12));
    });

    test('navigate with view=swimlane advances by 7 days', () {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.swimlane,
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      c.navigate(1);
      expect(c.focusedDate, DateTime(2026, 5, 18));
    });
  });

  group('EdenSchedulerController — goToday', () {
    test('resets focusedDate to clock today', () {
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 1, 1),
        clock: () => DateTime(2026, 5, 16, 9),
      );
      addTearDown(c.dispose);
      c.goToday();
      expect(c.focusedDate, DateTime(2026, 5, 16));
    });

    test('goToday is no-op when already on today', () {
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 16),
        clock: () => DateTime(2026, 5, 16, 9),
      );
      addTearDown(c.dispose);
      var notifies = 0;
      c.addListener(() => notifies++);
      c.goToday();
      expect(notifies, 0);
    });
  });

  group('EdenSchedulerController — resource filter', () {
    test('toggle adds then removes resource', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      c.toggleResourceFilter('r1');
      expect(c.selectedResources, contains('r1'));
      c.toggleResourceFilter('r1');
      expect(c.selectedResources, isEmpty);
    });

    test('selectedResources is unmodifiable', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      c.toggleResourceFilter('r1');
      expect(() => c.selectedResources.add('r2'), throwsUnsupportedError);
    });
  });

  group('EdenSchedulerController — search', () {
    test('setSearch trims whitespace + notifies', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      var notifies = 0;
      c.addListener(() => notifies++);
      c.setSearch('  hello  ');
      expect(c.search, 'hello');
      expect(notifies, 1);
    });

    test('setSearch with same trimmed value is no-op', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      c.setSearch('hello');
      var notifies = 0;
      c.addListener(() => notifies++);
      c.setSearch(' hello ');
      expect(notifies, 0);
    });
  });

  group('EdenSchedulerController — selection', () {
    test('toggleSelection round-trips; clearSelection empties', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      c.toggleSelection('e1');
      c.toggleSelection('e2');
      expect(c.selectedEventIds, {'e1', 'e2'});
      c.toggleSelection('e1');
      expect(c.selectedEventIds, {'e2'});
      c.clearSelection();
      expect(c.selectedEventIds, isEmpty);
    });

    test('clearSelection is no-op when already empty', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      var notifies = 0;
      c.addListener(() => notifies++);
      c.clearSelection();
      expect(notifies, 0);
    });
  });

  group('EdenSchedulerController — fixture builder', () {
    test('EdenSchedulerModelsFixtures.controllerWith uses fixed clock', () {
      final c = EdenSchedulerModelsFixtures.controllerWith();
      addTearDown(c.dispose);
      expect(c.today, DateTime(2026, 5, 16));
      expect(c.view, EdenSchedulerView.week);
    });
  });

  group('EdenSchedulerController — ChangeNotifier contract', () {
    test('extends ChangeNotifier', () {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      expect(c, isA<ChangeNotifier>());
    });
  });
}

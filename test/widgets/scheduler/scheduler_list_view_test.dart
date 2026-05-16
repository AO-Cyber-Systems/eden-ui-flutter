// Hand-built tests (no LLM-generated test data) for EdenSchedulerListView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_list_view_fixtures.dart';

void main() {
  group('EdenSchedulerListView — rendering', () {
    testWidgets('empty events renders empty state', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: const [],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('No events in this range.'), findsOneWidget);
    });

    testWidgets('1 event renders 1 row under date header', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.todayMorning],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Coffee meeting'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('EdenSchedulerListView — date headers', () {
    testWidgets('today renders "Today"', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.todayMorning],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('tomorrow renders "Tomorrow"', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.tomorrowEvent],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('yesterday renders "Yesterday"', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.yesterdayEvent],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('+5 days renders full date label', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.fiveDaysFromNow],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Thu, May 21, 2026'), findsOneWidget);
    });
  });

  group('EdenSchedulerListView — sorting', () {
    testWidgets('events on same day render in ascending time order',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [
            EdenSchedulerListViewFixtures.todayMorning, // 9 AM
            EdenSchedulerListViewFixtures.todayEarliest, // 7 AM
            EdenSchedulerListViewFixtures.todayEarly, // 8 AM
          ],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      // Use widget tester to read the order of titles in the rendered list.
      final earliest = tester.getTopLeft(find.text('Pre-dawn standup'));
      final earlyTop = tester.getTopLeft(find.text('Strategy session'));
      final morningTop = tester.getTopLeft(find.text('Coffee meeting'));
      expect(earliest.dy, lessThan(earlyTop.dy));
      expect(earlyTop.dy, lessThan(morningTop.dy));
    });
  });

  group('EdenSchedulerListView — range bounds', () {
    testWidgets('event within week-start + 14 days is included',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.withinRange],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Sprint demo'), findsOneWidget);
    });

    testWidgets('event 20 days from today is excluded (outside 14-day range)',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.twentyDaysFromNow],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Roadmap planning'), findsNothing);
    });

    testWidgets('dateRange:30 includes events 20 days out', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.twentyDaysFromNow],
          dateRange: const Duration(days: 30),
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Roadmap planning'), findsOneWidget);
    });
  });

  group('EdenSchedulerListView — search filter', () {
    testWidgets('controller search narrows events by title (case-insensitive)',
        (tester) async {
      final c = EdenSchedulerController(
        initialDate: EdenSchedulerListViewFixtures.today,
        clock: EdenSchedulerListViewFixtures.clock(),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          controller: c,
          events: [
            EdenSchedulerListViewFixtures.todayMorning,
            EdenSchedulerListViewFixtures.todayEarly,
          ],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      // Both visible.
      expect(find.text('Coffee meeting'), findsOneWidget);
      expect(find.text('Strategy session'), findsOneWidget);
      // Search for COFFEE.
      c.setSearch('COFFEE');
      await tester.pump();
      expect(find.text('Coffee meeting'), findsOneWidget);
      expect(find.text('Strategy session'), findsNothing);
    });
  });

  group('EdenSchedulerListView — resource filter', () {
    testWidgets('selectedResources narrows to matching resourceIds',
        (tester) async {
      final c = EdenSchedulerController(
        initialDate: EdenSchedulerListViewFixtures.today,
        clock: EdenSchedulerListViewFixtures.clock(),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          controller: c,
          events: [
            EdenSchedulerListViewFixtures.todayMorning, // no resourceIds
            EdenSchedulerListViewFixtures.withResource, // r-47
          ],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
      ));
      expect(find.text('Coffee meeting'), findsOneWidget);
      expect(find.text('Truck 47 visit'), findsOneWidget);
      // Toggle r-47 filter.
      c.toggleResourceFilter('r-47');
      await tester.pump();
      expect(find.text('Coffee meeting'), findsNothing);
      expect(find.text('Truck 47 visit'), findsOneWidget);
    });
  });

  group('EdenSchedulerListView — interaction', () {
    testWidgets('tapping row fires onEventTap', (tester) async {
      EdenSchedulerEvent? captured;
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [EdenSchedulerListViewFixtures.todayMorning],
          clock: EdenSchedulerListViewFixtures.clock(),
          onEventTap: (e) => captured = e,
        ),
      ));
      await tester.tap(find.text('Coffee meeting'));
      expect(captured?.id, 'today-9');
    });
  });

  group('EdenSchedulerListView — responsive', () {
    testWidgets('390pt narrow renders without overflow', (tester) async {
      await tester.pumpWidget(EdenSchedulerListViewFixtures.wrap(
        EdenSchedulerListView(
          focusedDate: EdenSchedulerListViewFixtures.today,
          events: [
            EdenSchedulerListViewFixtures.todayMorning,
            EdenSchedulerListViewFixtures.tomorrowEvent,
          ],
          clock: EdenSchedulerListViewFixtures.clock(),
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

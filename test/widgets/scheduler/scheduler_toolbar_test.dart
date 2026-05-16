// Hand-built tests (no LLM-generated test data) for SchedulerToolbar.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/src/widgets/scheduler/scheduler_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_toolbar_fixtures.dart';

void main() {
  group('SchedulerToolbar — title formatter', () {
    Future<void> _mount(
      WidgetTester tester, {
      required EdenSchedulerView view,
      required DateTime focusedDate,
      double width = 1400,
    }) async {
      await tester.binding.setSurfaceSize(Size(width, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final theme = ThemeData.light();
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: view,
          focusedDate: focusedDate,
          isDark: false,
          theme: theme,
          onPrev: () {},
          onNext: () {},
          onToday: () {},
          onViewChanged: (_) {},
        ),
        width: width,
      ));
    }

    testWidgets('day view → "Mon, Mar 9, 2026"', (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.day,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
      );
      expect(find.text('Mon, Mar 9, 2026'), findsOneWidget);
    });

    testWidgets('mobile view → "Mon, Mar 9, 2026"', (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.mobile,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
      );
      expect(find.text('Mon, Mar 9, 2026'), findsOneWidget);
    });

    testWidgets('workWeek view (focused Mon) → "Mar 9–13, 2026"',
        (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.workWeek,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
      );
      expect(find.text('Mar 9–13, 2026'), findsOneWidget);
    });

    testWidgets('workWeek view (focused Wed) → "Mar 9–13, 2026"',
        (tester) async {
      // Mid-week should still snap to Mon..Fri.
      await _mount(
        tester,
        view: EdenSchedulerView.workWeek,
        focusedDate: EdenSchedulerToolbarFixtures.wed2026Mar11,
      );
      expect(find.text('Mar 9–13, 2026'), findsOneWidget);
    });

    testWidgets('week view (focused Mon) → "Mar 9–15, 2026"', (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.week,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
      );
      expect(find.text('Mar 9–15, 2026'), findsOneWidget);
    });

    testWidgets('week view (focused Sun) → "Mar 9–15, 2026" (same week)',
        (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.week,
        focusedDate: EdenSchedulerToolbarFixtures.sun2026Mar15,
      );
      expect(find.text('Mar 9–15, 2026'), findsOneWidget);
    });

    testWidgets('month view → "March 2026"', (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.month,
        focusedDate: DateTime(2026, 3, 15),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('list view → "Week of Mar 9, 2026"', (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.list,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
      );
      expect(find.text('Week of Mar 9, 2026'), findsOneWidget);
    });

    testWidgets('swimlane view → "Mar 9–29, 2026" (3-week, 20-day span)',
        (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.swimlane,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
      );
      expect(find.text('Mar 9–29, 2026'), findsOneWidget);
    });

    testWidgets('workWeek month-boundary → "Mar 30 – Apr 3, 2026"',
        (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.workWeek,
        focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar30,
      );
      expect(find.text('Mar 30 – Apr 3, 2026'), findsOneWidget);
    });

    testWidgets('week year-boundary → "Dec 28, 2026 – Jan 3, 2027"',
        (tester) async {
      await _mount(
        tester,
        view: EdenSchedulerView.week,
        focusedDate: EdenSchedulerToolbarFixtures.wed2026Dec30,
      );
      expect(find.text('Dec 28, 2026 – Jan 3, 2027'), findsOneWidget);
    });
  });

  group('SchedulerToolbar — ViewToggle visibility', () {
    testWidgets('default visibleViews=null renders all 7 buttons',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: EdenSchedulerView.week,
          focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
          isDark: false,
          theme: ThemeData.light(),
          onPrev: () {},
          onNext: () {},
          onToday: () {},
          onViewChanged: (_) {},
        ),
      ));
      // Labels expected when label-mode (wide width).
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Work Week'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Swimlane'), findsOneWidget);
    });

    testWidgets('visibleViews=[day,week,month] renders only those 3',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: EdenSchedulerView.week,
          focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
          isDark: false,
          theme: ThemeData.light(),
          onPrev: () {},
          onNext: () {},
          onToday: () {},
          onViewChanged: (_) {},
          visibleViews: const [
            EdenSchedulerView.day,
            EdenSchedulerView.week,
            EdenSchedulerView.month,
          ],
        ),
      ));
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Work Week'), findsNothing);
      expect(find.text('List'), findsNothing);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Swimlane'), findsNothing);
    });
  });

  group('SchedulerToolbar — interaction', () {
    testWidgets('Prev tap fires onPrev callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var prevTaps = 0;
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: EdenSchedulerView.week,
          focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
          isDark: false,
          theme: ThemeData.light(),
          onPrev: () => prevTaps++,
          onNext: () {},
          onToday: () {},
          onViewChanged: (_) {},
        ),
      ));
      await tester.tap(find.byTooltip('Previous'));
      expect(prevTaps, 1);
    });

    testWidgets('Today tap fires onToday callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var todayTaps = 0;
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: EdenSchedulerView.week,
          focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
          isDark: false,
          theme: ThemeData.light(),
          onPrev: () {},
          onNext: () {},
          onToday: () => todayTaps++,
          onViewChanged: (_) {},
        ),
      ));
      await tester.tap(find.text('Today'));
      expect(todayTaps, 1);
    });

    testWidgets('tapping a view label fires onViewChanged', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      EdenSchedulerView? captured;
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: EdenSchedulerView.week,
          focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
          isDark: false,
          theme: ThemeData.light(),
          onPrev: () {},
          onNext: () {},
          onToday: () {},
          onViewChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('Day'));
      expect(captured, EdenSchedulerView.day);
    });
  });

  group('SchedulerToolbar.fromController', () {
    testWidgets('reads view + focusedDate from controller', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.month,
        initialDate: DateTime(2026, 3, 15),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar.fromController(
          controller: c,
          isDark: false,
          theme: ThemeData.light(),
        ),
      ));
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('rebuilds when controller notifies', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.month,
        initialDate: DateTime(2026, 3, 15),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar.fromController(
          controller: c,
          isDark: false,
          theme: ThemeData.light(),
        ),
      ));
      c.setView(EdenSchedulerView.day);
      await tester.pump();
      expect(find.textContaining('Sun, Mar 15'), findsOneWidget);
    });

    testWidgets('Prev/Next route through controller.navigate', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 3, 9),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar.fromController(
          controller: c,
          isDark: false,
          theme: ThemeData.light(),
        ),
      ));
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
      expect(c.focusedDate, DateTime(2026, 3, 10));
    });
  });

  group('SchedulerToolbar — responsive (iPhone-narrow)', () {
    testWidgets('390pt renders without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(EdenSchedulerToolbarFixtures.wrap(
        SchedulerToolbar(
          view: EdenSchedulerView.week,
          focusedDate: EdenSchedulerToolbarFixtures.mon2026Mar09,
          isDark: false,
          theme: ThemeData.light(),
          onPrev: () {},
          onNext: () {},
          onToday: () {},
          onViewChanged: (_) {},
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

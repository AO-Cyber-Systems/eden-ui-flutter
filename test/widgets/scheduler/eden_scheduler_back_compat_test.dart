// Hand-built back-compat regression tests for EdenScheduler.
// Locked across Objective 004 — these MUST pass unchanged through all 16 TRDs.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_models_fixtures.dart';

Widget wrap(Widget child, {double width = 800, double height = 600}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );
}

void main() {
  group('EdenScheduler — back-compat', () {
    testWidgets('zero-param constructor renders without throwing',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenScheduler()));
      expect(find.byType(EdenScheduler), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('legacy multi-named-param constructor renders',
        (tester) async {
      await tester.pumpWidget(wrap(EdenScheduler(
        events: const [],
        view: EdenSchedulerView.week,
        initialDate: EdenSchedulerModelsFixtures.monday,
        onEventTap: (_) {},
        onTimeSlotTap: (_) {},
        onViewChanged: (_) {},
      )));
      expect(find.byType(EdenScheduler), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('events render in week view (legacy event constructor)',
        (tester) async {
      final events = [EdenSchedulerModelsFixtures.backCompatEvent];
      await tester.pumpWidget(wrap(EdenScheduler(
        events: events,
        view: EdenSchedulerView.week,
        initialDate: EdenSchedulerModelsFixtures.monday,
      )));
      // The event title "Back Compat" should be in the tree.
      expect(find.textContaining('Back Compat'), findsWidgets);
    });

    testWidgets('onViewChanged still fires on toolbar toggle', (tester) async {
      // Wide enough to render the labeled (text-mode) ViewToggle (>=1100pt).
      await tester.binding.setSurfaceSize(const Size(1400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      EdenSchedulerView? captured;
      await tester.pumpWidget(wrap(
        EdenScheduler(
          view: EdenSchedulerView.week,
          onViewChanged: (v) => captured = v,
        ),
        width: 1400,
      ));
      // Tap Month label in the toolbar.
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(captured, EdenSchedulerView.month);
    });
  });

  group('EdenScheduler — new controller param', () {
    testWidgets('external controller drives view + date', (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: EdenSchedulerModelsFixtures.monday,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenScheduler(controller: c)));
      // Day-view title contains 'Mon' (Monday) and the date.
      expect(find.textContaining('Mon'), findsWidgets);
    });

    testWidgets('controller.setView rebuilds widget body', (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.week,
        initialDate: EdenSchedulerModelsFixtures.monday,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenScheduler(controller: c)));
      // Switch the controller to month — widget should rebuild.
      c.setView(EdenSchedulerView.month);
      await tester.pump();
      // Title now reads "May 2026".
      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('widget does NOT dispose externally-owned controller',
        (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: EdenSchedulerModelsFixtures.monday,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenScheduler(controller: c)));
      // Unmount the widget.
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      // Controller is still usable (would throw if disposed).
      c.setView(EdenSchedulerView.week);
      expect(c.view, EdenSchedulerView.week);
    });
  });

  group('EdenScheduler — responsive', () {
    testWidgets('390pt narrow renders without overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenScheduler(view: EdenSchedulerView.day),
        width: 390,
        height: 700,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

// Hand-built tests (no LLM-generated test data) for Wave 4 sidebar widgets.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EdenSchedulerMiniCalendar', () {
    testWidgets('renders M/T/W/T/F/S/S day-of-week headers', (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerMiniCalendar(
        focusedDate: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 16),
      )));
      expect(find.text('M'), findsAtLeastNWidgets(1));
      expect(find.text('F'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders month title', (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerMiniCalendar(
        focusedDate: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 16),
      )));
      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('day cell tap fires onDateTap', (tester) async {
      DateTime? captured;
      await tester.pumpWidget(wrap(EdenSchedulerMiniCalendar(
        focusedDate: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 16),
        onDateTap: (d) => captured = d,
      )));
      await tester.tap(find.text('16'));
      expect(captured?.day, 16);
    });

    testWidgets('month nav arrow fires onMonthChange', (tester) async {
      int? delta;
      await tester.pumpWidget(wrap(EdenSchedulerMiniCalendar(
        focusedDate: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 16),
        onMonthChange: (d) => delta = d,
      )));
      await tester.tap(find.byTooltip('Next month'));
      expect(delta, 1);
    });
  });

  group('EdenSchedulerDensityLegend', () {
    testWidgets('renders Open and Full labels', (tester) async {
      await tester.pumpWidget(wrap(const EdenSchedulerDensityLegend()));
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
    });
  });

  group('EdenSchedulerZoomIndicator', () {
    testWidgets('renders percentage', (tester) async {
      await tester.pumpWidget(wrap(const EdenSchedulerZoomIndicator(zoom: 1.0)));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('zoom=0.5 renders "50%"', (tester) async {
      await tester.pumpWidget(wrap(const EdenSchedulerZoomIndicator(zoom: 0.5)));
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('+ tap increases zoom by step (clamped to max)',
        (tester) async {
      double? newZoom;
      await tester.pumpWidget(wrap(EdenSchedulerZoomIndicator(
        zoom: 1.0,
        onZoomChange: (z) => newZoom = z,
      )));
      await tester.tap(find.byTooltip('Zoom in'));
      expect(newZoom, closeTo(1.25, 0.001));
    });

    testWidgets('- tap decreases zoom by step (clamped to min)',
        (tester) async {
      double? newZoom;
      await tester.pumpWidget(wrap(EdenSchedulerZoomIndicator(
        zoom: 0.5,
        onZoomChange: (z) => newZoom = z,
      )));
      await tester.tap(find.byTooltip('Zoom out'));
      expect(newZoom, 0.5); // already at min, clamps.
    });
  });

  group('EdenSchedulerSearchField', () {
    testWidgets('typed text triggers controller.setSearch after debounce',
        (tester) async {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerSearchField(
        controller: c,
        debounce: const Duration(milliseconds: 50),
      )));
      await tester.enterText(find.byType(TextField), 'hello');
      // Wait for debounce.
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.search, 'hello');
    });
  });

  group('EdenSchedulerKeyboardShortcuts', () {
    testWidgets('renders child wrapped in Shortcuts/Actions/Focus',
        (tester) async {
      final c = EdenSchedulerController(initialView: EdenSchedulerView.week);
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerKeyboardShortcuts(
        controller: c,
        child: const Text('body'),
      )));
      expect(find.byType(EdenSchedulerKeyboardShortcuts), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('autofocus=true propagates to Focus child', (tester) async {
      final c = EdenSchedulerController(initialView: EdenSchedulerView.week);
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerKeyboardShortcuts(
        controller: c,
        autofocus: true,
        child: const Text('body'),
      )));
      // Find the EdenScheduler-owned Focus widget.
      final focuses = tester.widgetList<Focus>(find.descendant(
        of: find.byType(EdenSchedulerKeyboardShortcuts),
        matching: find.byType(Focus),
      ));
      expect(focuses.any((f) => f.autofocus == true), isTrue);
    });
  });

  group('EdenSchedulerOverflowMenu', () {
    testWidgets('three-dot icon opens popup menu', (tester) async {
      await tester.pumpWidget(wrap(EdenSchedulerOverflowMenu(
        items: const [
          PopupMenuItem<String>(value: 'export', child: Text('Export iCal')),
          PopupMenuItem<String>(value: 'print', child: Text('Print')),
        ],
      )));
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Export iCal'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
    });
  });

  group('EdenSchedulerSidebar', () {
    testWidgets('renders mini-cal + density legend', (tester) async {
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 16),
        clock: () => DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(EdenSchedulerSidebar(
        controller: c,
        resources: const [],
        todayClock: () => DateTime(2026, 5, 16),
      )));
      expect(find.text('May 2026'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
      expect(find.text('Show unassigned'), findsOneWidget);
    });

    testWidgets('resources section appears when non-empty', (tester) async {
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 16),
        clock: () => DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(EdenSchedulerSidebar(
        controller: c,
        resources: const [
          EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
        ],
        todayClock: () => DateTime(2026, 5, 16),
      )));
      expect(find.text('Resources'), findsOneWidget);
      expect(find.text('Truck 47'), findsOneWidget);
    });
  });
}

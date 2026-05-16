// Hand-built tests (no LLM-generated test data) for EdenSchedulerMobileView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child, {double width = 390, double height = 700}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );
}

void main() {
  group('EdenSchedulerMobileView — integration', () {
    testWidgets('renders Day/Week/Month tab strip', (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerMobileView(
        controller: c,
        events: const [],
        clock: () => DateTime(2026, 5, 16, 12),
      )));
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('tapping Month tab switches controller to month', (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerMobileView(
        controller: c,
        events: const [],
        clock: () => DateTime(2026, 5, 16, 12),
      )));
      await tester.tap(find.text('Month'));
      await tester.pump();
      expect(c.view, EdenSchedulerView.month);
    });

    testWidgets('renders resource chip strip when resources provided',
        (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerMobileView(
        controller: c,
        events: const [],
        clock: () => DateTime(2026, 5, 16, 12),
        resources: const [
          EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          EdenSchedulerResource(id: 'r2', name: 'Truck 12'),
        ],
      )));
      expect(find.text('Truck 47'), findsOneWidget);
      expect(find.text('Truck 12'), findsOneWidget);
    });

    testWidgets('tapping a chip toggles controller.selectedResources',
        (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerMobileView(
        controller: c,
        events: const [],
        clock: () => DateTime(2026, 5, 16, 12),
        resources: const [
          EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
        ],
      )));
      await tester.tap(find.text('Truck 47'));
      await tester.pump();
      expect(c.selectedResources, contains('r1'));
    });

    testWidgets('390pt narrow renders without overflow', (tester) async {
      final c = EdenSchedulerController(
        initialView: EdenSchedulerView.day,
        initialDate: DateTime(2026, 5, 16),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(EdenSchedulerMobileView(
        controller: c,
        events: const [],
        clock: () => DateTime(2026, 5, 16, 12),
      )));
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenSchedulerPinchZoom', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenSchedulerPinchZoom(
            zoom: 1.0,
            child: const Text('Body'),
          ),
        ),
      ));
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('exposes zoom + callback param fields', (tester) async {
      // The pinch zoom widget hosts the gesture detector; we verify it's
      // present in the tree and that the gesture detector callbacks are
      // wired (we don't simulate full pinch since that requires raw pointer
      // injection beyond standard widget-test conventions).
      var startCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenSchedulerPinchZoom(
            zoom: 1.0,
            onScaleStart: () => startCalled = true,
            child: const Text('child'),
          ),
        ),
      ));
      // Locate the gesture detector that hosts the scale callbacks.
      final detector = tester.widget<GestureDetector>(
        find.byType(GestureDetector).first,
      );
      expect(detector.onScaleStart, isNotNull);
      expect(detector.onScaleUpdate, isNotNull);
      expect(detector.onScaleEnd, isNotNull);
    });
  });

  group('EdenSchedulerResourceChipStrip', () {
    testWidgets('renders all provided resources', (tester) async {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: EdenSchedulerResourceChipStrip(
              controller: c,
              resources: const [
                EdenSchedulerResource(id: 'r1', name: 'A'),
                EdenSchedulerResource(id: 'r2', name: 'B'),
                EdenSchedulerResource(id: 'r3', name: 'C'),
              ],
            ),
          ),
        ),
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });
}

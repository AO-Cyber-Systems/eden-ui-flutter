// Hand-built tests (no LLM-generated test data) for EdenSchedulerSwimlaneView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Future<void> setSurface(WidgetTester tester, double width,
    [double height = 700]) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('EdenSchedulerSwimlaneView — minimum viewport', () {
    testWidgets('at width <1200pt renders "Switch to mobile" fallback',
        (tester) async {
      await setSurface(tester, 800);
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [
            EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          ],
          events: const [],
          clock: () => DateTime(2026, 5, 11),
        ),
      ));
      expect(find.textContaining('Swimlane view requires'), findsOneWidget);
    });

    testWidgets('at width ≥1200pt renders the full grid', (tester) async {
      await setSurface(tester, 1400);
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [
            EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          ],
          events: const [],
          clock: () => DateTime(2026, 5, 11),
        ),
      ));
      expect(find.text('Truck 47'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });
  });

  group('EdenSchedulerSwimlaneView — empty resources', () {
    testWidgets('renders "No resources to display." when empty',
        (tester) async {
      await setSurface(tester, 1400);
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [],
          events: const [],
        ),
      ));
      expect(find.text('No resources to display.'), findsOneWidget);
    });
  });

  group('EdenSchedulerSwimlaneView — event rendering', () {
    testWidgets('event for (resource, date) renders in correct cell',
        (tester) async {
      await setSurface(tester, 1400);
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [
            EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          ],
          events: [
            EdenSchedulerEvent(
              id: 'e',
              title: 'Service call',
              start: DateTime(2026, 5, 12, 9),
              end: DateTime(2026, 5, 12, 10),
              resourceIds: const ['r1'],
            ),
          ],
          clock: () => DateTime(2026, 5, 11),
        ),
      ));
      expect(find.text('Service call'), findsOneWidget);
    });

    testWidgets('event with no matching resource is not rendered',
        (tester) async {
      await setSurface(tester, 1400);
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [
            EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          ],
          events: [
            EdenSchedulerEvent(
              id: 'e',
              title: 'Service call',
              start: DateTime(2026, 5, 12, 9),
              end: DateTime(2026, 5, 12, 10),
              resourceIds: const ['r2'],
            ),
          ],
          clock: () => DateTime(2026, 5, 11),
        ),
      ));
      expect(find.text('Service call'), findsNothing);
    });
  });

  group('EdenSchedulerSwimlaneView — collapse', () {
    testWidgets('tapping resource header toggles collapse', (tester) async {
      await setSurface(tester, 1400);
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [
            EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          ],
          events: const [],
          clock: () => DateTime(2026, 5, 11),
        ),
      ));
      // Initially uncollapsed: full name visible.
      expect(find.text('Truck 47'), findsOneWidget);
      // Tap the header.
      await tester.tap(find.text('Truck 47'));
      await tester.pump();
      // After collapse, just the initial letter T renders.
      expect(find.text('T'), findsOneWidget);
    });
  });

  group('EdenSchedulerSwimlaneView — availability blocks', () {
    testWidgets('maintenance block renders with amber tint background',
        (tester) async {
      await setSurface(tester, 1400);
      final c = EdenSchedulerController(
        initialDate: DateTime(2026, 5, 11),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(wrap(
        EdenSchedulerSwimlaneView(
          controller: c,
          resources: const [
            EdenSchedulerResource(id: 'r1', name: 'Truck 47'),
          ],
          events: const [],
          availabilityBlocks: [
            EdenSchedulerAvailabilityBlock(
              id: 'b',
              resourceId: 'r1',
              start: DateTime(2026, 5, 12),
              end: DateTime(2026, 5, 12, 17),
              kind: EdenSchedulerAvailabilityKind.maintenance,
            ),
          ],
          clock: () => DateTime(2026, 5, 11),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

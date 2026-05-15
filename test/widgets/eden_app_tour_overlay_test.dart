import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenAppTourOverlay', () {
    testWidgets('renders the child tree unmodified when no tour active',
        (tester) async {
      final inboxKey = GlobalKey();
      await tester.pumpWidget(wrap(
        EdenAppTourOverlay(
          steps: <EdenTourStep>[
            EdenTourStep(
              key: inboxKey,
              title: 'Inbox',
              description: 'Your messages live here',
            ),
          ],
          child: const Text('Child content'),
        ),
      ));
      // The child renders inside the tour wrapper.
      expect(find.text('Child content'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('eden_app_tour_child')),
        findsOneWidget,
      );
    });

    testWidgets('isActive=false by default + child is mounted', (tester) async {
      final tourKey = GlobalKey<EdenAppTourOverlayState>();
      await tester.pumpWidget(wrap(
        EdenAppTourOverlay(
          key: tourKey,
          steps: const <EdenTourStep>[],
          child: const Text('Body content sentinel'),
        ),
      ));
      // Body renders (not blocked by a Placeholder stub).
      expect(find.text('Body content sentinel'), findsOneWidget);
      expect(tourKey.currentState!.isActive, isFalse);
    });

    testWidgets(
        'startTour() with steps flips isActive + child still mounted',
        (tester) async {
      final tourKey = GlobalKey<EdenAppTourOverlayState>();
      final inboxKey = GlobalKey();
      final step = EdenTourStep(
        key: inboxKey,
        title: 'Inbox',
        description: '...',
      );
      await tester.pumpWidget(wrap(
        EdenAppTourOverlay(
          key: tourKey,
          steps: <EdenTourStep>[step],
          child: EdenTourTarget(
            step: step,
            child: const Text('Inbox content'),
          ),
        ),
      ));
      // Sentinel renders inside the wrapped Showcase target.
      expect(find.text('Inbox content'), findsOneWidget);
      tourKey.currentState!.startTour();
      await tester.pump();
      expect(tourKey.currentState!.isActive, isTrue);
    });

    testWidgets('empty steps + startTour() fires onComplete immediately',
        (tester) async {
      final tourKey = GlobalKey<EdenAppTourOverlayState>();
      var completed = false;
      await tester.pumpWidget(wrap(
        EdenAppTourOverlay(
          key: tourKey,
          steps: const <EdenTourStep>[],
          onComplete: () => completed = true,
          child: const Text('Body'),
        ),
      ));
      tourKey.currentState!.startTour();
      // Pump for post-frame callback to fire.
      await tester.pump();
      await tester.pump();
      expect(completed, isTrue);
      expect(tourKey.currentState!.isActive, isFalse);
    });

    testWidgets(
        'EdenAppTourOverlay.of(context) returns the nearest state',
        (tester) async {
      final tourKey = GlobalKey<EdenAppTourOverlayState>();
      EdenAppTourOverlayState? found;
      await tester.pumpWidget(wrap(
        EdenAppTourOverlay(
          key: tourKey,
          steps: const <EdenTourStep>[],
          child: Builder(builder: (context) {
            found = EdenAppTourOverlay.of(context);
            return const Text('Body');
          }),
        ),
      ));
      expect(found, isNotNull);
      expect(identical(found, tourKey.currentState), isTrue);
    });
  });
}

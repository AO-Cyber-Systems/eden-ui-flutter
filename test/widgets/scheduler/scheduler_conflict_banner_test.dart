// Hand-built tests (no LLM-generated test data) for the conflict + selection banners.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EdenSchedulerConflictBanner', () {
    testWidgets('count=0 renders nothing', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSchedulerConflictBanner(conflictCount: 0),
      ));
      expect(find.textContaining('conflict'), findsNothing);
    });

    testWidgets('count=1 uses singular text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSchedulerConflictBanner(conflictCount: 1),
      ));
      expect(find.text('1 scheduling conflict detected.'), findsOneWidget);
    });

    testWidgets('count=3 uses plural text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSchedulerConflictBanner(conflictCount: 3),
      ));
      expect(find.text('3 scheduling conflicts detected.'), findsOneWidget);
    });

    testWidgets('onResolve tap fires callback', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(
        EdenSchedulerConflictBanner(
          conflictCount: 2,
          onResolve: () => called = true,
        ),
      ));
      await tester.tap(find.text('Resolve'));
      expect(called, isTrue);
    });

    testWidgets('onDismiss tap fires callback', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(
        EdenSchedulerConflictBanner(
          conflictCount: 2,
          onDismiss: () => called = true,
        ),
      ));
      await tester.tap(find.byIcon(Icons.close));
      expect(called, isTrue);
    });
  });

  group('EdenSchedulerSelectionBanner', () {
    testWidgets('count=0 renders nothing', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSchedulerSelectionBanner(selectionCount: 0),
      ));
      expect(find.textContaining('selected'), findsNothing);
    });

    testWidgets('count=1 uses singular text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSchedulerSelectionBanner(selectionCount: 1),
      ));
      expect(find.text('1 event selected.'), findsOneWidget);
    });

    testWidgets('count=3 uses plural text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSchedulerSelectionBanner(selectionCount: 3),
      ));
      expect(find.text('3 events selected.'), findsOneWidget);
    });

    testWidgets('onClear tap fires callback', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(
        EdenSchedulerSelectionBanner(
          selectionCount: 2,
          onClear: () => called = true,
        ),
      ));
      await tester.tap(find.text('Clear'));
      expect(called, isTrue);
    });

    testWidgets('custom actions render', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSchedulerSelectionBanner(
          selectionCount: 2,
          actions: [
            TextButton(onPressed: () {}, child: const Text('Reassign')),
          ],
        ),
      ));
      expect(find.text('Reassign'), findsOneWidget);
    });
  });
}

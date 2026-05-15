import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_offline_queue_viewer_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
        home: Scaffold(body: SizedBox(width: 600, height: 800, child: child)));
  }

  group('EdenOfflineQueueViewer', () {
    testWidgets(
        'empty queue renders empty state with message + check icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenOfflineQueueViewer(items: <EdenOfflineQueueItem>[]),
      ));
      expect(find.text('No pending changes'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('offline_queue_empty')),
        findsOneWidget,
      );
    });

    testWidgets('mixed queue renders one row per item with key',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
        ),
      ));
      for (final item in EdenOfflineQueueViewerFixtures.mixed) {
        expect(
          find.byKey(ValueKey<String>('queue_row_${item.id}')),
          findsOneWidget,
          reason: 'expected row for ${item.id}',
        );
      }
    });

    testWidgets('each row shows actionType + summary text', (tester) async {
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
        ),
      ));
      // Two items use 'Update Customer' so use findsAtLeastNWidgets.
      expect(find.text('Update Customer'), findsAtLeastNWidgets(1));
      expect(find.text('Create Work Order'), findsOneWidget);
      expect(find.text('Customer ABC123: phone → 555-0100'), findsOneWidget);
    });

    testWidgets('relative timestamps use the frozen now injection',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
        ),
      ));
      // q1 = 30s ago → 'just now'.
      // q2 = 5 min ago.
      // q3 = 2 h ago.
      // q4 = yesterday.
      expect(find.text('just now'), findsOneWidget);
      expect(find.text('5 min ago'), findsOneWidget);
      expect(find.text('2 h ago'), findsOneWidget);
      expect(find.text('yesterday'), findsOneWidget);
    });

    testWidgets('status pills render distinct labels per status',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
        ),
      ));
      expect(find.text('Pending'), findsNWidgets(2));
      expect(find.text('Syncing'), findsOneWidget);
      expect(find.text('Conflict'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('tapping Retry invokes onRetry with the item',
        (tester) async {
      EdenOfflineQueueItem? retried;
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
          onRetry: (item) => retried = item,
        ),
      ));
      // q5 is the error item.
      await tester.tap(find.byKey(const ValueKey<String>('retry_q5')));
      await tester.pump();
      expect(retried, isNotNull);
      expect(retried!.id, 'q5');
    });

    testWidgets(
        'tapping Discard opens confirm dialog; confirm fires onDiscard',
        (tester) async {
      EdenOfflineQueueItem? discarded;
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
          onDiscard: (item) => discarded = item,
        ),
      ));
      await tester.tap(find.byKey(const ValueKey<String>('discard_q1')));
      await tester.pumpAndSettle();
      // Confirm dialog visible.
      expect(find.text('Discard change?'), findsOneWidget);
      // The dialog adds a "Discard" button on top of the per-row buttons.
      // Tap the LAST occurrence — the dialog's confirm button.
      await tester.tap(find.text('Discard').last);
      await tester.pumpAndSettle();
      expect(discarded, isNotNull);
      expect(discarded!.id, 'q1');
    });

    testWidgets(
        'conflict item shows Resolve button + tapping fires onResolveConflict',
        (tester) async {
      EdenOfflineQueueItem? resolved;
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: EdenOfflineQueueViewerFixtures.mixed,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
          onResolveConflict: (item) => resolved = item,
        ),
      ));
      // q4 has status=conflict.
      expect(find.byKey(const ValueKey<String>('resolve_q4')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('resolve_q4')));
      await tester.pump();
      expect(resolved, isNotNull);
      expect(resolved!.id, 'q4');
    });

    testWidgets('payload preview is truncated to 80 chars with ellipsis',
        (tester) async {
      final longPayload = 'x' * 200;
      final items = <EdenOfflineQueueItem>[
        EdenOfflineQueueItem(
          id: 'long',
          actionType: 'Update Customer',
          summary: 'big payload',
          queuedAt: EdenOfflineQueueViewerFixtures.referenceNow,
          payloadPreview: longPayload,
        ),
      ];
      await tester.pumpWidget(wrap(
        EdenOfflineQueueViewer(
          items: items,
          now: EdenOfflineQueueViewerFixtures.referenceNow,
        ),
      ));
      // The rendered preview should be truncated.
      final expected = '${'x' * 80}…';
      expect(find.text(expected), findsOneWidget);
      expect(find.text(longPayload), findsNothing);
    });
  });
}

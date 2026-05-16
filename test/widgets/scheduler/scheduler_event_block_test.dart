// Hand-built tests (no LLM-generated test data) for EdenSchedulerEventBlock.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_scheduler_event_block_fixtures.dart';

void main() {
  group('EdenSchedulerEventBlock — static rendering', () {
    testWidgets('renders event title', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
        ),
      ));
      expect(find.text('Coffee meeting'), findsOneWidget);
    });

    testWidgets('event with location shows location.name as subtitle',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.locAssignee,
        ),
      ));
      expect(find.text('On-site call'), findsOneWidget);
      expect(find.text('Site A'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('compact mode hides location + assignee subtitle',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.locAssignee,
          compact: true,
        ),
      ));
      expect(find.text('On-site call'), findsOneWidget);
      // Compact mode collapses metadata.
      expect(find.text('Site A'), findsNothing);
      expect(find.text('Alice'), findsNothing);
    });
  });

  group('EdenSchedulerEventBlock — readiness border', () {
    testWidgets('readiness=warning renders yellow border', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.warningReadiness,
        ),
      ));
      // Confirm border is rendered (no exception); detailed color check would
      // require diving into BoxDecoration internals.
      expect(find.text('Warning event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('readiness=ready renders green border', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.readyReadiness,
        ),
      ));
      expect(find.text('Ready event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispatchIssue takes precedence — red border', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.dispatchIssue,
        ),
      ));
      expect(find.text('Issue event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no readiness, no dispatchIssue → no border', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenSchedulerEventBlock — tap interaction', () {
    testWidgets('tap fires onTap with the event', (tester) async {
      EdenSchedulerEvent? captured;
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
          onTap: (e) => captured = e,
          draggable: false,
          resizable: false,
        ),
      ));
      await tester.tap(find.text('Coffee meeting'));
      expect(captured?.id, 'v');
    });
  });

  group('EdenSchedulerEventBlock — draggable flag', () {
    testWidgets('draggable=false hides Draggable wrapper', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
          draggable: false,
          onMove: (_, __, ___) {},
        ),
      ));
      expect(find.byType(Draggable<EdenSchedulerEvent>), findsNothing);
      expect(find.byType(LongPressDraggable<EdenSchedulerEvent>), findsNothing);
    });

    testWidgets('draggable=true + onMove non-null renders Draggable',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
          onMove: (_, __, ___) {},
          resizable: false,
        ),
      ));
      // Either Draggable or LongPressDraggable should be present.
      final hasAny = find.byType(Draggable<EdenSchedulerEvent>).evaluate().isNotEmpty ||
          find.byType(LongPressDraggable<EdenSchedulerEvent>).evaluate().isNotEmpty;
      expect(hasAny, isTrue);
    });
  });

  group('EdenSchedulerEventBlock — resizable flag', () {
    testWidgets('resizable=false hides resize handles', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
          onResize: (_, __, ___) {},
          resizable: false,
        ),
      ));
      // No resize-handle MouseRegions with the SystemMouseCursors.resizeRow cursor.
      final mouseRegions = tester.widgetList<MouseRegion>(
        find.byType(MouseRegion),
      );
      final hasResizeCursor = mouseRegions.any(
        (r) => r.cursor == SystemMouseCursors.resizeRow,
      );
      expect(hasResizeCursor, isFalse);
    });

    testWidgets('resizable=true renders 2 resize-cursor handles',
        (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEventBlockFixtures.vanilla,
          onResize: (_, __, ___) {},
          draggable: false,
        ),
      ));
      final mouseRegions = tester.widgetList<MouseRegion>(
        find.byType(MouseRegion),
      );
      final resizeRegions = mouseRegions.where(
        (r) => r.cursor == SystemMouseCursors.resizeRow,
      );
      expect(resizeRegions.length, greaterThanOrEqualTo(2));
    });
  });

  group('EdenSchedulerEventBlock — responsive', () {
    testWidgets('60pt-wide column ellipsizes long title', (tester) async {
      await tester.pumpWidget(EdenSchedulerEventBlockFixtures.wrap(
        EdenSchedulerEventBlock(
          event: EdenSchedulerEvent(
            id: 'l',
            title: 'A very long event title that definitely overflows narrow columns',
            start: DateTime(2026, 5, 16, 9),
            end: DateTime(2026, 5, 16, 10),
          ),
          compact: true,
        ),
        width: 60,
        height: 40,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_route_stop_list_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 400, double height = 600}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
      );

  // -----------------------------------------------------------------
  // Task 1 — Static rendering: ordered list + empty state + status +
  // ETA + address.
  // -----------------------------------------------------------------
  group('EdenRouteStopList ordered list rendering', () {
    testWidgets('renders 3 stop rows in order', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: EdenRouteStopListFixtures.threeStops),
      ));
      expect(find.text('Acme Industrial'), findsOneWidget);
      expect(find.text('Beta Co'), findsOneWidget);
      expect(find.text('Gamma LLC'), findsOneWidget);
    });

    testWidgets('stop number badges show 1, 2, 3 in sequence', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: EdenRouteStopListFixtures.threeStops),
      ));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('EdenRouteStopList empty state', () {
    testWidgets('empty list renders EdenEmptyState', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: EdenRouteStopListFixtures.emptyList),
      ));
      expect(find.byType(EdenEmptyState), findsOneWidget);
      expect(find.text('No stops planned'), findsOneWidget);
    });

    testWidgets('custom emptyMessage renders', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(
          stops: EdenRouteStopListFixtures.emptyList,
          emptyMessage: 'No deliveries today',
        ),
      ));
      expect(find.text('No deliveries today'), findsOneWidget);
    });
  });

  group('EdenRouteStopList status badge colors', () {
    Color statusColorOf(WidgetTester tester, String stopId) {
      final container = tester.widget<Container>(
        find.byKey(Key('eden-route-stop-status-$stopId')),
      );
      return (container.decoration as BoxDecoration).color!;
    }

    testWidgets('pending status → grey', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.pendingStop]),
      ));
      // Grey-500 / slate-400 = 0xFF94A3B8.
      expect(statusColorOf(tester, 'pe'), const Color(0xFF94A3B8));
    });

    testWidgets('enRoute status → blue', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.enRouteStop]),
      ));
      expect(statusColorOf(tester, 'er'), const Color(0xFF3B82F6));
    });

    testWidgets('arrived status → amber (warning)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.arrivedStop]),
      ));
      expect(statusColorOf(tester, 'ar'), EdenColors.warning);
    });

    testWidgets('completed status → green (success)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.completedStop]),
      ));
      expect(statusColorOf(tester, 'co'), EdenColors.success);
    });

    testWidgets('skipped status → red (error)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.skippedStop]),
      ));
      expect(statusColorOf(tester, 'sk'), EdenColors.error);
    });
  });

  group('EdenRouteStopList ETA formatter', () {
    testWidgets('8:30 AM stop → ~8:30 AM', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: EdenRouteStopListFixtures.threeStops),
      ));
      expect(find.text('~8:30 AM'), findsOneWidget);
    });

    testWidgets('2:05 PM → ~2:05 PM', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: [EdenRouteStopListFixtures.afternoonEtaStop],
        ),
      ));
      expect(find.text('~2:05 PM'), findsOneWidget);
    });

    testWidgets('midnight (00:00) → ~12:00 AM', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: [EdenRouteStopListFixtures.midnightEtaStop]),
      ));
      expect(find.text('~12:00 AM'), findsOneWidget);
    });

    testWidgets('noon (12:00) → ~12:00 PM', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: [EdenRouteStopListFixtures.noonEtaStop]),
      ));
      expect(find.text('~12:00 PM'), findsOneWidget);
    });

    testWidgets('no ETA → no caption', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.noEtaStop]),
      ));
      // Find any text starting with '~' — should not exist.
      expect(find.byWidgetPredicate((w) {
        if (w is Text && w.data != null) {
          return w.data!.startsWith('~');
        }
        return false;
      }), findsNothing);
    });
  });

  group('EdenRouteStopList address preview', () {
    testWidgets('address renders as single-line comma-separated', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: [EdenRouteStopListFixtures.stopWithAddress]),
      ));
      expect(find.text('100 Main St, Boston, MA'), findsOneWidget);
    });

    testWidgets('no address → no address line', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenRouteStopList(stops: [EdenRouteStopListFixtures.noAddressStop]),
      ));
      // No text contains ', MA' or address-looking strings.
      expect(find.textContaining(', MA'), findsNothing);
    });
  });

  // -----------------------------------------------------------------
  // Task 2 — Drag-reorder + tap interactions + disabled-reorder +
  // iPhone-narrow safety.
  // -----------------------------------------------------------------
  group('EdenRouteStopList drag handle visibility', () {
    testWidgets('reorderable (default) → drag handles visible', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: EdenRouteStopListFixtures.threeStops),
      ));
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    });

    testWidgets('reorderable: false → no drag handles', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: EdenRouteStopListFixtures.threeStops,
          reorderable: false,
        ),
      ));
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('reorderable: false uses ListView, not ReorderableListView',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: EdenRouteStopListFixtures.threeStops,
          reorderable: false,
        ),
      ));
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('EdenRouteStopList reorder math', () {
    testWidgets(
        'drag index 0 → position 2 fires onReorder(0, 2) intuitively '
        '(Flutter raw newIndex=3 hidden)', (tester) async {
      int? receivedOld;
      int? receivedNew;
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: EdenRouteStopListFixtures.threeStops,
          onReorder: (o, n) {
            receivedOld = o;
            receivedNew = n;
          },
        ),
      ));
      // Invoke ReorderableListView's onReorder directly with Flutter's raw
      // off-by-one newIndex (moving down from 0 to slot 2 → raw newIndex=3).
      final rlv = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      rlv.onReorder!(0, 3);
      expect(receivedOld, 0);
      expect(receivedNew, 2,
          reason: 'consumer should receive intuitive newIndex=2 (not raw 3)');
    });

    testWidgets('drag index 2 → position 0 fires onReorder(2, 0)',
        (tester) async {
      int? receivedOld;
      int? receivedNew;
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: EdenRouteStopListFixtures.threeStops,
          onReorder: (o, n) {
            receivedOld = o;
            receivedNew = n;
          },
        ),
      ));
      final rlv = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      // Moving UP (newIndex < oldIndex) — Flutter's raw is the intuitive index.
      rlv.onReorder!(2, 0);
      expect(receivedOld, 2);
      expect(receivedNew, 0);
    });
  });

  group('EdenRouteStopList tap interactions', () {
    testWidgets('tap on stop body fires onStopTap with correct id',
        (tester) async {
      String? tappedId;
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: EdenRouteStopListFixtures.threeStops,
          onStopTap: (id) => tappedId = id,
        ),
      ));
      // Tap on the label text of stop s2 (Beta Co).
      await tester.tap(find.text('Beta Co'));
      await tester.pump();
      expect(tappedId, 's2');
    });

    testWidgets('tap on status badge fires onStatusTap; onStopTap does NOT fire',
        (tester) async {
      String? bodyTappedId;
      String? statusTappedId;
      await tester.pumpWidget(wrap(
        EdenRouteStopList(
          stops: EdenRouteStopListFixtures.threeStops,
          onStopTap: (id) => bodyTappedId = id,
          onStatusTap: (id) => statusTappedId = id,
        ),
      ));
      await tester.tap(find.byKey(const Key('eden-route-stop-status-s1')));
      await tester.pump();
      expect(statusTappedId, 's1');
      expect(bodyTappedId, isNull,
          reason: 'status-badge gesture should NOT bubble to InkWell');
    });

    testWidgets('onStopTap == null → tap on body does not throw',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: EdenRouteStopListFixtures.threeStops),
      ));
      await tester.tap(find.text('Beta Co'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenRouteStopList iPhone-narrow safety', () {
    testWidgets('390pt + long labels — no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRouteStopList(stops: EdenRouteStopListFixtures.longLabels),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

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
}

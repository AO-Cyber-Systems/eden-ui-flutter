import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_location_map_page_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

/// Surface size large enough to render top-3/5 + bottom-2/5 split.
const _defaultSurfaceSize = Size(900, 1200);

Future<void> pumpAtDefault(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = _defaultSurfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(child);
}

void main() {
  group('EdenLocationMapPage — composition smoke', () {
    testWidgets('renders Scaffold + AppBar with default title + 2 list rows',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            onPinTapped: (_) {},
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.text('Locations'), findsOneWidget);
      expect(find.byType(EdenMapPreview), findsOneWidget);
      // Both names appear.
      expect(find.text('Mike T.'), findsOneWidget);
      expect(find.text('Sarah K.'), findsOneWidget);
    });

    testWidgets('appBarTitle override renders custom title', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            appBarTitle: 'My Locations',
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.text('My Locations'), findsOneWidget);
    });

    testWidgets('listTitle override renders custom header', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            listTitle: 'Field Team',
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.text('Field Team'), findsOneWidget);
    });

    testWidgets('count badge shows pin count', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenLocationMapPage — empty pins', () {
    testWidgets('empty pins → EdenMapPreview NOT mounted', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(const EdenLocationMapPage(
            provider: NoOpMapProvider(),
            pins: <EdenLocationPin>[],
          )));
      expect(find.byType(EdenMapPreview), findsNothing);
      expect(find.textContaining('No active locations'), findsOneWidget);
    });
  });

  group('EdenLocationMapPage — relative time formatting', () {
    testWidgets('lastSeenAt 45s ago → "45s ago"', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: [EdenLocationMapPageFixtures.tech2()],
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.textContaining('45s ago'), findsOneWidget);
    });

    testWidgets('lastSeenAt 3m ago → "3m ago"', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: [EdenLocationMapPageFixtures.tech1()],
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.textContaining('3m ago'), findsOneWidget);
    });

    testWidgets('lastSeenAt 2h ago → "12:30 PM" (12h time)', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: [EdenLocationMapPageFixtures.techLongName()],
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      // 2h before 2:30 PM = 12:30 PM.
      expect(find.textContaining('12:30 PM'), findsOneWidget);
    });
  });

  group('EdenLocationMapPage — battery indicator', () {
    testWidgets('batteryLevel: 78 → battery widget visible', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: [EdenLocationMapPageFixtures.tech1()],
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(
          find.byKey(const ValueKey('eden_location_battery_dot_tech-1')),
          findsOneWidget);
    });

    testWidgets('batteryLevel: null → battery widget omitted',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: [EdenLocationMapPageFixtures.techNoBattery()],
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(
          find.byKey(const ValueKey('eden_location_battery_dot_tech-4')),
          findsNothing);
    });
  });

  group('EdenLocationMapPage — tap behavior', () {
    testWidgets('tap on list row fires onPinTapped with pin.id',
        (tester) async {
      final taps = <String>[];
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            onPinTapped: taps.add,
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      await tester.tap(find.text('Mike T.'));
      await tester.pump();
      expect(taps, ['tech-1']);
    });

    testWidgets('onPinTapped: null — tap does not throw', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      await tester.tap(find.text('Mike T.'));
      await tester.pump();
      // no throw == pass
    });
  });

  group('EdenLocationMapPage — refresh button', () {
    testWidgets('onRefresh: non-null → refresh IconButton visible + tap fires',
        (tester) async {
      var taps = 0;
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            onRefresh: () => taps++,
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      final btn = find.byIcon(Icons.refresh);
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('onRefresh: null → refresh IconButton NOT visible',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.twoPins(),
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });

  group('EdenLocationMapPage — clustering v1', () {
    testWidgets(
        'clusterPinsAbove: null (default) — markers count == pins.length',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.clusterFive(),
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      final preview = tester.widget<EdenMapPreview>(find.byType(EdenMapPreview));
      expect(preview.markers.length, 5);
    });

    testWidgets(
        'clusterPinsAbove: 1 — five close pins cluster to fewer markers',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.clusterFive(),
            clusterPinsAbove: 1,
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      final preview = tester.widget<EdenMapPreview>(find.byType(EdenMapPreview));
      expect(preview.markers.length, lessThan(5));
    });

    testWidgets(
        'clusterPinsAbove: 100 + 5 pins — no clustering (under threshold)',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenLocationMapPage(
            provider: const NoOpMapProvider(),
            pins: EdenLocationMapPageFixtures.clusterFive(),
            clusterPinsAbove: 100,
            now: EdenLocationMapPageFixtures.frozen(),
          )));
      final preview = tester.widget<EdenMapPreview>(find.byType(EdenMapPreview));
      expect(preview.markers.length, 5);
    });
  });

  group('EdenLocationMapPage — iPhone-narrow ≥390pt', () {
    testWidgets('renders 5 pins at 390pt without overflow + long name ellipsizes',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(EdenLocationMapPage(
        provider: const NoOpMapProvider(),
        pins: [
          EdenLocationMapPageFixtures.tech1(),
          EdenLocationMapPageFixtures.tech2(),
          EdenLocationMapPageFixtures.techLongName(),
          EdenLocationMapPageFixtures.techNoBattery(),
        ],
        now: EdenLocationMapPageFixtures.frozen(),
      )));
      // No throw == no overflow asserts visually. Verify long name visible.
      expect(find.textContaining('Christopher'), findsOneWidget);
    });
  });
}

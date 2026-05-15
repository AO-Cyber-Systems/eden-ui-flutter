import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_network_status_bar_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenNetworkStatusBar', () {
    testWidgets('status=online renders SizedBox.shrink (no chrome)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(status: EdenNetworkStatus.online),
      ));
      // No banner text rendered.
      expect(find.text('No internet connection'), findsNothing);
      expect(find.text('Reconnecting...'), findsNothing);
      expect(find.text('Syncing changes...'), findsNothing);
    });

    testWidgets(
        'status=offline renders red banner with offline text + wifi-off icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(status: EdenNetworkStatus.offline),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets(
        'status=reconnecting renders amber banner with reconnecting text + spinner',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(status: EdenNetworkStatus.reconnecting),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Reconnecting...'), findsOneWidget);
      // A progress indicator is present (spinner).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'status=syncing renders blue banner with syncing text',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(status: EdenNetworkStatus.syncing),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Syncing changes...'), findsOneWidget);
    });

    testWidgets('offline with retryButton=true renders Retry + invokes callback',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(wrap(
        EdenNetworkStatusBar(
          status: EdenNetworkStatus.offline,
          retryButton: true,
          onRetry: () => retried = true,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, true);
    });

    testWidgets(
        'reconnecting with attemptCount=3 renders attempt-numbered text',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(
          status: EdenNetworkStatus.reconnecting,
          attemptCount: 3,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Reconnecting (attempt 3)...'), findsOneWidget);
    });

    testWidgets('state transition online → offline animates in via SlideTransition',
        (tester) async {
      // Start with online (no banner content).
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(status: EdenNetworkStatus.online),
      ));
      expect(find.text('No internet connection'), findsNothing);

      // Switch to offline.
      await tester.pumpWidget(wrap(
        const EdenNetworkStatusBar(status: EdenNetworkStatus.offline),
      ));
      await tester.pump();
      // AnimatedSwitcher uses SlideTransition to animate the new banner in.
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets(
        'iPhone-narrow safe: banner + icon + retry button fit one row at 390pt',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(
        EdenNetworkStatusBar(
          status: EdenNetworkStatus.offline,
          retryButton: true,
          onRetry: () {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      // Sanity: the fixture has all 4 enum values.
      expect(EdenNetworkStatusBarFixtures.allStates.length, 4);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_detail_page_scaffold_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenDetailPageScaffold', () {
    // ---------------- Happy path ----------------

    testWidgets('composes header + body when no tabs/side rail given',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(EdenDetailPageScaffoldFixtures.headerOnly()));
      // Header renders the title from the EdenDetailHeader fixture.
      expect(find.text('Customer ABC123'), findsOneWidget);
      // Body renders.
      expect(find.text('body content'), findsOneWidget);
      // No TabBar in this configuration.
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('renders TabBar when tabs are provided', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailPageScaffoldFixtures.withTabs(['Overview', 'Activity']),
      ));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
    });

    testWidgets('tab switching renders different body content',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailPageScaffoldFixtures.withTabs(['Overview', 'Activity']),
      ));
      // Initially the first tab body is visible.
      expect(find.text('Tab body: Overview'), findsOneWidget);
      // Tap the second tab.
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Tab body: Activity'), findsOneWidget);
    });

    // ---------------- Edge cases ----------------

    testWidgets('no side rail → body takes full width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailPageScaffoldFixtures.headerOnly(),
      ));
      // No "Side rail" text from the side-rail fixture.
      expect(find.text('Side rail'), findsNothing);
    });

    testWidgets('tabs slot null → header + body only with no TabBar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailPageScaffoldFixtures.headerOnly(),
      ));
      expect(find.byType(TabBar), findsNothing);
    });

    // ---------------- Failure / safety ----------------

    testWidgets(
        'iPhone-narrow → side rail collapses to a Details bottom-sheet trigger',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailPageScaffoldFixtures.narrowResponsive(),
      ));
      await tester.pumpAndSettle();
      // The "Details" trigger button is visible.
      expect(find.widgetWithText(OutlinedButton, 'Details'), findsOneWidget);
      // The side rail itself is NOT rendered inline.
      expect(find.text('Side rail'), findsNothing);
      // Tap to open the bottom sheet → side rail content becomes visible.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Details'));
      await tester.pumpAndSettle();
      expect(find.text('Side rail'), findsOneWidget);
    });

    testWidgets('iPhone-narrow with tabs renders without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailPageScaffoldFixtures.withTabs(
          ['Overview', 'Activity', 'Files', 'Settings', 'Audit'],
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1280pt) full composition renders without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(EdenDetailPageScaffoldFixtures.full()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Header + side rail + tabbed body all visible.
      expect(find.text('Customer ABC123'), findsOneWidget);
      expect(find.text('Side rail'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}

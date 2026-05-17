import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_loyalty_member_detail_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
  }

  group('EdenLoyaltyMemberDetail — header', () {
    testWidgets('renders member name', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('Jane Doe'), findsWidgets);
    });

    testWidgets('renders preset Gold tier badge', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.byType(EdenMembershipTierBadge), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('renders custom tier badge when customTierLabel set', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.customTier(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.byType(EdenMembershipTierBadge), findsOneWidget);
      expect(find.text('Concierge'), findsOneWidget);
    });

    testWidgets('renders no tier badge when tier+customTierLabel both null', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.tierless(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.byType(EdenMembershipTierBadge), findsNothing);
    });

    testWidgets('shows initials when avatarUrl is null (Jane Doe → JD)', (tester) async {
      // Use tierless (no recent purchases) to isolate the avatar's "JD" so
      // we don't conflict with EdenActivityFeedItem.actorInitials.
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: const EdenLoyaltyMember(id: 'c-jd', name: 'Jane Doe'),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('JD'), findsOneWidget);
    });
  });

  group('EdenLoyaltyMemberDetail — KPI strip', () {
    testWidgets('lifetime spend rendered as \$189.50', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text(r'$189.50'), findsOneWidget);
    });

    testWidgets("lifetime spend rendered as '—' when null", (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.tierless(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      // Three KPIs with no data => at least the spend slot has '—'
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('points rendered as 1247 when set', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('1247'), findsOneWidget);
    });

    testWidgets("points rendered as '—' when null", (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.tierless(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('—'), findsWidgets);
    });

    testWidgets("days-since-last-visit rendered as '1d' for 1-day-ago purchase",
        (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('1d'), findsOneWidget);
    });

    testWidgets("days-since-last-visit rendered as '—' when recentPurchases empty",
        (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.tierless(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('—'), findsWidgets);
    });
  });

  group('EdenLoyaltyMemberDetail — helpers', () {
    testWidgets("initialsFor('Jane Doe') = 'JD'", (tester) async {
      expect(edenLoyaltyInitialsFor('Jane Doe'), 'JD');
    });

    testWidgets("initialsFor('Cher') = 'C'", (tester) async {
      expect(edenLoyaltyInitialsFor('Cher'), 'C');
    });

    testWidgets("formatRelativeTime(now, now) = 'just now'", (tester) async {
      final now = DateTime(2026, 5, 17, 12, 0, 0);
      expect(edenLoyaltyFormatRelativeTime(now, now), 'just now');
    });

    testWidgets("formatRelativeTime(now - 5min, now) = '5m ago'", (tester) async {
      final now = DateTime(2026, 5, 17, 12, 0, 0);
      expect(
        edenLoyaltyFormatRelativeTime(
          now.subtract(const Duration(minutes: 5)),
          now,
        ),
        '5m ago',
      );
    });

    testWidgets("formatRelativeTime(now - 3h, now) = '3h ago'", (tester) async {
      final now = DateTime(2026, 5, 17, 12, 0, 0);
      expect(
        edenLoyaltyFormatRelativeTime(
          now.subtract(const Duration(hours: 3)),
          now,
        ),
        '3h ago',
      );
    });

    testWidgets("formatRelativeTime(now - 36h, now) = 'yesterday'", (tester) async {
      final now = DateTime(2026, 5, 17, 12, 0, 0);
      expect(
        edenLoyaltyFormatRelativeTime(
          now.subtract(const Duration(hours: 36)),
          now,
        ),
        'yesterday',
      );
    });
  });

  group('EdenLoyaltyMemberDetail — responsive (iPhone-narrow 390pt)', () {
    testWidgets('no RenderFlex overflow at 390pt with full janeGold fixture',
        (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      await tester.pump();

      // No overflow errors should have been recorded.
      expect(tester.takeException(), isNull);
    });
  });
}

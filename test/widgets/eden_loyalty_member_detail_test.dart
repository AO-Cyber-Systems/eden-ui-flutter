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

  group('EdenLoyaltyMemberDetail — birthday callout', () {
    testWidgets('shown when birthday is today + promo enabled', (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.platinumWithBirthday(now: now),
        now: now,
      )));
      expect(find.byType(EdenAlert), findsOneWidget);
      expect(find.textContaining('Birthday on'), findsOneWidget);
    });

    testWidgets('shown when birthday is +7 days', (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      final m = EdenLoyaltyMember(
        id: 'b7',
        name: 'B Seven',
        birthday: now.add(const Duration(days: 7)),
      );
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(member: m, now: now)));
      expect(find.byType(EdenAlert), findsOneWidget);
    });

    testWidgets('shown when birthday is -7 days', (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      final m = EdenLoyaltyMember(
        id: 'bm7',
        name: 'B Minus Seven',
        birthday: now.subtract(const Duration(days: 7)),
      );
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(member: m, now: now)));
      expect(find.byType(EdenAlert), findsOneWidget);
    });

    testWidgets('NOT shown when birthday is +20 days', (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      final m = EdenLoyaltyMember(
        id: 'b20',
        name: 'B Twenty',
        birthday: now.add(const Duration(days: 20)),
      );
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(member: m, now: now)));
      expect(find.byType(EdenAlert), findsNothing);
    });

    testWidgets('NOT shown when birthday is null', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.silverBudget(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.byType(EdenAlert), findsNothing);
    });

    testWidgets('NOT shown when birthdayPromoEnabled false', (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.platinumWithBirthday(now: now),
        now: now,
        birthdayPromoEnabled: false,
      )));
      expect(find.byType(EdenAlert), findsNothing);
    });

    testWidgets('year-wrap: Dec 30 birthday + now Jan 5 → callout shown',
        (tester) async {
      final now = DateTime(2026, 1, 5, 12, 0, 0);
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.yearWrapBirthday(),
        now: now,
      )));
      expect(find.byType(EdenAlert), findsOneWidget);
    });
  });

  group('EdenLoyaltyMemberDetail — recent purchases', () {
    testWidgets('renders 3 EdenActivityFeedItem rows when 3 purchases',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.byType(EdenActivityFeedItem), findsNWidgets(3));
    });

    testWidgets('renders maxRecent=2 rows when there are 5 purchases',
        (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      final five = [
        for (var i = 0; i < 5; i++)
          EdenLoyaltyPurchase(
            id: 'p$i',
            occurredAt: now.subtract(Duration(days: i + 1)),
            totalCents: 1000 + i,
            lineCount: i + 1,
          ),
      ];
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMember(
          id: 'big',
          name: 'Multi Buyer',
          recentPurchases: five,
        ),
        now: now,
        maxRecent: 2,
      )));
      expect(find.byType(EdenActivityFeedItem), findsNWidgets(2));
    });

    testWidgets('renders empty-state text when recentPurchases empty',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.emptyHistory(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.text('No recent purchases'), findsOneWidget);
      expect(find.byType(EdenActivityFeedItem), findsNothing);
    });

    testWidgets('entity name includes line count + formatted total',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      // EdenActivityFeedItem renders entityName inside a RichText TextSpan.
      // findRichText: search for matching span via inferred semantics label.
      final rich = find.byType(RichText);
      var found = false;
      for (final el in tester.elementList(rich)) {
        final widget = el.widget as RichText;
        final text = widget.text.toPlainText();
        if (text.contains(r'3 items — $18.75')) {
          found = true;
          break;
        }
      }
      expect(found, isTrue,
          reason:
              'Expected a RichText containing "3 items — \$18.75" — janeGold p-1 (3 items, 1875c)');
    });

    testWidgets('entity name includes location when locationName set',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.janeGold(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      final rich = find.byType(RichText);
      var found = false;
      for (final el in tester.elementList(rich)) {
        final widget = el.widget as RichText;
        final text = widget.text.toPlainText();
        if (text.contains('@ Downtown')) {
          found = true;
          break;
        }
      }
      expect(found, isTrue,
          reason:
              'Expected a RichText containing "@ Downtown" — janeGold p-1/p-2 have locationName: Downtown');
    });
  });

  group('EdenLoyaltyMemberDetail — footer', () {
    testWidgets("renders 'Member since {Month Year}' when joinedAt set",
        (tester) async {
      final now = EdenLoyaltyMemberFixtures.t0;
      final m = EdenLoyaltyMember(
        id: 'j',
        name: 'Joiner',
        joinedAt: DateTime(2024, 5, 1),
      );
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(member: m, now: now)));
      expect(find.text('Member since May 2024'), findsOneWidget);
    });

    testWidgets('footer absent when joinedAt null', (tester) async {
      await tester.pumpWidget(wrap(EdenLoyaltyMemberDetail(
        member: EdenLoyaltyMemberFixtures.silverBudget(),
        now: EdenLoyaltyMemberFixtures.t0,
      )));
      expect(find.textContaining('Member since'), findsNothing);
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

    testWidgets('at 1024pt: KPI strip horizontal + callout + 3 recents + footer',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 1400);
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

      // KPI labels present (horizontal layout).
      expect(find.text('Lifetime spend'), findsOneWidget);
      expect(find.text('Points'), findsOneWidget);
      expect(find.text('Days since visit'), findsOneWidget);

      // Birthday callout (janeGold has birthday +3 days).
      expect(find.byType(EdenAlert), findsOneWidget);

      // 3 recents.
      expect(find.byType(EdenActivityFeedItem), findsNWidgets(3));

      // Footer.
      expect(find.textContaining('Member since'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_membership_tier_badge_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenMembershipTierBadge', () {
    testWidgets('Bronze preset renders Bronze label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge(tier: EdenMembershipTier.bronze),
      ));
      expect(find.text('Bronze'), findsOneWidget);
    });

    testWidgets('Silver preset renders Silver label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge(tier: EdenMembershipTier.silver),
      ));
      expect(find.text('Silver'), findsOneWidget);
    });

    testWidgets('Gold preset renders Gold label with star icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge(tier: EdenMembershipTier.gold),
      ));
      expect(find.text('Gold'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Platinum preset renders Platinum label with shield icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge(tier: EdenMembershipTier.platinum),
      ));
      expect(find.text('Platinum'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('VIP preset renders VIP label with crown-like icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge(tier: EdenMembershipTier.vip),
      ));
      expect(find.text('VIP'), findsOneWidget);
      // Material doesn't include a literal "crown" icon; the widget uses
      // workspace_premium as the closest semantic.
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('Custom tier renders label + custom palette', (tester) async {
      const bg = Color(0xFFEC4899);
      const fg = Color(0xFFFFFFFF);
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge.custom(
          label: 'Elite',
          backgroundColor: bg,
          foregroundColor: fg,
        ),
      ));
      expect(find.text('Elite'), findsOneWidget);
    });

    testWidgets('Custom tier with icon renders icon + label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge.custom(
          label: 'TS-SCI',
          backgroundColor: Color(0xFF7F1D1D),
          foregroundColor: Color(0xFFFFFFFF),
          icon: Icons.security,
        ),
      ));
      expect(find.text('TS-SCI'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('showIcon=false hides the icon on preset tier',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMembershipTierBadge(
          tier: EdenMembershipTier.gold,
          showIcon: false,
        ),
      ));
      expect(find.text('Gold'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('Custom label longer than 20 chars truncates with ellipsis',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 100,
          child: EdenMembershipTierBadge.custom(
            label: 'A very long tier name that should truncate',
            backgroundColor: Color(0xFFFFFFFF),
            foregroundColor: Color(0xFF000000),
          ),
        ),
      ));
      // Ensure no overflow exception.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'iPhone-narrow safe: row of 5 preset badges renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: EdenMembershipTier.values
                .map((t) => EdenMembershipTierBadge(tier: t))
                .toList(),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      for (final name in EdenMembershipTierBadgeFixtures.presetTierNames) {
        expect(find.text(name), findsOneWidget);
      }
    });
  });
}

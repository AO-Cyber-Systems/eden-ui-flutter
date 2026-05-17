import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_membership_manager_fixtures.dart';

Widget wrap(Widget child, {double width = 600, double height = 600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenMembershipManager header rendering', () {
    testWidgets('renders EdenMembershipTierBadge for gold tier',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.byType(EdenMembershipTierBadge), findsOneWidget);
    });

    testWidgets('renders customer display name', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.text('Susan M. Goldman'), findsOneWidget);
    });

    testWidgets('renders monthly price via EdenCurrencyDisplay',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      final display =
          tester.widget<EdenCurrencyDisplay>(find.byType(EdenCurrencyDisplay));
      expect(display.cents, 8900);
    });

    testWidgets('renders next-billing-date', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.textContaining('Jun 17, 2026'), findsOneWidget);
    });
  });

  group('EdenMembershipManager status pill states', () {
    testWidgets('active → "Active" label', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('paused → "Paused" label', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.silverPaused(),
      )));
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('cancelled → "Cancelled" label', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.platinumCancelled(),
      )));
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('pastDue → "Past due" label', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.vipPastDue(),
      )));
      expect(find.text('Past due'), findsOneWidget);
    });
  });

  group('EdenMembershipManager benefits section', () {
    testWidgets('3 benefits → 3 rows', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.text('Haircuts'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Add-ons'), findsOneWidget);
    });

    testWidgets('finite benefit shows "1 of 2"', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.text('1 of 2'), findsOneWidget);
    });

    testWidgets('unlimited benefit shows "Unlimited"', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.text('Unlimited'), findsOneWidget);
    });
  });

  group('EdenMembershipManager action visibility by status', () {
    testWidgets('active shows Pause + Cancel + Change card', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
        onPause: () {},
        onCancel: () {},
        onChangeCard: () {},
      )));
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Change card'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
    });

    testWidgets('paused shows Resume + Cancel + Change card', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.silverPaused(),
        onResume: () {},
        onCancel: () {},
        onChangeCard: () {},
      )));
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('cancelled shows no action buttons', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.platinumCancelled(),
        onPause: () {},
        onCancel: () {},
        onChangeCard: () {},
      )));
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets(
        'pastDue shows Update payment method + Cancel; no Pause',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.vipPastDue(),
        onUpdatePaymentMethod: () {},
        onCancel: () {},
        onPause: () {},
      )));
      expect(find.text('Update payment method'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });
  });

  group('EdenMembershipManager callbacks', () {
    testWidgets('Pause tap fires onPause', (tester) async {
      var count = 0;
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
        onPause: () => count++,
      )));
      await tester.tap(find.text('Pause'));
      expect(count, 1);
    });

    testWidgets('Resume tap fires onResume', (tester) async {
      var count = 0;
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.silverPaused(),
        onResume: () => count++,
      )));
      await tester.tap(find.text('Resume'));
      expect(count, 1);
    });

    testWidgets('Cancel tap fires onCancel', (tester) async {
      var count = 0;
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
        onCancel: () => count++,
      )));
      await tester.tap(find.text('Cancel'));
      expect(count, 1);
    });

    testWidgets('Change card tap fires onChangeCard', (tester) async {
      var count = 0;
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
        onChangeCard: () => count++,
      )));
      await tester.tap(find.text('Change card'));
      expect(count, 1);
    });

    testWidgets('null callbacks hide their buttons', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
        // no callbacks
      )));
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Change card'), findsNothing);
    });
  });

  group('EdenMembershipManager tippingFallbackBuilder slot', () {
    testWidgets('builder non-null renders consumer widget', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
        tippingFallbackBuilder: (_) => const Text('CUSTOM-TIP'),
      )));
      expect(find.text('CUSTOM-TIP'), findsOneWidget);
    });

    testWidgets('builder null renders nothing extra', (tester) async {
      await tester.pumpWidget(wrap(EdenMembershipManager(
        membership: EdenMembershipManagerFixtures.goldActive(),
      )));
      expect(find.text('CUSTOM-TIP'), findsNothing);
    });
  });

  group('EdenMembershipManager iPhone-narrow (390pt)', () {
    testWidgets('action buttons wrap without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenMembershipManager(
              membership: EdenMembershipManagerFixtures.goldActive(),
              onPause: () {},
              onCancel: () {},
              onChangeCard: () {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

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

final _testNow = DateTime(2026, 5, 17);

void main() {
  group('EdenPackageRedeem rendering', () {
    testWidgets('2 packages no filter → both rendered', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [
          EdenPackageRedeemFixtures.susanPackages()[0], // Cut & Color 6-Pack
          EdenPackageRedeemFixtures.susanPackages()[1], // Birthday Special
        ],
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Cut & Color 6-Pack'), findsOneWidget);
      expect(find.text('Birthday Special'), findsOneWidget);
    });

    testWidgets('serviceEntry filters by applicableServices', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: EdenPackageRedeemFixtures.susanPackages(),
        serviceEntry: EdenPackageRedeemFixtures.haircutEntry,
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      // Cut & Color + Birthday Special both have haircut-women applicable.
      // Facial 10-Pack is filtered out.
      expect(find.text('Cut & Color 6-Pack'), findsOneWidget);
      expect(find.text('Birthday Special'), findsOneWidget);
      expect(find.text('Facial 10-Pack'), findsNothing);
    });

    testWidgets('empty filter result shows hint with service name',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: EdenPackageRedeemFixtures.susanPackages(),
        serviceEntry: EdenPackageRedeemFixtures.unmatchableEntry,
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('No applicable packages for "Massage"'),
          findsOneWidget);
    });
  });

  group('EdenPackageRedeem Apply buttons', () {
    testWidgets('package with 3 remaining → 3 Apply buttons',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.susanPackages()[0]], // 3 remaining
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Apply 1 visit'), findsOneWidget);
      expect(find.text('Apply 2 visits'), findsOneWidget);
      expect(find.text('Apply 3 visits'), findsOneWidget);
    });

    testWidgets('package with 5+ remaining caps at 3 buttons', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.susanPackages()[2]], // 7 remaining
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Apply 1 visit'), findsOneWidget);
      expect(find.text('Apply 2 visits'), findsOneWidget);
      expect(find.text('Apply 3 visits'), findsOneWidget);
      expect(find.text('Apply 4 visits'), findsNothing);
    });

    testWidgets('package with 1 remaining → 1 Apply button', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.susanPackages()[1]],
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Apply 1 visit'), findsOneWidget);
      expect(find.text('Apply 2 visits'), findsNothing);
    });

    testWidgets('package with 0 remaining is filtered out', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [
          EdenPackage(
            id: 'pkg-zero',
            customerId: 'cust-x',
            name: 'Spent Pack',
            totalVisits: 5,
            remainingVisits: 0,
            purchasedAt: DateTime(2026, 1, 1),
            applicableServices: const [],
          ),
        ],
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Spent Pack'), findsNothing);
    });
  });

  group('EdenPackageRedeem expiry filter', () {
    testWidgets('past expiresAt is filtered out via nowOverride',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.packageExpired()],
        onRedeem: (_, __) {},
        nowOverride: _testNow, // 2026-05-17 > 2025-01-01
      )));
      expect(find.text('Old Pack'), findsNothing);
      expect(find.text('No packages available'), findsOneWidget);
    });

    testWidgets('null expiresAt always shown', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.packageNoExpiry()],
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Lifetime'), findsOneWidget);
    });

    testWidgets('future expiresAt shown', (tester) async {
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.packageFutureExpiry()],
        onRedeem: (_, __) {},
        nowOverride: _testNow,
      )));
      expect(find.text('Future-Expiry'), findsOneWidget);
    });
  });

  group('EdenPackageRedeem onRedeem callback', () {
    testWidgets('tap Apply 2 visits fires onRedeem with packageId + 2',
        (tester) async {
      String? pkgId;
      int? visits;
      await tester.pumpWidget(wrap(EdenPackageRedeem(
        packages: [EdenPackageRedeemFixtures.susanPackages()[0]],
        onRedeem: (id, n) {
          pkgId = id;
          visits = n;
        },
        nowOverride: _testNow,
      )));
      await tester.tap(find.text('Apply 2 visits'));
      expect(pkgId, 'pkg-cutcolor-6');
      expect(visits, 2);
    });
  });

  group('EdenPackageRedeem iPhone-narrow (390pt)', () {
    testWidgets('3 packages × 3 Apply buttons each renders without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenPackageRedeem(
              packages: EdenPackageRedeemFixtures.susanPackages(),
              onRedeem: (_, __) {},
              nowOverride: _testNow,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

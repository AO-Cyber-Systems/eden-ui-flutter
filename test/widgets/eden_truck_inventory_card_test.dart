import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_truck_inventory_card_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 400, double height = 200}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
      );

  // -----------------------------------------------------------------
  // Task 1 — Static rendering + compose + decimal + edge cases
  // -----------------------------------------------------------------
  group('EdenTruckInventoryCard static rendering', () {
    testWidgets('renders truck icon (local_shipping_outlined)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets("renders truck label 'Truck 47'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      expect(find.text('Truck 47'), findsOneWidget);
    });

    testWidgets("renders fuel-type chip 'Propane'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      expect(find.widgetWithText(Chip, 'Propane'), findsOneWidget);
    });

    testWidgets("renders capacity '320/500 gal  •  64%'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      expect(find.text('320/500 gal  •  64%'), findsOneWidget);
    });

    testWidgets('renders EdenStockLevelIndicator', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      expect(find.byType(EdenStockLevelIndicator), findsOneWidget);
    });
  });

  group('EdenTruckInventoryCard EdenStockLevelIndicator compose params', () {
    testWidgets('showLabel: false (suppress internal labels)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      final indicator = tester.widget<EdenStockLevelIndicator>(
        find.byType(EdenStockLevelIndicator),
      );
      expect(indicator.showLabel, isFalse);
    });

    testWidgets('currentStock: 64 (pre-computed percent for 320/500)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      final indicator = tester.widget<EdenStockLevelIndicator>(
        find.byType(EdenStockLevelIndicator),
      );
      expect(indicator.currentStock, 64);
    });

    testWidgets('reorderPoint: 0 (internal maxCapacity = 100 → percent gauge)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      final indicator = tester.widget<EdenStockLevelIndicator>(
        find.byType(EdenStockLevelIndicator),
      );
      expect(indicator.reorderPoint, 0);
    });
  });

  group('EdenTruckInventoryCard decimal precision', () {
    testWidgets("decimalFuel (320.5/500.0) → '320.5/500 gal  •  64%'",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.decimalFuel),
      ));
      expect(find.text('320.5/500 gal  •  64%'), findsOneWidget);
    });
  });

  group('EdenTruckInventoryCard edge cases', () {
    testWidgets("empty (0/500) → '0/500 gal  •  0%', no throw",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.emptyTank),
      ));
      expect(find.text('0/500 gal  •  0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("zeroCapacity (0/0) → '— / 0 gal  •  0%' (em-dash), no throw",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.zeroCapacity),
      ));
      expect(find.text('— / 0 gal  •  0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        "overfull (550/500) → '550/500 gal  •  100%' (clamped) + Overfull chip",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.overfull),
      ));
      expect(find.text('550/500 gal  •  100%'), findsOneWidget);
      expect(find.text('Overfull'), findsOneWidget);
    });

    testWidgets("full (500/500) → '500/500 gal  •  100%', NO Overfull chip",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.full),
      ));
      expect(find.text('500/500 gal  •  100%'), findsOneWidget);
      expect(find.text('Overfull'), findsNothing);
    });
  });

  // -----------------------------------------------------------------
  // Task 2 — onTap + responsive layout + iPhone-narrow
  // -----------------------------------------------------------------
  group('EdenTruckInventoryCard onTap', () {
    testWidgets(
        'onTap supplied → keyed outer InkWell present + tap fires',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenTruckInventoryCard(
          data: EdenTruckInventoryCardFixtures.normal,
          onTap: () => tapped = true,
        ),
      ));
      final inkWell =
          find.byKey(const ValueKey('eden-truck-inventory-card-tap'));
      expect(inkWell, findsOneWidget);
      await tester.tap(inkWell);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
        'no onTap → no keyed outer InkWell (Chip InkWell is allowed)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
      ));
      expect(
        find.byKey(const ValueKey('eden-truck-inventory-card-tap')),
        findsNothing,
      );
    });
  });

  group('EdenTruckInventoryCard responsive layout', () {
    testWidgets('width 300 → vertical layout (icon above percent)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
        width: 300,
        height: 400,
      ));
      final iconPos =
          tester.getCenter(find.byIcon(Icons.local_shipping_outlined));
      final percentPos = tester.getCenter(find.text('320/500 gal  •  64%'));
      expect(iconPos.dy, lessThan(percentPos.dy),
          reason: 'narrow → icon stacked above percent');
    });

    testWidgets('width 600 → horizontal layout (icon left of percent)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.normal),
        width: 600,
        height: 200,
      ));
      final iconPos =
          tester.getCenter(find.byIcon(Icons.local_shipping_outlined));
      final percentPos = tester.getCenter(find.text('320/500 gal  •  64%'));
      expect(iconPos.dx, lessThan(percentPos.dx),
          reason: 'wide → icon left of percent');
      expect((iconPos.dy - percentPos.dy).abs(), lessThan(60),
          reason: 'wide → icon + percent roughly aligned vertically');
    });
  });

  group('EdenTruckInventoryCard iPhone-narrow safety', () {
    testWidgets('390pt + longLabels — no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTruckInventoryCard(
            data: EdenTruckInventoryCardFixtures.longLabels),
        width: 390,
        height: 250,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

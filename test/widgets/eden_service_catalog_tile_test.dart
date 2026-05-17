import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_service_catalog_tile_fixtures.dart';

Widget wrap(Widget child, {double width = 600, double height = 400}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('formatServiceDuration', () {
    test('returns "0m" for 0 minutes', () {
      expect(formatServiceDuration(0), '0m');
    });
    test('returns "30m" for 30 minutes', () {
      expect(formatServiceDuration(30), '30m');
    });
    test('returns "1h" for 60 minutes', () {
      expect(formatServiceDuration(60), '1h');
    });
    test('returns "1h 30m" for 90 minutes', () {
      expect(formatServiceDuration(90), '1h 30m');
    });
    test('returns "2h 5m" for 125 minutes', () {
      expect(formatServiceDuration(125), '2h 5m');
    });
  });

  group('EdenServiceCatalogTile static rendering', () {
    testWidgets('renders EdenCard with service name', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      expect(find.byType(EdenCard), findsOneWidget);
      expect(find.text("Women's Haircut"), findsOneWidget);
    });

    testWidgets('renders duration "45m"', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      expect(find.text('45m'), findsOneWidget);
    });

    testWidgets('renders EdenCurrencyDisplay for price', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      expect(find.byType(EdenCurrencyDisplay), findsOneWidget);
      final display =
          tester.widget<EdenCurrencyDisplay>(find.byType(EdenCurrencyDisplay));
      expect(display.cents, 8500);
    });

    testWidgets('renders 3 EdenAvatar widgets for 3 capable staff',
        (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      expect(find.byType(EdenAvatar), findsNWidgets(3));
    });

    testWidgets('renders 2 customization chips when 2 customizations',
        (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      expect(find.text('Add color toner'), findsOneWidget);
      expect(find.text('Add blowout'), findsOneWidget);
    });

    testWidgets('empty capableStaff renders no EdenAvatar', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircutNoStaff(),
      )));
      expect(find.byType(EdenAvatar), findsNothing);
    });

    testWidgets('empty customizations renders no customization chips',
        (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircutNoCustomizations(),
      )));
      expect(find.text('Add color toner'), findsNothing);
      expect(find.text('Add blowout'), findsNothing);
    });

    testWidgets('null photoUrl renders placeholder spa icon', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircutNoPhoto(),
      )));
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    });

    testWidgets('non-null photoUrl renders Image network', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      // Image.network is rendered (may show errorBuilder fallback if network fails)
      // Either way, the photo branch is taken (not the spa_outlined placeholder)
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('8 staff renders 5 avatars + "+3" chip', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salon8Staff(),
      )));
      expect(find.byType(EdenAvatar), findsNWidgets(5));
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('5 staff renders 5 avatars + NO overflow chip',
        (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salon5Staff(),
      )));
      expect(find.byType(EdenAvatar), findsNWidgets(5));
      expect(find.text('+0'), findsNothing);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('6 staff renders 5 avatars + "+1" chip', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salon6Staff(),
      )));
      expect(find.byType(EdenAvatar), findsNWidgets(5));
      expect(find.text('+1'), findsOneWidget);
    });
  });

  group('EdenServiceCatalogTile interaction', () {
    testWidgets('tap fires onTap with the entry', (tester) async {
      EdenServiceCatalogEntry? tapped;
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
        onTap: (e) => tapped = e,
      )));
      await tester.tap(find.byType(EdenServiceCatalogTile));
      expect(tapped, isNotNull);
      expect(tapped!.id, 'salon-haircut');
    });

    testWidgets('null onTap does not throw on tap', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      await tester.tap(find.byType(EdenServiceCatalogTile));
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenServiceCatalogTile customizationsBuilder slot', () {
    testWidgets('builder replaces default chip strip', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
        customizationsBuilder: (_, entry) => Text('CUSTOM-${entry.id}'),
      )));
      expect(find.text('CUSTOM-salon-haircut'), findsOneWidget);
      expect(find.text('Add color toner'), findsNothing);
    });
  });

  group('EdenServiceCatalogTile theme-profile fallback', () {
    testWidgets('renders without EdenThemeProfileScope ancestor',
        (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.salonHaircut(),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with EdenThemeProfileScope ancestor commercialWarm',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenThemeProfileScope(
            profile: EdenThemeProfile.commercialWarm,
            child: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: EdenServiceCatalogTile(
                  entry: EdenServiceCatalogTileFixtures.salonHaircut(),
                ),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text("Women's Haircut"), findsOneWidget);
    });
  });

  group('EdenServiceCatalogTile iPhone-narrow (390pt) safety', () {
    testWidgets('8 staff + 4 customizations + 60-char name renders safely',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenServiceCatalogTile(
          entry: EdenServiceCatalogTileFixtures.salonLongName(),
        ),
        width: 390,
        height: 600,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Premium Signature'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenServiceCatalogTile generic across verticals', () {
    testWidgets('trades install entry renders identically', (tester) async {
      await tester.pumpWidget(wrap(EdenServiceCatalogTile(
        entry: EdenServiceCatalogTileFixtures.tradesInstall(),
      )));
      expect(find.text('Install water heater'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

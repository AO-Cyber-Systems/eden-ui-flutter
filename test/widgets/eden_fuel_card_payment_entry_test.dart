import 'package:eden_ui_flutter/src/widgets/eden_fuel_card_payment_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_fuel_card_payment_entry_fixtures.dart';

Widget wrap(Widget child, {double width = 500}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

Future<void> pumpWide(WidgetTester tester, Widget child,
    {double width = 500}) async {
  await tester.binding.setSurfaceSize(Size(width + 100, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrap(child, width: width));
}

void main() {
  group('defaultPromptsFor — network-specific prompts', () {
    test('fleetCor has driverId / vehicleId / odometer / tripNumber', () {
      final p =
          EdenFuelCardPaymentEntry.defaultPromptsFor(EdenFuelCardNetwork.fleetCor);
      expect(p.map((e) => e.fieldKey),
          containsAll(['driverId', 'vehicleId', 'odometer', 'tripNumber']));
      expect(p.where((e) => e.required).map((e) => e.fieldKey),
          containsAll(['driverId', 'vehicleId', 'odometer']));
    });

    test('wex has driverId + odometer required', () {
      final p =
          EdenFuelCardPaymentEntry.defaultPromptsFor(EdenFuelCardNetwork.wex);
      expect(p.where((e) => e.required).map((e) => e.fieldKey),
          containsAll(['driverId', 'odometer']));
    });

    test('voyager has driverId + vehicleId required', () {
      final p =
          EdenFuelCardPaymentEntry.defaultPromptsFor(EdenFuelCardNetwork.voyager);
      expect(p.where((e) => e.required).map((e) => e.fieldKey),
          containsAll(['driverId', 'vehicleId']));
    });

    test('efs matches fleetCor required-set', () {
      final p =
          EdenFuelCardPaymentEntry.defaultPromptsFor(EdenFuelCardNetwork.efs);
      expect(p.where((e) => e.required).map((e) => e.fieldKey),
          containsAll(['driverId', 'vehicleId', 'odometer']));
    });

    test('generic has only driverId required', () {
      final p = EdenFuelCardPaymentEntry.defaultPromptsFor(
          EdenFuelCardNetwork.generic);
      expect(p.where((e) => e.required).map((e) => e.fieldKey), ['driverId']);
    });
  });

  group('networkLabel renders human-readable', () {
    test('all variants', () {
      expect(EdenFuelCardPaymentEntry.networkLabel(EdenFuelCardNetwork.fleetCor),
          'FleetCor');
      expect(EdenFuelCardPaymentEntry.networkLabel(EdenFuelCardNetwork.wex),
          'WEX');
      expect(EdenFuelCardPaymentEntry.networkLabel(EdenFuelCardNetwork.voyager),
          'Voyager');
      expect(EdenFuelCardPaymentEntry.networkLabel(EdenFuelCardNetwork.efs),
          'EFS');
      expect(EdenFuelCardPaymentEntry.networkLabel(EdenFuelCardNetwork.generic),
          'Generic fleet card');
    });
  });

  group('EdenFuelCardPaymentEntry — wizard flow', () {
    testWidgets('renders network label on step 1', (tester) async {
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.fleetCor,
          onSubmit: (_) {},
        ),
      );
      expect(find.text('FleetCor'), findsOneWidget);
    });

    testWidgets('next disabled until PAN entered', (tester) async {
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.fleetCor,
          onSubmit: (_) {},
        ),
      );
      final next = tester.widget<ElevatedButton>(
          find.byKey(const Key('fuel-card-next')));
      expect(next.onPressed, isNull);

      await tester.enterText(find.byType(TextField), '4111222233334444');
      await tester.pumpAndSettle();
      final next2 = tester.widget<ElevatedButton>(
          find.byKey(const Key('fuel-card-next')));
      expect(next2.onPressed, isNotNull);
    });

    testWidgets('swipe button visible when onSwipeCard provided',
        (tester) async {
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.fleetCor,
          onSubmit: (_) {},
          onSwipeCard: (ctx) async => '4111000022223333',
        ),
      );
      expect(find.byKey(const Key('fuel-card-swipe')), findsOneWidget);
    });

    testWidgets('swipe button auto-populates PAN', (tester) async {
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.fleetCor,
          onSubmit: (_) {},
          onSwipeCard: (ctx) async => '4111000022226666',
        ),
      );
      await tester.tap(find.byKey(const Key('fuel-card-swipe')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Last 4: 6666'), findsOneWidget);
    });

    testWidgets('progresses through all 4 steps and submits', (tester) async {
      EdenFuelCardPaymentDraft? captured;
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.generic,
          onSubmit: (d) => captured = d,
          prefilledAmount: 125.50,
        ),
      );
      // Step 1: enter PAN
      await tester.enterText(
          find.byType(TextField).first, '4111000022227777');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      // Step 2: enter required driverId
      await tester.enterText(find.byType(TextField).first, 'DRV-101');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      // Step 3: amount prefilled — advance
      expect(find.byKey(const Key('fuel-card-next')), findsOneWidget);
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      // Step 4: confirm
      expect(find.text('•••• 7777'), findsOneWidget);
      await tester.tap(find.byKey(const Key('fuel-card-submit')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.network, EdenFuelCardNetwork.generic);
      expect(captured!.panLast4, '7777');
      expect(captured!.amountUsd, 125.50);
      expect(captured!.promptValues['driverId'], 'DRV-101');
    });
  });

  group('EdenFuelCardPaymentEntry — PCI scope', () {
    testWidgets('draft contains ONLY last 4, not full PAN', (tester) async {
      EdenFuelCardPaymentDraft? captured;
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.generic,
          onSubmit: (d) => captured = d,
          prefilledAmount: 10,
        ),
      );
      await tester.enterText(
          find.byType(TextField).first, '4111000099998888');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'DRV');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-submit')));
      await tester.pumpAndSettle();
      expect(captured!.panLast4, '8888');
      expect(captured!.panLast4.length, 4);
    });
  });

  group('EdenFuelCardPaymentEntry — promptsOverride', () {
    testWidgets('REPLACES default prompts entirely', (tester) async {
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.fleetCor,
          onSubmit: (_) {},
          promptsOverride: FuelCardFixtures.customMinimalPrompts(),
        ),
      );
      await tester.enterText(find.byType(TextField), '4111111111111111');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      // FleetCor would have 4 prompts; override has 1 only
      expect(find.text('Driver ID'), findsOneWidget);
      expect(find.text('Vehicle ID'), findsNothing);
      expect(find.text('Odometer (mi)'), findsNothing);
    });
  });

  group('EdenFuelCardPaymentEntry — back navigation', () {
    testWidgets('back returns to previous step', (tester) async {
      await pumpWide(
        tester,
        EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.generic,
          onSubmit: (_) {},
        ),
      );
      await tester.enterText(find.byType(TextField).first, '4111000077776666');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fuel-card-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('fuel-card-back')));
      await tester.pumpAndSettle();
      expect(find.text('Generic fleet card'), findsOneWidget);
    });
  });
}

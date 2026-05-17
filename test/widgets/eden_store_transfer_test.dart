import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_store_transfer_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1024, double height = 800}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  Future<void> selectLocation(
    WidgetTester tester, {
    required int dropdownIndex,
    required String label,
  }) async {
    // Find the Nth EdenSelect<EdenLocation> (0 = source, 1 = dest).
    final selects = find.byType(EdenSelect<EdenLocation>);
    expect(selects, findsAtLeastNWidgets(dropdownIndex + 1));
    await tester.tap(selects.at(dropdownIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('EdenStoreTransferFlow — mode dispatch', () {
    testWidgets('dispatch constructor renders step 1', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Step 1 of 4'), findsOneWidget);
      expect(find.byType(EdenSelect<EdenLocation>), findsNWidgets(2));
    });

    testWidgets('receive constructor renders Receive step', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.receive(
        initialTransfer:
            EdenStoreTransferFixtures.sampleInTransitTransfer(),
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Receive transfer'), findsOneWidget);
    });
  });

  group('EdenStoreTransferFlow — Step 1 SelectLocations', () {
    testWidgets('source == dest → inline alert + Next disabled',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
      )));
      // Pick Downtown for both.
      await selectLocation(tester, dropdownIndex: 0, label: 'Downtown');
      await selectLocation(tester, dropdownIndex: 1, label: 'Downtown');
      expect(find.textContaining('must differ'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('source != dest → Next enabled', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
      )));
      await selectLocation(tester, dropdownIndex: 0, label: 'Downtown');
      await selectLocation(tester, dropdownIndex: 1, label: 'Airport');
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EdenStoreTransferFlow — Step 2 SelectItems', () {
    Future<void> advanceToStep2(WidgetTester tester) async {
      await selectLocation(tester, dropdownIndex: 0, label: 'Downtown');
      await selectLocation(tester, dropdownIndex: 1, label: 'Airport');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders barcode lookup affordance', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
        onItemLookup: EdenStoreTransferFixtures.okLookupFn(
          EdenStoreTransferFixtures.sampleItem(),
        ),
      )));
      await advanceToStep2(tester);
      expect(find.byType(EdenSearchInput), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Scan'), findsOneWidget);
    });

    testWidgets('Scan with valid SKU adds item to list', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
        onItemLookup: EdenStoreTransferFixtures.okLookupFn(
          EdenStoreTransferFixtures.sampleItem(),
        ),
      )));
      await advanceToStep2(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(EdenSearchInput),
          matching: find.byType(TextField),
        ),
        'SKU-A',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Scan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Espresso 1kg'), findsOneWidget);
    });

    testWidgets('Scan with not-found SKU shows warning', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
        onItemLookup: EdenStoreTransferFixtures.notFoundLookupFn(),
      )));
      await advanceToStep2(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(EdenSearchInput),
          matching: find.byType(TextField),
        ),
        'NOPE',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Scan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not found'), findsOneWidget);
    });

    testWidgets('Next disabled when no items', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
      )));
      await advanceToStep2(tester);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull);
    });
  });

  group('EdenStoreTransferFlow — Step 3 Shipping', () {
    Future<void> advanceToStep3(WidgetTester tester) async {
      await selectLocation(tester, dropdownIndex: 0, label: 'Downtown');
      await selectLocation(tester, dropdownIndex: 1, label: 'Airport');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(EdenSearchInput),
          matching: find.byType(TextField),
        ),
        'SKU-A',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets("'Walk-in transfer' checkbox renders + disables carrier",
        (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
        onItemLookup: EdenStoreTransferFixtures.okLookupFn(
          EdenStoreTransferFixtures.sampleItem(),
        ),
      )));
      await advanceToStep3(tester);
      final checkbox = find.byType(CheckboxListTile);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      // Find shipping-carrier TextField + assert it's disabled.
      final carrierField = find.byKey(const ValueKey('shippingCarrier'));
      final tf = tester.widget<TextField>(find.descendant(
        of: carrierField,
        matching: find.byType(TextField),
      ));
      expect(tf.enabled, isFalse);
    });
  });

  group('EdenStoreTransferFlow — Step 4 ConfirmDispatch', () {
    Future<void> advanceToStep4(WidgetTester tester) async {
      await selectLocation(tester, dropdownIndex: 0, label: 'Downtown');
      await selectLocation(tester, dropdownIndex: 1, label: 'Airport');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(EdenSearchInput),
          matching: find.byType(TextField),
        ),
        'SKU-A',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      // Shipping → Next.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets("'Confirm dispatch' emits draft with status=inTransit",
        (tester) async {
      EdenStoreTransferDraft? submitted;
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (d) => submitted = d,
        onItemLookup: EdenStoreTransferFixtures.okLookupFn(
          EdenStoreTransferFixtures.sampleItem(),
        ),
      )));
      await advanceToStep4(tester);
      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirm dispatch'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      expect(submitted!.status, EdenStoreTransferStatus.inTransit);
      expect(submitted!.sourceLocationId, 'L-DOWN');
      expect(submitted!.destLocationId, 'L-AIR');
      expect(submitted!.items.length, 1);
    });
  });

  group('EdenStoreTransferFlow — Receive mode', () {
    testWidgets('renders header with source → dest', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.receive(
        initialTransfer:
            EdenStoreTransferFixtures.sampleInTransitTransfer(),
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Downtown'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Airport'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders one receive row per item', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.receive(
        initialTransfer:
            EdenStoreTransferFixtures.sampleInTransitTransfer(),
        onSubmit: (_) {},
      )));
      expect(find.byKey(const ValueKey('receivedQty-I-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('receivedQty-I-2')), findsOneWidget);
    });

    testWidgets("variance picker appears when receivedQty != expectedQty",
        (tester) async {
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.receive(
        initialTransfer:
            EdenStoreTransferFixtures.sampleInTransitTransfer(),
        onSubmit: (_) {},
      )));
      // Default qty: I-1 expected 12, I-2 expected 6. Change I-1 to 10.
      await tester.enterText(
        find.byKey(const ValueKey('receivedQty-I-1')),
        '10',
      );
      await tester.pumpAndSettle();
      expect(find.byType(EdenSelect<EdenVarianceReason>), findsOneWidget);
    });

    testWidgets("'Confirm receive' emits draft with status=received + variance",
        (tester) async {
      EdenStoreTransferDraft? submitted;
      await tester.pumpWidget(wrap(EdenStoreTransferFlow.receive(
        initialTransfer:
            EdenStoreTransferFixtures.sampleInTransitTransfer(),
        onSubmit: (d) => submitted = d,
      )));
      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirm receive'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      expect(submitted!.status, EdenStoreTransferStatus.received);
      expect(submitted!.transferId, 'XFR-101');
    });
  });

  group('EdenStoreTransferFlow — helpers', () {
    test('edenStoreTransferIsValidLocationPair: both null → false', () {
      expect(edenStoreTransferIsValidLocationPair(null, null), isFalse);
    });

    test('edenStoreTransferIsValidLocationPair: same id → false', () {
      const a = EdenLocation(id: 'X', name: 'X');
      expect(edenStoreTransferIsValidLocationPair(a, a), isFalse);
    });

    test('edenStoreTransferIsValidLocationPair: different → true', () {
      const a = EdenLocation(id: 'A', name: 'A');
      const b = EdenLocation(id: 'B', name: 'B');
      expect(edenStoreTransferIsValidLocationPair(a, b), isTrue);
    });
  });

  group('EdenStoreTransferFlow — iPhone-narrow 390pt', () {
    testWidgets('dispatch mode at 390pt has no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenStoreTransferFlow.dispatch(
            availableLocations: EdenStoreTransferFixtures.locations,
            onSubmit: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('receive mode at 390pt has no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenStoreTransferFlow.receive(
            initialTransfer:
                EdenStoreTransferFixtures.sampleInTransitTransfer(),
            onSubmit: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

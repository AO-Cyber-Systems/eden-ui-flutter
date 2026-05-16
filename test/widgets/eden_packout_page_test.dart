import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_packout_page_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

const _defaultSurfaceSize = Size(900, 1600);

Future<void> pumpAtDefault(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = _defaultSurfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(child);
}

void main() {
  group('EdenPackoutPage — composition smoke', () {
    testWidgets('empty items → EdenEmptyState visible + no summary',
        (tester) async {
      await pumpAtDefault(tester, wrap(const EdenPackoutPage(items: [])));
      expect(find.text('No packout items'), findsOneWidget);
    });

    testWidgets('2 items → 2 cards visible + summary line',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(items: EdenPackoutPageFixtures.twoItems())));
      expect(find.text('3/4" copper pipe'), findsOneWidget);
      expect(find.text('R410A refrigerant'), findsOneWidget);
      // Summary "2 item types loaded · 14 units used" — 12 + 2 used.
      expect(find.textContaining('2 item types loaded'), findsOneWidget);
      expect(find.textContaining('14 units used'), findsOneWidget);
    });

    testWidgets('appBarTitle override visible', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: EdenPackoutPageFixtures.twoItems(),
            appBarTitle: 'Materials Audit',
          )));
      expect(find.text('Materials Audit'), findsOneWidget);
    });

    testWidgets('appointmentTitle visible in AppBar subtitle',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: EdenPackoutPageFixtures.twoItems(),
            appointmentTitle: 'HVAC Repair — Johnson',
          )));
      expect(find.text('HVAC Repair — Johnson'), findsOneWidget);
    });
  });

  group('EdenPackoutPage — card collapsed view', () {
    testWidgets('itemName + sku + 3 quantity chips visible', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(items: [EdenPackoutPageFixtures.copper()])));
      expect(find.text('3/4" copper pipe'), findsOneWidget);
      expect(find.textContaining('CU-075'), findsOneWidget);
      expect(find.text('Loaded'), findsOneWidget);
      expect(find.text('Used'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
    });

    testWidgets('sku: null → SKU text not rendered as a separate label',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
              items: [EdenPackoutPageFixtures.widgetNoSku()])));
      // Confirm the no-sku item rendered without the SKU prefix string.
      expect(find.textContaining('SKU:'), findsNothing);
    });
  });

  group('EdenPackoutPage — expand/collapse', () {
    testWidgets('tap card header expands to show Save button', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(items: [EdenPackoutPageFixtures.copper()])));
      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });
  });

  group('EdenPackoutPage — edit + dirty pill', () {
    testWidgets('change qty used → "Unsaved" pill visible', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(items: [EdenPackoutPageFixtures.copper()])));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('eden_packout_used_pi-1')), '15');
      await tester.pumpAndSettle();
      expect(find.text('Unsaved'), findsOneWidget);
    });
  });

  group('EdenPackoutPage — save semantics', () {
    testWidgets('save fires onSaveItem with edit; clears pending',
        (tester) async {
      final (captured, save) =
          EdenPackoutPageFixtures.saveRecorder();
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: [EdenPackoutPageFixtures.copper()],
            onSaveItem: save,
          )));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('eden_packout_used_pi-1')), '15');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(captured, hasLength(1));
      expect(captured.first.$2.used, 15);
      // Pending cleared → no "Unsaved" pill.
      expect(find.text('Unsaved'), findsNothing);
      expect(find.text('Usage saved'), findsOneWidget);
    });

    testWidgets('save error → SnackBar visible; pending persists',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: [EdenPackoutPageFixtures.copper()],
            onSaveItem: EdenPackoutPageFixtures.failingSave('boom'),
          )));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('eden_packout_used_pi-1')), '15');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to save'), findsOneWidget);
      expect(find.text('Unsaved'), findsOneWidget);
    });

    testWidgets('save disabled when not dirty', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: [EdenPackoutPageFixtures.copper()],
            onSaveItem: (_, __) async => EdenPackoutPageFixtures.copper(),
          )));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      final btn = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(btn.onPressed, isNull);
    });
  });

  group('EdenPackoutPage — refresh', () {
    testWidgets('onRefresh non-null → RefreshIndicator wraps the list',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: EdenPackoutPageFixtures.twoItems(),
            onRefresh: () async {},
          )));
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('onRefresh null → no RefreshIndicator wrap', (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(items: EdenPackoutPageFixtures.twoItems())));
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  group('EdenPackoutPage — summary count with pending edit', () {
    testWidgets('pending edit influences total units used',
        (tester) async {
      await pumpAtDefault(
          tester,
          wrap(EdenPackoutPage(
            items: [EdenPackoutPageFixtures.copper()],
            onSaveItem: (item, edit) async => item.copyWith(
              quantityUsed: edit.used,
              quantityReturned: edit.returned,
            ),
          )));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('eden_packout_used_pi-1')), '15');
      await tester.pumpAndSettle();
      // 15 (pending) used.
      expect(find.textContaining('15 units used'), findsOneWidget);
    });
  });

  group('EdenPackoutPage — didUpdateWidget items reset', () {
    testWidgets('items prop change resets _localItems + pending edits',
        (tester) async {
      // Use a Builder to swap items between pumps.
      late StateSetter setter;
      var items = [EdenPackoutPageFixtures.copper()];
      await pumpAtDefault(
          tester,
          wrap(StatefulBuilder(builder: (ctx, s) {
            setter = s;
            return EdenPackoutPage(items: items);
          })));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('eden_packout_used_pi-1')), '15');
      await tester.pumpAndSettle();
      expect(find.text('Unsaved'), findsOneWidget);
      // Swap items.
      setter(() {
        items = EdenPackoutPageFixtures.twoItems();
      });
      await tester.pumpAndSettle();
      expect(find.text('Unsaved'), findsNothing);
      expect(find.text('R410A refrigerant'), findsOneWidget);
    });
  });

  group('EdenPackoutPage — iPhone-narrow ≥390pt', () {
    testWidgets('3 items at 390pt no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(EdenPackoutPage(
        items: EdenPackoutPageFixtures.threeItems(),
      )));
      // No exception.
      expect(find.text('3/4" copper pipe'), findsOneWidget);
    });
  });
}

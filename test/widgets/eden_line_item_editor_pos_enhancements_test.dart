// Tests for POS-cart UX enhancements absorbed into EdenLineItemEditor.
//
// RED phase — all tests here exercise NEW API surface that does not yet exist
// in the widget. They MUST fail before implementation.
//
// New features under test (from eden-biz PCF-12 audit of cart_panel.dart):
//   1. EdenLineItem.modifiers — list of modifier strings rendered below description
//   2. EdenLineItemEditorTotalsBar — computed subtotal / discount / total display
//   3. showQtyStepperInTableMode — surfaces +/− stepper in table-mode qty cell
//   4. onTotalsComputed callback — pushes Map<String,double> totals to consumer
//   5. Qty stepper + / − tap in stacked-card mode emits correct increments
//   6. EdenLineItem.subtotal correctness with modifiers present
//   7. EdenLineItemEditorTotalsBar zero-discount branch (no discount row)
//   8. Backward-compat: existing constructor calls without new args still compile

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_line_item_editor_fixtures.dart';

/// Same wrap helper used in the main test file.
Widget wrap(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // 1. EdenLineItem.modifiers — value model field
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItem.modifiers field', () {
    test('modifiers default to empty list when not provided', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'Latte',
        quantity: 1,
        unitPrice: 5.0,
      );
      expect(item.modifiers, isEmpty);
    });

    test('modifiers are preserved on construction', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'Latte',
        quantity: 1,
        unitPrice: 5.0,
        modifiers: ['Oat milk', 'Extra shot'],
      );
      expect(item.modifiers, ['Oat milk', 'Extra shot']);
    });

    test('copyWith preserves modifiers when not overridden', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'Latte',
        quantity: 1,
        unitPrice: 5.0,
        modifiers: ['Oat milk'],
      );
      final updated = item.copyWith(quantity: 2);
      expect(updated.modifiers, ['Oat milk']);
    });

    test('copyWith(modifiers: [...]) replaces modifier list', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'Latte',
        quantity: 1,
        unitPrice: 5.0,
        modifiers: ['Oat milk'],
      );
      final updated = item.copyWith(modifiers: ['Almond milk', 'No foam']);
      expect(updated.modifiers, ['Almond milk', 'No foam']);
    });

    test('subtotal unaffected by modifiers (qty × unitPrice)', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'Latte',
        quantity: 2,
        unitPrice: 5.0,
        modifiers: ['Oat milk', 'Extra shot'],
      );
      expect(item.subtotal, closeTo(10.0, 0.001));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 2. Modifier display rendered below description
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditor — modifier display', () {
    testWidgets(
        'modifiers strings render below description in stacked-card mode',
        (tester) async {
      final items = [
        const EdenLineItem<String>(
          id: 'm-1',
          payload: 'sku',
          description: 'Latte',
          quantity: 1,
          unitPrice: 5.0,
          modifiers: ['Oat milk', 'Extra shot'],
        ),
      ];
      await tester.pumpWidget(wrap(
        EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
        ),
        width: 390,
      ));
      expect(find.text('Oat milk'), findsOneWidget);
      expect(find.text('Extra shot'), findsOneWidget);
    });

    testWidgets('modifiers render in table mode when present', (tester) async {
      final items = [
        const EdenLineItem<String>(
          id: 'm-1',
          payload: 'sku',
          description: 'Latte',
          quantity: 1,
          unitPrice: 5.0,
          modifiers: ['Oat milk'],
        ),
      ];
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      expect(find.text('Oat milk'), findsOneWidget);
    });

    testWidgets('item with no modifiers renders no modifier text',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      // Fixture has no modifiers — no modifier Text widgets beyond headers.
      // Confirm no extraneous text appears that would indicate ghost rendering.
      expect(find.text('Oat milk'), findsNothing);
      expect(find.text('Extra shot'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 3. EdenLineItemEditorTotalsBar
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditorTotalsBar', () {
    testWidgets('renders subtotal for 2 items (no discount)', (tester) async {
      // retail-1: qty 2 × $4.50 = $9.00
      // retail-2: qty 1 × $6.25 = $6.25
      // subtotal = $15.25; no discount → total also $15.25
      // EdenCurrencyDisplay renders $15.25 twice (subtotal row + total row).
      final items = EdenLineItemEditorFixtures.retailCart().sublist(0, 2);
      await tester.pumpWidget(wrap(EdenLineItemEditorTotalsBar<String>(
        items: items,
        currencyCode: 'USD',
      )));
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text(r'$15.25'), findsNWidgets(2));
    });

    testWidgets('renders total = subtotal when no discounts', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart().sublist(0, 2);
      await tester.pumpWidget(wrap(EdenLineItemEditorTotalsBar<String>(
        items: items,
        currencyCode: 'USD',
      )));
      expect(find.text('Total'), findsOneWidget);
      // Total == subtotal since no discounts.
      expect(find.text(r'$15.25'), findsNWidgets(2));
    });

    testWidgets('renders discount row and adjusted total when discounts present',
        (tester) async {
      // trades-4 has discountAmount: 25.0 — total = subtotal − 25
      final items = EdenLineItemEditorFixtures.tradesQuote();
      // trades-1: 1.5 × 120 = 180; trades-2: 2 × 95 = 190;
      // trades-3: 2 × 45 = 90 (tax 0.0625: 90 × 1.0625 = 95.625)
      // trades-4: qty 1 × 0 − 25 = -25
      // subtotal (before discount) = sum of discounted values
      // We just test that 'Discounts' row appears and has a formatted value.
      await tester.pumpWidget(wrap(EdenLineItemEditorTotalsBar<String>(
        items: items,
        currencyCode: 'USD',
      )));
      expect(find.text('Discounts'), findsOneWidget);
    });

    testWidgets('does NOT render discount row when no items have discounts',
        (tester) async {
      // retailCart has no discountAmount on any item.
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditorTotalsBar<String>(
        items: items,
        currencyCode: 'USD',
      )));
      expect(find.text('Discounts'), findsNothing);
    });

    testWidgets('renders correctly for empty items list', (tester) async {
      await tester.pumpWidget(wrap(EdenLineItemEditorTotalsBar<String>(
        items: const [],
        currencyCode: 'USD',
      )));
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text(r'$0.00'), findsNWidgets(2)); // subtotal + total both 0
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 4. showQtyStepperInTableMode — table-mode +/− buttons
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditor — showQtyStepperInTableMode', () {
    testWidgets(
        'showQtyStepperInTableMode=false (default) → no stepper buttons in table mode',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      // Default is false; table mode uses a plain TextField for quantity.
      // The stepper +/- icons should NOT appear.
      expect(find.byTooltip('Increase quantity'), findsNothing);
      expect(find.byTooltip('Decrease quantity'), findsNothing);
    });

    testWidgets(
        'showQtyStepperInTableMode=true → + and − buttons visible in table mode',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        showQtyStepperInTableMode: true,
      )));
      // One pair of +/- per row × 3 rows = 3 each.
      expect(find.byTooltip('Increase quantity'), findsNWidgets(items.length));
      expect(find.byTooltip('Decrease quantity'), findsNWidgets(items.length));
    });

    testWidgets(
        'tapping + in table mode with showQtyStepperInTableMode=true emits qty+1',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
        showQtyStepperInTableMode: true,
      )));
      // Tap the first + button (row 0 = 'Coffee — Large', qty = 2).
      await tester.tap(find.byTooltip('Increase quantity').first);
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.first.quantity, closeTo(3.0, 0.001));
    });

    testWidgets(
        'tapping − in table mode with showQtyStepperInTableMode=true emits qty-1',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
        showQtyStepperInTableMode: true,
      )));
      // Row 0 = 'Coffee — Large', initial qty = 2 → tap − → 1.
      await tester.tap(find.byTooltip('Decrease quantity').first);
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.first.quantity, closeTo(1.0, 0.001));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 5. onTotalsComputed callback
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditor — onTotalsComputed callback', () {
    testWidgets('onTotalsComputed fires on initial render with correct values',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart().sublist(0, 2);
      // retail-1: 2 × 4.50 = 9.00; retail-2: 1 × 6.25 = 6.25; sum = 15.25
      Map<String, double>? receivedTotals;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        onTotalsComputed: (totals) => receivedTotals = totals,
      )));
      await tester.pump();
      expect(receivedTotals, isNotNull);
      expect(receivedTotals!['subtotal'], closeTo(15.25, 0.01));
      expect(receivedTotals!['total'], closeTo(15.25, 0.01));
    });

    testWidgets('onTotalsComputed null (default) → no exception', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        // onTotalsComputed not provided — must be optional / null-safe
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 6. Stacked-card qty stepper in narrow mode
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditor — qty stepper stacked-card mode (existing)', () {
    testWidgets('+ button in stacked-card mode increments qty by 1',
        (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(
        EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (next) => captured = next,
        ),
        width: 390,
      ));
      // retail-1 qty = 2; tap + → 3.
      await tester.tap(find.byTooltip('Increase quantity').first);
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.first.quantity, closeTo(3.0, 0.001));
    });

    testWidgets('− button clamps at 0 (not negative)', (tester) async {
      final items = [
        const EdenLineItem<String>(
          id: 'x',
          payload: 'p',
          description: 'Widget',
          quantity: 1,
          unitPrice: 10.0,
        ),
      ];
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(
        EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (next) => captured = next,
        ),
        width: 390,
      ));
      // Tap − twice: 1→0, then 0→0 (clamped).
      await tester.tap(find.byTooltip('Decrease quantity').first);
      await tester.pump();
      expect(captured!.first.quantity, closeTo(0.0, 0.001));
      // Second tap must NOT go negative.
      await tester.tap(find.byTooltip('Decrease quantity').first);
      await tester.pump();
      expect(captured!.first.quantity, closeTo(0.0, 0.001));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 7. Backward-compat: existing constructor still compiles and renders
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditor — backward compatibility', () {
    testWidgets(
        'existing call-site pattern (no new props) still renders without error',
        (tester) async {
      // This mirrors how eden-biz PCF-12 calls the widget today
      // (from cart_panel.dart _toEdenLineItem + EdenLineItemEditor<CartItem>).
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        visibleColumns: const [
          EdenLineItemColumn.description,
          EdenLineItemColumn.quantity,
          EdenLineItemColumn.unitPrice,
          EdenLineItemColumn.discount,
          EdenLineItemColumn.lineTotal,
          EdenLineItemColumn.remove,
        ],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('Coffee — Large'), findsOneWidget);
    });
  });
}

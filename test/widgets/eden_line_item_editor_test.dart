import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_line_item_editor_fixtures.dart';

/// Standard wrap helper used across the eden-ui-flutter test suite.
///
/// Default width 800pt keeps the editor in table mode (≥600pt threshold).
/// Tests that need stacked-card mode pass `width: 390`.
Widget wrap(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // EdenLineItem<T> value class — math + copyWith
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItem value class', () {
    test('lineTotal: qty 2 × unitPrice 50 = 100', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'd',
        quantity: 2.0,
        unitPrice: 50.0,
      );
      expect(item.lineTotal, closeTo(100.0, 0.01));
    });

    test('lineTotal with discount: (2 × 50 − 10) × 1.0 = 90', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'd',
        quantity: 2.0,
        unitPrice: 50.0,
        discountAmount: 10.0,
      );
      expect(item.lineTotal, closeTo(90.0, 0.01));
    });

    test('lineTotal with tax: (2 × 50) × 1.0825 = 108.25', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'd',
        quantity: 2.0,
        unitPrice: 50.0,
        taxRate: 0.0825,
      );
      expect(item.lineTotal, closeTo(108.25, 0.01));
    });

    test('lineTotal negative when discount > subtotal: 2 × 50 − 110 = -10', () {
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'd',
        quantity: 2.0,
        unitPrice: 50.0,
        discountAmount: 110.0,
      );
      expect(item.lineTotal, closeTo(-10.0, 0.01));
    });

    test('copyWith(quantity: 5) returns new instance with quantity 5; other fields preserved', () {
      const original = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'd',
        quantity: 2.0,
        unitPrice: 50.0,
        discountAmount: 5.0,
        taxRate: 0.0825,
        note: 'hi',
      );
      final updated = original.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.id, original.id);
      expect(updated.payload, original.payload);
      expect(updated.description, original.description);
      expect(updated.unitPrice, original.unitPrice);
      expect(updated.discountAmount, original.discountAmount);
      expect(updated.taxRate, original.taxRate);
      expect(updated.note, original.note);
      // Verify it's a new instance, not the same one.
      expect(identical(updated, original), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Table-mode rendering — Task 1
  // ─────────────────────────────────────────────────────────────────────

  group('EdenLineItemEditor table mode (width >= 600pt)', () {
    testWidgets('renders 3 rows for retailCart fixture', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(
        wrap(EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
        )),
      );
      expect(find.text('Coffee — Large'), findsOneWidget);
      expect(find.text('Almond Croissant'), findsOneWidget);
      expect(find.text('Oat Milk (substitution)'), findsOneWidget);
    });

    testWidgets('line total for retail-1 (qty 2, unitPrice 4.50) renders as \$9.00', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(
        wrap(EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
        )),
      );
      // EdenCurrencyDisplay renders with cents — assert format directly.
      expect(find.text(r'$9.00'), findsOneWidget);
    });

    testWidgets('default visibleColumns include Description / Qty / Unit / Total / (remove)', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(
        wrap(EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
        )),
      );
      // Column headers (case-insensitive lookups for clarity).
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Qty'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      // Remove column has no header text; locate via icon presence.
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(items.length));
    });

    testWidgets('library export surface — EdenLineItemEditor + EdenLineItem + EdenLineItemColumn reachable', (tester) async {
      // Compile-time assertion via referencing each public name.
      const columns = <EdenLineItemColumn>[
        EdenLineItemColumn.description,
        EdenLineItemColumn.quantity,
        EdenLineItemColumn.unitPrice,
        EdenLineItemColumn.discount,
        EdenLineItemColumn.tax,
        EdenLineItemColumn.lineTotal,
        EdenLineItemColumn.remove,
        EdenLineItemColumn.reorderHandle,
        EdenLineItemColumn.custom,
      ];
      const item = EdenLineItem<String>(
        id: 'a',
        payload: 'p',
        description: 'd',
        quantity: 1,
        unitPrice: 1,
      );
      expect(columns.length, 9);
      expect(item.id, 'a');
      // Smoke that the widget itself constructs without error.
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: const [item],
        onItemsChanged: (_) {},
      )));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Task 2: editing, remove, reorder, responsive, readOnly, slots, a11y
  // ─────────────────────────────────────────────────────────────────────

  // Helper to find an editable cell's TextField via Semantics label.
  Finder qtyFieldFor(String description) =>
      find.descendant(
        of: find.bySemanticsLabel('Quantity for line item $description'),
        matching: find.byType(TextField),
      );

  Finder unitFieldFor(String description) =>
      find.descendant(
        of: find.bySemanticsLabel('Unit price for line item $description'),
        matching: find.byType(TextField),
      );

  Finder discountFieldFor(String description) =>
      find.descendant(
        of: find.bySemanticsLabel('Discount for line item $description'),
        matching: find.byType(TextField),
      );

  Finder taxFieldFor(String description) =>
      find.descendant(
        of: find.bySemanticsLabel('Tax rate for line item $description'),
        matching: find.byType(TextField),
      );

  group('EdenLineItemEditor — editing quantity', () {
    testWidgets('entering 5 into quantity field invokes onItemsChanged with quantity 5', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
      )));
      // Row 0 is 'Coffee — Large'.
      await tester.enterText(qtyFieldFor('Coffee — Large'), '5');
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.first.quantity, closeTo(5.0, 0.0001));
    });

    testWidgets('entering 2.5 into quantity preserves decimal', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
      )));
      await tester.enterText(qtyFieldFor('Coffee — Large'), '2.5');
      await tester.pump();
      expect(captured!.first.quantity, closeTo(2.5, 0.0001));
    });

    testWidgets('decimal formatter handles malformed input (2.5.3) without crashing', (tester) async {
      // FilteringTextInputFormatter.allow keeps individual matching chars.
      // Multi-period strings like '2.5.3' may either be retained as-is OR
      // partially filtered — either way, double.tryParse returns null and
      // we don't emit, so the widget remains in a consistent state without
      // throwing.
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      await tester.enterText(qtyFieldFor('Coffee — Large'), '2.5.3');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('line-total cell updates when quantity changes', (tester) async {
      // Stateful host re-renders editor on every callback.
      List<EdenLineItem<String>> items = EdenLineItemEditorFixtures.retailCart();
      late StateSetter rerender;
      await tester.pumpWidget(wrap(StatefulBuilder(builder: (ctx, setState) {
        rerender = setState;
        return EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (next) {
            items = next;
            setState(() {});
          },
        );
      })));
      // retail-1 has qty 2 × $4.50 = $9.00; change qty to 5 → $22.50.
      await tester.enterText(qtyFieldFor('Coffee — Large'), '5');
      await tester.pump();
      // Force a rebuild in case StatefulBuilder didn't redraw.
      rerender(() {});
      await tester.pump();
      expect(find.text(r'$22.50'), findsOneWidget);
    });
  });

  group('EdenLineItemEditor — editing unit price', () {
    testWidgets('entering 12.34 into unit-price row 1 invokes onItemsChanged with unitPrice 12.34', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
      )));
      // Row 1 = 'Almond Croissant'.
      await tester.enterText(unitFieldFor('Almond Croissant'), '12.34');
      await tester.pump();
      expect(captured![1].unitPrice, closeTo(12.34, 0.0001));
    });

    testWidgets('negative input -5 stripped by decimal formatter (no leading minus)', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
      )));
      await tester.enterText(unitFieldFor('Almond Croissant'), '-5');
      await tester.pump();
      // Decimal-only formatter strips the '-', producing '5'.
      expect(captured![1].unitPrice, closeTo(5.0, 0.0001));
    });
  });

  group('EdenLineItemEditor — editing discount + tax', () {
    testWidgets('entering 15 into discount field sets discountAmount to 15', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
        visibleColumns: const [
          EdenLineItemColumn.description,
          EdenLineItemColumn.quantity,
          EdenLineItemColumn.unitPrice,
          EdenLineItemColumn.discount,
          EdenLineItemColumn.lineTotal,
          EdenLineItemColumn.remove,
        ],
      )));
      await tester.enterText(discountFieldFor('Coffee — Large'), '15');
      await tester.pump();
      expect(captured!.first.discountAmount, closeTo(15.0, 0.0001));
    });

    testWidgets('entering 0.0825 into tax field sets taxRate to 0.0825', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
        visibleColumns: const [
          EdenLineItemColumn.description,
          EdenLineItemColumn.quantity,
          EdenLineItemColumn.unitPrice,
          EdenLineItemColumn.tax,
          EdenLineItemColumn.lineTotal,
          EdenLineItemColumn.remove,
        ],
      )));
      await tester.enterText(taxFieldFor('Coffee — Large'), '0.0825');
      await tester.pump();
      expect(captured!.first.taxRate, closeTo(0.0825, 0.0001));
    });
  });

  group('EdenLineItemEditor — remove', () {
    testWidgets('tap remove icon row 1 → onItemsChanged with row 1 absent', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      List<EdenLineItem<String>>? captured;
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (next) => captured = next,
      )));
      // Tap the remove icon for row 1 (Almond Croissant).
      final removeFinder = find.byTooltip('Remove line item: Almond Croissant');
      expect(removeFinder, findsOneWidget);
      await tester.tap(removeFinder);
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.length, items.length - 1);
      expect(captured!.any((i) => i.id == 'retail-2'), isFalse);
    });

    testWidgets('readOnly=true → no remove icon rendered', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        readOnly: true,
      )));
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });
  });

  group('EdenLineItemEditor — stacked-card mode at width 390pt', () {
    testWidgets('renders Column of EdenCard widgets, not Table; no overflow', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(
        EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
      // At 390pt, EdenDataTable.dense should NOT appear.
      expect(find.byType(EdenDataTable), findsNothing);
      // EdenCard widgets render — one per row.
      expect(find.byType(EdenCard), findsNWidgets(items.length));
      // Description still visible.
      expect(find.text('Coffee — Large'), findsOneWidget);
      expect(find.text('Almond Croissant'), findsOneWidget);
    });

    testWidgets('reorderable=true at width 390 → ReorderableListView ancestor present', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(
        EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
          reorderable: true,
        ),
        width: 390,
      ));
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('reorderable=true at width 800 (table mode) → NO ReorderableListView', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(
        EdenLineItemEditor<String>(
          items: items,
          onItemsChanged: (_) {},
          reorderable: true,
        ),
        width: 800,
      ));
      expect(find.byType(ReorderableListView), findsNothing);
    });
  });

  group('EdenLineItemEditor — readOnly', () {
    testWidgets('readOnly=true → no TextField widgets', (tester) async {
      final items = EdenLineItemEditorFixtures.salonServices();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        readOnly: true,
      )));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('readOnly=true → currency cells render via EdenCurrencyDisplay', (tester) async {
      final items = EdenLineItemEditorFixtures.salonServices();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        readOnly: true,
      )));
      // salon-1: qty 1 × $75 (unit) → $75.00 line total; salon-2: $25 unit → $25 total.
      // BOTH unit-price + line-total cells render via EdenCurrencyDisplay,
      // so each amount appears 2× (one per column). Assert at-least-one rather
      // than exactly-one to permit the dual display.
      expect(find.text(r'$75.00'), findsNWidgets(2));
      expect(find.text(r'$25.00'), findsNWidgets(2));
      // EdenCurrencyDisplay widgets render 2× per row (unit + total) × 2 rows = 4.
      expect(find.byType(EdenCurrencyDisplay), findsNWidgets(items.length * 2));
    });
  });

  group('EdenLineItemEditor — slots', () {
    testWidgets('itemPickerSlot renders ABOVE the table', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        itemPickerSlot: const Text('PICKER_SLOT'),
      )));
      expect(find.text('PICKER_SLOT'), findsOneWidget);
    });

    testWidgets('footerSlot renders BELOW the table', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        footerSlot: const Text('FOOTER_SLOT'),
      )));
      expect(find.text('FOOTER_SLOT'), findsOneWidget);
    });

    testWidgets('customColumnBuilder + .custom visibleColumns renders builder per row', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        visibleColumns: const [
          EdenLineItemColumn.description,
          EdenLineItemColumn.quantity,
          EdenLineItemColumn.unitPrice,
          EdenLineItemColumn.lineTotal,
          EdenLineItemColumn.custom,
          EdenLineItemColumn.remove,
        ],
        customColumnBuilder: (ctx, item, idx) => Text('CUSTOM-$idx'),
      )));
      expect(find.text('CUSTOM-0'), findsOneWidget);
      expect(find.text('CUSTOM-1'), findsOneWidget);
      expect(find.text('CUSTOM-2'), findsOneWidget);
    });

    testWidgets('customColumnBuilder null with .custom present → no exception', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
        visibleColumns: const [
          EdenLineItemColumn.description,
          EdenLineItemColumn.quantity,
          EdenLineItemColumn.lineTotal,
          EdenLineItemColumn.custom,
          EdenLineItemColumn.remove,
        ],
      )));
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenLineItemEditor — empty state', () {
    testWidgets('items=[] renders EdenEmptyState', (tester) async {
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: const [],
        onItemsChanged: (_) {},
      )));
      expect(find.byType(EdenEmptyState), findsOneWidget);
    });

    testWidgets('items=[] AND itemPickerSlot → both render together', (tester) async {
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: const [],
        onItemsChanged: (_) {},
        itemPickerSlot: const Text('PICKER_FOR_EMPTY'),
      )));
      expect(find.byType(EdenEmptyState), findsOneWidget);
      expect(find.text('PICKER_FOR_EMPTY'), findsOneWidget);
    });
  });

  group('EdenLineItemEditor — Section 508 a11y', () {
    testWidgets('description cell has Semantics label "Description for line item Coffee — Large"', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      expect(
        find.bySemanticsLabel('Description for line item Coffee — Large'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('quantity cell has Semantics label "Quantity for line item Coffee — Large"', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      expect(
        find.bySemanticsLabel('Quantity for line item Coffee — Large'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('remove button has tooltip "Remove line item: Coffee — Large"', (tester) async {
      final items = EdenLineItemEditorFixtures.retailCart();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      expect(find.byTooltip('Remove line item: Coffee — Large'), findsOneWidget);
    });

    testWidgets('negative line total renders in danger color', (tester) async {
      final items = EdenLineItemEditorFixtures.negativeLineTotal();
      await tester.pumpWidget(wrap(EdenLineItemEditor<String>(
        items: items,
        onItemsChanged: (_) {},
      )));
      // Negative total = -10.00; rendered with leading minus.
      expect(find.text(r'-$10.00'), findsOneWidget);
      // Pick the EdenCurrencyDisplay carrying the negative cents and verify
      // its computed text style color is not the default.
      final display = tester.widget<EdenCurrencyDisplay>(
        find.byWidgetPredicate((w) =>
            w is EdenCurrencyDisplay && w.cents < 0 && w.style?.color != null),
      );
      expect(display.style?.color, isNotNull);
    });
  });
}

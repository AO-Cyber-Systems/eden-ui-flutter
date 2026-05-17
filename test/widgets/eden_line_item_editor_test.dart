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
}

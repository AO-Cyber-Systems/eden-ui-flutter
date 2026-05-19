// RED phase — tests for tipCents breakdown row and currencyFormatter hook.
// These tests will fail until EdenReceiptData gains tipCents and
// EdenReceiptPreview gains the currencyFormatter parameter.
//
// Hand-built per global TDD Playbook habit 4. Do not regenerate via LLM.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child, {double width = 480, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  // ---------------------------------------------------------------------------
  // tipCents — breakdown row
  // ---------------------------------------------------------------------------
  group('EdenReceiptPreview — tipCents', () {
    testWidgets('tipCents=null hides Tip row', (tester) async {
      const data = EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Tip Test Shop'),
        lineItems: [],
        subtotalCents: 1000,
        taxCents: 80,
        totalCents: 1080,
        tenderSummary: [
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 1080,
            last4: '1234',
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenReceiptPreview(data: data)));
      expect(find.text('Tip'), findsNothing);
    });

    testWidgets('tipCents=0 hides Tip row', (tester) async {
      const data = EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Tip Test Shop'),
        lineItems: [],
        subtotalCents: 1000,
        taxCents: 80,
        totalCents: 1080,
        tipCents: 0,
        tenderSummary: [
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 1080,
            last4: '1234',
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenReceiptPreview(data: data)));
      expect(find.text('Tip'), findsNothing);
    });

    testWidgets('tipCents>0 renders Tip row between Tax and Total',
        (tester) async {
      const data = EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Coffee Corner'),
        lineItems: [
          EdenReceiptLineItem(name: 'Espresso', qty: 1, unitPriceCents: 350),
        ],
        subtotalCents: 350,
        taxCents: 30,
        tipCents: 70,
        totalCents: 450,
        tenderSummary: [
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 450,
            last4: '5678',
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenReceiptPreview(data: data)));
      expect(find.text('Tip'), findsOneWidget);
      // Total must still appear.
      expect(find.text('Total'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tipCents ordering: Subtotal, Tax, Tip, Total appear',
        (tester) async {
      const data = EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Diner 24'),
        lineItems: [
          EdenReceiptLineItem(name: 'Pancakes', qty: 2, unitPriceCents: 899),
        ],
        subtotalCents: 1798,
        taxCents: 144,
        tipCents: 360,
        totalCents: 2302,
        tenderSummary: [
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.cash,
            amountCents: 2302,
            cashGivenCents: 2500,
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenReceiptPreview(data: data)));
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Tax'), findsOneWidget);
      expect(find.text('Tip'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // currencyFormatter — consumer-controlled formatting hook
  // ---------------------------------------------------------------------------
  group('EdenReceiptPreview — currencyFormatter hook', () {
    testWidgets('custom formatter produces formatted strings visible in SMS mode',
        (tester) async {
      const data = EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Euro Bakery'),
        lineItems: [
          EdenReceiptLineItem(name: 'Croissant', qty: 1, unitPriceCents: 250),
        ],
        subtotalCents: 250,
        taxCents: 20,
        totalCents: 270,
        currency: 'EUR',
        tenderSummary: [
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 270,
          ),
        ],
      );
      String customFormat(int cents, String code) {
        final whole = cents ~/ 100;
        final frac = (cents % 100).toString().padLeft(2, '0');
        return '$whole,$frac €';
      }

      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: data,
            mode: EdenReceiptPreviewMode.sms,
            currencyFormatter: customFormat,
          ),
        ),
      );
      final selectable =
          tester.widget<SelectableText>(find.byType(SelectableText));
      // Custom formatter produces "2,70 €" style output.
      expect(selectable.data, contains('2,70 €'));
    });

    testWidgets('null currencyFormatter falls back to EdenCurrencyDisplay default',
        (tester) async {
      const data = EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Default Shop'),
        lineItems: [],
        subtotalCents: 500,
        taxCents: 40,
        totalCents: 540,
        tenderSummary: [
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 540,
          ),
        ],
      );
      // No currencyFormatter passed — should render without exception using
      // built-in EdenCurrencyDisplay.
      await tester.pumpWidget(
        wrap(EdenReceiptPreview(data: data)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Subtotal'), findsOneWidget);
    });
  });
}

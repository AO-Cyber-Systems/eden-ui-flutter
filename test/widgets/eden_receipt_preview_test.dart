import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_receipt_preview_fixtures.dart';

Widget wrap(Widget child, {double width = 480, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('EdenReceiptPreview — web mode static rendering (happy path)', () {
    testWidgets('renders storeName from header', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Eden Coffee Co.'), findsOneWidget);
    });

    testWidgets('renders address when non-null', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('123 Main St, Springfield IL 62701'), findsOneWidget);
    });

    testWidgets('omits address when null', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.salonTicket()),
        ),
      );
      expect(find.textContaining('Main St'), findsNothing);
    });

    testWidgets('renders line item names', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Espresso Single'), findsOneWidget);
      expect(find.text('Croissant'), findsOneWidget);
      expect(find.text('Mocha'), findsOneWidget);
    });

    testWidgets('renders Subtotal / Tax / Total labels', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Tax'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('renders tender row label for cash', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Cash'), findsOneWidget);
    });

    testWidgets('renders Change due row when cashGiven > total',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Change due'), findsOneWidget);
    });

    testWidgets('renders thankYouMessage from footer when present',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Thank you for visiting!'), findsOneWidget);
    });
  });

  group('EdenReceiptPreview — conditional rows', () {
    testWidgets('discountCents=null hides discount row', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.coffeeShop3Items()),
        ),
      );
      expect(find.text('Discount'), findsNothing);
    });

    testWidgets('discountCents>0 shows discount row', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShopWithDiscountAndPromo(),
          ),
        ),
      );
      expect(find.text('Discount'), findsOneWidget);
    });

    testWidgets('promo non-null shows promo row with code label',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShopWithDiscountAndPromo(),
          ),
        ),
      );
      expect(find.textContaining('SUMMER10'), findsOneWidget);
    });
  });

  group('EdenReceiptPreview — tender variants', () {
    testWidgets('card tender with last4 renders "Card **** 4242"',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShopWithDiscountAndPromo(),
          ),
        ),
      );
      expect(find.text('Card **** 4242'), findsOneWidget);
    });

    testWidgets('split tender renders 2 separate tender rows',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.salonTicket()),
        ),
      );
      expect(find.text('Card **** 9876'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      // The split-tender salon fixture has cash 4040 with cashGiven 4500 →
      // change due 460 → 1 'Change due' row.
      expect(find.text('Change due'), findsOneWidget);
    });

    testWidgets('cash tender without cashGiven shows no Change due',
        (tester) async {
      // emptyLineItems fixture has cash amount=0 + cashGiven=null → no change row.
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.emptyLineItems()),
        ),
      );
      expect(find.text('Change due'), findsNothing);
    });

    testWidgets('account tender renders "Account" label', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.tradesInvoice()),
        ),
      );
      expect(find.text('Account'), findsOneWidget);
    });
  });

  group('EdenReceiptPreview — print mode', () {
    testWidgets('printWidth.mm80 constrains body to ~302pt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.print,
            printWidth: EdenReceiptPrintWidth.mm80,
          ),
          width: 800,
          height: 1000,
        ),
      );
      final body = tester.getSize(find.byKey(const ValueKey('eden-receipt-body')));
      expect(body.width, lessThanOrEqualTo(302.0));
    });

    testWidgets('printWidth.mm58 constrains body to ~219pt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.print,
            printWidth: EdenReceiptPrintWidth.mm58,
          ),
          width: 800,
          height: 1000,
        ),
      );
      final body = tester.getSize(find.byKey(const ValueKey('eden-receipt-body')));
      expect(body.width, lessThanOrEqualTo(219.0));
    });
  });

  group('EdenReceiptPreview — email mode', () {
    testWidgets('email mode renders without fixed-width constraint key',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.email,
          ),
        ),
      );
      // The `eden-receipt-body` key only wraps the print-mode ConstrainedBox.
      expect(find.byKey(const ValueKey('eden-receipt-body')), findsNothing);
      // Still shows store name + line items + total.
      expect(find.text('Eden Coffee Co.'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });
  });

  group('EdenReceiptPreview — sms mode', () {
    testWidgets('sms mode renders a SelectableText', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.sms,
          ),
        ),
      );
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('sms mode body contains store name', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.sms,
          ),
        ),
      );
      final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(selectable.data, contains('Eden Coffee Co.'));
    });

    testWidgets('sms mode body contains Total + Subtotal text', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.sms,
          ),
        ),
      );
      final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(selectable.data, contains('Total:'));
      expect(selectable.data, contains('Subtotal:'));
    });

    testWidgets('sms mode body contains line item names', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(
            data: EdenReceiptFixtures.coffeeShop3Items(),
            mode: EdenReceiptPreviewMode.sms,
          ),
        ),
      );
      final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(selectable.data, contains('Espresso Single'));
      expect(selectable.data, contains('Croissant'));
    });
  });

  group('EdenReceiptPreview — edge cases', () {
    testWidgets('empty line items still renders breakdown + tender',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.emptyLineItems()),
        ),
      );
      // No line item names rendered.
      expect(find.text('Espresso Single'), findsNothing);
      // But breakdown + tender still present.
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      // No exceptions during build.
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero total renders without exception', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenReceiptPreview(data: EdenReceiptFixtures.emptyLineItems()),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenReceiptPreview — iPhone-narrow safety', () {
    testWidgets('390pt web mode renders without RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdenReceiptPreview(
              data: EdenReceiptFixtures.longProductName(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Long product name is shown (may be truncated visually).
      expect(find.textContaining('Vanilla Hazelnut'), findsOneWidget);
    });
  });
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenReceiptPreview.
//
// Hand-built per global TDD Playbook habit 4. Touch by hand when adding
// transaction shapes (zero-tax / split-tender / promo / refund-as-negative-line).

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenReceiptFixtures {
  EdenReceiptFixtures._();

  /// 3-item coffee transaction: 2x Espresso $3.50 + 1x Croissant $4.25 +
  /// 1x Mocha $5.75 → subtotal $13.50 + tax $0.95 + total $14.45. Single
  /// cash tender of $15.00 → $0.55 change due.
  static EdenReceiptData coffeeShop3Items() => const EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(
          storeName: 'Eden Coffee Co.',
          address: '123 Main St, Springfield IL 62701',
          phone: '(555) 123-4567',
        ),
        lineItems: <EdenReceiptLineItem>[
          EdenReceiptLineItem(name: 'Espresso Single', qty: 2, unitPriceCents: 350),
          EdenReceiptLineItem(name: 'Croissant', qty: 1, unitPriceCents: 425),
          EdenReceiptLineItem(name: 'Mocha', qty: 1, unitPriceCents: 575),
        ],
        subtotalCents: 1700,
        taxCents: 95,
        totalCents: 1795,
        tenderSummary: <EdenReceiptTender>[
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.cash,
            amountCents: 1795,
            cashGivenCents: 2000,
          ),
        ],
        footer: EdenReceiptFooter(
          returnPolicy: 'Returns within 30 days with receipt.',
          thankYouMessage: 'Thank you for visiting!',
        ),
      );

  /// Same items as coffeeShop3Items but with discount $2.00 + promo SUMMER10
  /// $10.00 applied. Card tender (no cashGiven, last4 4242).
  static EdenReceiptData coffeeShopWithDiscountAndPromo() => const EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(
          storeName: 'Eden Coffee Co.',
          address: '123 Main St',
        ),
        lineItems: <EdenReceiptLineItem>[
          EdenReceiptLineItem(name: 'Espresso Single', qty: 2, unitPriceCents: 350),
          EdenReceiptLineItem(name: 'Croissant', qty: 1, unitPriceCents: 425),
          EdenReceiptLineItem(name: 'Mocha', qty: 1, unitPriceCents: 575),
        ],
        subtotalCents: 1700,
        discountCents: 200,
        promo: EdenReceiptPromo(code: 'SUMMER10', amountCents: 1000),
        taxCents: 35,
        totalCents: 535,
        tenderSummary: <EdenReceiptTender>[
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 535,
            last4: '4242',
          ),
        ],
      );

  /// Salon ticket — split tender (card + cash with change). Tax exempt.
  static EdenReceiptData salonTicket() => const EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Aurora Salon'),
        lineItems: <EdenReceiptLineItem>[
          EdenReceiptLineItem(name: 'Womens Haircut', qty: 1, unitPriceCents: 4500),
          EdenReceiptLineItem(name: 'Full Color', qty: 1, unitPriceCents: 8500),
        ],
        subtotalCents: 13000,
        taxCents: 1040,
        totalCents: 14040,
        tenderSummary: <EdenReceiptTender>[
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 10000,
            last4: '9876',
          ),
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.cash,
            amountCents: 4040,
            cashGivenCents: 4500,
          ),
        ],
      );

  /// Trades invoice — account tender, no cash, no change.
  static EdenReceiptData tradesInvoice() => const EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(
          storeName: 'Acme Plumbing LLC',
          address: '500 Industrial Way',
          phone: '(770) 555-0199',
        ),
        lineItems: <EdenReceiptLineItem>[
          EdenReceiptLineItem(name: 'Labor (2 techs, 4 hrs)', qty: 8, unitPriceCents: 7500),
          EdenReceiptLineItem(name: 'PVC pipe 3/4" 10ft', qty: 4, unitPriceCents: 1200),
          EdenReceiptLineItem(name: 'Elbow 90deg fitting', qty: 6, unitPriceCents: 350),
          EdenReceiptLineItem(name: 'Permit fee', qty: 1, unitPriceCents: 7500),
        ],
        subtotalCents: 75000,
        taxCents: 6000,
        totalCents: 81000,
        tenderSummary: <EdenReceiptTender>[
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.account,
            amountCents: 81000,
          ),
        ],
        footer: EdenReceiptFooter(
          taxId: 'EIN: 88-1234567',
          returnPolicy: 'Net 30 payment terms.',
        ),
      );

  /// Edge: empty line items + zero total + cash $0 tender.
  static EdenReceiptData emptyLineItems() => const EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Zero Total Co.'),
        lineItems: <EdenReceiptLineItem>[],
        subtotalCents: 0,
        taxCents: 0,
        totalCents: 0,
        tenderSummary: <EdenReceiptTender>[
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.cash,
            amountCents: 0,
          ),
        ],
      );

  /// Edge: a single line item with a deliberately long name for ellipsize
  /// tests at narrow widths.
  static EdenReceiptData longProductName() => const EdenReceiptData(
        storeHeader: EdenReceiptStoreHeader(storeName: 'Cafe Long Name Coffee Roastery LLC'),
        lineItems: <EdenReceiptLineItem>[
          EdenReceiptLineItem(
            name: 'Vanilla Hazelnut Latte Macchiato Extra Foam',
            qty: 1,
            unitPriceCents: 695,
          ),
        ],
        subtotalCents: 695,
        taxCents: 55,
        totalCents: 750,
        tenderSummary: <EdenReceiptTender>[
          EdenReceiptTender(
            method: EdenReceiptTenderMethod.card,
            amountCents: 750,
            last4: '0000',
          ),
        ],
      );
}

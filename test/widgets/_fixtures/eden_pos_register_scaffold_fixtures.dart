// Do NOT regenerate via LLM — hand-built fixtures for EdenPOSRegisterScaffold.
//
// Hand-built per global TDD Playbook habit 4. Touch by hand when adding
// transaction shapes (split-tender, mid-cart customer-attach, promo-applied).

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPosSessionFixtures {
  EdenPosSessionFixtures._();

  static const empty = EdenPosSession();

  static const withCustomer = EdenPosSession(
    customer: EdenPosCustomer(
      id: 'c-1',
      name: 'Jane Doe',
      tier: 'gold',
      points: 1247,
    ),
  );

  static const midTransaction = EdenPosSession(
    cartItems: <EdenPosCartItem>[
      EdenPosCartItem(
        id: 'ci-1',
        productId: 'p-1',
        name: 'Espresso Single',
        qty: 2,
        unitPriceCents: 350,
      ),
      EdenPosCartItem(
        id: 'ci-2',
        productId: 'p-2',
        name: 'Croissant',
        qty: 1,
        unitPriceCents: 425,
      ),
    ],
    customer: EdenPosCustomer(
      id: 'c-1',
      name: 'Jane Doe',
      tier: 'gold',
      points: 1247,
    ),
    tenderState: EdenPosTenderState(
      method: EdenPosTenderMethod.card,
      amountCents: 1125,
      last4: '4242',
    ),
  );

  /// 8 hand-built coffee products for the LEFT zone quick-add grid.
  static List<EdenQuickAddProduct> sampleProducts() =>
      const <EdenQuickAddProduct>[
        EdenQuickAddProduct(
          id: 'p-1',
          name: 'Espresso Single',
          priceCents: 350,
          onHand: 25,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'p-2',
          name: 'Americano',
          priceCents: 400,
          onHand: 18,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'p-3',
          name: 'Cappuccino',
          priceCents: 475,
          onHand: 7,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'p-4',
          name: 'Latte',
          priceCents: 525,
          onHand: 30,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'p-5',
          name: 'Mocha',
          priceCents: 575,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'p-6',
          name: 'Cortado',
          priceCents: 425,
          onHand: 0,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'p-7',
          name: 'Iced Coffee',
          priceCents: 425,
          onHand: 20,
          reorderPoint: 10,
          categoryId: 'cold',
        ),
        EdenQuickAddProduct(
          id: 'p-8',
          name: 'Cold Brew',
          priceCents: 525,
          onHand: 12,
          reorderPoint: 10,
          categoryId: 'cold',
        ),
      ];

  static const sampleCategories = <EdenQuickAddCategory>[
    EdenQuickAddCategory(id: 'hot', label: 'Hot'),
    EdenQuickAddCategory(id: 'cold', label: 'Cold'),
  ];
}

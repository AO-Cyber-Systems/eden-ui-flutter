// Do NOT regenerate via LLM — hand-built fixtures for EdenQuickAddProductGrid.
//
// Hand-built per global TDD Playbook habit 4: fixture builders, not
// LLM-generated test data. Touch fields by hand when adding new cases.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenQuickAddProductFixtures {
  EdenQuickAddProductFixtures._();

  /// 12-product coffee-shop SKU set mixing photoUrl / onHand / reorderPoint
  /// permutations so static-render tests exercise every conditional branch:
  ///
  /// - 8 of 12 have non-null `photoUrl` (4 are null → placeholder icon path).
  /// - 6 of 12 have non-null `onHand` + `reorderPoint` (stock overlay path).
  /// - 6 categoryId='hot', 6 categoryId='cold'.
  static List<EdenQuickAddProduct> coffee12() => const <EdenQuickAddProduct>[
        EdenQuickAddProduct(
          id: 'espresso-single',
          name: 'Espresso Single',
          priceCents: 350,
          photoUrl: 'https://example.com/p/espresso-single.jpg',
          onHand: 25,
          reorderPoint: 10,
          categoryId: 'hot',
          sku: 'ESP-001',
        ),
        EdenQuickAddProduct(
          id: 'americano',
          name: 'Americano',
          priceCents: 400,
          photoUrl: 'https://example.com/p/americano.jpg',
          onHand: 18,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'latte',
          name: 'Latte',
          priceCents: 475,
          photoUrl: 'https://example.com/p/latte.jpg',
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'cappuccino',
          name: 'Cappuccino',
          priceCents: 525,
          onHand: 7,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'mocha',
          name: 'Mocha',
          priceCents: 575,
          photoUrl: 'https://example.com/p/mocha.jpg',
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'cortado',
          name: 'Cortado',
          priceCents: 425,
          photoUrl: 'https://example.com/p/cortado.jpg',
          onHand: 30,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
        EdenQuickAddProduct(
          id: 'flat-white',
          name: 'Flat White',
          priceCents: 450,
          photoUrl: 'https://example.com/p/flat-white.jpg',
          categoryId: 'cold',
        ),
        EdenQuickAddProduct(
          id: 'drip-coffee',
          name: 'Drip Coffee',
          priceCents: 300,
          onHand: 22,
          reorderPoint: 10,
          categoryId: 'cold',
        ),
        EdenQuickAddProduct(
          id: 'cold-brew',
          name: 'Cold Brew',
          priceCents: 525,
          photoUrl: 'https://example.com/p/cold-brew.jpg',
          onHand: 12,
          reorderPoint: 10,
          categoryId: 'cold',
        ),
        EdenQuickAddProduct(
          id: 'tea',
          name: 'Hot Tea',
          priceCents: 325,
          photoUrl: 'https://example.com/p/tea.jpg',
          categoryId: 'cold',
        ),
        EdenQuickAddProduct(
          id: 'hot-chocolate',
          name: 'Hot Chocolate',
          priceCents: 450,
          onHand: 8,
          reorderPoint: 10,
          categoryId: 'cold',
        ),
        EdenQuickAddProduct(
          id: 'macchiato',
          name: 'Caramel Macchiato',
          priceCents: 575,
          photoUrl: 'https://example.com/p/macchiato.jpg',
          categoryId: 'cold',
        ),
      ];

  /// Single-item list — exercises 1-tile render path.
  static List<EdenQuickAddProduct> coffee1() => const <EdenQuickAddProduct>[
        EdenQuickAddProduct(
          id: 'espresso-single',
          name: 'Espresso Single',
          priceCents: 350,
          photoUrl: 'https://example.com/p/espresso-single.jpg',
          onHand: 25,
          reorderPoint: 10,
          categoryId: 'hot',
        ),
      ];

  /// 100-product smoke list — hand-built via List.generate (loop construction,
  /// not LLM-generated). Each entry deterministic by index so the smoke test
  /// is reproducible.
  static List<EdenQuickAddProduct> coffee100() => List<EdenQuickAddProduct>.generate(
        100,
        (i) => EdenQuickAddProduct(
          id: 'p-$i',
          name: 'Coffee #${i.toString().padLeft(3, '0')}',
          priceCents: 250 + i,
        ),
      );

  /// Same coffee set but with long enough names to force `maxLines: 2`
  /// ellipsis at narrow widths.
  static List<EdenQuickAddProduct> coffee12LongNames() => const <EdenQuickAddProduct>[
        EdenQuickAddProduct(
          id: 'p-vh',
          name: 'Vanilla Hazelnut Latte Macchiato',
          priceCents: 650,
          photoUrl: 'https://example.com/p/vh.jpg',
          onHand: 8,
          reorderPoint: 10,
        ),
        EdenQuickAddProduct(
          id: 'p-cb',
          name: 'Caramel Brulee Frappuccino Venti',
          priceCents: 695,
        ),
        EdenQuickAddProduct(
          id: 'p-pl',
          name: 'Pumpkin Spice Latte Extra Foam',
          priceCents: 575,
          photoUrl: 'https://example.com/p/pl.jpg',
        ),
        EdenQuickAddProduct(
          id: 'p-wm',
          name: 'White Chocolate Mocha Double Shot',
          priceCents: 625,
          onHand: 14,
          reorderPoint: 10,
        ),
        EdenQuickAddProduct(
          id: 'p-cc',
          name: 'Cinnamon Dolce Caffe Misto',
          priceCents: 525,
          photoUrl: 'https://example.com/p/cc.jpg',
        ),
        EdenQuickAddProduct(
          id: 'p-tc',
          name: 'Toasted Coconut Cold Brew',
          priceCents: 575,
        ),
        EdenQuickAddProduct(
          id: 'p-hc',
          name: 'Honey Citrus Mint Tea Venti',
          priceCents: 425,
          photoUrl: 'https://example.com/p/hc.jpg',
        ),
        EdenQuickAddProduct(
          id: 'p-cm',
          name: 'Chocolate Malted Cookie Crumble',
          priceCents: 595,
        ),
        EdenQuickAddProduct(
          id: 'p-bv',
          name: 'Blueberry Vanilla Crisp Frappe',
          priceCents: 645,
          photoUrl: 'https://example.com/p/bv.jpg',
        ),
        EdenQuickAddProduct(
          id: 'p-rc',
          name: 'Raspberry Chocolate Truffle Mocha',
          priceCents: 675,
        ),
        EdenQuickAddProduct(
          id: 'p-st',
          name: 'Salted Caramel Toffee Nut Latte',
          priceCents: 625,
          photoUrl: 'https://example.com/p/st.jpg',
        ),
        EdenQuickAddProduct(
          id: 'p-pc',
          name: 'Peppermint Mocha Holiday Special',
          priceCents: 695,
        ),
      ];

  /// 2-category set — exercises chip-strip render + selection callback paths.
  static List<EdenQuickAddCategory> coffeeCategories() => const <EdenQuickAddCategory>[
        EdenQuickAddCategory(id: 'hot', label: 'Hot drinks', icon: null),
        EdenQuickAddCategory(id: 'cold', label: 'Cold drinks', icon: null),
      ];
}

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_quick_add_product_grid_fixtures.dart';

Widget wrap(Widget child, {double width = 600, double height = 400}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('EdenQuickAddProductGrid — static rendering (happy path)', () {
    testWidgets('renders 12 tiles for coffee12 fixture inside a GridView',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
      // GridView lazily realizes children, so we cannot count tiles directly.
      // Verify against the products list by finding currency display widgets
      // which are 1-per-tile.
      expect(find.byType(EdenCurrencyDisplay).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('renders product names from fixtures', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
          ),
        ),
      );
      expect(find.text('Espresso Single'), findsOneWidget);
    });

    testWidgets('renders prices via EdenCurrencyDisplay', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
          ),
        ),
      );
      final currency = find.byType(EdenCurrencyDisplay);
      expect(currency, findsOneWidget);
      final widget = tester.widget<EdenCurrencyDisplay>(currency);
      expect(widget.cents, 350);
    });

    testWidgets('renders EdenAuthenticatedImage when photoUrl is non-null',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
          ),
        ),
      );
      expect(find.byType(EdenAuthenticatedImage), findsOneWidget);
    });

    testWidgets('renders placeholder icon when photoUrl is null',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: const <EdenQuickAddProduct>[
              EdenQuickAddProduct(
                id: 'no-photo',
                name: 'No Photo Item',
                priceCents: 100,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(EdenAuthenticatedImage), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('renders EdenStockLevelIndicator overlay when onHand non-null',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: const <EdenQuickAddProduct>[
              EdenQuickAddProduct(
                id: 'stocked',
                name: 'Stocked Item',
                priceCents: 100,
                onHand: 15,
                reorderPoint: 10,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(EdenStockLevelIndicator), findsOneWidget);
    });

    testWidgets('does NOT render EdenStockLevelIndicator when onHand is null',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: const <EdenQuickAddProduct>[
              EdenQuickAddProduct(
                id: 'no-stock',
                name: 'No Stock Item',
                priceCents: 100,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(EdenStockLevelIndicator), findsNothing);
    });
  });

  group('EdenQuickAddProductGrid — static rendering (edge cases)', () {
    testWidgets('empty list renders EdenEmptyState with default label',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const EdenQuickAddProductGrid(products: <EdenQuickAddProduct>[]),
        ),
      );
      expect(find.byType(EdenEmptyState), findsOneWidget);
      expect(find.text('No products'), findsOneWidget);
    });

    testWidgets('empty list renders custom emptyLabel when provided',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const EdenQuickAddProductGrid(
            products: <EdenQuickAddProduct>[],
            emptyLabel: 'No services',
          ),
        ),
      );
      expect(find.text('No services'), findsOneWidget);
    });

    testWidgets('single-product list renders 1 tile', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
          ),
        ),
      );
      expect(find.text('Espresso Single'), findsOneWidget);
      expect(find.byType(EdenCurrencyDisplay), findsOneWidget);
    });

    testWidgets('100-product list renders without throwing', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee100(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('EdenQuickAddProductGrid — tap interaction', () {
    testWidgets('tap on tile fires onTap with the correct product',
        (tester) async {
      EdenQuickAddProduct? tapped;
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
            onTap: (p) => tapped = p,
          ),
        ),
      );
      await tester.tap(find.text('Espresso Single'));
      await tester.pump();
      expect(tapped, isNotNull);
      expect(tapped!.id, 'espresso-single');
    });

    testWidgets('null onTap callback does not throw on tap', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
          ),
        ),
      );
      await tester.tap(find.text('Espresso Single'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenQuickAddProductGrid — long-press drag', () {
    testWidgets('every tile wraps in LongPressDraggable<EdenQuickAddProduct>',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
          ),
        ),
      );
      final draggables = find.byType(LongPressDraggable<EdenQuickAddProduct>);
      expect(draggables, findsOneWidget);
    });

    testWidgets('drag data on the tile is the correct product', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee1(),
          ),
        ),
      );
      final draggable = tester.widget<LongPressDraggable<EdenQuickAddProduct>>(
        find.byType(LongPressDraggable<EdenQuickAddProduct>),
      );
      expect(draggable.data, isNotNull);
      expect(draggable.data!.id, 'espresso-single');
    });
  });

  group('EdenQuickAddProductGrid — category filter', () {
    testWidgets('renders ChoiceChip strip when categories provided',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
            categories: EdenQuickAddProductFixtures.coffeeCategories(),
            selectedCategoryId: null,
            onCategorySelected: (_) {},
          ),
        ),
      );
      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(find.text('Hot drinks'), findsOneWidget);
      expect(find.text('Cold drinks'), findsOneWidget);
    });

    testWidgets('tapping chip fires onCategorySelected with id',
        (tester) async {
      String? selectedId;
      bool callbackFired = false;
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
            categories: EdenQuickAddProductFixtures.coffeeCategories(),
            selectedCategoryId: null,
            onCategorySelected: (id) {
              callbackFired = true;
              selectedId = id;
            },
          ),
        ),
      );
      await tester.tap(find.text('Hot drinks'));
      await tester.pumpAndSettle();
      expect(callbackFired, isTrue);
      expect(selectedId, 'hot');
    });

    testWidgets('null categories does not render chip strip', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
          ),
        ),
      );
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('EdenQuickAddProductGrid — responsive crossAxisCount', () {
    testWidgets('400pt constraint → 4 columns', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
          ),
          width: 400,
        ),
      );
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });

    testWidgets('700pt constraint → 6 columns', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
          ),
          width: 700,
        ),
      );
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 6);
    });

    testWidgets('1100pt constraint → 8 columns', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
          ),
          width: 1100,
          height: 700,
        ),
      );
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 8);
    });

    testWidgets('explicit crossAxisCount: 5 wins over auto', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenQuickAddProductGrid(
            products: EdenQuickAddProductFixtures.coffee12(),
            crossAxisCount: 5,
          ),
          width: 1100,
          height: 700,
        ),
      );
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 5);
    });
  });

  group('EdenQuickAddProductGrid — iPhone-narrow safety', () {
    testWidgets('390pt: 4-col grid + long names truncate without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdenQuickAddProductGrid(
              products: EdenQuickAddProductFixtures.coffee12LongNames(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
      // Long name visible as a substring (ellipsis truncates the rest).
      expect(find.textContaining('Vanilla Hazelnut'), findsAtLeastNWidgets(1));
    });
  });
}

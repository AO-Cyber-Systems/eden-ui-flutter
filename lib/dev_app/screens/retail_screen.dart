import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 014 — B-Retail back-office + cross-vertical
/// polish.
///
/// TRD 014-02 creates the file with the [EdenQuickAddProductGrid] section.
/// TRDs 014-03 through 014-06 + 014-01 each append additional `Section(...)`
/// entries at the marked anchor comments — they do NOT re-create the file.
class RetailScreen extends StatefulWidget {
  const RetailScreen({super.key});

  @override
  State<RetailScreen> createState() => _RetailScreenState();
}

class _RetailScreenState extends State<RetailScreen> {
  String? _selectedCategoryId;

  static const _categories = <EdenQuickAddCategory>[
    EdenQuickAddCategory(id: 'hot', label: 'Hot drinks'),
    EdenQuickAddCategory(id: 'cold', label: 'Cold drinks'),
  ];

  // Hand-built demo products — NOT LLM-generated. Touch by hand to add cases.
  // Photo URLs reference picsum.photos seeds so the dev catalog renders real
  // images at run-time without needing signed auth headers (test environment
  // gets the EdenAuthenticatedImage default-headers path).
  static const _products = <EdenQuickAddProduct>[
    EdenQuickAddProduct(
      id: 'p-1',
      name: 'Espresso Single',
      priceCents: 350,
      photoUrl: 'https://picsum.photos/seed/p-1/200',
      onHand: 25,
      reorderPoint: 10,
      categoryId: 'hot',
    ),
    EdenQuickAddProduct(
      id: 'p-2',
      name: 'Americano',
      priceCents: 400,
      photoUrl: 'https://picsum.photos/seed/p-2/200',
      onHand: 18,
      reorderPoint: 10,
      categoryId: 'hot',
    ),
    EdenQuickAddProduct(
      id: 'p-3',
      name: 'Cappuccino',
      priceCents: 475,
      photoUrl: 'https://picsum.photos/seed/p-3/200',
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
      photoUrl: 'https://picsum.photos/seed/p-5/200',
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
      photoUrl: 'https://picsum.photos/seed/p-7/200',
      onHand: 20,
      reorderPoint: 10,
      categoryId: 'cold',
    ),
    EdenQuickAddProduct(
      id: 'p-8',
      name: 'Cold Brew',
      priceCents: 525,
      photoUrl: 'https://picsum.photos/seed/p-8/200',
      onHand: 12,
      reorderPoint: 10,
      categoryId: 'cold',
    ),
    EdenQuickAddProduct(
      id: 'p-9',
      name: 'Iced Latte',
      priceCents: 550,
      onHand: 8,
      reorderPoint: 10,
      categoryId: 'cold',
    ),
    EdenQuickAddProduct(
      id: 'p-10',
      name: 'Iced Mocha',
      priceCents: 600,
      photoUrl: 'https://picsum.photos/seed/p-10/200',
      categoryId: 'cold',
    ),
    EdenQuickAddProduct(
      id: 'p-11',
      name: 'Iced Americano',
      priceCents: 450,
      onHand: 22,
      reorderPoint: 10,
      categoryId: 'cold',
    ),
    EdenQuickAddProduct(
      id: 'p-12',
      name: 'Sparkling Water',
      priceCents: 300,
      photoUrl: 'https://picsum.photos/seed/p-12/200',
      onHand: 50,
      reorderPoint: 10,
      categoryId: 'cold',
    ),
  ];

  List<EdenQuickAddProduct> get _filtered => _selectedCategoryId == null
      ? _products
      : _products.where((p) => p.categoryId == _selectedCategoryId).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B-Retail — Back-Office + POS')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'EdenQuickAddProductGrid — Touch-friendly tile grid',
            child: SizedBox(
              height: 480,
              child: EdenQuickAddProductGrid(
                products: _filtered,
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (id) =>
                    setState(() => _selectedCategoryId = id),
                onTap: (p) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped: ${p.name}')),
                ),
              ),
            ),
          ),
          // ─── Objective 014 anchor: TRD 014-03 EdenReceiptPreview ───
          // ─── Objective 014 anchor: TRD 014-04 EdenInventoryRowEditor ───
          // ─── Objective 014 anchor: TRD 014-05 EdenReceivingFlow ───
          // ─── Objective 014 anchor: TRD 014-06 EdenSalesAnalyticsScaffold ───
          // ─── Objective 014 anchor: TRD 014-01 EdenPOSRegisterScaffold ───
        ],
      ),
    );
  }
}

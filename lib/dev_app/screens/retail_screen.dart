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
          const Section(
            title: 'EdenReceiptPreview — Configurable receipt layout',
            child: _ReceiptDemoBlock(),
          ),
          // ─── Objective 014 anchor: TRD 014-04 EdenInventoryRowEditor ───
          // ─── Objective 014 anchor: TRD 014-05 EdenReceivingFlow ───
          // ─── Objective 014 anchor: TRD 014-06 EdenSalesAnalyticsScaffold ───
          // ─── Objective 014 anchor: TRD 014-01 EdenPOSRegisterScaffold ───
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// TRD 014-03 — EdenReceiptPreview demo block
// ───────────────────────────────────────────────────────────────────────────

class _ReceiptDemoBlock extends StatefulWidget {
  const _ReceiptDemoBlock();

  @override
  State<_ReceiptDemoBlock> createState() => _ReceiptDemoBlockState();
}

class _ReceiptDemoBlockState extends State<_ReceiptDemoBlock> {
  EdenReceiptPreviewMode _mode = EdenReceiptPreviewMode.web;
  EdenReceiptPrintWidth _printWidth = EdenReceiptPrintWidth.mm80;

  // Hand-built demo transaction: 3-item coffee shop with discount + tax +
  // cash change-due + footer. NOT LLM-generated.
  static const _data = EdenReceiptData(
    storeHeader: EdenReceiptStoreHeader(
      storeName: 'Eden Coffee Co.',
      address: '123 Main St, Springfield IL 62701',
      phone: '(555) 123-4567',
    ),
    lineItems: <EdenReceiptLineItem>[
      EdenReceiptLineItem(
        name: 'Espresso Single',
        qty: 2,
        unitPriceCents: 350,
      ),
      EdenReceiptLineItem(name: 'Croissant', qty: 1, unitPriceCents: 425),
      EdenReceiptLineItem(name: 'Mocha', qty: 1, unitPriceCents: 575),
    ],
    subtotalCents: 1700,
    discountCents: 200,
    taxCents: 105,
    totalCents: 1605,
    tenderSummary: <EdenReceiptTender>[
      EdenReceiptTender(
        method: EdenReceiptTenderMethod.cash,
        amountCents: 1605,
        cashGivenCents: 2000,
      ),
    ],
    footer: EdenReceiptFooter(
      returnPolicy: 'Returns within 30 days with receipt.',
      taxId: 'EIN: 12-3456789',
      thankYouMessage: 'Thank you for visiting!',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in EdenReceiptPreviewMode.values)
              ChoiceChip(
                label: Text(m.name),
                selected: _mode == m,
                onSelected: (_) => setState(() => _mode = m),
              ),
          ],
        ),
        if (_mode == EdenReceiptPreviewMode.print) ...[
          const SizedBox(height: EdenSpacing.space2),
          Wrap(
            spacing: 8,
            children: [
              for (final w in EdenReceiptPrintWidth.values)
                ChoiceChip(
                  label: Text(w.name),
                  selected: _printWidth == w,
                  onSelected: (_) => setState(() => _printWidth = w),
                ),
            ],
          ),
        ],
        const SizedBox(height: EdenSpacing.space3),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 520,
            child: EdenReceiptPreview(
              data: _data,
              mode: _mode,
              printWidth: _printWidth,
            ),
          ),
        ),
      ],
    );
  }
}

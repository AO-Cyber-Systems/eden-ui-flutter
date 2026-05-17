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
          const Section(
            title: 'EdenInventoryRowEditor — Inline-edit inventory row',
            child: _InventoryRowDemoBlock(),
          ),
          // ─── Objective 014 anchor: TRD 014-05 EdenReceivingFlow ───
          const Section(
            title: 'EdenReceivingFlow — PO receiving multi-step',
            child: _ReceivingFlowDemoBlock(),
          ),
          // ─── Objective 014 anchor: TRD 014-06 EdenSalesAnalyticsScaffold ───
          const Section(
            title: 'EdenSalesAnalyticsScaffold — Sales analytics composite',
            child: SizedBox(
              height: 640,
              child: EdenSalesAnalyticsScaffold(data: _analyticsDemoData),
            ),
          ),
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

// ───────────────────────────────────────────────────────────────────────────
// TRD 014-04 — EdenInventoryRowEditor demo block
// ───────────────────────────────────────────────────────────────────────────

class _InventoryRowDemoBlock extends StatefulWidget {
  const _InventoryRowDemoBlock();

  @override
  State<_InventoryRowDemoBlock> createState() => _InventoryRowDemoBlockState();
}

class _InventoryRowDemoBlockState extends State<_InventoryRowDemoBlock> {
  // Hand-built demo rows — NOT LLM-generated. Mixes cost/price/onHand
  // permutations to exercise null-field handling + stock-indicator
  // thresholds.
  static const _rows = <EdenInventoryRowData>[
    EdenInventoryRowData(
      rowId: 'r-1',
      sku: 'CB-001',
      name: 'Espresso Blend 1kg',
      costCents: 1200,
      priceCents: 2400,
      onHand: 18,
      reorderPoint: 10,
      location: 'A-12',
    ),
    EdenInventoryRowData(
      rowId: 'r-2',
      sku: 'TS-RED-M',
      name: 'T-shirt Red Medium',
      costCents: 700,
      priceCents: 1995,
      onHand: 35,
      reorderPoint: 20,
      location: 'B-04',
    ),
    EdenInventoryRowData(
      rowId: 'r-3',
      sku: 'PG-090',
      name: 'PVC Elbow 90deg',
      costCents: 80,
      priceCents: 350,
      onHand: 3,
      reorderPoint: 20,
      location: 'C-08',
    ),
    EdenInventoryRowData(
      rowId: 'r-4',
      sku: 'NA-NEW',
      name: 'New product (no stock data)',
      costCents: 150,
      priceCents: 300,
    ),
    EdenInventoryRowData(
      rowId: 'r-5',
      sku: 'MN',
      name: 'Minimal placeholder',
    ),
  ];

  final Set<String> _selected = <String>{};
  String? _editingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_selected.length} selected',
              style: theme.textTheme.labelMedium,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (final row in _rows) ...[
                EdenInventoryRowEditor(
                  data: row,
                  editable: _editingId == row.rowId,
                  selected: _selected.contains(row.rowId),
                  onSelectionChanged: (id, sel) => setState(() {
                    if (sel) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                  }),
                  onRequestEdit: () =>
                      setState(() => _editingId = row.rowId),
                  onCommit: (d) {
                    setState(() => _editingId = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Committed: ${d.rowId} cost=${d.costCents} '
                          'price=${d.priceCents} onHand=${d.onHand} '
                          'reorder=${d.reorderPoint} loc=${d.location}',
                        ),
                      ),
                    );
                  },
                  onCancel: () => setState(() => _editingId = null),
                ),
                if (row != _rows.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// TRD 014-05 — EdenReceivingFlow demo block
// ───────────────────────────────────────────────────────────────────────────

// Hand-built sample data — mirrors test/widgets/_fixtures/
// eden_receiving_flow_fixtures.dart::acmeCoffeePo. Do NOT regenerate via LLM.
const _kAcmeCoffeePo = EdenReceivingDoc(
  poNumber: 'PO-4827',
  vendor: 'Acme Coffee Co.',
  expectedItems: <EdenReceivingExpectedItem>[
    EdenReceivingExpectedItem(
      lineId: 'L-1',
      sku: 'CB-001',
      name: 'Espresso Blend 1kg',
      expectedQty: 10,
      expectedUnitCostCents: 1200,
    ),
    EdenReceivingExpectedItem(
      lineId: 'L-2',
      sku: 'AM-FLT',
      name: 'Americano filter',
      expectedQty: 5,
      expectedUnitCostCents: 800,
    ),
    EdenReceivingExpectedItem(
      lineId: 'L-3',
      sku: 'CP-SYR',
      name: 'Cappuccino syrup',
      expectedQty: 3,
      expectedUnitCostCents: 600,
    ),
    EdenReceivingExpectedItem(
      lineId: 'L-4',
      sku: 'MO-MIX',
      name: 'Mocha mix',
      expectedQty: 2,
      expectedUnitCostCents: 900,
    ),
    EdenReceivingExpectedItem(
      lineId: 'L-5',
      sku: 'SW-024',
      name: 'Sparkling Water 24-pack',
      expectedQty: 24,
      expectedUnitCostCents: 100,
    ),
  ],
  expectedTotalCents: 20600,
);

class _ReceivingFlowDemoBlock extends StatelessWidget {
  const _ReceivingFlowDemoBlock();

  Future<EdenReceivingDoc?> _lookup(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'po-not-found') return null;
    return _kAcmeCoffeePo;
  }

  Future<String?> _capturePhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'demo://damaged-photo-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: 560,
        child: EdenReceivingFlow(
          onPoLookup: _lookup,
          onPhotoCapture: _capturePhoto,
          onSubmit: (draft) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Submitted ${draft.poNumber} → ${draft.disposition.name} '
                '(${draft.receivedItems.length} lines, '
                'photoRef=${draft.damagedPhotoRef})',
              ),
            ));
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// TRD 014-06 — EdenSalesAnalyticsScaffold demo data
// ───────────────────────────────────────────────────────────────────────────

// Hand-built sample data — mirrors test/widgets/_fixtures/
// eden_sales_analytics_scaffold_fixtures.dart::weekOfMay. Do NOT regenerate
// via LLM.
const _analyticsDemoData = EdenSalesAnalyticsData(
  dateRangeLabel: 'May 11-17',
  kpis: <EdenAnalyticsKpi>[
    EdenAnalyticsKpi(
      label: 'Gross sales',
      valueText: r'$12,438',
      deltaPctSinceLastPeriod: 0.12,
      icon: Icons.attach_money,
    ),
    EdenAnalyticsKpi(
      label: 'Transactions',
      valueText: '142',
      deltaPctSinceLastPeriod: 0.04,
      icon: Icons.receipt_long,
    ),
    EdenAnalyticsKpi(
      label: 'Avg basket',
      valueText: r'$87.59',
      deltaPctSinceLastPeriod: -0.03,
      icon: Icons.shopping_basket,
    ),
    EdenAnalyticsKpi(
      label: 'Refund rate',
      valueText: '2.3%',
      deltaPctSinceLastPeriod: -0.01,
      icon: Icons.undo,
    ),
    EdenAnalyticsKpi(
      label: 'Top dept',
      valueText: 'Hot drinks',
      icon: Icons.local_cafe,
    ),
  ],
  trendSeries: <EdenAnalyticsTrendPoint>[
    EdenAnalyticsTrendPoint(label: 'Mon', value: 1450),
    EdenAnalyticsTrendPoint(label: 'Tue', value: 1670),
    EdenAnalyticsTrendPoint(label: 'Wed', value: 1840),
    EdenAnalyticsTrendPoint(label: 'Thu', value: 2020),
    EdenAnalyticsTrendPoint(label: 'Fri', value: 2350),
    EdenAnalyticsTrendPoint(label: 'Sat', value: 1900),
    EdenAnalyticsTrendPoint(label: 'Sun', value: 1208),
  ],
  topProducts: <EdenAnalyticsTopProductRow>[
    EdenAnalyticsTopProductRow(
        rank: 1,
        name: 'Espresso Single',
        unitsSold: 142,
        revenueCents: 49700,
        trend: 'up'),
    EdenAnalyticsTopProductRow(
        rank: 2,
        name: 'Americano',
        unitsSold: 98,
        revenueCents: 39200,
        trend: 'flat'),
    EdenAnalyticsTopProductRow(
        rank: 3,
        name: 'Cappuccino',
        unitsSold: 76,
        revenueCents: 36100,
        trend: 'up'),
    EdenAnalyticsTopProductRow(
        rank: 4,
        name: 'Latte',
        unitsSold: 64,
        revenueCents: 33600,
        trend: 'down'),
    EdenAnalyticsTopProductRow(
        rank: 5,
        name: 'Mocha',
        unitsSold: 54,
        revenueCents: 31050,
        trend: 'up'),
    EdenAnalyticsTopProductRow(
        rank: 6,
        name: 'Iced Coffee',
        unitsSold: 51,
        revenueCents: 21675,
        trend: 'flat'),
    EdenAnalyticsTopProductRow(
        rank: 7,
        name: 'Cold Brew',
        unitsSold: 42,
        revenueCents: 22050,
        trend: 'up'),
    EdenAnalyticsTopProductRow(
        rank: 8,
        name: 'Sparkling Water',
        unitsSold: 38,
        revenueCents: 11400,
        trend: 'down'),
  ],
  topCategories: <EdenAnalyticsCategorySlice>[
    EdenAnalyticsCategorySlice(label: 'Hot drinks', value: 6840),
    EdenAnalyticsCategorySlice(label: 'Cold drinks', value: 3210),
    EdenAnalyticsCategorySlice(label: 'Pastries', value: 1830),
    EdenAnalyticsCategorySlice(label: 'Merchandise', value: 558),
  ],
);

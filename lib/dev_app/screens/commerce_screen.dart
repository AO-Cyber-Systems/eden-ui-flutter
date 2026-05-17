import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 012 (Cross-Vertical Commerce Primitives).
///
/// TRD 012-01 (this TRD) creates the file with the LineItemEditor section
/// across 5 cross-vertical scenarios (retail / medical / fuel / trades / salon)
/// and registers the `Commerce Primitives` tile on `home_screen`.
///
/// Subsequent TRDs APPEND additional `Section(...)` entries beneath the
/// placeholder comments below. Each TRD's append site is anchored by a
/// `// TRD 012-NN appends:` comment so future TRDs know where to splice.
///
/// Reference layout: see `compliance_screen.dart` for the same
/// bootstrap-and-append pattern used by objective 011.
class CommerceScreen extends StatefulWidget {
  const CommerceScreen({super.key});

  @override
  State<CommerceScreen> createState() => _CommerceScreenState();
}

class _CommerceScreenState extends State<CommerceScreen> {
  // Each vertical demo owns its own items list so the dev catalog can
  // demonstrate live editing without test fixtures bleeding into prod code.
  late List<EdenLineItem<String>> _retailItems;
  late List<EdenLineItem<String>> _medicalItems;
  late List<EdenLineItem<String>> _fuelItems;
  late List<EdenLineItem<String>> _tradesItems;
  late List<EdenLineItem<String>> _salonItems;

  @override
  void initState() {
    super.initState();
    _retailItems = const [
      EdenLineItem<String>(
        id: 'retail-1',
        payload: 'COFFEE',
        description: 'Coffee — Large',
        quantity: 2,
        unitPrice: 4.50,
      ),
      EdenLineItem<String>(
        id: 'retail-2',
        payload: 'CROISSANT',
        description: 'Almond Croissant',
        quantity: 1,
        unitPrice: 6.25,
      ),
    ];
    _medicalItems = const [
      EdenLineItem<String>(
        id: 'med-1',
        payload: 'visit',
        description: 'Office visit (est. patient)',
        quantity: 1,
        unitPrice: 125.0,
      ),
      EdenLineItem<String>(
        id: 'med-2',
        payload: 'lab',
        description: 'CBC panel',
        quantity: 1,
        unitPrice: 45.0,
        discountAmount: 5.0,
      ),
    ];
    _fuelItems = const [
      EdenLineItem<String>(
        id: 'fuel-1',
        payload: 'diesel',
        description: 'Off-road diesel (200 gal)',
        quantity: 200,
        unitPrice: 3.45,
      ),
    ];
    _tradesItems = const [
      EdenLineItem<String>(
        id: 'trades-1',
        payload: 'labor',
        description: 'HVAC diagnostic',
        quantity: 1.5,
        unitPrice: 120.0,
      ),
      EdenLineItem<String>(
        id: 'trades-2',
        payload: 'material',
        description: 'R-410A refrigerant 2lbs',
        quantity: 2,
        unitPrice: 45.0,
        taxRate: 0.0625,
      ),
    ];
    _salonItems = const [
      EdenLineItem<String>(
        id: 'salon-1',
        payload: 'cut',
        description: 'Stylist cut',
        quantity: 1,
        unitPrice: 75.0,
      ),
      EdenLineItem<String>(
        id: 'salon-2',
        payload: 'addon',
        description: 'Olaplex add-on',
        quantity: 1,
        unitPrice: 25.0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commerce Primitives')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'EdenLineItemEditor — cross-vertical line-item composer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Retail cart', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenLineItemEditor<String>(
                  items: _retailItems,
                  onItemsChanged: (next) => setState(() => _retailItems = next),
                ),
                const SizedBox(height: 24),
                const Text('Medical claim (with discount)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenLineItemEditor<String>(
                  items: _medicalItems,
                  onItemsChanged: (next) => setState(() => _medicalItems = next),
                  visibleColumns: const [
                    EdenLineItemColumn.description,
                    EdenLineItemColumn.quantity,
                    EdenLineItemColumn.unitPrice,
                    EdenLineItemColumn.discount,
                    EdenLineItemColumn.lineTotal,
                    EdenLineItemColumn.remove,
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Fuel POD (single-item delivery)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenLineItemEditor<String>(
                  items: _fuelItems,
                  onItemsChanged: (next) => setState(() => _fuelItems = next),
                ),
                const SizedBox(height: 24),
                const Text('Trades quote (labor + material + tax)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenLineItemEditor<String>(
                  items: _tradesItems,
                  onItemsChanged: (next) => setState(() => _tradesItems = next),
                  visibleColumns: const [
                    EdenLineItemColumn.description,
                    EdenLineItemColumn.quantity,
                    EdenLineItemColumn.unitPrice,
                    EdenLineItemColumn.tax,
                    EdenLineItemColumn.lineTotal,
                    EdenLineItemColumn.remove,
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Salon services (read-only checkout preview)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenLineItemEditor<String>(
                  items: _salonItems,
                  onItemsChanged: (next) => setState(() => _salonItems = next),
                  readOnly: true,
                ),
              ],
            ),
          ),
          const Section(
            title: 'EdenAggregateKpiStrip — N-tile strip + aggregate footer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales day (retail)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenAggregateKpiStrip(
                  tiles: [
                    EdenKpiTile(label: 'Sales', displayValue: r'$1,245', trend: 0.12),
                    EdenKpiTile(label: 'Orders', displayValue: '47', trend: 0.04),
                    EdenKpiTile(label: 'Avg ticket', displayValue: r'$26.49', trend: -0.02),
                    EdenKpiTile(
                      label: 'Refund rate',
                      displayValue: '2.1%',
                      trend: 0.01,
                      polarity: EdenKpiTrendPolarity.negativeIsGood,
                    ),
                  ],
                  aggregate: EdenKpiAggregate(
                    label: 'Day total',
                    displayValue: r'$1,245',
                    mode: EdenKpiAggregateMode.sum,
                  ),
                ),
                SizedBox(height: 24),
                Text('Fuel volume (week)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenAggregateKpiStrip(
                  tiles: [
                    EdenKpiTile(label: 'Gallons', displayValue: '8,420', trend: 0.08),
                    EdenKpiTile(label: 'Stops', displayValue: '34', trend: 0.05),
                    EdenKpiTile(label: 'Avg/stop', displayValue: '247.6 gal', trend: 0.03),
                    EdenKpiTile(label: 'Truck util', displayValue: '82%', trend: 0.06),
                    EdenKpiTile(label: 'Routes', displayValue: '6', trend: 0),
                  ],
                  aggregate: EdenKpiAggregate(
                    label: 'Week gal',
                    displayValue: '8,420',
                    mode: EdenKpiAggregateMode.sum,
                  ),
                ),
                SizedBox(height: 24),
                Text('Medical claims rollup', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenAggregateKpiStrip(
                  tiles: [
                    EdenKpiTile(label: 'Submitted', displayValue: '124', trend: 0.07),
                    EdenKpiTile(label: 'Paid', displayValue: '108', trend: 0.09),
                    EdenKpiTile(
                      label: 'Denied',
                      displayValue: '8',
                      trend: -0.02,
                      polarity: EdenKpiTrendPolarity.negativeIsGood,
                    ),
                    EdenKpiTile(
                      label: 'AR days',
                      displayValue: '42',
                      trend: 0.03,
                      polarity: EdenKpiTrendPolarity.negativeIsGood,
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text('Trades revenue', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenAggregateKpiStrip(
                  tiles: [
                    EdenKpiTile(label: 'Booked', displayValue: r'$24,600', trend: 0.15),
                    EdenKpiTile(label: 'Completed', displayValue: r'$19,200', trend: 0.10),
                    EdenKpiTile(
                      label: 'Outstanding',
                      displayValue: r'$5,400',
                      trend: 0.03,
                      polarity: EdenKpiTrendPolarity.negativeIsGood,
                    ),
                    EdenKpiTile(label: 'Win rate', displayValue: '34%', trend: 0.04),
                  ],
                  aggregate: EdenKpiAggregate(label: 'Net booked', displayValue: r'$24,600'),
                ),
              ],
            ),
          ),
          Section(
            title: 'EdenPaymentEntry — payment method + amount entry',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Retail POS — cash / card / gift', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenPaymentEntry(
                  allowedMethods: const [
                    EdenPaymentMethod.cash,
                    EdenPaymentMethod.card,
                    EdenPaymentMethod.giftCard,
                  ],
                  onDraftChanged: (_) {},
                  expectedAmount: 47.50,
                ),
                const SizedBox(height: 24),
                const Text('Medical copay — card / check / portal', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenPaymentEntry(
                  allowedMethods: const [
                    EdenPaymentMethod.card,
                    EdenPaymentMethod.check,
                    EdenPaymentMethod.portal,
                  ],
                  onDraftChanged: (_) {},
                  expectedAmount: 25.00,
                ),
                const SizedBox(height: 24),
                const Text('Trades invoice — card / ACH / check', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenPaymentEntry(
                  allowedMethods: const [
                    EdenPaymentMethod.card,
                    EdenPaymentMethod.ach,
                    EdenPaymentMethod.check,
                  ],
                  onDraftChanged: (_) {},
                  expectedAmount: 1240.00,
                  requireReference: true,
                ),
                const SizedBox(height: 24),
                const Text('Fuel POD — cash / card / account', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenPaymentEntry(
                  allowedMethods: const [
                    EdenPaymentMethod.cash,
                    EdenPaymentMethod.card,
                    EdenPaymentMethod.accountOnFile,
                  ],
                  onDraftChanged: (_) {},
                  expectedAmount: 690.00,
                ),
              ],
            ),
          ),
          Section(
            title: 'EdenSplitTender — multi-method composer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Retail POS — 3-way split', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenSplitTender(
                  total: 87.50,
                  allowedMethods: const [
                    EdenPaymentMethod.cash,
                    EdenPaymentMethod.card,
                    EdenPaymentMethod.giftCard,
                  ],
                  onDraftsChanged: (_) {},
                  initialDrafts: const [
                    EdenPaymentDraft(
                      method: EdenPaymentMethod.giftCard,
                      amount: 25.00,
                      reference: 'GC-1024',
                    ),
                    EdenPaymentDraft(
                      method: EdenPaymentMethod.card,
                      amount: 50.00,
                      reference: '4242',
                    ),
                    EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 12.50),
                  ],
                  allowOverCapacity: true,
                ),
                const SizedBox(height: 24),
                const Text('Trades invoice — 2-way split with reference', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenSplitTender(
                  total: 1240.00,
                  allowedMethods: const [
                    EdenPaymentMethod.card,
                    EdenPaymentMethod.ach,
                    EdenPaymentMethod.check,
                  ],
                  onDraftsChanged: (_) {},
                  initialDrafts: const [
                    EdenPaymentDraft(
                      method: EdenPaymentMethod.ach,
                      amount: 1000.00,
                      reference: '1234',
                    ),
                    EdenPaymentDraft(
                      method: EdenPaymentMethod.check,
                      amount: 240.00,
                      reference: '#1003',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Single-tender baseline (balanced)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                EdenSplitTender(
                  total: 50.00,
                  allowedMethods: const [
                    EdenPaymentMethod.cash,
                    EdenPaymentMethod.card,
                  ],
                  onDraftsChanged: (_) {},
                ),
              ],
            ),
          ),
          const Section(
            title: 'EdenSparkline — compact trend line (no axes, no animation)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lab trend — hemoglobin', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: EdenSparkline(
                        values: [12.5, 13.1, 12.8, 11.9, 12.2, 12.5],
                        referenceLines: [12.0], // low-normal threshold
                        height: 48,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Hgb: 12.5 g/dL (ref ≥ 12)'),
                  ],
                ),
                SizedBox(height: 24),
                Text('Sales 7-day trend (in KPI tile)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenAggregateKpiStrip(
                  tiles: [
                    EdenKpiTile(
                      label: 'Sales',
                      displayValue: r'$1,245',
                      trend: 0.12,
                      trailingSlot: SizedBox(
                        width: 80,
                        height: 24,
                        child: EdenSparkline(
                          values: [1200, 1340, 1180, 1420, 1520, 1480, 1245],
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text('Tank level history', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  width: 300,
                  child: EdenSparkline(
                    values: [88, 75, 62, 51, 40, 30, 23],
                    minValue: 0,
                    maxValue: 100,
                    referenceLines: [25.0], // refill threshold
                    height: 60,
                  ),
                ),
                SizedBox(height: 24),
                Text('Flat line baseline', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: EdenSparkline(values: [50, 50, 50, 50], height: 40),
                ),
                SizedBox(height: 24),
                Text('Sparkline with NaN gaps', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: EdenSparkline(
                    values: [10.0, double.nan, 15.0, 12.0, double.nan, 14.0],
                    nullablePoints: true,
                    height: 40,
                  ),
                ),
              ],
            ),
          ),
          const Section(
            title: 'EdenBarChart — grouped / stacked / horizontal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Retail daily sales (single series + target line)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: EdenBarChart(
                    series: [
                      EdenChartSeries(name: 'Sales', data: [
                        EdenChartDataPoint(label: 'Mon', value: 1200),
                        EdenChartDataPoint(label: 'Tue', value: 1340),
                        EdenChartDataPoint(label: 'Wed', value: 1180),
                        EdenChartDataPoint(label: 'Thu', value: 1420),
                        EdenChartDataPoint(label: 'Fri', value: 1520),
                        EdenChartDataPoint(label: 'Sat', value: 1680),
                        EdenChartDataPoint(label: 'Sun', value: 1245),
                      ]),
                    ],
                    xAxisLabel: 'Day of week',
                    yAxisLabel: r'Sales ($)',
                    referenceLines: [1500.0],
                  ),
                ),
                SizedBox(height: 24),
                Text('Fuel monthly volume by truck (grouped)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: EdenBarChart(
                    series: [
                      EdenChartSeries(name: 'Truck A', data: [
                        EdenChartDataPoint(label: 'W1', value: 2400),
                        EdenChartDataPoint(label: 'W2', value: 2600),
                        EdenChartDataPoint(label: 'W3', value: 2200),
                        EdenChartDataPoint(label: 'W4', value: 2800),
                      ]),
                      EdenChartSeries(name: 'Truck B', data: [
                        EdenChartDataPoint(label: 'W1', value: 2100),
                        EdenChartDataPoint(label: 'W2', value: 2400),
                        EdenChartDataPoint(label: 'W3', value: 2000),
                        EdenChartDataPoint(label: 'W4', value: 2500),
                      ]),
                      EdenChartSeries(name: 'Truck C', data: [
                        EdenChartDataPoint(label: 'W1', value: 1800),
                        EdenChartDataPoint(label: 'W2', value: 2000),
                        EdenChartDataPoint(label: 'W3', value: 1900),
                        EdenChartDataPoint(label: 'W4', value: 2100),
                      ]),
                    ],
                    xAxisLabel: 'Week',
                    yAxisLabel: 'Gallons',
                  ),
                ),
                SizedBox(height: 24),
                Text('Medical claims by status (stacked)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: EdenBarChart(
                    stacked: true,
                    series: [
                      EdenChartSeries(name: 'Paid', data: [
                        EdenChartDataPoint(label: 'Jan', value: 92),
                        EdenChartDataPoint(label: 'Feb', value: 88),
                        EdenChartDataPoint(label: 'Mar', value: 95),
                        EdenChartDataPoint(label: 'Apr', value: 91),
                        EdenChartDataPoint(label: 'May', value: 94),
                        EdenChartDataPoint(label: 'Jun', value: 89),
                      ]),
                      EdenChartSeries(name: 'Denied', data: [
                        EdenChartDataPoint(label: 'Jan', value: 8),
                        EdenChartDataPoint(label: 'Feb', value: 12),
                        EdenChartDataPoint(label: 'Mar', value: 5),
                        EdenChartDataPoint(label: 'Apr', value: 9),
                        EdenChartDataPoint(label: 'May', value: 6),
                        EdenChartDataPoint(label: 'Jun', value: 11),
                      ]),
                    ],
                    xAxisLabel: 'Month',
                    yAxisLabel: 'Claims',
                  ),
                ),
                SizedBox(height: 24),
                Text('Trades revenue by service category (horizontal)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: EdenBarChart(
                    horizontal: true,
                    series: [
                      EdenChartSeries(name: 'Revenue', data: [
                        EdenChartDataPoint(label: 'HVAC Install', value: 24600),
                        EdenChartDataPoint(label: 'HVAC Repair', value: 18200),
                        EdenChartDataPoint(label: 'Plumbing', value: 12400),
                        EdenChartDataPoint(label: 'Electrical', value: 9800),
                        EdenChartDataPoint(label: 'Refrig.', value: 6200),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Section(
            title: 'EdenDonutChart — center-label + legend',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service mix (salon)', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenDonutChart(
                  data: [
                    EdenChartDataPoint(label: 'Cut', value: 40),
                    EdenChartDataPoint(label: 'Color', value: 30),
                    EdenChartDataPoint(label: 'Treatment', value: 20),
                    EdenChartDataPoint(label: 'Retail', value: 10),
                  ],
                  size: 200,
                  centerLabel: r'$2,400 total',
                ),
                SizedBox(height: 24),
                Text(
                  'Inventory by category (retail — centerLabelSlot composition)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenDonutChart(
                  data: [
                    EdenChartDataPoint(label: 'Apparel', value: 1850),
                    EdenChartDataPoint(label: 'Accessories', value: 1200),
                    EdenChartDataPoint(label: 'Footwear', value: 980),
                    EdenChartDataPoint(label: 'Home', value: 640),
                    EdenChartDataPoint(label: 'Other', value: 220),
                  ],
                  size: 220,
                  centerLabelSlot: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 28),
                      SizedBox(height: 4),
                      Text(
                        r'$4,890',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      Text('On-hand', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Payment method split (medical — legend right)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenDonutChart(
                  data: [
                    EdenChartDataPoint(label: 'Insurance', value: 65),
                    EdenChartDataPoint(label: 'Patient card', value: 20),
                    EdenChartDataPoint(label: 'Check', value: 10),
                    EdenChartDataPoint(label: 'Portal', value: 5),
                  ],
                  size: 200,
                  centerLabel: r'$8,420',
                  legendPosition: EdenChartLegendPosition.right,
                ),
                SizedBox(height: 24),
                Text(
                  'Revenue distribution (trades — default bottom legend)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenDonutChart(
                  data: [
                    EdenChartDataPoint(label: 'HVAC', value: 56),
                    EdenChartDataPoint(label: 'Plumbing', value: 28),
                    EdenChartDataPoint(label: 'Electrical', value: 16),
                  ],
                  size: 200,
                  centerLabel: r'$48,200',
                ),
              ],
            ),
          ),
          // TRD 015-01 appends here ↓ Objective 015 — Tipping primitives
          const Section(
            title:
                'EdenTippingSelector + EdenTipSplitEditor — tip primitives',
            child: _Obj015TippingDemo(),
          ),
          // TRD 015-03 appends here ↓ Objective 015 — Gift card manager
          const Section(
            title:
                'EdenGiftCardManager — issue / redeem / lookup / balance / ledger',
            child: _Obj015GiftCardDemo(),
          ),
          // TRD 015-08 appends here ↓ Objective 015 — Promotions
          const Section(
            title:
                'EdenPromotionAuthor + EdenPromotionApply — promotion authoring + apply',
            child: _Obj015PromotionsDemo(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TRD 015-01 — Tipping primitives demo
// ─────────────────────────────────────────────────────────────────────────

class _Obj015TippingDemo extends StatefulWidget {
  const _Obj015TippingDemo();
  @override
  State<_Obj015TippingDemo> createState() => _Obj015TippingDemoState();
}

class _Obj015TippingDemoState extends State<_Obj015TippingDemo> {
  EdenTipDraft? _salonDraft;
  EdenTipDraft? _restaurantDraft;
  EdenTipDraft? _retailDraft;
  List<EdenTipSplitAllocation>? _splitAllocations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Salon — 18% standard (subtotal \$100.00)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenTippingSelector(
          subtotal: 100.0,
          presets: EdenTipPresets.salonStandard,
          onDraftChanged: (d) => setState(() => _salonDraft = d),
        ),
        if (_salonDraft != null)
          Text(
            'Captured: mode=${_salonDraft!.mode.name} '
            'tip=\$${_salonDraft!.tipAmount.toStringAsFixed(2)}',
          ),
        const SizedBox(height: 24),
        const Text(
          'Restaurant — 22% mid-tier (subtotal \$78.50)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenTippingSelector(
          subtotal: 78.50,
          presets: EdenTipPresets.restaurantStandard,
          onDraftChanged: (d) => setState(() => _restaurantDraft = d),
        ),
        if (_restaurantDraft != null)
          Text(
            'Captured: mode=${_restaurantDraft!.mode.name} '
            'tip=\$${_restaurantDraft!.tipAmount.toStringAsFixed(2)}',
          ),
        const SizedBox(height: 24),
        const Text(
          'Retail counter — light tier, single flat custom (subtotal \$12.49)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenTippingSelector(
          subtotal: 12.49,
          presets: EdenTipPresets.lightTier,
          onDraftChanged: (d) => setState(() => _retailDraft = d),
        ),
        if (_retailDraft != null)
          Text(
            'Captured: mode=${_retailDraft!.mode.name} '
            'tip=\$${_retailDraft!.tipAmount.toStringAsFixed(2)}',
          ),
        const SizedBox(height: 24),
        const Text(
          'Multi-staff tip split — primary 60% / assistant 25% / shampoo 15%',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenTipSplitEditor(
          totalTip: 24.00,
          recipients: const [
            EdenTipRecipient(
              id: 'sarah',
              displayName: 'Sarah',
              roleLabel: 'Primary stylist',
            ),
            EdenTipRecipient(
              id: 'mia',
              displayName: 'Mia',
              roleLabel: 'Assistant',
            ),
            EdenTipRecipient(
              id: 'amy',
              displayName: 'Amy',
              roleLabel: 'Shampoo',
            ),
          ],
          initialAllocations: const [
            EdenTipSplitAllocation(
              recipient: EdenTipRecipient(
                id: 'sarah',
                displayName: 'Sarah',
                roleLabel: 'Primary stylist',
              ),
              share: 0.60,
            ),
            EdenTipSplitAllocation(
              recipient: EdenTipRecipient(
                id: 'mia',
                displayName: 'Mia',
                roleLabel: 'Assistant',
              ),
              share: 0.25,
            ),
            EdenTipSplitAllocation(
              recipient: EdenTipRecipient(
                id: 'amy',
                displayName: 'Amy',
                roleLabel: 'Shampoo',
              ),
              share: 0.15,
            ),
          ],
          onAllocationsChanged: (a) =>
              setState(() => _splitAllocations = a),
        ),
        if (_splitAllocations != null)
          Text(
            'Captured allocations: '
            '${_splitAllocations!.map((a) => '${a.recipient.displayName}=${(a.share * 100).toStringAsFixed(0)}%').join(', ')}',
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TRD 015-03 — Gift card manager demo
// ─────────────────────────────────────────────────────────────────────────

class _Obj015GiftCardDemo extends StatefulWidget {
  const _Obj015GiftCardDemo();
  @override
  State<_Obj015GiftCardDemo> createState() => _Obj015GiftCardDemoState();
}

class _Obj015GiftCardDemoState extends State<_Obj015GiftCardDemo> {
  EdenGiftCardMode _mode = EdenGiftCardMode.issue;

  static final _sampleCard = EdenGiftCardRecord(
    code: 'GC123456789',
    initialAmount: 100.0,
    currentBalance: 67.50,
    issuedAt: DateTime(2026, 1, 15),
    recipientName: 'Maya Rivera',
    recipientContact: 'maya@example.com',
  );

  static final _sampleLedger = <EdenGiftCardLedgerEntry>[
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 1, 15, 10, 30),
      action: EdenGiftCardLedgerAction.issue,
      amount: 100.0,
      balanceAfter: 100.0,
      memo: 'Original sale',
    ),
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 1, 20, 14, 15),
      action: EdenGiftCardLedgerAction.redeem,
      amount: -25.0,
      balanceAfter: 75.0,
      memo: 'Haircut',
    ),
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 2, 5, 11, 0),
      action: EdenGiftCardLedgerAction.redeem,
      amount: -7.50,
      balanceAfter: 67.50,
      memo: 'Tip add-on',
    ),
  ];

  Future<EdenGiftCardRecord?> _demoLookup(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (code.toUpperCase().contains('GC')) return _sampleCard;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in EdenGiftCardMode.values)
              ChoiceChip(
                label: Text(m.name),
                selected: _mode == m,
                onSelected: (_) => setState(() => _mode = m),
              ),
          ],
        ),
        const SizedBox(height: 16),
        EdenGiftCardManager(
          mode: _mode,
          record: _mode == EdenGiftCardMode.issue ? null : _sampleCard,
          ledgerEntries:
              _mode == EdenGiftCardMode.ledger ? _sampleLedger : null,
          onLookup: _demoLookup,
          onDraftChanged: (draft) {
            // Dev catalog logs to a SnackBar so demos are visibly wired.
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Draft emitted: ${draft.runtimeType}'),
              duration: const Duration(milliseconds: 600),
            ));
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TRD 015-08 — Promotion author + apply demo
// ─────────────────────────────────────────────────────────────────────────

class _Obj015PromotionsDemo extends StatefulWidget {
  const _Obj015PromotionsDemo();
  @override
  State<_Obj015PromotionsDemo> createState() =>
      _Obj015PromotionsDemoState();
}

class _Obj015PromotionsDemoState extends State<_Obj015PromotionsDemo> {
  EdenPromotionRule _authoredRule = const EdenPromotionRule(
    id: 'demo-author',
    label: 'Demo BOGO',
    type: EdenPromotionType.bogo,
    discountKind: EdenPromotionDiscountKind.buyXgetYfree,
    buyQuantity: 2,
    getQuantity: 1,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Author mode — live-edit a promotion rule',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenPromotionAuthor(
          rule: _authoredRule,
          memberTierOptions: const [
            (id: 'gold', label: 'Gold'),
            (id: 'vip', label: 'VIP'),
          ],
          onRuleChanged: (r) => setState(() => _authoredRule = r),
        ),
        const SizedBox(height: 24),
        const Text(
          'Apply mode — eligibility check + apply',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenPromotionApply(
          context: EdenPromotionApplyContext(
            lineItems: const [
              EdenLineItem<String>(
                id: 'sku-1',
                payload: 'sku-1',
                description: 'Aloe mask',
                quantity: 2,
                unitPrice: 15.00,
              ),
              EdenLineItem<String>(
                id: 'sku-2',
                payload: 'sku-2',
                description: 'Charcoal mask',
                quantity: 1,
                unitPrice: 18.00,
              ),
            ],
            subtotal: 100.00,
            currentTime: DateTime(2026, 7, 1),
            customerMemberTierIds: const ['gold'],
          ),
          availableRules: const [
            EdenPromotionRule(
              id: 'p-bogo',
              label: 'Buy 2 get 1 free — masks',
              type: EdenPromotionType.bogo,
              discountKind: EdenPromotionDiscountKind.buyXgetYfree,
              buyQuantity: 2,
              getQuantity: 1,
            ),
            EdenPromotionRule(
              id: 'p-gold',
              label: 'Gold-tier 15% off',
              type: EdenPromotionType.memberPricing,
              discountKind: EdenPromotionDiscountKind.percentOff,
              discountValue: 0.15,
              constraints: EdenPromotionConstraint(
                eligibleMemberTierIds: ['gold'],
              ),
            ),
            EdenPromotionRule(
              id: 'p-summer',
              label: 'Summer 20% off — code SUMMER20',
              type: EdenPromotionType.couponCode,
              discountKind: EdenPromotionDiscountKind.percentOff,
              discountValue: 0.20,
              couponCode: 'SUMMER20',
            ),
          ],
          onPromotionApplied: (r) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(r == null
                  ? 'Promotion cleared'
                  : 'Applied: ${r.appliedRule.label} '
                      '(\$${r.discountAmount.toStringAsFixed(2)} off)'),
              duration: const Duration(milliseconds: 800),
            ));
          },
        ),
      ],
    );
  }
}

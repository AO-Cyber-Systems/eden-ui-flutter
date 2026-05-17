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
          // TRD 012-06 appends: Section(title: 'EdenBarChart — grouped / stacked / horizontal', child: ...).
          // TRD 012-07 appends: Section(title: 'EdenDonutChart — center-label + legend', child: ...).
        ],
      ),
    );
  }
}

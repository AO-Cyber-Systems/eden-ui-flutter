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
          // TRD 012-03 appends: Section(title: 'EdenPaymentEntry — payment method + amount entry', child: ...).
          // TRD 012-04 appends: Section(title: 'EdenSplitTender — multi-method composer', child: ...).
          // TRD 012-05 appends: Section(title: 'EdenSparkline — compact trend line (no axes, no animation)', child: ...).
          // TRD 012-06 appends: Section(title: 'EdenBarChart — grouped / stacked / horizontal', child: ...).
          // TRD 012-07 appends: Section(title: 'EdenDonutChart — center-label + legend', child: ...).
        ],
      ),
    );
  }
}

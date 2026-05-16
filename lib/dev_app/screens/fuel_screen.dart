import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 005 (B-Fuel components).
///
/// TRD 005-01 creates the file with the TankGauge section. TRDs 005-02
/// through 005-06 append additional Section(...) entries for each new
/// fuel widget at their respective anchor placeholders.
class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  EdenTankGaugeMode _gaugeMode = EdenTankGaugeMode.linear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B-Fuel — Vertical Components')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'EdenTankGauge — Liquid-level meter',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in EdenTankGaugeMode.values)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: _gaugeMode == m,
                        onSelected: (_) => setState(() => _gaugeMode = m),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _GaugeDemo(
                      label: 'Empty',
                      data: const EdenTankGaugeData(
                        capacityGal: 500,
                        currentGal: 0,
                        fuelTypeLabel: 'Propane',
                      ),
                      mode: _gaugeMode,
                    ),
                    _GaugeDemo(
                      label: 'Low (16%)',
                      data: const EdenTankGaugeData(
                        capacityGal: 500,
                        currentGal: 80,
                        fuelTypeLabel: 'Propane',
                      ),
                      mode: _gaugeMode,
                    ),
                    _GaugeDemo(
                      label: 'Amber (40%)',
                      data: const EdenTankGaugeData(
                        capacityGal: 500,
                        currentGal: 200,
                        fuelTypeLabel: 'Diesel',
                      ),
                      mode: _gaugeMode,
                    ),
                    _GaugeDemo(
                      label: 'Normal (64%)',
                      data: const EdenTankGaugeData(
                        capacityGal: 500,
                        currentGal: 320,
                        fuelTypeLabel: 'Heating oil',
                      ),
                      mode: _gaugeMode,
                    ),
                    _GaugeDemo(
                      label: 'Full (100%)',
                      data: const EdenTankGaugeData(
                        capacityGal: 500,
                        currentGal: 500,
                      ),
                      mode: _gaugeMode,
                    ),
                    _GaugeDemo(
                      label: 'Overfull (110%)',
                      data: const EdenTankGaugeData(
                        capacityGal: 500,
                        currentGal: 550,
                      ),
                      mode: _gaugeMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Section(
            title: 'EdenRouteStopList — Ordered stop sequence',
            child: _RouteStopListDemo(),
          ),
          Section(
            title: 'EdenMeterReadingEntry — Reading capture',
            child: SizedBox(
              width: 400,
              child: EdenMeterReadingEntry(
                onPhotoPick: () async {
                  // Demo: small delay simulating a camera capture.
                  await Future<void>.delayed(
                      const Duration(milliseconds: 300));
                  return 'https://via.placeholder.com/240x240.png?text=Tank+photo';
                },
                onSubmit: (draft) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Recorded: ${draft.gallons} gal · ${draft.source.name} '
                        '· operator ${draft.operatorId}'),
                  ));
                },
              ),
            ),
          ),
          Section(
            title: 'EdenHazmatDocViewer — Manifest + MSDS + cert',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in EdenHazmatCertStatus.values)
                      _HazmatCertStatusDemo(status: status),
                  ],
                ),
                const SizedBox(height: 16),
                const EdenHazmatDocViewer(
                  data: EdenHazmatDocData(
                    manifestAttachment: EdenAttachment(
                      name: 'manifest-2026-05-16.pdf',
                      size: 124500,
                      type: 'application/pdf',
                      url: 'https://example.com/manifest.pdf',
                    ),
                    msdsAttachment: EdenAttachment(
                      name: 'msds-propane.pdf',
                      size: 89200,
                      type: 'application/pdf',
                      url: 'https://example.com/msds.pdf',
                    ),
                    driverCertLabel: 'DOT HM-126F • Driver J. Smith',
                  ),
                ),
              ],
            ),
          ),
          Section(
            title: 'EdenFuelPriceTicker — Real-time price',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 400,
                  child: EdenFuelPriceTicker(
                    data: EdenFuelPriceData(
                      currentCents: 250,
                      priorCents: 245,
                      fuelTypeLabel: 'Heating oil',
                      asOf: DateTime.now()
                          .subtract(const Duration(minutes: 5)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 400,
                  child: EdenFuelPriceTicker(
                    data: EdenFuelPriceData(
                      currentCents: 240,
                      priorCents: 250,
                      fuelTypeLabel: 'Diesel',
                      asOf: DateTime.now()
                          .subtract(const Duration(hours: 2)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 400,
                  child: EdenFuelPriceTicker(
                    data: EdenFuelPriceData(
                      currentCents: 250,
                      priorCents: 250,
                      fuelTypeLabel: 'Propane',
                      asOf: DateTime.now(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: EdenFuelPriceTicker(
                    data: EdenFuelPriceData(
                      currentCents: 350,
                      priorCents: 250,
                      fuelTypeLabel: 'Aviation fuel',
                      asOf: DateTime.now()
                          .subtract(const Duration(days: 1)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 400,
                  child: EdenFuelPriceTicker(
                    data: EdenFuelPriceData(
                      currentCents: 260,
                      priorCents: 250,
                      fuelTypeLabel: 'Gasoline (wholesale resale)',
                      asOf: DateTime.now()
                          .subtract(const Duration(minutes: 30)),
                    ),
                    deltaPolarity:
                        EdenFuelPriceDeltaPolarity.higherIsBetter,
                  ),
                ),
              ],
            ),
          ),
          Section(
            title: 'EdenTruckInventoryCard — Per-truck inventory',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 350,
                  child: EdenTruckInventoryCard(
                    data: const EdenTruckInventoryData(
                      truckLabel: 'Truck 47',
                      fuelTypeLabel: 'Propane',
                      capacityGal: 500,
                      currentGal: 320,
                    ),
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tapped Truck 47')),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 600,
                  child: EdenTruckInventoryCard(
                    data: EdenTruckInventoryData(
                      truckLabel: 'Tanker A-12',
                      fuelTypeLabel: 'Heating oil',
                      capacityGal: 2500,
                      currentGal: 1850,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 350,
                  child: EdenTruckInventoryCard(
                    data: EdenTruckInventoryData(
                      truckLabel: 'Truck 99',
                      fuelTypeLabel: 'Diesel',
                      capacityGal: 500,
                      currentGal: 0,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 350,
                  child: EdenTruckInventoryCard(
                    data: EdenTruckInventoryData(
                      truckLabel: 'Truck 14',
                      fuelTypeLabel: 'Gasoline',
                      capacityGal: 500,
                      currentGal: 500,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 350,
                  child: EdenTruckInventoryCard(
                    data: EdenTruckInventoryData(
                      truckLabel: 'Tanker B-99',
                      fuelTypeLabel: 'Heating oil',
                      capacityGal: 500,
                      currentGal: 550,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 350,
                  child: EdenTruckInventoryCard(
                    data: EdenTruckInventoryData(
                      truckLabel: 'Truck (unspecified)',
                      fuelTypeLabel: 'Propane',
                      capacityGal: 0,
                      currentGal: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive demo of [EdenRouteStopList] — holds mutable stops state in
/// the demo widget so drag-reorder mutations re-render correctly.
class _RouteStopListDemo extends StatefulWidget {
  @override
  State<_RouteStopListDemo> createState() => _RouteStopListDemoState();
}

class _RouteStopListDemoState extends State<_RouteStopListDemo> {
  List<EdenRouteStopData> _stops = _initialStops();
  bool _reorderable = true;

  static List<EdenRouteStopData> _initialStops() => [
        EdenRouteStopData(
          id: 's1',
          label: 'Acme Industrial — 250 gal propane',
          status: EdenRouteStopStatus.completed,
          estimatedArrival: DateTime(2026, 5, 16, 8, 30),
          address: const EdenAddress(
            streetLine1: '100 Main St',
            city: 'Boston',
            regionCode: 'MA',
            postalCode: '02101',
            countryCode: 'US',
          ),
          payloadGal: 250,
        ),
        EdenRouteStopData(
          id: 's2',
          label: 'Beta Co Heating — 180 gal heating oil',
          status: EdenRouteStopStatus.enRoute,
          estimatedArrival: DateTime(2026, 5, 16, 9, 45),
          address: const EdenAddress(
            streetLine1: '42 Oak Ave',
            city: 'Cambridge',
            regionCode: 'MA',
            postalCode: '02139',
            countryCode: 'US',
          ),
          payloadGal: 180,
        ),
        EdenRouteStopData(
          id: 's3',
          label: 'Gamma LLC Yard — 500 gal diesel',
          status: EdenRouteStopStatus.pending,
          estimatedArrival: DateTime(2026, 5, 16, 11, 15),
          address: const EdenAddress(
            streetLine1: '789 Industrial Way',
            streetLine2: 'Suite B',
            city: 'Quincy',
            regionCode: 'MA',
            postalCode: '02169',
            countryCode: 'US',
          ),
          payloadGal: 500,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Reorderable:'),
            const SizedBox(width: 8),
            Switch(
              value: _reorderable,
              onChanged: (v) => setState(() => _reorderable = v),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => setState(() => _stops = []),
              child: const Text('Show empty state'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _stops = _initialStops()),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: EdenRouteStopList(
            stops: _stops,
            reorderable: _reorderable,
            onReorder: (o, n) => setState(() {
              final item = _stops.removeAt(o);
              _stops.insert(n, item);
            }),
            onStopTap: (id) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped stop $id')),
            ),
            onStatusTap: (id) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped status $id')),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cert-status mini-demo for the HazmatDocViewer catalog section.
class _HazmatCertStatusDemo extends StatelessWidget {
  const _HazmatCertStatusDemo({required this.status});

  final EdenHazmatCertStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      child: EdenHazmatDocViewer(
        data: EdenHazmatDocData(
          manifestAttachment: const EdenAttachment(
            name: 'manifest.pdf',
            size: 100,
            type: 'application/pdf',
            url: 'https://example.com/manifest.pdf',
          ),
          driverCertLabel: 'Sample driver',
          certStatus: status,
        ),
      ),
    );
  }
}

class _GaugeDemo extends StatelessWidget {
  const _GaugeDemo({
    required this.label,
    required this.data,
    required this.mode,
  });

  final String label;
  final EdenTankGaugeData data;
  final EdenTankGaugeMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenTankGauge(data: data, mode: mode),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

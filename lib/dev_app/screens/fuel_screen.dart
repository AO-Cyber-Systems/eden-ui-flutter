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
          // TRD 005-02 will append: Section(title: 'EdenRouteStopList — Ordered stop sequence', child: ...).
          // TRD 005-03 will append: Section(title: 'EdenMeterReadingEntry — Reading capture', child: ...).
          // TRD 005-04 will append: Section(title: 'EdenHazmatDocViewer — Manifest + MSDS + cert', child: ...).
          // TRD 005-05 will append: Section(title: 'EdenFuelPriceTicker — Real-time price', child: ...).
          // TRD 005-06 will append: Section(title: 'EdenTruckInventoryCard — Per-truck inventory', child: ...).
        ],
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

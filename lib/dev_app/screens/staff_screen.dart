import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 015 — Staff cluster.
///
/// TRD 015-04 bootstraps this file with the Commissions editor section.
/// TRD 015-05 appends EdenTimeClock + EdenTimeCard demos below.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  EdenCommissionRule _salonRule = const EdenCommissionRule(
    id: 'r-salon-1',
    label: 'Senior stylist — 50% flat',
    mode: EdenCommissionMode.percent,
    percent: 0.50,
  );
  EdenCommissionRule _retailRule = const EdenCommissionRule(
    id: 'r-retail-1',
    label: 'Retail associate — \$3 flat per sale',
    mode: EdenCommissionMode.fixed,
    fixedAmount: 3.00,
  );
  EdenCommissionRule _tradesRule = const EdenCommissionRule(
    id: 'r-trades-1',
    label: 'HVAC technician — tiered 5/8/10/12%',
    mode: EdenCommissionMode.tiered,
    tiers: [
      EdenCommissionTier(thresholdAmount: 0.0, rate: 0.05),
      EdenCommissionTier(thresholdAmount: 1000.0, rate: 0.08),
      EdenCommissionTier(thresholdAmount: 2500.0, rate: 0.10),
      EdenCommissionTier(thresholdAmount: 5000.0, rate: 0.12),
    ],
  );
  EdenCommissionRule _chairSplitRule = const EdenCommissionRule(
    id: 'r-salon-2',
    label: 'Salon chair — 80/15/5 split',
    mode: EdenCommissionMode.split,
    splits: [
      EdenCommissionSplitParticipant(
        id: 'sarah',
        displayName: 'Sarah (stylist)',
        sharePercent: 0.80,
      ),
      EdenCommissionSplitParticipant(
        id: 'mia',
        displayName: 'Mia (assistant)',
        sharePercent: 0.15,
      ),
      EdenCommissionSplitParticipant(
        id: 'chair',
        displayName: 'Chair rental',
        sharePercent: 0.05,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff — Objective 015')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'EdenCommissionsEditor — commission-rule editor',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salon — senior stylist 50% flat percent',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                EdenCommissionsEditor(
                  rule: _salonRule,
                  onRuleChanged: (r) => setState(() => _salonRule = r),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Retail — \$3 flat per qualifying sale',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                EdenCommissionsEditor(
                  rule: _retailRule,
                  onRuleChanged: (r) => setState(() => _retailRule = r),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trades — HVAC technician tiered 5/8/10/12% over \$1K/\$2.5K/\$5K',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                EdenCommissionsEditor(
                  rule: _tradesRule,
                  onRuleChanged: (r) => setState(() => _tradesRule = r),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Salon chair — 80% stylist / 15% assistant / 5% chair-rental split',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                EdenCommissionsEditor(
                  rule: _chairSplitRule,
                  onRuleChanged: (r) =>
                      setState(() => _chairSplitRule = r),
                  onAddParticipantTap: () {
                    // Consumer wires the participant picker; the library
                    // calls back. The dev-catalog leaves this as a stub
                    // SnackBar.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Consumer would show participant picker'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // TRD 015-05 appends here ↓ EdenTimeClock + EdenTimeCard
        ],
      ),
    );
  }
}

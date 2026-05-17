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
          Section(
            title: 'EdenTimeClock — kiosk-mode time clock',
            child: _Obj015TimeClockDemo(),
          ),
          Section(
            title: 'EdenTimeCard — manager approval queue',
            child: _Obj015TimeCardDemo(),
          ),
          // TRD 015-05 appends here ↓ EdenTimeClock + EdenTimeCard
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TRD 015-05 — Time clock + time card demos
// ─────────────────────────────────────────────────────────────────────────

class _Obj015TimeClockDemo extends StatefulWidget {
  @override
  State<_Obj015TimeClockDemo> createState() => _Obj015TimeClockDemoState();
}

class _Obj015TimeClockDemoState extends State<_Obj015TimeClockDemo> {
  String _state = 'idle';

  Future<String?> _resolveStaff(String pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (pin == '1234') return 'staff-demo';
    return null;
  }

  EdenTimeClockSession? _session() {
    if (_state == 'clockedIn') {
      return EdenTimeClockSession(
        staffId: 'staff-demo',
        clockInAt: DateTime.now().subtract(const Duration(minutes: 90)),
        isOnBreak: false,
      );
    }
    if (_state == 'onBreak') {
      return EdenTimeClockSession(
        staffId: 'staff-demo',
        clockInAt: DateTime.now().subtract(const Duration(hours: 4)),
        lastBreakStartAt:
            DateTime.now().subtract(const Duration(minutes: 5)),
        breaksAccumulated: const Duration(minutes: 25),
        isOnBreak: true,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final s in ['idle', 'clockedIn', 'onBreak'])
              ChoiceChip(
                label: Text(s),
                selected: _state == s,
                onSelected: (_) => setState(() => _state = s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        EdenTimeClock(
          onResolveStaff: _resolveStaff,
          onAction: (event) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Action: ${event.action.name} '
                  'staffId=${event.staffId}'),
              duration: const Duration(milliseconds: 800),
            ));
            // Mirror common parent behavior: clockIn → state=clockedIn,
            // breakStart → onBreak, etc.
            setState(() {
              switch (event.action) {
                case EdenTimeClockAction.clockIn:
                  _state = 'clockedIn';
                  break;
                case EdenTimeClockAction.clockOut:
                  _state = 'idle';
                  break;
                case EdenTimeClockAction.breakStart:
                  _state = 'onBreak';
                  break;
                case EdenTimeClockAction.breakEnd:
                  _state = 'clockedIn';
                  break;
              }
            });
          },
          activeSession: _session(),
        ),
      ],
    );
  }
}

class _Obj015TimeCardDemo extends StatelessWidget {
  static final _entries = <EdenTimeCardEntry>[
    EdenTimeCardEntry(
      id: 'tc-demo-1',
      staffId: 'staff-1',
      staffName: 'Sarah Vega',
      clockedInAt: DateTime(2026, 5, 16, 9, 0),
      clockedOutAt: DateTime(2026, 5, 16, 17, 30),
      breaksAccumulated: const Duration(minutes: 30),
      dispute: EdenTimeCardDispute.none,
    ),
    EdenTimeCardEntry(
      id: 'tc-demo-2',
      staffId: 'staff-2',
      staffName: 'Marcus Lee',
      clockedInAt: DateTime(2026, 5, 16, 8, 15),
      clockedOutAt: DateTime(2026, 5, 16, 16, 45),
      breaksAccumulated: const Duration(minutes: 45),
      dispute: EdenTimeCardDispute.employeeDisputed,
      note: 'Claims 30-min lunch not 45',
    ),
    EdenTimeCardEntry(
      id: 'tc-demo-3',
      staffId: 'staff-3',
      staffName: 'Jordan Park',
      clockedInAt: DateTime(2026, 5, 17, 9, 0),
      clockedOutAt: null,
      breaksAccumulated: Duration.zero,
      dispute: EdenTimeCardDispute.none,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EdenTimeCard(
      entries: _entries,
      onAction: (event) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Approval: ${event.action.name} entry=${event.entryId}'),
          duration: const Duration(milliseconds: 800),
        ));
      },
    );
  }
}

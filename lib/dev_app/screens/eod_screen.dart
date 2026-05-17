import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 015 — End of Day cluster.
///
/// TRD 015-06 bootstraps this file with the CashDrawerClose section.
/// TRD 015-07 appends EdenShiftClose + EdenXZReport demos below.
class EodScreen extends StatefulWidget {
  const EodScreen({super.key});

  @override
  State<EodScreen> createState() => _EodScreenState();
}

class _EodScreenState extends State<EodScreen> {
  late EdenDrawerSession _session;

  @override
  void initState() {
    super.initState();
    _session = EdenDrawerSession(
      drawerId: 'reg-1',
      openedAt: DateTime(2026, 5, 17, 9, 0),
      startingFloat: 200.00,
      transactions: [
        EdenCashTransaction(
          id: 't-1',
          amount: -150.00,
          reason: 'Cash drop',
          occurredAt: DateTime(2026, 5, 17, 13, 0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('End of Day — Objective 015')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title:
                'EdenCashDrawerClose — drawer count + cash drop + bank deposit',
            child: EdenCashDrawerClose(
              initialSession: _session,
              onSessionChanged: (s) => setState(() => _session = s),
              onSubmit: (result) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Drawer closed. Variance: '
                      '\$${result.finalSession.computedVariance.toStringAsFixed(2)}'),
                  duration: const Duration(milliseconds: 1200),
                ));
              },
              varianceManagerOverrideMessage:
                  'Variance exceeds \$5 — manager approval required',
            ),
          ),
          Section(
            title: 'EdenXZReport — X/Z shift report',
            child: _Obj015XZReportDemo(),
          ),
          Section(
            title: 'EdenShiftClose — composite end-of-shift wizard',
            child: _Obj015ShiftCloseDemo(),
          ),
          // TRD 015-07 appends here ↓ EdenShiftClose + EdenXZReport
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TRD 015-07 — XZReport + ShiftClose demos
// ─────────────────────────────────────────────────────────────────────────

EdenShiftReport _demoShiftReport() {
  return EdenShiftReport(
    reportId: 'z-demo',
    kind: EdenShiftReportKind.zClose,
    shiftLabel: 'Register 1 — May 17 evening',
    shiftStart: DateTime(2026, 5, 17, 14, 0),
    shiftEnd: DateTime(2026, 5, 17, 22, 0),
    grossSales: 4250.00,
    netSales: 4087.50,
    taxCollected: 350.00,
    tipsCollected: 425.00,
    byTender: const [
      EdenSalesByTender(
          tenderLabel: 'Cash', amount: 1225.00, transactionCount: 18),
      EdenSalesByTender(
          tenderLabel: 'Card', amount: 2750.00, transactionCount: 42),
      EdenSalesByTender(
          tenderLabel: 'Gift card', amount: 275.00, transactionCount: 6),
    ],
    byCategory: const [
      EdenSalesByCategory(
          categoryLabel: 'Services', amount: 3200.00, unitCount: 38),
      EdenSalesByCategory(
          categoryLabel: 'Retail', amount: 850.00, unitCount: 24),
    ],
    byEmployee: const [
      EdenSalesByEmployee(
        employeeId: 'e-1',
        employeeName: 'Sarah Vega',
        salesAmount: 2400.00,
        tipAmount: 280.00,
        transactionCount: 28,
      ),
    ],
    refundsVoids: const EdenRefundsVoids(
      refundsAmount: 75.00,
      refundsCount: 2,
      voidsAmount: 87.50,
      voidsCount: 3,
    ),
    cashVariance: -3.00,
  );
}

class _Obj015XZReportDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final z = _demoShiftReport();
    final x = z.copyWith(kind: EdenShiftReportKind.xMid, clearCashVariance: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'X (mid-shift) vs Z (end-of-shift)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenXZReport(report: x),
        const SizedBox(height: 24),
        EdenXZReport(report: z),
        const SizedBox(height: 24),
        const Text(
          'Print-friendly variant (Z)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenXZReport(report: z, printFriendly: true),
      ],
    );
  }
}

class _Obj015ShiftCloseDemo extends StatelessWidget {
  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EdenShiftClose(
                  initialSession: EdenDrawerSession(
                    drawerId: 'reg-1',
                    openedAt: DateTime(2026, 5, 17, 14, 0),
                    startingFloat: 300.00,
                    transactions: const <EdenCashTransaction>[],
                  ),
                  reportSnapshot: _demoShiftReport(),
                  onSessionChanged: (_) {},
                  onCompleted: (result) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Shift closed. Distributed: ${result.distributedTo.map((c) => c.name).join(", ")}'),
                      duration: const Duration(milliseconds: 1200),
                    ));
                  },
                  onDistribute: (report, channel) async {
                    await Future<void>.delayed(
                        const Duration(milliseconds: 300));
                  },
                  allowDeposit: false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap the button to open the composite end-of-shift wizard',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        EdenButton(
          label: 'Open shift close',
          onPressed: () => _openSheet(context),
        ),
      ],
    );
  }
}

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
          // TRD 015-07 appends here ↓ EdenShiftClose + EdenXZReport
        ],
      ),
    );
  }
}

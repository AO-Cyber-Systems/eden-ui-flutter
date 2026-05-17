// Do NOT regenerate via LLM — hand-built fixtures for EdenCashDrawerClose.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenCashDrawerCloseFixtures {
  static final EdenDrawerSession emptyDrawerSession = EdenDrawerSession(
    drawerId: 'reg-1',
    openedAt: DateTime(2026, 5, 17, 9, 0),
    startingFloat: 200.00,
    transactions: const <EdenCashTransaction>[],
  );

  static final EdenDrawerSession sessionWithTransactions = EdenDrawerSession(
    drawerId: 'reg-1',
    openedAt: DateTime(2026, 5, 17, 9, 0),
    startingFloat: 200.00,
    transactions: [
      EdenCashTransaction(
        id: 't-1',
        amount: -150.00,
        reason: 'Cash drop',
        occurredAt: DateTime(2026, 5, 17, 13, 0),
        witnessId: 'mgr-1',
      ),
      EdenCashTransaction(
        id: 't-2',
        amount: -25.00,
        reason: 'Petty cash — office supplies',
        occurredAt: DateTime(2026, 5, 17, 15, 30),
      ),
    ],
  );

  /// 10×\$100 + 10×\$20 + 5×\$5 = \$1225
  static const List<EdenDenominationCount> balancedClose =
      <EdenDenominationCount>[
    EdenDenominationCount(
      denomination: EdenDenomination(value: 100.0, label: r'$100'),
      count: 10,
    ),
    EdenDenominationCount(
      denomination: EdenDenomination(value: 20.0, label: r'$20'),
      count: 10,
    ),
    EdenDenominationCount(
      denomination: EdenDenomination(value: 5.0, label: r'$5'),
      count: 5,
    ),
  ];
}

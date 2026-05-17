// Do NOT regenerate via LLM — hand-built fixtures for EdenXZReport.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenXZReportFixtures {
  static final EdenShiftReport sampleZReport = EdenShiftReport(
    reportId: 'z-2026-05-17-reg1-evening',
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
      EdenSalesByCategory(
          categoryLabel: 'Gift cards', amount: 200.00, unitCount: 4),
    ],
    byEmployee: const [
      EdenSalesByEmployee(
        employeeId: 'e-1',
        employeeName: 'Sarah Vega',
        salesAmount: 2400.00,
        tipAmount: 280.00,
        transactionCount: 28,
      ),
      EdenSalesByEmployee(
        employeeId: 'e-2',
        employeeName: 'Marcus Lee',
        salesAmount: 1850.00,
        tipAmount: 145.00,
        transactionCount: 22,
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

  static final EdenShiftReport sampleXReport = sampleZReport.copyWith(
    kind: EdenShiftReportKind.xMid,
    clearCashVariance: true,
  );

  static final EdenShiftReport emptyEmployeeReport = sampleZReport.copyWith(
    byEmployee: const <EdenSalesByEmployee>[],
  );
}

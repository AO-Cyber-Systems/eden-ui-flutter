// Do NOT regenerate via LLM — hand-built fixtures for EdenShiftClose.

import 'package:eden_ui_flutter/eden_ui.dart';

import 'eden_xz_report_fixtures.dart';

class EdenShiftCloseFixtures {
  static final EdenShiftReport sampleShiftReport =
      EdenXZReportFixtures.sampleZReport;

  static EdenDrawerSession initialSession() {
    return EdenDrawerSession(
      drawerId: 'reg-1',
      openedAt: DateTime(2026, 5, 17, 14, 0),
      startingFloat: 300.00,
      transactions: const <EdenCashTransaction>[],
    );
  }
}

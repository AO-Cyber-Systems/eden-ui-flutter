// Do NOT regenerate via LLM — hand-built fixtures for EdenTimeClock.
//
// Sessions used across the EdenTimeClock test suite + dev catalog
// for obj 015-05.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenTimeClockFixtures {
  static final EdenTimeClockSession clockedInSession =
      EdenTimeClockSession(
    staffId: 'staff-1',
    clockInAt: DateTime(2026, 5, 17, 9, 0),
    breaksAccumulated: Duration.zero,
    isOnBreak: false,
  );

  static final EdenTimeClockSession onBreakSession = EdenTimeClockSession(
    staffId: 'staff-2',
    clockInAt: DateTime(2026, 5, 17, 8, 30),
    lastBreakStartAt: DateTime(2026, 5, 17, 12, 15),
    breaksAccumulated: const Duration(minutes: 15),
    isOnBreak: true,
  );
}

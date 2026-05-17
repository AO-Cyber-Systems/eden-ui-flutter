// Do NOT regenerate via LLM — hand-built fixtures for EdenTimeCard.
//
// Time card entries used across the EdenTimeCard test suite + dev
// catalog for obj 015-05.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenTimeCardFixtures {
  static final List<EdenTimeCardEntry> completedTimeCards = [
    EdenTimeCardEntry(
      id: 'tc-1',
      staffId: 'staff-1',
      staffName: 'Sarah Vega',
      clockedInAt: DateTime(2026, 5, 16, 9, 0),
      clockedOutAt: DateTime(2026, 5, 16, 17, 30),
      breaksAccumulated: const Duration(minutes: 30),
      dispute: EdenTimeCardDispute.none,
    ),
    EdenTimeCardEntry(
      id: 'tc-2',
      staffId: 'staff-2',
      staffName: 'Marcus Lee',
      clockedInAt: DateTime(2026, 5, 16, 8, 15),
      clockedOutAt: DateTime(2026, 5, 16, 16, 45),
      breaksAccumulated: const Duration(minutes: 45),
      dispute: EdenTimeCardDispute.employeeDisputed,
      note: 'Claims 30-min lunch not 45',
    ),
    EdenTimeCardEntry(
      id: 'tc-3',
      staffId: 'staff-3',
      staffName: 'Jordan Park',
      clockedInAt: DateTime(2026, 5, 17, 9, 0),
      clockedOutAt: null,
      breaksAccumulated: Duration.zero,
      dispute: EdenTimeCardDispute.none,
    ),
  ];

  static const List<EdenTimeCardEntry> empty = <EdenTimeCardEntry>[];
}

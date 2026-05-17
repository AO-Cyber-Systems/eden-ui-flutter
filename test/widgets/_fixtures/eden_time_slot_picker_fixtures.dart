// Do NOT regenerate via LLM — hand-built fixtures for EdenTimeSlotPicker.
//
// Powers obj 016-02 tests. Slot data uses deterministic salon-context staff
// names (Aisha / Brendan / Carla) and hand-marked block times (Brendan blocked
// 12-13 for lunch, Carla blocked 15:30). kFixedDay (Thursday 2026-05-21)
// pins date-header output for deterministic tests.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenTimeSlotPickerFixtures {
  EdenTimeSlotPickerFixtures._();

  static final DateTime kFixedDay = DateTime(2026, 5, 21);

  static List<EdenTimeSlotStaff> threeStaff() {
    return const [
      EdenTimeSlotStaff(
          id: 'st-aisha', displayName: 'Aisha', initials: 'AA'),
      EdenTimeSlotStaff(
          id: 'st-brendan', displayName: 'Brendan', initials: 'BB'),
      EdenTimeSlotStaff(
          id: 'st-carla', displayName: 'Carla', initials: 'CC'),
    ];
  }

  static List<EdenTimeSlotStaff> fiveStaff() {
    return const [
      EdenTimeSlotStaff(
          id: 'st-aisha', displayName: 'Aisha', initials: 'AA'),
      EdenTimeSlotStaff(
          id: 'st-brendan', displayName: 'Brendan', initials: 'BB'),
      EdenTimeSlotStaff(
          id: 'st-carla', displayName: 'Carla', initials: 'CC'),
      EdenTimeSlotStaff(
          id: 'st-david', displayName: 'David', initials: 'DD'),
      EdenTimeSlotStaff(
          id: 'st-elena', displayName: 'Elena', initials: 'EE'),
    ];
  }

  /// 3 staff × 9 hours (9-18) × 4 slots/hour = 108 slots.
  /// Brendan blocked 12:00-13:00 (lunch); Carla blocked 15:30 (break).
  static List<EdenTimeSlot> dayOf3Staff() {
    final out = <EdenTimeSlot>[];
    const staffIds = ['st-aisha', 'st-brendan', 'st-carla'];
    for (final staff in staffIds) {
      for (var h = 9; h < 18; h++) {
        for (var m = 0; m < 60; m += 15) {
          final blocked = (staff == 'st-brendan' && h == 12) ||
              (staff == 'st-carla' && h == 15 && m == 30);
          out.add(EdenTimeSlot(
            id: '$staff-${h.toString().padLeft(2, '0')}-${m.toString().padLeft(2, '0')}',
            staffId: staff,
            startTime: DateTime(kFixedDay.year, kFixedDay.month,
                kFixedDay.day, h, m),
            available: !blocked,
            blockedReason: blocked ? 'Booked' : null,
          ));
        }
      }
    }
    return out;
  }

  static List<EdenTimeSlot> emptyDay() => const [];

  /// Composes EdenServiceCatalogEntry from 016-01 with 3 capable staff
  /// (Aisha + Brendan + Carla) for service-filter tests.
  static EdenServiceCatalogEntry threeCapableStaffService() {
    return const EdenServiceCatalogEntry(
      id: 'srv-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [
        EdenServiceStaff(
            id: 'st-aisha', displayName: 'Aisha A.', initials: 'AA'),
        EdenServiceStaff(
            id: 'st-brendan', displayName: 'Brendan B.', initials: 'BB'),
        EdenServiceStaff(
            id: 'st-carla', displayName: 'Carla C.', initials: 'CC'),
      ],
    );
  }
}

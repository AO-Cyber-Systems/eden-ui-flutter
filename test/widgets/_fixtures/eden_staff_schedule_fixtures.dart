// Do NOT regenerate via LLM — hand-built fixtures for EdenStaffSchedule + EdenStaffCapabilityMatrix.
//
// Powers obj 016-06 tests. Aisha's weekly template = Mon-Sat 9-18 with 12-13
// lunch break, Sun off, Wed off. Brendan part-time. Capability matrix is a
// realistic 5-staff × 4-service salon slice (Aisha + Elena master all 4;
// David facials only; etc.).

import 'package:flutter/material.dart';
import 'package:eden_ui_flutter/eden_ui.dart';

class EdenStaffScheduleFixtures {
  EdenStaffScheduleFixtures._();

  static List<EdenStaffWeeklyShift> aishaFullWeek() {
    return const [
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.monday,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0),
        breaks: [
          EdenStaffBreak(
            startTime: TimeOfDay(hour: 12, minute: 0),
            endTime: TimeOfDay(hour: 13, minute: 0),
            label: 'Lunch',
          ),
        ],
      ),
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.tuesday,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0),
      ),
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.wednesday,
        working: false,
      ),
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.thursday,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0),
      ),
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.friday,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0),
      ),
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.saturday,
        startTime: TimeOfDay(hour: 10, minute: 0),
        endTime: TimeOfDay(hour: 16, minute: 0),
      ),
      EdenStaffWeeklyShift(
        staffId: 'st-aisha',
        weekday: EdenWeekday.sunday,
        working: false,
      ),
    ];
  }

  static EdenStaffWeeklyShift mondayShift() {
    return const EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.monday,
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 0),
    );
  }
}

class EdenStaffCapabilityMatrixFixtures {
  EdenStaffCapabilityMatrixFixtures._();

  static List<EdenStaffCapabilityRow> fiveStaff() {
    return const [
      EdenStaffCapabilityRow(
          id: 'st-aisha', displayName: 'Aisha A.', initials: 'AA'),
      EdenStaffCapabilityRow(
          id: 'st-brendan', displayName: 'Brendan B.', initials: 'BB'),
      EdenStaffCapabilityRow(
          id: 'st-carla', displayName: 'Carla C.', initials: 'CC'),
      EdenStaffCapabilityRow(
          id: 'st-david', displayName: 'David D.', initials: 'DD'),
      EdenStaffCapabilityRow(
          id: 'st-elena', displayName: 'Elena E.', initials: 'EE'),
    ];
  }

  static List<EdenServiceCatalogEntry> fourServices() {
    return const [
      EdenServiceCatalogEntry(
        id: 'srv-haircut',
        name: 'Haircut',
        durationMinutes: 45,
        priceCents: 8500,
      ),
      EdenServiceCatalogEntry(
        id: 'srv-color',
        name: 'Color',
        durationMinutes: 150,
        priceCents: 18500,
      ),
      EdenServiceCatalogEntry(
        id: 'srv-balayage',
        name: 'Balayage',
        durationMinutes: 195,
        priceCents: 28500,
      ),
      EdenServiceCatalogEntry(
        id: 'srv-facial',
        name: 'Facial',
        durationMinutes: 30,
        priceCents: 5500,
      ),
    ];
  }

  static List<EdenStaffCapability> realisticCapabilities() {
    return const [
      EdenStaffCapability(
          staffId: 'st-aisha', serviceId: 'srv-haircut', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-aisha', serviceId: 'srv-color', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-aisha', serviceId: 'srv-balayage', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-brendan', serviceId: 'srv-haircut', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-carla', serviceId: 'srv-haircut', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-carla', serviceId: 'srv-color', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-carla', serviceId: 'srv-facial', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-david', serviceId: 'srv-facial', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-elena', serviceId: 'srv-haircut', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-elena', serviceId: 'srv-color', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-elena', serviceId: 'srv-balayage', canPerform: true),
      EdenStaffCapability(
          staffId: 'st-elena', serviceId: 'srv-facial', canPerform: true),
    ];
  }
}

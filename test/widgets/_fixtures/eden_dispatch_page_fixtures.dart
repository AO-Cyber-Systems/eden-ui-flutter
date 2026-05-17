// Do NOT regenerate via LLM — hand-built fixtures for EdenDispatchPage.
//
// Cross-vertical dispatch scenarios: trades crew dispatch (4 crews × 12 jobs)
// and fuel multi-truck routing (3 trucks × 8 deliveries). Customer names,
// addresses, and work types are realistic but minimal.

import 'package:eden_ui_flutter/src/widgets/eden_dispatch_page.dart';
import 'package:eden_ui_flutter/src/widgets/scheduler/scheduler_controller.dart';
import 'package:eden_ui_flutter/src/widgets/scheduler/scheduler_models.dart';
import 'package:flutter/material.dart';

class DispatchFixtures {
  DispatchFixtures._();

  /// Trades dispatch: 4 crews + 12 work items.
  static EdenDispatchData tradesDispatch() {
    final controller = EdenSchedulerController(
      initialView: EdenSchedulerView.swimlane,
      initialDate: DateTime(2026, 5, 18),
    );
    final crews = const [
      EdenSchedulerResource(
        id: 'crew-a',
        name: 'Crew A — HVAC',
        crew: ['Bob T.', 'Sue M.'],
        color: Color(0xFFE0F2FE),
      ),
      EdenSchedulerResource(
        id: 'crew-b',
        name: 'Crew B — Plumbing',
        crew: ['Mike K.'],
        color: Color(0xFFFEF3C7),
      ),
      EdenSchedulerResource(
        id: 'crew-c',
        name: 'Crew C — Electrical',
        crew: ['Sarah W.', 'Tom L.'],
        color: Color(0xFFFEE2E2),
      ),
      EdenSchedulerResource(
        id: 'crew-d',
        name: 'Crew D — Generic',
        crew: ['Joe R.'],
        color: Color(0xFFE0E7FF),
      ),
    ];
    final events = [
      EdenSchedulerEvent(
        id: 'evt-1',
        title: 'AC tune-up — 245 Oak',
        start: DateTime(2026, 5, 18, 8),
        end: DateTime(2026, 5, 18, 10),
        resourceIds: const ['crew-a'],
      ),
      EdenSchedulerEvent(
        id: 'evt-2',
        title: 'Toilet rebuild — 12 Pine',
        start: DateTime(2026, 5, 18, 9),
        end: DateTime(2026, 5, 18, 11),
        resourceIds: const ['crew-b'],
      ),
    ];
    return EdenDispatchData(
      scheduler: EdenDispatchSchedulerSlot(
        controller: controller,
        events: events,
        crewResources: crews,
      ),
      queue: EdenDispatchWorkQueue(items: _tradesWorkItems()),
      mapSlot: EdenDispatchMapSlot(
        builder: (ctx, data) => Container(
          color: const Color(0xFFE0F2FE),
          alignment: Alignment.center,
          child: const Text('[map placeholder]'),
        ),
      ),
    );
  }

  /// Fuel dispatch: 3 trucks + 8 deliveries + AI slot wired.
  static EdenDispatchData fuelDispatch() {
    final controller = EdenSchedulerController(
      initialView: EdenSchedulerView.swimlane,
      initialDate: DateTime(2026, 5, 18),
    );
    final trucks = const [
      EdenSchedulerResource(
        id: 'truck-12',
        name: 'Truck-12 (4,000 gal diesel)',
        color: Color(0xFFE0F2FE),
      ),
      EdenSchedulerResource(
        id: 'truck-14',
        name: 'Truck-14 (3,000 gal propane)',
        color: Color(0xFFFEF3C7),
      ),
      EdenSchedulerResource(
        id: 'truck-22',
        name: 'Truck-22 (4,000 gal heating oil)',
        color: Color(0xFFFEE2E2),
      ),
    ];
    return EdenDispatchData(
      scheduler: EdenDispatchSchedulerSlot(
        controller: controller,
        events: const [],
        crewResources: trucks,
      ),
      queue: EdenDispatchWorkQueue(items: _fuelDeliveries()),
      mapSlot: EdenDispatchMapSlot(
        builder: (ctx, data) => Container(
          color: const Color(0xFFE0F2FE),
          alignment: Alignment.center,
          child: const Text('[fuel map placeholder]'),
        ),
      ),
      aiSlot: EdenDispatchAiSlot(
        builder: (ctx, data) => Container(
          color: const Color(0xFFF3E8FF),
          alignment: Alignment.center,
          child: const Text('[AI route optimizer]'),
        ),
      ),
    );
  }

  /// Empty dispatch — no crews, no queue, no slots.
  static EdenDispatchData emptyDispatch() {
    final controller = EdenSchedulerController(
      initialDate: DateTime(2026, 5, 18),
    );
    return EdenDispatchData(
      scheduler: EdenDispatchSchedulerSlot(
        controller: controller,
        events: const [],
        crewResources: const [],
      ),
      queue: const EdenDispatchWorkQueue(items: []),
    );
  }

  static List<EdenDispatchWorkItem> _tradesWorkItems() => const [
        EdenDispatchWorkItem(
          id: 'job-1',
          title: 'AC not cooling',
          customerName: 'Patel residence',
          address: '124 Maple St',
          urgency: 'high',
          estimatedDuration: Duration(hours: 2),
          requiredSkills: ['hvac'],
        ),
        EdenDispatchWorkItem(
          id: 'job-2',
          title: 'Furnace inspection',
          customerName: 'Smith residence',
          address: '8 Birch Ln',
          urgency: 'low',
          estimatedDuration: Duration(hours: 1),
          requiredSkills: ['hvac'],
        ),
        EdenDispatchWorkItem(
          id: 'job-3',
          title: 'Leaky kitchen faucet',
          customerName: 'Lee residence',
          address: '212 Cedar Dr',
          urgency: 'medium',
          estimatedDuration: Duration(hours: 1, minutes: 30),
          requiredSkills: ['plumbing'],
        ),
        EdenDispatchWorkItem(
          id: 'job-4',
          title: 'Burst pipe — basement',
          customerName: 'Garcia residence',
          address: '7 Elm Ct',
          urgency: 'critical',
          estimatedDuration: Duration(hours: 3),
          requiredSkills: ['plumbing'],
        ),
        EdenDispatchWorkItem(
          id: 'job-5',
          title: 'Panel upgrade to 200A',
          customerName: 'Chen residence',
          address: '301 Willow Ave',
          urgency: 'medium',
          estimatedDuration: Duration(hours: 4),
          requiredSkills: ['electrical'],
        ),
        EdenDispatchWorkItem(
          id: 'job-6',
          title: 'Outdoor outlet install',
          customerName: 'Brown residence',
          address: '15 Spruce Way',
          urgency: 'low',
          estimatedDuration: Duration(hours: 2),
          requiredSkills: ['electrical'],
        ),
        EdenDispatchWorkItem(
          id: 'job-7',
          title: 'Annual maintenance check',
          customerName: 'Wilson residence',
          address: '4 Aspen Ct',
          urgency: 'low',
          estimatedDuration: Duration(hours: 1),
        ),
        EdenDispatchWorkItem(
          id: 'job-8',
          title: 'Replace water heater',
          customerName: 'Adams residence',
          address: '67 Beech Rd',
          urgency: 'high',
          estimatedDuration: Duration(hours: 3),
          requiredSkills: ['plumbing'],
        ),
        EdenDispatchWorkItem(
          id: 'job-9',
          title: 'Thermostat install',
          customerName: 'Roberts residence',
          address: '90 Pine Crest',
          urgency: 'low',
          estimatedDuration: Duration(minutes: 45),
          requiredSkills: ['hvac'],
        ),
        EdenDispatchWorkItem(
          id: 'job-10',
          title: 'Compressor diagnosis',
          customerName: 'King residence',
          address: '21 Birchwood Ln',
          urgency: 'high',
          estimatedDuration: Duration(hours: 2),
          requiredSkills: ['hvac'],
        ),
        EdenDispatchWorkItem(
          id: 'job-11',
          title: 'GFCI replacement',
          customerName: 'Patel residence',
          address: '124 Maple St',
          urgency: 'medium',
          estimatedDuration: Duration(hours: 1),
          requiredSkills: ['electrical'],
        ),
        EdenDispatchWorkItem(
          id: 'job-12',
          title: 'PM checkup — multi-system',
          customerName: 'Thompson residence',
          address: '5 Magnolia Way',
          urgency: 'low',
          estimatedDuration: Duration(hours: 2),
        ),
      ];

  static List<EdenDispatchWorkItem> _fuelDeliveries() => const [
        EdenDispatchWorkItem(
          id: 'del-1',
          title: 'Will-call: 200 gal propane',
          customerName: 'Hansen Farm',
          address: '4421 County Rd 12',
          urgency: 'high',
          estimatedDuration: Duration(minutes: 45),
          requiredSkills: ['propane'],
        ),
        EdenDispatchWorkItem(
          id: 'del-2',
          title: 'Auto-fill: 500 gal diesel',
          customerName: 'Roberts Trucking',
          address: '12 Industrial Blvd',
          urgency: 'medium',
          estimatedDuration: Duration(hours: 1),
          requiredSkills: ['diesel'],
        ),
        EdenDispatchWorkItem(
          id: 'del-3',
          title: 'Will-call: 300 gal heating oil',
          customerName: 'Miller residence',
          address: '78 Oak Ridge',
          urgency: 'high',
          estimatedDuration: Duration(minutes: 50),
          requiredSkills: ['heating oil'],
        ),
        EdenDispatchWorkItem(
          id: 'del-4',
          title: 'Route stop: 100 gal propane',
          customerName: 'Davis residence',
          address: '102 Highland',
          urgency: 'low',
          estimatedDuration: Duration(minutes: 30),
          requiredSkills: ['propane'],
        ),
        EdenDispatchWorkItem(
          id: 'del-5',
          title: 'Will-call: 400 gal heating oil',
          customerName: 'Wright residence',
          address: '34 Lakeshore Dr',
          urgency: 'medium',
          estimatedDuration: Duration(hours: 1),
          requiredSkills: ['heating oil'],
        ),
        EdenDispatchWorkItem(
          id: 'del-6',
          title: 'Auto-fill: 600 gal diesel',
          customerName: 'Anderson Farms',
          address: '8800 Rural Rt 4',
          urgency: 'low',
          estimatedDuration: Duration(hours: 1, minutes: 15),
          requiredSkills: ['diesel'],
        ),
        EdenDispatchWorkItem(
          id: 'del-7',
          title: 'Will-call: 150 gal propane',
          customerName: 'Carter residence',
          address: '21 Sycamore',
          urgency: 'medium',
          estimatedDuration: Duration(minutes: 40),
          requiredSkills: ['propane'],
        ),
        EdenDispatchWorkItem(
          id: 'del-8',
          title: 'Route stop: 250 gal heating oil',
          customerName: 'Lopez residence',
          address: '56 Forest Glen',
          urgency: 'low',
          estimatedDuration: Duration(minutes: 35),
          requiredSkills: ['heating oil'],
        ),
      ];
}

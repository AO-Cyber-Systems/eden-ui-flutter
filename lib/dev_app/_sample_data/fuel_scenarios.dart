// lib/dev_app/_sample_data/fuel_scenarios.dart
//
// Hand-built sample data for the dev catalog. Do NOT regenerate via LLM —
// mutate in-place when downstream verticals shift. Real-world data has
// irregular distributions; uniform patterns (Customer 1/2/3, identical
// timestamps) are a smell that this file was AI-touched. Catch and fix.
//
// Catalog "today" anchor: DateTime(2026, 5, 16). All relative-time fixtures
// compute from this anchor for snapshot stability.

import 'package:flutter/material.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

/// Tank reading fixture — fed into EdenStockLevelIndicator demos.
class DemoTankReading {
  const DemoTankReading({
    required this.terminalName,
    required this.percentage,
    required this.gallons,
    required this.capacityGallons,
    this.isBelowReorder = false,
  });

  final String terminalName;

  /// 0.0 .. 1.0 (use multiplication by 100 in displays).
  final double percentage;
  final int gallons;
  final int capacityGallons;
  final bool isBelowReorder;
}

/// Network state sample — fuel-truck radios drop in/out of coverage often.
/// Drives EdenNetworkStatusBar demos.
class DemoNetworkStateSample {
  const DemoNetworkStateSample({
    required this.label,
    required this.state,
    this.detail,
  });

  final String label;

  /// 'online' | 'reconnecting' | 'offline' | 'syncing' — free-form to keep
  /// fixture forward-compat with future state extensions.
  final String state;
  final String? detail;
}

/// Per-delivery cost breakdown for EdenCostSummaryCard demos.
class FuelDeliveryCostBreakdown {
  const FuelDeliveryCostBreakdown({
    required this.fuel,
    required this.hauling,
    required this.surcharge,
    required this.tax,
    required this.total,
  });

  final String fuel;
  final String hauling;
  final String surcharge;
  final String tax;
  final String total;
}

/// Fuel vertical (truck deliveries / tank levels / dispatching).
///
/// Driver roster: Manny Tovar (lead), Kris O'Hara, Tomás Aguilera.
class FuelScenarios {
  // ---------------------------------------------------------------------------
  // REALISTIC FIXTURES
  // ---------------------------------------------------------------------------

  /// Week of deliveries. Multi-stop routes, varying truck assignments.
  static List<EdenSchedulerEvent> get weekDeliveries {
    final monday = DateTime(2026, 5, 11);
    return <EdenSchedulerEvent>[
      EdenSchedulerEvent(
        id: 'fu-evt-001',
        title: 'Route A · 4 stops · Diesel #2',
        description: 'Northpoint (1,800g), Holman (400g), Crete (1,200g), '
            'Sauk Trail Logistics (900g).',
        start: monday.add(const Duration(hours: 5, minutes: 30)),
        end: monday.add(const Duration(hours: 11, minutes: 30)),
        assignee: 'Manny Tovar',
        color: const Color(0xFF15803D),
        status: 'in_progress',
        type: 'delivery',
        resourceIds: <String>['truck-T7'],
        location: const EdenSchedulerLocation(
          name: 'Terminal 4 → Chicago South',
          latitude: 41.8497,
          longitude: -87.7449,
        ),
        readiness: EdenSchedulerEventReadiness.ready,
      ),
      EdenSchedulerEvent(
        id: 'fu-evt-002',
        title: 'Tank truck #T7 — maintenance',
        description: 'DOT inspection + brake pad replacement.',
        start: monday.add(const Duration(days: 1, hours: 7)),
        end: monday.add(const Duration(days: 1, hours: 13)),
        assignee: 'Shop',
        color: const Color(0xFF6B7280),
        status: 'scheduled',
        type: 'maintenance',
        resourceIds: <String>['truck-T7'],
      ),
      EdenSchedulerEvent(
        id: 'fu-evt-003',
        title: 'Route C · 2 stops · Unleaded 87',
        start: monday.add(const Duration(days: 2, hours: 6)),
        end: monday.add(const Duration(days: 2, hours: 9, minutes: 15)),
        assignee: "Kris O'Hara",
        color: const Color(0xFFEAB308),
        status: 'scheduled',
        type: 'delivery',
        resourceIds: <String>['truck-T3'],
      ),
      EdenSchedulerEvent(
        id: 'fu-evt-004',
        title: 'Route B · 5 stops · Diesel #2',
        start: monday.add(const Duration(days: 2, hours: 5, minutes: 45)),
        end: monday.add(const Duration(days: 2, hours: 14)),
        assignee: 'Tomás Aguilera',
        color: const Color(0xFF15803D),
        status: 'scheduled',
        type: 'delivery',
        resourceIds: <String>['truck-T9'],
      ),
      EdenSchedulerEvent(
        id: 'fu-evt-005',
        title: 'Customer support escort',
        description:
            'Northpoint Diesel — flow meter inspection. Manny to ride along.',
        start: monday.add(const Duration(days: 3, hours: 10)),
        end: monday.add(const Duration(days: 3, hours: 11, minutes: 30)),
        assignee: 'Manny Tovar',
        color: const Color(0xFF6B7280),
        type: 'admin',
      ),
      EdenSchedulerEvent(
        id: 'fu-evt-006',
        title: 'Emergency callout — tank low',
        description: 'Crete distribution center — tank at 11%; needs 1,500g.',
        start: monday.add(const Duration(days: 3, hours: 14, minutes: 30)),
        end: monday.add(const Duration(days: 3, hours: 17)),
        assignee: "Kris O'Hara",
        color: const Color(0xFFDC2626),
        status: 'in_progress',
        type: 'emergency',
        dispatchIssue: 'Customer ran dry — service penalty risk',
        readiness: EdenSchedulerEventReadiness.urgent,
      ),
      EdenSchedulerEvent(
        id: 'fu-evt-007',
        title: 'Route A · 4 stops · mixed',
        start: monday.add(const Duration(days: 4, hours: 5, minutes: 30)),
        end: monday.add(const Duration(days: 4, hours: 12)),
        assignee: 'Manny Tovar',
        color: const Color(0xFF15803D),
        type: 'delivery',
        resourceIds: <String>['truck-T7'],
      ),
    ];
  }

  static const EdenInsightContent tankLowStockInsight = EdenInsightContent(
    id: 'fu-insight-tanklow',
    type: EdenInsightType.alert,
    severity: EdenInsightSeverity.critical,
    title: 'Terminal 4 · Tank 3 (Unleaded 87) at 22%',
    subtitle: 'Reorder threshold is 25%. Refill scheduled Thu @ 6am.',
  );

  static const EdenInsightContent fuelConsumptionInsight = EdenInsightContent(
    id: 'fu-insight-consumption',
    type: EdenInsightType.chart,
    chartType: EdenChartType.bar,
    title: 'Gallons delivered · this week (by region)',
    data: <String, dynamic>{
      'series': <int>[6420, 4180, 8090, 3110, 5670],
      'labels': <String>[
        'Chi South',
        'Chi North',
        'Joliet',
        'Aurora',
        'Naperville',
      ],
    },
  );

  /// 5 tank readings spanning green / amber / red — used in
  /// EdenStockLevelIndicator demos.
  static const List<DemoTankReading> tankLevels = <DemoTankReading>[
    DemoTankReading(
      terminalName: 'Terminal 4 · Tank 7 · Diesel #2',
      percentage: 0.78,
      gallons: 18750,
      capacityGallons: 24000,
    ),
    DemoTankReading(
      terminalName: 'Terminal 4 · Tank 3 · Unleaded 87',
      percentage: 0.22,
      gallons: 5280,
      capacityGallons: 24000,
      isBelowReorder: true,
    ),
    DemoTankReading(
      terminalName: 'Terminal 4 · Tank 5 · Unleaded 91',
      percentage: 0.46,
      gallons: 11040,
      capacityGallons: 24000,
    ),
    DemoTankReading(
      terminalName: 'Outpost Tank · Sauk Trail (Diesel)',
      percentage: 0.11,
      gallons: 660,
      capacityGallons: 6000,
      isBelowReorder: true,
    ),
    DemoTankReading(
      terminalName: 'Outpost Tank · Crete (Diesel)',
      percentage: 0.93,
      gallons: 5580,
      capacityGallons: 6000,
    ),
  ];

  static const FuelDeliveryCostBreakdown deliveryCostBreakdown =
      FuelDeliveryCostBreakdown(
    fuel: r'$5,679.20',
    hauling: r'$420.00',
    surcharge: r'$87.50',
    tax: r'$612.45',
    total: r'$6,799.15',
  );

  /// Realistic network-state samples — driver radios go in/out of coverage.
  static const List<DemoNetworkStateSample> networkSamples =
      <DemoNetworkStateSample>[
    DemoNetworkStateSample(
      label: 'Truck T7 · Manny',
      state: 'online',
      detail: 'Terminal yard · strong signal',
    ),
    DemoNetworkStateSample(
      label: 'Truck T3 · Kris',
      state: 'reconnecting',
      detail: 'Approaching Joliet — last sync 2m ago',
    ),
    DemoNetworkStateSample(
      label: 'Truck T9 · Tomás',
      state: 'offline',
      detail: 'In tunnel · queued: 3 deliveries',
    ),
    DemoNetworkStateSample(
      label: 'Dispatch console',
      state: 'online',
    ),
  ];

  static const List<EdenActivityFeedItemData> activityFeed =
      <EdenActivityFeedItemData>[
    EdenActivityFeedItemData(
      actorName: 'Manny Tovar',
      actorInitials: 'MT',
      action: 'completed delivery to',
      entityName: 'Northpoint Diesel (1,800g)',
      timeAgo: '6m ago',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Dispatch',
      actorInitials: 'DS',
      action: 'dispatched emergency:',
      entityName: 'Crete tank at 11%',
      timeAgo: '23m ago',
      variant: EdenActivityVariant.danger,
    ),
    EdenActivityFeedItemData(
      actorName: "Kris O'Hara",
      actorInitials: 'KO',
      action: 'logged tank reading at',
      entityName: 'Terminal 4 / Tank 3 (22%)',
      timeAgo: '1h ago',
      variant: EdenActivityVariant.warning,
    ),
    EdenActivityFeedItemData(
      actorName: 'Tomás Aguilera',
      actorInitials: 'TA',
      action: 'began route B from',
      entityName: 'Terminal 4',
      timeAgo: '2h ago',
      variant: EdenActivityVariant.info,
    ),
  ];

  static List<EdenSchedulerEvent> get overflowDay {
    final day = DateTime(2026, 5, 19, 5, 0);
    final drivers = <String>['Manny Tovar', "Kris O'Hara", 'Tomás Aguilera'];
    final colors = <Color>[
      const Color(0xFF15803D),
      const Color(0xFFEAB308),
      const Color(0xFFDC2626),
    ];
    return List<EdenSchedulerEvent>.generate(10, (i) {
      final start = day.add(Duration(minutes: i * 45));
      return EdenSchedulerEvent(
        id: 'fu-overflow-${i.toString().padLeft(3, '0')}',
        title: i.isEven ? 'Route A delivery' : 'Customer callback',
        start: start,
        end: start.add(Duration(minutes: 60 + (i * 11) % 60)),
        assignee: drivers[i % drivers.length],
        color: colors[i % colors.length],
        type: 'delivery',
      );
    });
  }
}

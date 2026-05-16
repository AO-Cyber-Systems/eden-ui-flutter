// lib/dev_app/_sample_data/trades_scenarios.dart
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

import 'cross_cutting.dart';

/// Job-cost breakdown used by EdenCostSummaryCard in catalog demos.
class TradesJobCostBreakdown {
  const TradesJobCostBreakdown({
    required this.labor,
    required this.material,
    required this.equipment,
    required this.total,
    this.subContractors,
    this.permits,
  });

  final String labor;
  final String material;
  final String equipment;
  final String total;
  final String? subContractors;
  final String? permits;
}

/// Trades vertical (HVAC / electrical / plumbing) fixtures.
class TradesScenarios {
  // ---------------------------------------------------------------------------
  // REALISTIC FIXTURES
  // ---------------------------------------------------------------------------

  /// 8 events for the week of catalogToday (Mon 2026-05-11..Sun 2026-05-17).
  /// Real distribution: clustered morning installs, scattered afternoon
  /// service calls, one overrunning callback, one all-day project.
  static List<EdenSchedulerEvent> get weekEvents {
    final monday = DateTime(2026, 5, 11);
    return <EdenSchedulerEvent>[
      EdenSchedulerEvent(
        id: 'tr-evt-001',
        title: 'HVAC Install — Whitfield',
        description:
            '2-ton split unit. Bring lift kit. Marcus will be on-site.',
        start: monday.add(const Duration(hours: 7, minutes: 30)),
        end: monday.add(const Duration(hours: 12)),
        assignee: 'Alice Chen',
        color: const Color(0xFF1D4ED8),
        status: 'scheduled',
        type: 'install',
        resourceIds: <String>['truck-47'],
        location: const EdenSchedulerLocation(
          name: 'Whitfield residence',
          address: '1487 Briar Hollow Ln, Marietta, GA',
          latitude: 33.9526,
          longitude: -84.5499,
        ),
        readiness: EdenSchedulerEventReadiness.ready,
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-002',
        title: 'Furnace tune-up',
        start: monday.add(const Duration(days: 1, hours: 9)),
        end: monday.add(const Duration(days: 1, hours: 10, minutes: 30)),
        assignee: 'Bob Kowalski',
        color: const Color(0xFF0F766E),
        status: 'scheduled',
        type: 'maintenance',
        resourceIds: <String>['truck-12'],
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-003',
        title: 'Panel upgrade — Bartholomew',
        description: '200A service entrance. Parts pending: needs 12/3 roll.',
        start: monday.add(const Duration(days: 1, hours: 13)),
        end: monday.add(const Duration(days: 1, hours: 17, minutes: 30)),
        assignee: 'Bob Kowalski',
        color: const Color(0xFFB45309),
        status: 'pending_review',
        type: 'install',
        resourceIds: <String>['truck-12'],
        dispatchIssue: 'Parts not yet on truck',
        readiness: EdenSchedulerEventReadiness.warning,
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-004',
        title: 'AC service call',
        description: 'No cool air on second floor. Diagnostic.',
        start: monday.add(const Duration(days: 2, hours: 8, minutes: 15)),
        end: monday.add(const Duration(days: 2, hours: 10)),
        assignee: 'Alice Chen',
        color: const Color(0xFF1D4ED8),
        status: 'in_progress',
        type: 'service',
        resourceIds: <String>['truck-47'],
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-005',
        title: 'Permit pickup (city of Marietta)',
        start: monday.add(const Duration(days: 2, hours: 11, minutes: 30)),
        end: monday.add(const Duration(days: 2, hours: 12, minutes: 30)),
        assignee: 'Alice Chen',
        color: const Color(0xFF6B7280),
        status: 'scheduled',
        type: 'admin',
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-006',
        title: 'Callback — leaky condensate line',
        description: 'Customer noted drip overnight. Was on Mondayʼs install.',
        start: monday.add(const Duration(days: 3, hours: 14, minutes: 45)),
        end: monday.add(const Duration(days: 3, hours: 16, minutes: 30)),
        assignee: 'Alice Chen',
        color: const Color(0xFFDC2626),
        status: 'in_progress',
        type: 'callback',
        resourceIds: <String>['truck-47'],
        dispatchIssue: 'Customer reports water damage',
        readiness: EdenSchedulerEventReadiness.urgent,
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-007',
        title: 'New construction rough-in (3-day project)',
        description: 'Multi-day. Day 1 of 3.',
        start: monday.add(const Duration(days: 4, hours: 7)),
        end: monday.add(const Duration(days: 4, hours: 17)),
        assignee: 'Alice Chen',
        color: const Color(0xFF7E22CE),
        status: 'scheduled',
        type: 'project',
        resourceIds: <String>['truck-47', 'truck-12'],
      ),
      EdenSchedulerEvent(
        id: 'tr-evt-008',
        title: 'On-call rotation (weekend)',
        start: monday.add(const Duration(days: 5)),
        end: monday.add(const Duration(days: 7)),
        assignee: 'Bob Kowalski',
        color: const Color(0xFFF59E0B),
        allDay: true,
        type: 'on_call',
      ),
    ];
  }

  /// 54 events across the catalog week + the prior/next weeks, for the
  /// scheduler 50+-event stress demo (Wave 5). Hand-spread across days &
  /// hours so the layout engine has real conflict + non-conflict regions to
  /// resolve.
  static List<EdenSchedulerEvent> get monthEvents {
    final base = DateTime(2026, 5, 4); // 2 weeks before catalog today
    final out = <EdenSchedulerEvent>[];
    final techs = <String>['Alice Chen', 'Bob Kowalski', 'Carlos Mendez'];
    final colors = <Color>[
      const Color(0xFF1D4ED8),
      const Color(0xFF0F766E),
      const Color(0xFFB45309),
      const Color(0xFF7E22CE),
      const Color(0xFFDC2626),
    ];
    // Hand-curated job titles — believable distribution
    final titles = <String>[
      'AC tune-up',
      'Heat pump install',
      'Furnace inspection',
      'Duct cleaning',
      'Panel upgrade',
      'Outlet replacement',
      'Ceiling fan install',
      'EV charger install',
      'Plumbing leak repair',
      'Water heater swap',
      'Drain snake call',
      'Garbage disposal swap',
      'Thermostat install',
      'Mini-split balance',
      'Refrigerant top-off',
      'Capacitor swap',
      'Blower motor replace',
      'Permit pickup',
      'Estimate visit',
      'Warranty callback',
    ];

    // 27 days, ~2 events/day on average (range 0-4) → ~54 events
    final perDay = <int>[
      2, 3, 1, 2, 4, 0, 1, // week -2 mon-sun
      3, 2, 4, 2, 3, 1, 0, // week -1 mon-sun
      3, 2, 4, 3, 2, 0, 1, // week 0 mon-sun (catalog week)
      2, 3, 2, 2, 1, 0,    // week +1 mon-sat
    ];
    var idCounter = 100;
    for (var dayIdx = 0; dayIdx < perDay.length; dayIdx++) {
      final n = perDay[dayIdx];
      for (var k = 0; k < n; k++) {
        final hour = 7 + (k * 2) + (dayIdx % 2);
        final duration = (60 + ((dayIdx + k) * 17) % 90);
        final dayStart = base.add(Duration(days: dayIdx));
        final start = dayStart.add(Duration(hours: hour));
        final end = start.add(Duration(minutes: duration));
        out.add(EdenSchedulerEvent(
          id: 'tr-stress-${idCounter++}',
          title: titles[idCounter % titles.length],
          start: start,
          end: end,
          assignee: techs[idCounter % techs.length],
          color: colors[idCounter % colors.length],
          status: 'scheduled',
          type: 'service',
        ));
      }
    }
    return out;
  }

  /// EdenInsightCard fixtures (3 different insight types for cross-layout
  /// coverage on the AI surface).
  static const EdenInsightContent revenueInsight = EdenInsightContent(
    id: 'tr-insight-revenue',
    type: EdenInsightType.metric,
    title: 'Revenue · this month',
    subtitle: 'Atlanta metro · 47 jobs closed',
    data: <String, dynamic>{
      'value': r'$48,290',
      'trend': 'up',
      'change': '+8.2%',
    },
  );

  static const EdenInsightContent lookAheadRoutingInsight = EdenInsightContent(
    id: 'tr-insight-lookahead',
    type: EdenInsightType.suggestion,
    title: 'Consider re-routing Bob to Cobb',
    subtitle:
        'Thursday afternoon — 3 jobs cluster within 4 miles of his lunch stop.',
    data: <String, dynamic>{
      'reason': 'Save ~38 driving minutes',
    },
  );

  static const EdenInsightContent permitExpiringInsight = EdenInsightContent(
    id: 'tr-insight-permit',
    type: EdenInsightType.alert,
    severity: EdenInsightSeverity.warning,
    title: 'Permit expires in 3 days',
    subtitle:
        'Whitfield install — Marietta city permit #M-2026-04419.',
  );

  /// EdenBlockingAlerts fixtures — mix of severities & contexts.
  static const List<EdenBlockingAlertData> blockingAlerts =
      <EdenBlockingAlertData>[
    EdenBlockingAlertData(
      task: 'Install HVAC — Whitfield',
      context: 'Phase 2 / install day',
      reason: 'Waiting on city permit approval (submitted 5 days ago).',
    ),
    EdenBlockingAlertData(
      task: 'Survey — Bartholomew ranch',
      context: 'Phase 1 / pre-quote',
      reason:
          'Customer unavailable for site walk — rescheduling for next Tuesday.',
      severity: EdenBlockingSeverity.amber,
    ),
    EdenBlockingAlertData(
      task: 'Panel upgrade — Bartholomew',
      context: 'Materials / kit-out',
      reason:
          'Romex 12/3 250ft roll: 1 on hand, need 4. Reorder placed yesterday.',
    ),
  ];

  /// EdenCostSummaryCard fixture — sample job breakdown.
  static const TradesJobCostBreakdown jobCostBreakdown = TradesJobCostBreakdown(
    labor: r'$1,840.00',
    material: r'$3,217.45',
    equipment: r'$640.00',
    permits: r'$185.00',
    subContractors: r'$0.00',
    total: r'$5,882.45',
  );

  /// EdenActivityFeedItem fixtures — trades-specific events.
  static const List<EdenActivityFeedItemData> activityFeed =
      <EdenActivityFeedItemData>[
    EdenActivityFeedItemData(
      actorName: 'Alice Chen',
      actorInitials: 'AC',
      action: 'checked in on',
      entityName: 'Whitfield install',
      timeAgo: '7m ago',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Dispatch (system)',
      actorInitials: 'SY',
      action: 'assigned',
      entityName: 'Truck 47 to AC service call #4471',
      timeAgo: '22m ago',
      variant: EdenActivityVariant.info,
    ),
    EdenActivityFeedItemData(
      actorName: 'Marcus Whitfield',
      actorInitials: 'MW',
      action: 'signed estimate for',
      entityName: r'HVAC install ($8,420)',
      timeAgo: '1h ago',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Bob Kowalski',
      actorInitials: 'BK',
      action: 'flagged blocker on',
      entityName: 'Panel upgrade — Bartholomew',
      timeAgo: '2h ago',
      variant: EdenActivityVariant.warning,
    ),
    EdenActivityFeedItemData(
      actorName: 'Office (Sara)',
      actorInitials: 'SR',
      action: 'sent invoice for',
      entityName: r'Furnace tune-up — Pierre ($248)',
      timeAgo: '4h ago',
      variant: EdenActivityVariant.info,
    ),
    EdenActivityFeedItemData(
      actorName: 'Customer (Whitfield)',
      actorInitials: 'MW',
      action: 'opened callback ticket on',
      entityName: 'Condensate line leak',
      timeAgo: 'yesterday',
      variant: EdenActivityVariant.danger,
    ),
  ];

  // ---------------------------------------------------------------------------
  // MINIMAL FIXTURES
  // ---------------------------------------------------------------------------

  /// Single-event day fixture for the "minimal" demo state.
  static List<EdenSchedulerEvent> get singleEventDay {
    final day = DateTime(2026, 5, 16);
    return <EdenSchedulerEvent>[
      EdenSchedulerEvent(
        id: 'tr-min-001',
        title: 'AC tune-up — Pierre',
        start: day.add(const Duration(hours: 10)),
        end: day.add(const Duration(hours: 11, minutes: 30)),
        assignee: 'Alice Chen',
        color: const Color(0xFF1D4ED8),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // EDGE FIXTURES
  // ---------------------------------------------------------------------------

  /// 12-event single-day overflow probe — heavily-conflicting blocks for
  /// the layout engine to chew on.
  static List<EdenSchedulerEvent> get overflowDay {
    final day = DateTime(2026, 5, 22, 7, 0);
    return List<EdenSchedulerEvent>.generate(12, (i) {
      final start = day.add(Duration(minutes: i * 30));
      return EdenSchedulerEvent(
        id: 'tr-overflow-${i.toString().padLeft(3, '0')}',
        title:
            i.isEven ? 'AC service call' : 'Furnace install (long title here)',
        start: start,
        end: start.add(Duration(minutes: 90 + (i * 10) % 90)),
        assignee: i.isEven ? 'Alice Chen' : 'Bob Kowalski',
        color: i.isEven
            ? const Color(0xFF1D4ED8)
            : const Color(0xFFB45309),
        status: 'scheduled',
      );
    });
  }

  /// Customer fixture with extremely long name + address fields — narrow
  /// width probe.
  static DemoCustomer get longNameCustomer => CrossCuttingFixtures.customers[9];
}

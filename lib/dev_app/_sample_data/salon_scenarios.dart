// lib/dev_app/_sample_data/salon_scenarios.dart
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

/// Salon vertical (cuts / color / chemical services / front-desk) fixtures.
///
/// Stylist roster: Marisol Reyes (master, color), Devon Park (color
/// specialist), Tasha Ali (cuts), Ava Lindgren (chemical / extensions).
class SalonScenarios {
  // ---------------------------------------------------------------------------
  // REALISTIC FIXTURES
  // ---------------------------------------------------------------------------

  /// Week of appointments — Mon..Sat (closed Sundays). Variety: 30-min cuts,
  /// 60-min blowouts, 3hr balayage, 4hr+ color correction, walk-in slot.
  static List<EdenSchedulerEvent> get weekAppointments {
    final monday = DateTime(2026, 5, 11);
    return <EdenSchedulerEvent>[
      // Monday — slow start, 4 appts
      EdenSchedulerEvent(
        id: 'sl-evt-001',
        title: 'Cut & blow — A. Okonkwo-Reyes',
        start: monday.add(const Duration(hours: 10)),
        end: monday.add(const Duration(hours: 11)),
        assignee: 'Marisol Reyes',
        color: const Color(0xFFDB2777),
        status: 'booked',
        type: 'cut',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-002',
        title: 'Balayage — D. Pierre',
        description:
            'Cool-tone refresh; client brought reference photo. Allow 3h.',
        start: monday.add(const Duration(hours: 11, minutes: 30)),
        end: monday.add(const Duration(hours: 14, minutes: 30)),
        assignee: 'Devon Park',
        color: const Color(0xFFA855F7),
        status: 'booked',
        type: 'color',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-003',
        title: 'Trim — walk-in (Priya V.)',
        start: monday.add(const Duration(hours: 15)),
        end: monday.add(const Duration(hours: 15, minutes: 30)),
        assignee: 'Tasha Ali',
        color: const Color(0xFF0EA5E9),
        status: 'booked',
        type: 'cut',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-004',
        title: 'Color correction (3-step) — Eleanor M.',
        start: monday.add(const Duration(hours: 16)),
        end: monday.add(const Duration(hours: 20)),
        assignee: 'Ava Lindgren',
        color: const Color(0xFF7C2D12),
        status: 'booked',
        type: 'chemical',
        dispatchIssue: 'VIP — extends past close. OT approved.',
      ),
      // Tuesday — typical
      EdenSchedulerEvent(
        id: 'sl-evt-005',
        title: 'Root touch-up',
        start: monday.add(const Duration(days: 1, hours: 9, minutes: 30)),
        end: monday.add(const Duration(days: 1, hours: 11)),
        assignee: 'Devon Park',
        color: const Color(0xFFA855F7),
        status: 'booked',
        type: 'color',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-006',
        title: 'Cut',
        start: monday.add(const Duration(days: 1, hours: 11, minutes: 30)),
        end: monday.add(const Duration(days: 1, hours: 12, minutes: 15)),
        assignee: 'Tasha Ali',
        color: const Color(0xFF0EA5E9),
        type: 'cut',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-007',
        title: 'Chemical straightening',
        description: 'New client consultation — extra patch-test 24h prior.',
        start: monday.add(const Duration(days: 1, hours: 13)),
        end: monday.add(const Duration(days: 1, hours: 17)),
        assignee: 'Ava Lindgren',
        color: const Color(0xFF7C2D12),
        type: 'chemical',
        dispatchIssue: 'Allergy disclosure not on file yet',
        readiness: EdenSchedulerEventReadiness.warning,
      ),
      // Wed–Fri various
      EdenSchedulerEvent(
        id: 'sl-evt-008',
        title: 'Highlights — Whitfield (M.)',
        start: monday.add(const Duration(days: 2, hours: 10)),
        end: monday.add(const Duration(days: 2, hours: 12, minutes: 30)),
        assignee: 'Devon Park',
        color: const Color(0xFFA855F7),
        type: 'color',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-009',
        title: 'Beard trim',
        start: monday.add(const Duration(days: 3, hours: 11)),
        end: monday.add(const Duration(days: 3, hours: 11, minutes: 30)),
        assignee: 'Tasha Ali',
        color: const Color(0xFF0EA5E9),
        type: 'cut',
      ),
      EdenSchedulerEvent(
        id: 'sl-evt-010',
        title: 'Bridal trial — Sørensen',
        description: 'Updo + makeup, 2hr block.',
        start: monday.add(const Duration(days: 4, hours: 13)),
        end: monday.add(const Duration(days: 4, hours: 15)),
        assignee: 'Marisol Reyes',
        color: const Color(0xFFDB2777),
        type: 'styling',
      ),
      // Saturday — packed
      EdenSchedulerEvent(
        id: 'sl-evt-011',
        title: 'Wedding party (8 guests)',
        start: monday.add(const Duration(days: 5, hours: 8)),
        end: monday.add(const Duration(days: 5, hours: 13)),
        assignee: 'Marisol Reyes',
        color: const Color(0xFFDB2777),
        type: 'event',
      ),
    ];
  }

  static const EdenInsightContent bookingTrendInsight = EdenInsightContent(
    id: 'sl-insight-bookings',
    type: EdenInsightType.chart,
    chartType: EdenChartType.bar,
    title: 'Bookings · last 7 days',
    subtitle: 'Sat is 38% above 4-week avg; Mon is 22% below.',
    data: <String, dynamic>{
      'series': <int>[12, 18, 21, 17, 24, 38, 0],
      'labels': <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    },
  );

  static const EdenInsightContent productLowStockInsight = EdenInsightContent(
    id: 'sl-insight-lowstock',
    type: EdenInsightType.alert,
    severity: EdenInsightSeverity.warning,
    title: 'Redken bonding shampoo — 2 left',
    subtitle:
        'Reorder point is 4 bottles. Reorder placed last Tuesday — ETA Friday.',
  );

  static const EdenInsightContent rebookSuggestionInsight = EdenInsightContent(
    id: 'sl-insight-rebook',
    type: EdenInsightType.suggestion,
    title: 'Send rebook reminders',
    subtitle:
        '6 platinum clients have not rebooked > 8 weeks. Avg cadence is 6 wks.',
  );

  /// EdenBlockingAlerts — front-desk blockers.
  static const List<EdenBlockingAlertData> blockingAlerts =
      <EdenBlockingAlertData>[
    EdenBlockingAlertData(
      task: 'Chemical service — new client',
      context: 'Pre-service intake',
      reason: 'Allergy disclosure form not signed (24h patch-test required).',
      severity: EdenBlockingSeverity.amber,
    ),
    EdenBlockingAlertData(
      task: 'Cosmetology license renewal',
      context: 'Marisol Reyes',
      reason: 'License expires in 21 days — renewal not yet submitted.',
    ),
  ];

  /// Realistic membership-tier client mix. References cross-cutting customers.
  static List<DemoCustomer> get memberClients => <DemoCustomer>[
        CrossCuttingFixtures.customers[1], // Aisha — platinum
        CrossCuttingFixtures.customers[2], // D'Angelo — silver
        CrossCuttingFixtures.customers[5], // Eleanor — vip
        CrossCuttingFixtures.customers[8], // Priya — bronze
      ];

  static const List<EdenActivityFeedItemData> activityFeed =
      <EdenActivityFeedItemData>[
    EdenActivityFeedItemData(
      actorName: 'Marisol Reyes',
      actorInitials: 'MR',
      action: 'checked out',
      entityName: r'Aisha O.-R. (balayage, $385)',
      timeAgo: 'just now',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Devon Park',
      actorInitials: 'DP',
      action: 'rebooked',
      entityName: 'Priya V. for 2026-06-27',
      timeAgo: '11m ago',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Front desk',
      actorInitials: 'FD',
      action: 'recorded no-show:',
      entityName: '11am cut (S. Park)',
      timeAgo: '47m ago',
      variant: EdenActivityVariant.warning,
    ),
    EdenActivityFeedItemData(
      actorName: 'Walk-in (J. Yates)',
      actorInitials: 'JY',
      action: 'added to standby for',
      entityName: 'Tasha at 3pm',
      timeAgo: '1h ago',
      variant: EdenActivityVariant.info,
    ),
    EdenActivityFeedItemData(
      actorName: 'Ava Lindgren',
      actorInitials: 'AL',
      action: 'flagged consult required for',
      entityName: 'new chemical client (M. Khoury)',
      timeAgo: '3h ago',
      variant: EdenActivityVariant.warning,
    ),
  ];

  // ---------------------------------------------------------------------------
  // MINIMAL FIXTURES
  // ---------------------------------------------------------------------------

  static List<EdenSchedulerEvent> get singleEventDay {
    final day = DateTime(2026, 5, 16);
    return <EdenSchedulerEvent>[
      EdenSchedulerEvent(
        id: 'sl-min-001',
        title: 'Cut — Pierre',
        start: day.add(const Duration(hours: 10)),
        end: day.add(const Duration(hours: 10, minutes: 45)),
        assignee: 'Tasha Ali',
        color: const Color(0xFF0EA5E9),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // EDGE FIXTURES — packed-Saturday probe
  // ---------------------------------------------------------------------------

  static List<EdenSchedulerEvent> get overflowDay {
    final saturday = DateTime(2026, 5, 16, 8, 0);
    final stylists = <String>[
      'Marisol Reyes',
      'Devon Park',
      'Tasha Ali',
      'Ava Lindgren',
    ];
    final colors = <Color>[
      const Color(0xFFDB2777),
      const Color(0xFFA855F7),
      const Color(0xFF0EA5E9),
      const Color(0xFF7C2D12),
    ];
    final titles = <String>[
      'Cut',
      'Cut & color',
      'Balayage',
      'Root touch-up',
      'Highlights',
      'Blowout',
      'Updo',
      'Chemical straightening',
      'Beard trim',
      'Color gloss',
    ];
    return List<EdenSchedulerEvent>.generate(16, (i) {
      final start = saturday.add(Duration(minutes: i * 30));
      final stylistIdx = i % stylists.length;
      return EdenSchedulerEvent(
        id: 'sl-overflow-${i.toString().padLeft(3, '0')}',
        title: titles[i % titles.length],
        start: start,
        end: start.add(Duration(minutes: 45 + (i * 13) % 75)),
        assignee: stylists[stylistIdx],
        color: colors[stylistIdx],
        type: i.isEven ? 'cut' : 'color',
      );
    });
  }
}

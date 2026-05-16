// lib/dev_app/_sample_data/gov_scenarios.dart
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

/// Government / caseworker vertical fixtures.
///
/// Roster: Linnea Sørensen (senior caseworker, Tier 2), Avery Kim (analyst),
/// Hiroshi Tanaka (supervisor / approval authority).
class GovScenarios {
  // ---------------------------------------------------------------------------
  // REALISTIC FIXTURES
  // ---------------------------------------------------------------------------

  /// Week of case-review events, site inspections, and approval-board meetings.
  static List<EdenSchedulerEvent> get weekCases {
    final monday = DateTime(2026, 5, 11);
    return <EdenSchedulerEvent>[
      EdenSchedulerEvent(
        id: 'gv-evt-001',
        title: 'Case review · CCM-2026-0427',
        description: 'Tier 2 case. Verify supporting docs.',
        start: monday.add(const Duration(hours: 9)),
        end: monday.add(const Duration(hours: 10, minutes: 30)),
        assignee: 'Linnea Sørensen',
        color: const Color(0xFF334155),
        status: 'in_progress',
        type: 'case_review',
      ),
      EdenSchedulerEvent(
        id: 'gv-evt-002',
        title: 'Site inspection · permit 2026-04419',
        start: monday.add(const Duration(hours: 13, minutes: 30)),
        end: monday.add(const Duration(hours: 15)),
        assignee: 'Avery Kim',
        color: const Color(0xFF0F766E),
        status: 'scheduled',
        type: 'inspection',
      ),
      EdenSchedulerEvent(
        id: 'gv-evt-003',
        title: 'Approval board (weekly)',
        description: '8 cases on docket. Tanaka chairing.',
        start: monday.add(const Duration(days: 1, hours: 14)),
        end: monday.add(const Duration(days: 1, hours: 16)),
        assignee: 'Hiroshi Tanaka',
        color: const Color(0xFF7C2D12),
        status: 'scheduled',
        type: 'board',
      ),
      EdenSchedulerEvent(
        id: 'gv-evt-004',
        title: 'Case review · CCM-2026-0431',
        start: monday.add(const Duration(days: 2, hours: 10, minutes: 30)),
        end: monday.add(const Duration(days: 2, hours: 12)),
        assignee: 'Linnea Sørensen',
        color: const Color(0xFF334155),
        type: 'case_review',
        dispatchIssue: 'SLA breach risk — 12 days open',
        readiness: EdenSchedulerEventReadiness.urgent,
      ),
      EdenSchedulerEvent(
        id: 'gv-evt-005',
        title: 'Subject interview · CCM-2026-0414',
        start: monday.add(const Duration(days: 3, hours: 9, minutes: 30)),
        end: monday.add(const Duration(days: 3, hours: 10, minutes: 30)),
        assignee: 'Avery Kim',
        color: const Color(0xFF0F766E),
        type: 'interview',
      ),
      EdenSchedulerEvent(
        id: 'gv-evt-006',
        title: 'Quarterly compliance audit',
        start: monday.add(const Duration(days: 4, hours: 13)),
        end: monday.add(const Duration(days: 4, hours: 17)),
        assignee: 'Hiroshi Tanaka',
        color: const Color(0xFF7C2D12),
        type: 'audit',
      ),
    ];
  }

  static const EdenInsightContent backlogInsight = EdenInsightContent(
    id: 'gv-insight-backlog',
    type: EdenInsightType.metric,
    title: 'Open cases · backlog',
    subtitle: 'Up 18 vs last week — Tier 2 driving the increase.',
    data: <String, dynamic>{
      'value': '247',
      'trend': 'up',
      'change': '+8%',
    },
  );

  static const EdenInsightContent slaBreachInsight = EdenInsightContent(
    id: 'gv-insight-sla',
    type: EdenInsightType.alert,
    severity: EdenInsightSeverity.critical,
    title: '4 cases breaching SLA today',
    subtitle: 'CCM-2026-0431 already 12 days past target (10-day window).',
  );

  static const EdenInsightContent approvalRateInsight = EdenInsightContent(
    id: 'gv-insight-approval',
    type: EdenInsightType.chart,
    chartType: EdenChartType.line,
    title: 'Approval rate · last 6 weeks',
    subtitle: 'Trending up since intake-form refactor.',
    data: <String, dynamic>{
      'series': <int>[58, 61, 63, 67, 71, 74],
      'labels': <String>[
        'w-5',
        'w-4',
        'w-3',
        'w-2',
        'w-1',
        'this',
      ],
    },
  );

  static const List<EdenBlockingAlertData> blockingAlerts =
      <EdenBlockingAlertData>[
    EdenBlockingAlertData(
      task: 'Case CCM-2026-0414',
      context: 'Approval queue',
      reason:
          'Subject signature missing on Form 30-A; cannot present to board.',
    ),
    EdenBlockingAlertData(
      task: 'Caseworker access',
      context: 'Avery Kim',
      reason:
          'Tier-2 clearance expired 4 days ago — renewal in review.',
    ),
    EdenBlockingAlertData(
      task: 'Inspection report · 2026-04419',
      context: 'Quality review',
      reason: 'Awaiting supervisor sign-off (Tanaka returns Wednesday).',
      severity: EdenBlockingSeverity.amber,
    ),
  ];

  /// Citizens / case subjects.
  static List<DemoCustomer> get citizens => <DemoCustomer>[
        CrossCuttingFixtures.customers[6], // Linnea entry but as gov case subject
        const DemoCustomer(
          id: 'cust-161',
          name: 'Subject CCM-2026-0427',
          email: 'redacted@case-portal.local',
          phone: '+1 (770) 555-0427',
          address: EdenAddress(
            streetLine1: '[address sealed per Tier-2 protocol]',
            city: 'Marietta',
            regionCode: 'GA',
            postalCode: '30090',
            countryCode: 'US',
          ),
          vertical: 'gov',
          notes: 'Case opened 2026-04-18; awaiting Tier-2 review.',
        ),
        const DemoCustomer(
          id: 'cust-162',
          name: 'Subject CCM-2026-0431',
          email: 'redacted@case-portal.local',
          phone: '+1 (770) 555-0431',
          address: EdenAddress(
            streetLine1: '[address sealed per Tier-2 protocol]',
            city: 'Atlanta',
            regionCode: 'GA',
            postalCode: '30303',
            countryCode: 'US',
          ),
          vertical: 'gov',
          notes: 'SLA breach — 12 days past target window.',
        ),
      ];

  /// Caseworker staff fixtures (includes the senior caseworker from the
  /// cross-cutting staff list plus 2 gov-specific entries).
  static List<DemoStaff> get caseworkers => <DemoStaff>[
        CrossCuttingFixtures.staff[7], // Linnea Sørensen (senior)
        const DemoStaff(
          id: 'staff-321',
          name: 'Avery Kim',
          role: 'Case Analyst',
          vertical: 'gov',
          initials: 'AK',
          phone: '+1 (770) 555-0901',
        ),
        const DemoStaff(
          id: 'staff-322',
          name: 'Hiroshi Tanaka',
          role: 'Supervisor / Approval Authority',
          vertical: 'gov',
          initials: 'HT',
        ),
      ];

  static const List<EdenActivityFeedItemData> activityFeed =
      <EdenActivityFeedItemData>[
    EdenActivityFeedItemData(
      actorName: 'Linnea Sørensen',
      actorInitials: 'LS',
      action: 'escalated',
      entityName: 'Case CCM-2026-0427 to Tier 3',
      timeAgo: 'just now',
      variant: EdenActivityVariant.danger,
    ),
    EdenActivityFeedItemData(
      actorName: 'Hiroshi Tanaka',
      actorInitials: 'HT',
      action: 'signed approval for',
      entityName: 'Case CCM-2026-0408',
      timeAgo: '17m ago',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Avery Kim',
      actorInitials: 'AK',
      action: 'filed supporting documentation for',
      entityName: 'Case CCM-2026-0431',
      timeAgo: '1h ago',
      variant: EdenActivityVariant.info,
    ),
    EdenActivityFeedItemData(
      actorName: 'System',
      actorInitials: 'SY',
      action: 'opened case',
      entityName: 'CCM-2026-0444',
      timeAgo: '4h ago',
      variant: EdenActivityVariant.info,
    ),
    EdenActivityFeedItemData(
      actorName: 'Compliance bot',
      actorInitials: 'CB',
      action: 'flagged SLA breach on',
      entityName: 'Case CCM-2026-0431 (12d overdue)',
      timeAgo: 'yesterday',
      variant: EdenActivityVariant.warning,
    ),
  ];
}

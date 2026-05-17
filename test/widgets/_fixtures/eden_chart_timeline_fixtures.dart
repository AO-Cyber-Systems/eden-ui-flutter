// Do NOT regenerate via LLM — hand-built clinical timeline fixtures for EdenChartTimeline.
//
// Spans multiple years to exercise quarterly compression; mixes categories
// + severities to exercise filter chips + tinting.

import 'package:eden_ui_flutter/src/widgets/eden_chart_timeline.dart';

final _now = DateTime(2026, 5, 17, 14, 30);

class TimelineFixtures {
  TimelineFixtures._();

  // ───────────────────────── recent events ─────────────────────────

  static final annualPhysicalToday = EdenChartTimelineEvent(
    id: 'evt-001',
    patientId: 'pt-001',
    category: EdenChartEventCategory.encounter,
    title: 'Annual Physical',
    subtitle: 'Z00.00 — routine annual',
    occurredAt: _now,
    provider: 'Dr. Chen',
  );

  static final cbcOrderedToday = EdenChartTimelineEvent(
    id: 'evt-002',
    patientId: 'pt-001',
    category: EdenChartEventCategory.lab,
    title: 'CBC ordered',
    subtitle: '5 results, 1 flagged H',
    occurredAt: _now.subtract(const Duration(hours: 2)),
    provider: 'Dr. Chen',
  );

  static final startedMetforminToday = EdenChartTimelineEvent(
    id: 'evt-003',
    patientId: 'pt-001',
    category: EdenChartEventCategory.medication,
    title: 'Started Metformin 500mg',
    subtitle: 'Twice daily, PO',
    occurredAt: _now.subtract(const Duration(hours: 4)),
    provider: 'Dr. Chen',
  );

  static final soapNoteToday = EdenChartTimelineEvent(
    id: 'evt-004',
    patientId: 'pt-001',
    category: EdenChartEventCategory.note,
    title: 'SOAP note signed',
    subtitle: 'Annual physical — Dr. Chen',
    occurredAt: _now.subtract(const Duration(hours: 1)),
    provider: 'Dr. Chen',
  );

  static final erVisitChestPainCaution = EdenChartTimelineEvent(
    id: 'evt-005',
    patientId: 'pt-001',
    category: EdenChartEventCategory.encounter,
    title: 'ER Visit — Chest Pain',
    subtitle: 'Ruled out STEMI; observation 12h',
    occurredAt: _now.subtract(const Duration(days: 14)),
    severity: EdenChartEventSeverity.caution,
    provider: 'ER Provider',
  );

  static final strokeAdmitCritical = EdenChartTimelineEvent(
    id: 'evt-006',
    patientId: 'pt-001',
    category: EdenChartEventCategory.encounter,
    title: 'Acute Stroke Admission',
    subtitle: 'tPA administered; ICU 3d',
    occurredAt: _now.subtract(const Duration(days: 21)),
    severity: EdenChartEventSeverity.critical,
    provider: 'Dr. Martinez (Neuro)',
  );

  static final appendicitisResolved = EdenChartTimelineEvent(
    id: 'evt-007',
    patientId: 'pt-001',
    category: EdenChartEventCategory.encounter,
    title: 'Appendectomy (laparoscopic)',
    subtitle: 'Discharged POD1',
    occurredAt: DateTime(2019, 6, 5),
    severity: EdenChartEventSeverity.resolved,
    provider: 'Dr. Garcia',
  );

  // ───────────────────────── multi-day strips ──────────────────────

  /// Three days' worth: today + yesterday + 5d ago.
  static List<EdenChartTimelineEvent> get threeDaysWorth => [
        annualPhysicalToday,
        EdenChartTimelineEvent(
          id: 'evt-3d-1',
          patientId: 'pt-001',
          category: EdenChartEventCategory.lab,
          title: 'Lipid panel collected',
          occurredAt: _now.subtract(const Duration(days: 1)),
          provider: 'Lab',
        ),
        EdenChartTimelineEvent(
          id: 'evt-3d-2',
          patientId: 'pt-001',
          category: EdenChartEventCategory.note,
          title: 'Telehealth note',
          subtitle: '5-min check-in re: BP',
          occurredAt: _now.subtract(const Duration(days: 5)),
          provider: 'Dr. Chen',
        ),
      ];

  /// 5 mixed events today / few days back (all categories represented).
  static List<EdenChartTimelineEvent> get mixed5events => [
        annualPhysicalToday,
        cbcOrderedToday,
        startedMetforminToday,
        soapNoteToday,
        EdenChartTimelineEvent(
          id: 'evt-mix-5',
          patientId: 'pt-001',
          category: EdenChartEventCategory.order,
          title: 'Mammogram order placed',
          subtitle: 'Routine screening',
          occurredAt: _now.subtract(const Duration(days: 2)),
          provider: 'Dr. Chen',
        ),
      ];

  /// 5-year compressed history.
  static List<EdenChartTimelineEvent> get fiveYearHistory => [
        annualPhysicalToday,
        startedMetforminToday,
        erVisitChestPainCaution,
        // Past year (still day-level)
        EdenChartTimelineEvent(
          id: 'evt-5y-1',
          patientId: 'pt-001',
          category: EdenChartEventCategory.encounter,
          title: 'Annual Physical',
          occurredAt: _now.subtract(const Duration(days: 365)),
          provider: 'Dr. Chen',
        ),
        // >12mo ago (quarterly compression)
        EdenChartTimelineEvent(
          id: 'evt-5y-2',
          patientId: 'pt-001',
          category: EdenChartEventCategory.encounter,
          title: 'Annual Physical',
          occurredAt: DateTime(2024, 8, 10),
          provider: 'Dr. Chen',
        ),
        EdenChartTimelineEvent(
          id: 'evt-5y-3',
          patientId: 'pt-001',
          category: EdenChartEventCategory.medication,
          title: 'Started Lisinopril 10mg',
          occurredAt: DateTime(2024, 1, 8),
          provider: 'Dr. Chen',
        ),
        EdenChartTimelineEvent(
          id: 'evt-5y-4',
          patientId: 'pt-001',
          category: EdenChartEventCategory.lab,
          title: 'A1c 7.4',
          occurredAt: DateTime(2023, 5, 10),
          provider: 'Lab',
          severity: EdenChartEventSeverity.caution,
        ),
        appendicitisResolved,
        EdenChartTimelineEvent(
          id: 'evt-5y-5',
          patientId: 'pt-001',
          category: EdenChartEventCategory.encounter,
          title: 'Annual Physical',
          occurredAt: DateTime(2022, 8, 14),
          provider: 'Dr. Chen',
        ),
        EdenChartTimelineEvent(
          id: 'evt-5y-6',
          patientId: 'pt-001',
          category: EdenChartEventCategory.problem,
          title: 'Diagnosed T2DM',
          subtitle: 'E11.9',
          occurredAt: DateTime(2022, 8, 14),
          provider: 'Dr. Chen',
        ),
        EdenChartTimelineEvent(
          id: 'evt-5y-7',
          patientId: 'pt-001',
          category: EdenChartEventCategory.encounter,
          title: 'Annual Physical',
          occurredAt: DateTime(2021, 9, 1),
          provider: 'Dr. Old',
        ),
      ];

  static List<EdenChartTimelineEvent> get singleEncounterDetail => [
        annualPhysicalToday,
        cbcOrderedToday,
      ];

  // HIPAA isolation
  static final eventPatient001 = annualPhysicalToday;
  static final eventPatient002 = EdenChartTimelineEvent(
    id: 'evt-mix-pt2',
    patientId: 'pt-002',
    category: EdenChartEventCategory.encounter,
    title: 'New patient intake',
    occurredAt: _now,
    provider: 'Dr. Khan',
  );
}

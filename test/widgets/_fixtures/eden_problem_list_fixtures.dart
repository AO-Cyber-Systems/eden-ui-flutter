// Do NOT regenerate via LLM — hand-built clinical fixtures for EdenProblemList.
//
// Common ICD-10 codes:
//   E11.9 — Type 2 diabetes mellitus without complications
//   I10   — Essential (primary) hypertension
//   J44.9 — Chronic obstructive pulmonary disease, unspecified
//   E78.5 — Hyperlipidemia, unspecified
//   F33.0 — Major depressive disorder, recurrent, mild
//   M19.90 — Osteoarthritis, unspecified site
//   N18.3 — Chronic kidney disease, stage 3
//   G47.33 — Obstructive sleep apnea (adult)
//   K21.9  — GERD without esophagitis
//   K35.80 — Acute appendicitis (resolved)
//   R07.9  — Chest pain, unspecified

import 'package:eden_ui_flutter/src/widgets/eden_problem_list.dart';

class ProblemFixtures {
  ProblemFixtures._();

  static final t2dm = EdenCondition(
    id: 'cond-001',
    patientId: 'pt-001',
    code: 'E11.9',
    codeSystem: 'ICD-10-CM',
    description: 'Type 2 diabetes mellitus without complications',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2022, 8, 14),
    diagnosedBy: 'Dr. Chen',
  );

  static final htn = EdenCondition(
    id: 'cond-002',
    patientId: 'pt-001',
    code: 'I10',
    codeSystem: 'ICD-10-CM',
    description: 'Essential (primary) hypertension',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2021, 3, 2),
    diagnosedBy: 'Dr. Chen',
  );

  static final hyperlipidemia = EdenCondition(
    id: 'cond-003',
    patientId: 'pt-001',
    code: 'E78.5',
    codeSystem: 'ICD-10-CM',
    description: 'Hyperlipidemia, unspecified',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2023, 5, 10),
    diagnosedBy: 'Dr. Chen',
  );

  static final gerd = EdenCondition(
    id: 'cond-004',
    patientId: 'pt-001',
    code: 'K21.9',
    codeSystem: 'ICD-10-CM',
    description: 'GERD without esophagitis',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2024, 1, 18),
    diagnosedBy: 'Dr. Chen',
  );

  static final osa = EdenCondition(
    id: 'cond-005',
    patientId: 'pt-001',
    code: 'G47.33',
    codeSystem: 'ICD-10-CM',
    description: 'Obstructive sleep apnea (adult)',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2024, 9, 1),
    diagnosedBy: 'Dr. Park',
  );

  static final copdRecurrence = EdenCondition(
    id: 'cond-006',
    patientId: 'pt-001',
    code: 'J44.9',
    codeSystem: 'ICD-10-CM',
    description: 'Chronic obstructive pulmonary disease, unspecified',
    status: EdenConditionStatus.recurrence,
    onsetDate: DateTime(2020, 11, 4),
    diagnosedBy: 'Dr. Lee',
  );

  static final appendicitisResolved = EdenCondition(
    id: 'cond-007',
    patientId: 'pt-001',
    code: 'K35.80',
    codeSystem: 'ICD-10-CM',
    description: 'Acute appendicitis',
    status: EdenConditionStatus.resolved,
    onsetDate: DateTime(2019, 6, 3),
    resolvedDate: DateTime(2019, 6, 5),
    diagnosedBy: 'Dr. Garcia',
  );

  static final htnInactive = EdenCondition(
    id: 'cond-008',
    patientId: 'pt-001',
    code: 'I10',
    codeSystem: 'ICD-10-CM',
    description: 'Essential (primary) hypertension',
    status: EdenConditionStatus.inactive,
    onsetDate: DateTime(2015, 1, 1),
    diagnosedBy: 'Dr. Old',
  );

  static final chestPainProvisional = EdenCondition(
    id: 'cond-009',
    patientId: 'pt-001',
    code: 'R07.9',
    codeSystem: 'ICD-10-CM',
    description: 'Chest pain, unspecified',
    status: EdenConditionStatus.active,
    verification: EdenConditionVerification.provisional,
    onsetDate: DateTime(2026, 5, 16),
    diagnosedBy: 'Dr. Chen',
  );

  static final gerdRefuted = EdenCondition(
    id: 'cond-010',
    patientId: 'pt-001',
    code: 'K21.9',
    codeSystem: 'ICD-10-CM',
    description: 'GERD without esophagitis',
    status: EdenConditionStatus.inactive,
    verification: EdenConditionVerification.refuted,
    onsetDate: DateTime(2024, 1, 18),
    diagnosedBy: 'Dr. Chen',
  );

  // ───────────────────────── multi-condition strips ───────────────────

  static List<EdenCondition> get polychronic => [
        t2dm,
        htn,
        hyperlipidemia,
        appendicitisResolved,
        copdRecurrence,
      ];

  static List<EdenCondition> get polychronicPatient => [
        t2dm,
        htn,
        hyperlipidemia,
        gerd,
        osa,
      ];

  static List<EdenCondition> get singleChronic => [t2dm];

  static List<EdenCondition> get postSurgicalResolved => [appendicitisResolved];

  static List<EdenCondition> get nullOnsetMixed => [
        t2dm,
        EdenCondition(
          id: 'cond-null-onset',
          patientId: 'pt-001',
          code: 'F33.0',
          codeSystem: 'ICD-10-CM',
          description: 'Major depressive disorder, recurrent, mild',
          status: EdenConditionStatus.active,
          onsetDate: null,
          diagnosedBy: 'Dr. Patel',
        ),
      ];

  // HIPAA isolation
  static final t2dmPatient001 = t2dm;
  static final htnPatient002 = EdenCondition(
    id: 'cond-mix-1',
    patientId: 'pt-002',
    code: 'I10',
    codeSystem: 'ICD-10-CM',
    description: 'Essential (primary) hypertension',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2024, 3, 2),
    diagnosedBy: 'Dr. Khan',
  );
}

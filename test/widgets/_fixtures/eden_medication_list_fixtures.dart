// Do NOT regenerate via LLM — hand-built clinical fixtures for EdenMedicationList.
//
// Realistic-but-non-PII drugs at common doses:
// - metformin 500mg PO twice daily (T2DM)
// - lisinopril 10mg PO daily (HTN)
// - atorvastatin 40mg PO QHS (hyperlipidemia)
// - warfarin 5mg PO daily (AFib) — interaction with aspirin
// - aspirin 81mg PO daily (cardioprotective) — interaction with warfarin
// - levothyroxine 75mcg PO daily (hypothyroidism)
// - omeprazole 20mg PO daily (GERD) — paused fixture
// - sertraline 100mg PO daily (depression) — discontinued fixture
// - oxycodone 5mg PO q6h PRN (post-op) — Schedule II warning
// - acetaminophen 650mg PO q6h (post-op)
// - insulin glargine 20U SC qHS
// - albuterol HFA INH PRN

import 'package:eden_ui_flutter/src/widgets/eden_medication_list.dart';

class MedFixtures {
  MedFixtures._();

  // ──────────────────────────── single meds ────────────────────────────

  static final metformin500 = EdenMedicationStatement(
    id: 'med-001',
    patientId: 'pt-001',
    drugName: 'Metformin',
    doseLabel: '500mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Twice daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 3, 12),
  );

  static final lisinopril10 = EdenMedicationStatement(
    id: 'med-002',
    patientId: 'pt-001',
    drugName: 'Lisinopril',
    doseLabel: '10mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 1, 8),
  );

  static final atorvastatin40 = EdenMedicationStatement(
    id: 'med-003',
    patientId: 'pt-001',
    drugName: 'Atorvastatin',
    doseLabel: '40mg',
    route: EdenMedicationRoute.oral,
    frequency: 'At bedtime',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2023, 11, 5),
  );

  static final warfarin5 = EdenMedicationStatement(
    id: 'med-004',
    patientId: 'pt-elderly',
    drugName: 'Warfarin',
    doseLabel: '5mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2022, 6, 14),
  );

  /// Aspirin 81mg with an interaction warning vs the warfarin entry.
  static final aspirinWithWarfarinInteraction = EdenMedicationStatement(
    id: 'med-005',
    patientId: 'pt-elderly',
    drugName: 'Aspirin',
    doseLabel: '81mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2023, 2, 20),
    interactionWarning: 'Increased bleeding risk — monitor INR (warfarin)',
  );

  static final levothyroxine75 = EdenMedicationStatement(
    id: 'med-006',
    patientId: 'pt-elderly',
    drugName: 'Levothyroxine',
    doseLabel: '75mcg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily, AM',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2020, 9, 3),
  );

  static final pausedOmeprazole = EdenMedicationStatement(
    id: 'med-007',
    patientId: 'pt-001',
    drugName: 'Omeprazole',
    doseLabel: '20mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 4, 1),
    status: EdenMedicationStatus.paused,
    notes: 'Held pending biopsy review',
  );

  static final discontinuedSertraline = EdenMedicationStatement(
    id: 'med-008',
    patientId: 'pt-001',
    drugName: 'Sertraline',
    doseLabel: '100mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Patel',
    startDate: DateTime(2022, 5, 10),
    endDate: DateTime(2024, 2, 28),
    status: EdenMedicationStatus.discontinued,
  );

  // Refill scenarios
  static final lisinoprilNeedsRefill = EdenMedicationStatement(
    id: 'med-009',
    patientId: 'pt-001',
    drugName: 'Lisinopril',
    doseLabel: '10mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 1, 8),
    needsRefill: true,
    refillsRemaining: 2,
  );

  static final atorvastatinNoRefills = EdenMedicationStatement(
    id: 'med-010',
    patientId: 'pt-001',
    drugName: 'Atorvastatin',
    doseLabel: '40mg',
    route: EdenMedicationRoute.oral,
    frequency: 'At bedtime',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2023, 11, 5),
    needsRefill: true,
    refillsRemaining: 0,
  );

  // Route-abbreviation fixtures
  static final insulinSc = EdenMedicationStatement(
    id: 'med-011',
    patientId: 'pt-001',
    drugName: 'Insulin glargine',
    doseLabel: '20U',
    route: EdenMedicationRoute.injection,
    frequency: 'Once daily, at bedtime',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 6, 1),
  );

  static final albuterolInh = EdenMedicationStatement(
    id: 'med-012',
    patientId: 'pt-copd',
    drugName: 'Albuterol HFA',
    doseLabel: '90mcg',
    route: EdenMedicationRoute.inhaled,
    frequency: '2 puffs PRN',
    prescriber: 'Dr. Park',
    startDate: DateTime(2023, 4, 12),
  );

  // ──────────────────────────── multi-med strips ───────────────────────

  /// Polypharmacy elderly — 8 active meds including warfarin+aspirin
  /// interaction example.
  static final polypharmacyElderly = <EdenMedicationStatement>[
    warfarin5,
    aspirinWithWarfarinInteraction,
    levothyroxine75,
    EdenMedicationStatement(
      id: 'med-poly-1',
      patientId: 'pt-elderly',
      drugName: 'Amlodipine',
      doseLabel: '5mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily',
      prescriber: 'Dr. Lee',
      startDate: DateTime(2023, 8, 1),
    ),
    EdenMedicationStatement(
      id: 'med-poly-2',
      patientId: 'pt-elderly',
      drugName: 'Furosemide',
      doseLabel: '20mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily, AM',
      prescriber: 'Dr. Lee',
      startDate: DateTime(2023, 10, 5),
    ),
    EdenMedicationStatement(
      id: 'med-poly-3',
      patientId: 'pt-elderly',
      drugName: 'Metoprolol succinate',
      doseLabel: '50mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily',
      prescriber: 'Dr. Lee',
      startDate: DateTime(2022, 11, 14),
    ),
    EdenMedicationStatement(
      id: 'med-poly-4',
      patientId: 'pt-elderly',
      drugName: 'Atorvastatin',
      doseLabel: '20mg',
      route: EdenMedicationRoute.oral,
      frequency: 'At bedtime',
      prescriber: 'Dr. Lee',
      startDate: DateTime(2022, 6, 14),
    ),
    EdenMedicationStatement(
      id: 'med-poly-5',
      patientId: 'pt-elderly',
      drugName: 'Vitamin D3',
      doseLabel: '1000IU',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily',
      prescriber: 'Dr. Lee',
      startDate: DateTime(2023, 1, 1),
    ),
  ];

  /// Common T2DM + HTN combo (3 meds, all active).
  static final t2dmHtnCombo = <EdenMedicationStatement>[
    metformin500,
    lisinopril10,
    atorvastatin40,
  ];

  /// Post-op pain regimen: oxycodone PRN q6h + scheduled acetaminophen.
  static final postOpPain = <EdenMedicationStatement>[
    EdenMedicationStatement(
      id: 'med-postop-1',
      patientId: 'pt-postop',
      drugName: 'Oxycodone',
      doseLabel: '5mg',
      route: EdenMedicationRoute.oral,
      frequency: 'q6h PRN pain',
      prescriber: 'Dr. Garcia',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      interactionWarning: 'Schedule II — monitor for misuse',
    ),
    EdenMedicationStatement(
      id: 'med-postop-2',
      patientId: 'pt-postop',
      drugName: 'Acetaminophen',
      doseLabel: '650mg',
      route: EdenMedicationRoute.oral,
      frequency: 'q6h',
      prescriber: 'Dr. Garcia',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // Single-med-adult scenario
  static final singleMedAdult = <EdenMedicationStatement>[metformin500];

  // HIPAA isolation
  static final metforminPatient001 = metformin500;
  static final lisinoprilPatient002 = EdenMedicationStatement(
    id: 'med-mix-1',
    patientId: 'pt-002',
    drugName: 'Lisinopril',
    doseLabel: '10mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Khan',
  );
}

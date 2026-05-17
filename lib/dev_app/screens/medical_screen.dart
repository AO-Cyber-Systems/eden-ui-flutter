import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 013 (B-Medical clinical primitives).
///
/// TRD 013-01 creates this file with the VitalsRow section. TRDs 013-02
/// through 013-07 append additional Section(...) entries for each new
/// medical widget at their respective anchor placeholders below.
///
/// Anchor convention: each subsequent TRD inserts a new Section(...) above
/// the `// ── 013-NN anchor ──` comment line that the planner reserved for it.
class MedicalScreen extends StatelessWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B-Medical — Clinical Components')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const [
          Section(
            title: 'EdenVitalsRow — Clinical vital signs strip (013-01)',
            child: _VitalsRowDemo(),
          ),
          Section(
            title: 'EdenMedicationList — FHIR-shape medication list (013-02)',
            child: _MedicationListDemo(),
          ),
          Section(
            title: 'EdenLabResultTable — Compact clinical lab table (013-03)',
            child: _LabResultTableDemo(),
          ),
          Section(
            title: 'EdenProblemList — FHIR Condition list with ICD-10 (013-04)',
            child: _ProblemListDemo(),
          ),
          Section(
            title: 'EdenAllergyList — FHIR AllergyIntolerance + criticality banner (013-05)',
            child: _AllergyListDemo(),
          ),
          // ── 013-02 anchor (EdenMedicationList) ──
          // ── 013-03 anchor (EdenLabResultTable) ──
          // ── 013-04 anchor (EdenProblemList) ──
          // ── 013-05 anchor (EdenAllergyList) ──
          // ── 013-06 anchor (EdenSOAPNote) ──
          // ── 013-07 anchor (EdenChartTimeline) ──
          // ── 013-08 anchor (EdenPatientChartScaffold) ──
          // ── 013-09 anchor (EdenVisitEncounterScaffold) ──
        ],
      ),
    );
  }
}

class _VitalsRowDemo extends StatelessWidget {
  const _VitalsRowDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Healthy adult (all in-range)',
          child: EdenVitalsRow(vitals: _healthyAdult, showTimestamps: true),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Hypertensive elderly (BP crisis, HR elevated)',
          child: EdenVitalsRow(vitals: _hypertensiveElderly),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Febrile pediatric (Temp 102.4°F, HR 130)',
          child: EdenVitalsRow(vitals: _febrilePediatric),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'COPD flare (RR 28, SpO2 92%)',
          child: EdenVitalsRow(vitals: _copdFlare),
        ),
      ],
    );
  }
}

class _Subsection extends StatelessWidget {
  const _Subsection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        child,
      ],
    );
  }
}

// ────────────────────── catalog-only fixtures ──────────────────────
// Realistic-but-non-PII vitals. patientId values per scenario isolate
// each demo, exercising the HIPAA-isolation assert under real use.

final _healthyAdult = <EdenVitalSign>[
  const EdenVitalSign(
    patientId: 'demo-adult',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 128,
    diastolic: 82,
    priorValue: 126,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  ),
  EdenVitalSign(
    patientId: 'demo-adult',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 72,
    priorValue: 70,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 140,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  EdenVitalSign(
    patientId: 'demo-adult',
    kind: EdenVitalKind.temperature,
    unit: '°F',
    value: 98.6,
    referenceMin: 97.0,
    referenceMax: 99.5,
    criticalMin: 95.0,
    criticalMax: 103.0,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  EdenVitalSign(
    patientId: 'demo-adult',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 98,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  EdenVitalSign(
    patientId: 'demo-adult',
    kind: EdenVitalKind.respiratoryRate,
    unit: 'breaths/min',
    value: 16,
    referenceMin: 12,
    referenceMax: 20,
    criticalMin: 8,
    criticalMax: 30,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  EdenVitalSign(
    patientId: 'demo-adult',
    kind: EdenVitalKind.weight,
    unit: 'kg',
    value: 76,
    recordedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

const _hypertensiveElderly = <EdenVitalSign>[
  EdenVitalSign(
    patientId: 'demo-elderly',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 192,
    diastolic: 124,
    priorValue: 154,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  ),
  EdenVitalSign(
    patientId: 'demo-elderly',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 112,
    priorValue: 92,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 140,
  ),
  EdenVitalSign(
    patientId: 'demo-elderly',
    kind: EdenVitalKind.temperature,
    unit: '°F',
    value: 97.8,
    referenceMin: 97.0,
    referenceMax: 99.5,
  ),
  EdenVitalSign(
    patientId: 'demo-elderly',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 96,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  ),
  EdenVitalSign(
    patientId: 'demo-elderly',
    kind: EdenVitalKind.respiratoryRate,
    unit: 'breaths/min',
    value: 18,
    referenceMin: 12,
    referenceMax: 20,
  ),
  EdenVitalSign(
    patientId: 'demo-elderly',
    kind: EdenVitalKind.weight,
    unit: 'kg',
    value: 84,
  ),
];

const _febrilePediatric = <EdenVitalSign>[
  EdenVitalSign(
    patientId: 'demo-pediatric',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 100,
    diastolic: 64,
    referenceMin: 90,
    referenceMax: 140,
  ),
  EdenVitalSign(
    patientId: 'demo-pediatric',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 130,
    priorValue: 96,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 160,
  ),
  EdenVitalSign(
    patientId: 'demo-pediatric',
    kind: EdenVitalKind.temperature,
    unit: '°F',
    value: 102.4,
    priorValue: 99.8,
    referenceMin: 97.0,
    referenceMax: 99.5,
    criticalMin: 95.0,
    criticalMax: 104.5,
  ),
  EdenVitalSign(
    patientId: 'demo-pediatric',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 97,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  ),
  EdenVitalSign(
    patientId: 'demo-pediatric',
    kind: EdenVitalKind.respiratoryRate,
    unit: 'breaths/min',
    value: 24,
    referenceMin: 12,
    referenceMax: 20,
    criticalMax: 30,
  ),
  EdenVitalSign(
    patientId: 'demo-pediatric',
    kind: EdenVitalKind.weight,
    unit: 'kg',
    value: 22,
  ),
];

const _copdFlare = <EdenVitalSign>[
  EdenVitalSign(
    patientId: 'demo-copd',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 132,
    diastolic: 84,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  ),
  EdenVitalSign(
    patientId: 'demo-copd',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 108,
    priorValue: 88,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 140,
  ),
  EdenVitalSign(
    patientId: 'demo-copd',
    kind: EdenVitalKind.temperature,
    unit: '°F',
    value: 98.2,
    referenceMin: 97.0,
    referenceMax: 99.5,
  ),
  EdenVitalSign(
    patientId: 'demo-copd',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 92,
    priorValue: 96,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  ),
  EdenVitalSign(
    patientId: 'demo-copd',
    kind: EdenVitalKind.respiratoryRate,
    unit: 'breaths/min',
    value: 28,
    priorValue: 18,
    referenceMin: 12,
    referenceMax: 20,
    criticalMax: 30,
  ),
  EdenVitalSign(
    patientId: 'demo-copd',
    kind: EdenVitalKind.weight,
    unit: 'kg',
    value: 79,
  ),
];

// ────────────────────────── 013-02 demo ──────────────────────────

class _MedicationListDemo extends StatelessWidget {
  const _MedicationListDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'T2DM + HTN combo (3 active meds)',
          child: EdenMedicationList(medications: _t2dmCombo),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Polypharmacy elderly (warfarin + aspirin interaction)',
          child: EdenMedicationList(medications: _polypharmacyElderly),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Post-op pain regimen',
          child: EdenMedicationList(medications: _postOpPain),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Single-med adult (refill needed)',
          child: EdenMedicationList(medications: _refillNeeded),
        ),
      ],
    );
  }
}

final _t2dmCombo = <EdenMedicationStatement>[
  EdenMedicationStatement(
    id: 'demo-med-1',
    patientId: 'demo-pt-1',
    drugName: 'Metformin',
    doseLabel: '500mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Twice daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 3, 12),
  ),
  EdenMedicationStatement(
    id: 'demo-med-2',
    patientId: 'demo-pt-1',
    drugName: 'Lisinopril',
    doseLabel: '10mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 1, 8),
  ),
  EdenMedicationStatement(
    id: 'demo-med-3',
    patientId: 'demo-pt-1',
    drugName: 'Atorvastatin',
    doseLabel: '40mg',
    route: EdenMedicationRoute.oral,
    frequency: 'At bedtime',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2023, 11, 5),
  ),
];

final _polypharmacyElderly = <EdenMedicationStatement>[
  EdenMedicationStatement(
    id: 'demo-poly-1',
    patientId: 'demo-pt-2',
    drugName: 'Warfarin',
    doseLabel: '5mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2022, 6, 14),
  ),
  EdenMedicationStatement(
    id: 'demo-poly-2',
    patientId: 'demo-pt-2',
    drugName: 'Aspirin',
    doseLabel: '81mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2023, 2, 20),
    interactionWarning: 'Increased bleeding risk — monitor INR (warfarin)',
  ),
  EdenMedicationStatement(
    id: 'demo-poly-3',
    patientId: 'demo-pt-2',
    drugName: 'Levothyroxine',
    doseLabel: '75mcg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily, AM',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2020, 9, 3),
  ),
  EdenMedicationStatement(
    id: 'demo-poly-4',
    patientId: 'demo-pt-2',
    drugName: 'Amlodipine',
    doseLabel: '5mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Lee',
    startDate: DateTime(2023, 8, 1),
  ),
];

final _postOpPain = <EdenMedicationStatement>[
  EdenMedicationStatement(
    id: 'demo-pp-1',
    patientId: 'demo-pt-3',
    drugName: 'Oxycodone',
    doseLabel: '5mg',
    route: EdenMedicationRoute.oral,
    frequency: 'q6h PRN pain',
    prescriber: 'Dr. Garcia',
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    interactionWarning: 'Schedule II — monitor for misuse',
  ),
  EdenMedicationStatement(
    id: 'demo-pp-2',
    patientId: 'demo-pt-3',
    drugName: 'Acetaminophen',
    doseLabel: '650mg',
    route: EdenMedicationRoute.oral,
    frequency: 'q6h',
    prescriber: 'Dr. Garcia',
    startDate: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

final _refillNeeded = <EdenMedicationStatement>[
  EdenMedicationStatement(
    id: 'demo-r-1',
    patientId: 'demo-pt-4',
    drugName: 'Lisinopril',
    doseLabel: '10mg',
    route: EdenMedicationRoute.oral,
    frequency: 'Once daily',
    prescriber: 'Dr. Chen',
    startDate: DateTime(2024, 1, 8),
    needsRefill: true,
    refillsRemaining: 0,
  ),
];

// ────────────────────────── 013-03 demo ──────────────────────────

class _LabResultTableDemo extends StatelessWidget {
  const _LabResultTableDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Recent CBC + CMP (panel grouped)',
          child: EdenLabResultTable(
            results: _recentBasicLabs,
            groupByPanel: true,
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Abnormal lipid panel (flagged)',
          child: EdenLabResultTable(
            results: _abnormalLipid,
            groupByPanel: true,
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Critical-flagged glucose + potassium',
          child: EdenLabResultTable(
            results: _criticalFlagged,
          ),
        ),
      ],
    );
  }
}

final _recentBasicLabs = <EdenLabResult>[
  EdenLabResult(
    id: 'demo-lab-1',
    patientId: 'demo-labs',
    testName: 'White Blood Cells',
    testCode: 'WBC',
    value: 7.5,
    unit: 'k/uL',
    referenceMin: 4.5,
    referenceMax: 11.0,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17),
  ),
  EdenLabResult(
    id: 'demo-lab-2',
    patientId: 'demo-labs',
    testName: 'Hemoglobin',
    testCode: 'HGB',
    value: 14.2,
    unit: 'g/dL',
    referenceMin: 12.0,
    referenceMax: 16.0,
    panelName: 'CBC',
    trendValues: [13.8, 14.0, 14.1, 14.0],
    collectedAt: DateTime(2026, 5, 17),
  ),
  EdenLabResult(
    id: 'demo-lab-3',
    patientId: 'demo-labs',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 92,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    panelName: 'CMP',
    trendValues: [88, 90, 91, 89],
    collectedAt: DateTime(2026, 5, 17),
  ),
  EdenLabResult(
    id: 'demo-lab-4',
    patientId: 'demo-labs',
    testName: 'Creatinine',
    testCode: 'CR',
    value: 0.9,
    unit: 'mg/dL',
    referenceMin: 0.6,
    referenceMax: 1.3,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17),
  ),
];

final _abnormalLipid = <EdenLabResult>[
  EdenLabResult(
    id: 'demo-lipid-1',
    patientId: 'demo-lipid',
    testName: 'Total Cholesterol',
    testCode: 'TC',
    value: 245,
    unit: 'mg/dL',
    referenceMax: 200,
    flag: EdenLabFlag.high,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17),
  ),
  EdenLabResult(
    id: 'demo-lipid-2',
    patientId: 'demo-lipid',
    testName: 'LDL Cholesterol',
    testCode: 'LDL',
    value: 168,
    unit: 'mg/dL',
    referenceMax: 100,
    flag: EdenLabFlag.high,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17),
  ),
  EdenLabResult(
    id: 'demo-lipid-3',
    patientId: 'demo-lipid',
    testName: 'HDL Cholesterol',
    testCode: 'HDL',
    value: 52,
    unit: 'mg/dL',
    referenceMin: 40,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17),
  ),
];

final _criticalFlagged = <EdenLabResult>[
  EdenLabResult(
    id: 'demo-crit-1',
    patientId: 'demo-crit',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 420,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    criticalMax: 400,
    flag: EdenLabFlag.criticalHigh,
    collectedAt: DateTime(2026, 5, 17),
  ),
  EdenLabResult(
    id: 'demo-crit-2',
    patientId: 'demo-crit',
    testName: 'Potassium',
    testCode: 'K',
    value: 6.8,
    unit: 'mEq/L',
    referenceMin: 3.5,
    referenceMax: 5.0,
    criticalMax: 6.0,
    flag: EdenLabFlag.criticalHigh,
    collectedAt: DateTime(2026, 5, 17),
  ),
];

// ────────────────────────── 013-04 demo ──────────────────────────

class _ProblemListDemo extends StatelessWidget {
  const _ProblemListDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'T2DM + HTN combo (active chronic problems)',
          child: EdenProblemList(conditions: _polychronicCombo),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Single chronic (T2DM only)',
          child: EdenProblemList(conditions: _singleChronic),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Resolved post-surgical (showResolved=true)',
          child: EdenProblemList(
            conditions: _resolvedPostSurgical,
            showResolved: true,
          ),
        ),
      ],
    );
  }
}

final _polychronicCombo = <EdenCondition>[
  EdenCondition(
    id: 'demo-cond-1',
    patientId: 'demo-prob',
    code: 'E11.9',
    codeSystem: 'ICD-10-CM',
    description: 'Type 2 diabetes mellitus without complications',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2022, 8, 14),
    diagnosedBy: 'Dr. Chen',
  ),
  EdenCondition(
    id: 'demo-cond-2',
    patientId: 'demo-prob',
    code: 'I10',
    codeSystem: 'ICD-10-CM',
    description: 'Essential (primary) hypertension',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2021, 3, 2),
    diagnosedBy: 'Dr. Chen',
  ),
  EdenCondition(
    id: 'demo-cond-3',
    patientId: 'demo-prob',
    code: 'E78.5',
    codeSystem: 'ICD-10-CM',
    description: 'Hyperlipidemia, unspecified',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2023, 5, 10),
    diagnosedBy: 'Dr. Chen',
  ),
];

final _singleChronic = <EdenCondition>[
  EdenCondition(
    id: 'demo-sc-1',
    patientId: 'demo-sc',
    code: 'E11.9',
    codeSystem: 'ICD-10-CM',
    description: 'Type 2 diabetes mellitus without complications',
    status: EdenConditionStatus.active,
    onsetDate: DateTime(2022, 8, 14),
    diagnosedBy: 'Dr. Chen',
  ),
];

final _resolvedPostSurgical = <EdenCondition>[
  EdenCondition(
    id: 'demo-rps-1',
    patientId: 'demo-rps',
    code: 'K35.80',
    codeSystem: 'ICD-10-CM',
    description: 'Acute appendicitis',
    status: EdenConditionStatus.resolved,
    onsetDate: DateTime(2019, 6, 3),
    resolvedDate: DateTime(2019, 6, 5),
    diagnosedBy: 'Dr. Garcia',
  ),
];

// ────────────────────────── 013-05 demo ──────────────────────────

class _AllergyListDemo extends StatelessWidget {
  const _AllergyListDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'PCN anaphylaxis (high-criticality banner active)',
          child: EdenAllergyList(allergies: _pcnAnaphylaxis),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Multi-allergy elderly (3 high-criticality, 1 low)',
          child: EdenAllergyList(allergies: _multiAllergy),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'NKDA empty state',
          child: EdenAllergyList(allergies: const []),
        ),
      ],
    );
  }
}

final _pcnAnaphylaxis = <EdenAllergyIntolerance>[
  EdenAllergyIntolerance(
    id: 'demo-all-1',
    patientId: 'demo-all-pt-1',
    allergen: 'Penicillin',
    type: EdenAllergenType.medication,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.severe,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Chen',
  ),
];

final _multiAllergy = <EdenAllergyIntolerance>[
  EdenAllergyIntolerance(
    id: 'demo-mall-1',
    patientId: 'demo-mall-pt',
    allergen: 'Penicillin',
    type: EdenAllergenType.medication,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.severe,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Lee',
  ),
  EdenAllergyIntolerance(
    id: 'demo-mall-2',
    patientId: 'demo-mall-pt',
    allergen: 'Codeine',
    type: EdenAllergenType.medication,
    reaction: 'GI upset',
    severity: EdenAllergySeverity.mild,
    criticality: EdenAllergyCriticality.low,
    verifiedBy: 'Patient-reported',
  ),
  EdenAllergyIntolerance(
    id: 'demo-mall-3',
    patientId: 'demo-mall-pt',
    allergen: 'Latex',
    type: EdenAllergenType.environmental,
    reaction: 'Contact dermatitis',
    severity: EdenAllergySeverity.severe,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Lee',
  ),
  EdenAllergyIntolerance(
    id: 'demo-mall-4',
    patientId: 'demo-mall-pt',
    allergen: 'Peanuts',
    type: EdenAllergenType.food,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.lifeThreatening,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Lee',
  ),
];

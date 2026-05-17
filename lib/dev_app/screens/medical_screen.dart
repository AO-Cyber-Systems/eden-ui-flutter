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
          Section(
            title: 'EdenSOAPNote — SOAP composer + viewer (013-06)',
            child: _SoapNoteDemo(),
          ),
          Section(
            title: 'EdenChartTimeline — Clinical history timeline (013-07)',
            child: _ChartTimelineDemo(),
          ),
          Section(
            title: 'EdenPatientChartScaffold — 3-pane chart shell (013-08)',
            child: _PatientChartScaffoldDemo(),
          ),
          Section(
            title: 'EdenVisitEncounterScaffold — during-visit workflow (013-09)',
            child: _VisitEncounterDemo(),
          ),
          Section(
            title: 'EdenAVSGenerator — patient-facing After Visit Summary (017-01)',
            child: _AvsGeneratorDemo(),
          ),
          Section(
            title: 'EdenInsuranceCard — front/back capture + extracted data (017-02)',
            child: _InsuranceCardDemo(),
          ),
          Section(
            title: 'EdenAppointmentStatusFlow — 8-state appointment lifecycle (017-03)',
            child: _AppointmentStatusFlowDemo(),
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

// ────────────────────────── 013-06 demo ──────────────────────────

class _SoapNoteDemo extends StatelessWidget {
  const _SoapNoteDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Empty compose mode',
          child: EdenSOAPNote(
            data: EdenSoapNoteData(patientId: 'demo-soap-1'),
            patientId: 'demo-soap-1',
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Partial draft compose mode',
          child: EdenSOAPNote(
            data: EdenSoapNoteData(
              patientId: 'demo-soap-2',
              subjective:
                  '52yo F here for annual physical, no complaints. ROS negative.',
              objective:
                  'BP 124/78, HR 68, BMI 23. Exam: well-appearing, NAD.',
            ),
            patientId: 'demo-soap-2',
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Signed view mode (full content)',
          child: EdenSOAPNote(
            data: EdenSoapNoteData(
              patientId: 'demo-soap-3',
              subjective:
                  '52yo F here for annual physical, no complaints. ROS negative.',
              objective:
                  'BP 124/78, HR 68, BMI 23. Exam: well-appearing, NAD. Lungs CTA. Heart RRR. Abdomen soft.',
              assessment:
                  'Z00.00 — Encounter for general adult medical exam without abnormal findings.',
              plan:
                  '1. Continue current meds. 2. Mammogram due — order placed. 3. RTC 12mo.',
              signedBy: 'Dr. Chen (NPI 1234567890)',
              signedAt: DateTime(2026, 5, 17, 14, 32),
            ),
            patientId: 'demo-soap-3',
            mode: EdenSoapMode.view,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── 013-07 demo ──────────────────────────

class _ChartTimelineDemo extends StatelessWidget {
  const _ChartTimelineDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Recent 30-day timeline',
          child: EdenChartTimeline(events: _recent30Day),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: '5-year compressed timeline (quarterly headers for >12mo)',
          child: EdenChartTimeline(events: _fiveYearTimeline),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Single encounter detail',
          child: EdenChartTimeline(events: _singleEncounter),
        ),
      ],
    );
  }
}

final _recent30Day = <EdenChartTimelineEvent>[
  EdenChartTimelineEvent(
    id: 'demo-tl-1',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.encounter,
    title: 'Annual Physical',
    subtitle: 'Z00.00 routine',
    occurredAt: DateTime.now(),
    provider: 'Dr. Chen',
  ),
  EdenChartTimelineEvent(
    id: 'demo-tl-2',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.lab,
    title: 'CBC + CMP collected',
    subtitle: '12 results, 1 H flag',
    occurredAt: DateTime.now().subtract(const Duration(days: 1)),
    provider: 'Lab',
  ),
  EdenChartTimelineEvent(
    id: 'demo-tl-3',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.encounter,
    title: 'ER Visit — Chest Pain',
    subtitle: 'Ruled out STEMI',
    occurredAt: DateTime.now().subtract(const Duration(days: 14)),
    severity: EdenChartEventSeverity.caution,
    provider: 'ER Provider',
  ),
];

final _fiveYearTimeline = <EdenChartTimelineEvent>[
  ..._recent30Day,
  EdenChartTimelineEvent(
    id: 'demo-tl-5y-1',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.medication,
    title: 'Started Lisinopril 10mg',
    occurredAt: DateTime(2024, 1, 8),
    provider: 'Dr. Chen',
  ),
  EdenChartTimelineEvent(
    id: 'demo-tl-5y-2',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.lab,
    title: 'A1c 7.4',
    occurredAt: DateTime(2023, 5, 10),
    severity: EdenChartEventSeverity.caution,
    provider: 'Lab',
  ),
  EdenChartTimelineEvent(
    id: 'demo-tl-5y-3',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.problem,
    title: 'Diagnosed T2DM',
    subtitle: 'E11.9',
    occurredAt: DateTime(2022, 8, 14),
    provider: 'Dr. Chen',
  ),
  EdenChartTimelineEvent(
    id: 'demo-tl-5y-4',
    patientId: 'demo-tl',
    category: EdenChartEventCategory.encounter,
    title: 'Appendectomy',
    subtitle: 'Laparoscopic, POD1 d/c',
    occurredAt: DateTime(2019, 6, 5),
    severity: EdenChartEventSeverity.resolved,
    provider: 'Dr. Garcia',
  ),
];

final _singleEncounter = <EdenChartTimelineEvent>[
  EdenChartTimelineEvent(
    id: 'demo-se-1',
    patientId: 'demo-se',
    category: EdenChartEventCategory.encounter,
    title: 'Annual Physical',
    subtitle: 'Z00.00 — routine annual exam',
    occurredAt: DateTime.now(),
    provider: 'Dr. Chen',
  ),
];

// ────────────────────────── 013-08 demo ──────────────────────────

class _PatientChartScaffoldDemo extends StatelessWidget {
  const _PatientChartScaffoldDemo();

  @override
  Widget build(BuildContext context) {
    final data = _polychronicScaffoldData();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Expanded tier (1200×800) — three-pane layout',
          child: SizedBox(
            width: 1200,
            height: 800,
            child: EdenPatientChartScaffold(
              data: data,
              patientId: data.patientId,
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'Compact tier (390×800) — collapsed to tabs',
          child: SizedBox(
            width: 390,
            height: 800,
            child: EdenPatientChartScaffold(
              data: data,
              patientId: data.patientId,
            ),
          ),
        ),
      ],
    );
  }
}

EdenPatientChartData _polychronicScaffoldData() {
  const pid = 'demo-chart';
  final demographics = EdenPatientDemographics(
    patientId: pid,
    name: 'Jane Doe',
    mrn: '123456',
    dob: DateTime(1979, 3, 4),
    sex: 'F',
    payer: 'Aetna',
    pcp: 'Dr. Chen',
  );
  final vitals = <EdenVitalSign>[
    EdenVitalSign(
      patientId: pid,
      kind: EdenVitalKind.bloodPressure,
      unit: 'mmHg',
      systolic: 128,
      diastolic: 82,
      referenceMin: 90,
      referenceMax: 140,
    ),
    EdenVitalSign(
      patientId: pid,
      kind: EdenVitalKind.heartRate,
      unit: 'bpm',
      value: 72,
      referenceMin: 60,
      referenceMax: 100,
    ),
    EdenVitalSign(
      patientId: pid,
      kind: EdenVitalKind.temperature,
      unit: '°F',
      value: 98.6,
      referenceMin: 97.0,
      referenceMax: 99.5,
    ),
    EdenVitalSign(
      patientId: pid,
      kind: EdenVitalKind.spo2,
      unit: '%',
      value: 98,
      referenceMin: 95,
      referenceMax: 100,
      criticalMin: 90,
    ),
  ];
  final meds = <EdenMedicationStatement>[
    EdenMedicationStatement(
      id: 'sc-med-1',
      patientId: pid,
      drugName: 'Metformin',
      doseLabel: '500mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Twice daily',
      prescriber: 'Dr. Chen',
      startDate: DateTime(2022, 8, 14),
    ),
  ];
  final problems = <EdenCondition>[
    EdenCondition(
      id: 'sc-cond-1',
      patientId: pid,
      code: 'E11.9',
      codeSystem: 'ICD-10-CM',
      description: 'Type 2 diabetes mellitus without complications',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2022, 8, 14),
      diagnosedBy: 'Dr. Chen',
    ),
  ];
  final allergies = <EdenAllergyIntolerance>[
    EdenAllergyIntolerance(
      id: 'sc-all-1',
      patientId: pid,
      allergen: 'Penicillin',
      type: EdenAllergenType.medication,
      reaction: 'Anaphylaxis',
      severity: EdenAllergySeverity.severe,
      criticality: EdenAllergyCriticality.high,
      verifiedBy: 'Dr. Chen',
    ),
  ];
  final labs = <EdenLabResult>[
    EdenLabResult(
      id: 'sc-lab-1',
      patientId: pid,
      testName: 'Hemoglobin',
      testCode: 'HGB',
      value: 14.2,
      unit: 'g/dL',
      referenceMin: 12.0,
      referenceMax: 16.0,
      panelName: 'CBC',
      collectedAt: DateTime(2026, 5, 17),
    ),
  ];
  final notes = <EdenSoapNoteData>[
    EdenSoapNoteData(
      patientId: pid,
      subjective: 'Annual physical, no complaints.',
      objective: 'BP 128/82, HR 72, BMI 23.',
      assessment: 'Z00.00 annual physical.',
      plan: '1. Continue meds. 2. RTC 12mo.',
      signedBy: 'Dr. Chen',
    ),
  ];
  final timeline = <EdenChartTimelineEvent>[
    EdenChartTimelineEvent(
      id: 'sc-evt-1',
      patientId: pid,
      category: EdenChartEventCategory.encounter,
      title: 'Annual Physical',
      occurredAt: DateTime.now(),
      provider: 'Dr. Chen',
    ),
  ];
  final alerts = const <EdenBlockingAlertData>[
    EdenBlockingAlertData(
      task: 'Drug-drug check',
      context: 'Med review',
      reason: 'Verify INR before warfarin titration',
    ),
  ];
  final audit = <EdenAuditLogEntry>[
    EdenAuditLogEntry(
      id: 'sc-aud-1',
      timestamp: DateTime(2026, 5, 17, 8, 30),
      actor: 'dr.chen@example.com',
      action: 'VIEW_CHART',
      target: 'Patient $pid',
    ),
  ];
  return EdenPatientChartData(
    patientId: pid,
    demographics: demographics,
    vitals: vitals,
    medications: meds,
    problems: problems,
    allergies: allergies,
    labs: labs,
    notes: notes,
    timelineEvents: timeline,
    blockingAlerts: alerts,
    auditEvents: audit,
  );
}

// ────────────────────────── 013-09 demo ──────────────────────────

class _VisitEncounterDemo extends StatelessWidget {
  const _VisitEncounterDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Annual physical — empty (just started)',
          child: SizedBox(
            width: 1200,
            height: 600,
            child: EdenVisitEncounterScaffold(
              data: EdenVisitEncounterData(
                patientId: 'demo-visit-1',
                encounterId: 'enc-demo-1',
                encounterDate: DateTime(2026, 5, 17, 10, 30),
                provider: 'Dr. Chen',
                encounterType: 'Annual Physical',
                vitals: [
                  EdenVitalSign(
                    patientId: 'demo-visit-1',
                    kind: EdenVitalKind.bloodPressure,
                    unit: 'mmHg',
                    systolic: 124,
                    diastolic: 78,
                    referenceMin: 90,
                    referenceMax: 140,
                  ),
                ],
              ),
              patientId: 'demo-visit-1',
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        _Subsection(
          label: 'URI visit — mid-visit with PCN-allergy alert',
          child: SizedBox(
            width: 1200,
            height: 700,
            child: EdenVisitEncounterScaffold(
              data: EdenVisitEncounterData(
                patientId: 'demo-visit-2',
                encounterId: 'enc-demo-2',
                encounterDate: DateTime(2026, 5, 17, 14, 0),
                provider: 'Dr. Chen',
                encounterType: 'URI Visit',
                chiefComplaint:
                    'Cough × 5d, sore throat, low-grade fever to 100.2°F.',
                vitals: [
                  EdenVitalSign(
                    patientId: 'demo-visit-2',
                    kind: EdenVitalKind.temperature,
                    unit: '°F',
                    value: 99.4,
                    referenceMin: 97.0,
                    referenceMax: 99.5,
                  ),
                ],
                soapNote: const EdenSoapNoteData(
                  patientId: 'demo-visit-2',
                  subjective:
                      '38yo M, 4-day cough + sore throat. No SOB.',
                ),
                blockingAlerts: const [
                  EdenBlockingAlertData(
                    task: 'Penicillin allergy',
                    context: 'Patient PHI',
                    reason:
                        'Anaphylaxis to PCN documented — do not prescribe Augmentin',
                  ),
                ],
              ),
              patientId: 'demo-visit-2',
              initialStep: EdenVisitStep.soap,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── 017-01 demo ──────────────────────────

class _AvsGeneratorDemo extends StatelessWidget {
  const _AvsGeneratorDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Behavioral-health follow-up (compact, all callbacks wired)',
          child: EdenAVSGenerator(
            document: _avsBehavioralHealthFollowUp,
            onPrintRequested: () => debugPrint('AVS: Print tapped'),
            onEmailRequested: (e) => debugPrint('AVS: Email tapped — ${e.format}'),
            onPortalShareRequested: (e) =>
                debugPrint('AVS: Portal share tapped — ${e.format}'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Cash-pay new-patient eval (compact, only Print callback — '
              'demonstrates callback-gating)',
          child: EdenAVSGenerator(
            document: _avsCashPayNewPatientEval,
            onPrintRequested: () => debugPrint('AVS: Print tapped'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Concierge annual physical (printFriendly layout, all callbacks)',
          child: EdenAVSGenerator(
            document: _avsConciergeAnnualPhysical,
            layout: EdenAvsLayout.printFriendly,
            onPrintRequested: () => debugPrint('AVS: Print tapped'),
            onEmailRequested: (e) => debugPrint('AVS: Email tapped — ${e.format}'),
            onPortalShareRequested: (e) =>
                debugPrint('AVS: Portal share tapped — ${e.format}'),
          ),
        ),
      ],
    );
  }
}

// Inline demo fixtures for catalog use (NOT shared with test fixtures —
// dev_app/ must not import test/).
final _avsBehavioralHealthFollowUp = EdenAvsDocument(
  patientId: 'demo-avs-alpha',
  patientDisplayName: 'Alex Alpha',
  encounterDate: DateTime(2026, 5, 17, 10, 30),
  providerName: 'Dr. Jane Smith',
  providerCredentials: 'PsyD',
  facilityName: 'Eden Behavioral Health Center',
  visitReason: 'Anxiety follow-up',
  soapData: const EdenSoapNoteData(
    patientId: 'demo-avs-alpha',
    subjective:
        'Patient reports improvement in anxiety since starting sertraline. '
        'GAD-7 score down from 14 to 8.',
    objective: 'Affect brighter. GAD-7 score 8 (mild).',
    assessment: 'F41.1 — Generalized anxiety disorder, improving on sertraline.',
    plan: 'Continue sertraline 50mg. Continue weekly CBT. RTC 4 weeks.',
  ),
  medications: [
    EdenMedicationStatement(
      id: 'demo-med-001',
      patientId: 'demo-avs-alpha',
      drugName: 'Sertraline',
      doseLabel: '50mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily, morning',
      prescriber: 'Dr. Jane Smith',
      status: EdenMedicationStatus.active,
    ),
  ],
  problems: [
    EdenCondition(
      id: 'demo-cond-001',
      patientId: 'demo-avs-alpha',
      code: 'F41.1',
      codeSystem: 'ICD-10-CM',
      description: 'Generalized anxiety disorder',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2025, 11, 1),
      diagnosedBy: 'Dr. Jane Smith',
    ),
  ],
  followUpInstructions:
      'Continue sertraline 50mg daily. Follow up in 4 weeks for medication review.',
  nextAppointmentAt: DateTime(2026, 6, 14, 10, 30),
);

final _avsCashPayNewPatientEval = EdenAvsDocument(
  patientId: 'demo-avs-bravo',
  patientDisplayName: 'Blake Bravo',
  encounterDate: DateTime(2026, 5, 17, 13, 0),
  providerName: 'Dr. Maya Patel',
  providerCredentials: 'ND',
  facilityName: 'Eden Wellness Clinic',
  visitReason: 'Initial wellness consult',
  soapData: const EdenSoapNoteData(
    patientId: 'demo-avs-bravo',
    subjective: '34yo presenting with persistent fatigue x 4 months.',
    objective: 'BP 118/72, HR 68, BMI 22.1. Exam unremarkable.',
    assessment: 'R53.83 — Other fatigue. Differential includes anemia, hypothyroidism.',
    plan: 'CBC, CMP, TSH, vitamin D, ferritin. RTC for lab review in 2 weeks.',
  ),
  medications: const [],
  problems: [
    EdenCondition(
      id: 'demo-cond-002',
      patientId: 'demo-avs-bravo',
      code: 'R53.83',
      codeSystem: 'ICD-10-CM',
      description: 'Other fatigue',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2026, 1, 15),
      diagnosedBy: 'Dr. Maya Patel',
    ),
  ],
  followUpInstructions:
      'Lab orders sent to your portal. Schedule labs within the next week.',
);

final _avsConciergeAnnualPhysical = EdenAvsDocument(
  patientId: 'demo-avs-charlie',
  patientDisplayName: 'Casey Charlie',
  encounterDate: DateTime(2026, 5, 17, 8, 0),
  providerName: 'Dr. Robert Kim',
  providerCredentials: 'MD',
  facilityName: 'Eden Concierge Health',
  visitReason: 'Annual physical',
  soapData: const EdenSoapNoteData(
    patientId: 'demo-avs-charlie',
    subjective: '58yo M here for annual physical. No new complaints.',
    objective: 'BP 128/78. HR 72. Full ROS negative. Exam NAD.',
    assessment: 'Hyperlipidemia controlled. Hypertension well-controlled.',
    plan: 'Continue atorvastatin + lisinopril. Repeat lipid panel in 6 months.',
  ),
  medications: [
    EdenMedicationStatement(
      id: 'demo-med-003',
      patientId: 'demo-avs-charlie',
      drugName: 'Atorvastatin',
      doseLabel: '40mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily, evening',
      status: EdenMedicationStatus.active,
    ),
    EdenMedicationStatement(
      id: 'demo-med-004',
      patientId: 'demo-avs-charlie',
      drugName: 'Lisinopril',
      doseLabel: '10mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily, morning',
      status: EdenMedicationStatus.active,
    ),
  ],
  problems: [
    EdenCondition(
      id: 'demo-cond-003',
      patientId: 'demo-avs-charlie',
      code: 'E78.5',
      codeSystem: 'ICD-10-CM',
      description: 'Hyperlipidemia, unspecified',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2024, 6, 1),
    ),
    EdenCondition(
      id: 'demo-cond-004',
      patientId: 'demo-avs-charlie',
      code: 'I10',
      codeSystem: 'ICD-10-CM',
      description: 'Essential (primary) hypertension',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2023, 9, 12),
    ),
  ],
  followUpInstructions:
      'Continue current medications. Annual physical scheduled in 12 months.',
  nextAppointmentAt: DateTime(2027, 5, 17, 8, 0),
);

// ────────────────────────── 017-02 demo ──────────────────────────

class _InsuranceCardDemo extends StatelessWidget {
  const _InsuranceCardDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Primary Aetna PPO + Secondary BCBS HDHP '
              '(priorityRank visual discrimination)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EdenInsuranceCard(
                policy: _demoPrimaryAetnaPpo,
                onEditRequested: (p) =>
                    debugPrint('Insurance: Edit tapped for ${p.id}'),
                onReplaceImageRequested: (p) =>
                    debugPrint('Insurance: Replace image for ${p.id}'),
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenInsuranceCard(
                policy: _demoSecondaryBcbsHdhp,
                onReplaceImageRequested: (p) =>
                    debugPrint('Insurance: Replace image for ${p.id}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Medicare Traditional '
              '(single-sided card — empty back placeholder visible)',
          child: EdenInsuranceCard(
            policy: _demoMedicareTraditional,
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Expired HDHP (planTerminationDate=2020 → expired banner)',
          child: EdenInsuranceCard(
            policy: _demoExpiredHdhp,
            now: DateTime(2026, 5, 17),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Cross-vertical reuse: trades CDL driver license '
              '(planType=other + customPlanTypeLabel override)',
          child: EdenInsuranceCard(
            policy: _demoCrossVerticalCdl,
            now: DateTime(2026, 5, 17),
          ),
        ),
      ],
    );
  }
}

// Inline demo policies for catalog use (NOT shared with test fixtures).
const _demoPrimaryAetnaPpo = EdenInsurancePolicy(
  id: 'demo-policy-aetna-001',
  patientId: 'demo-policy-alpha',
  planName: 'Aetna Choice POS II',
  planType: EdenInsurancePlanType.ppo,
  payerId: '60054',
  memberId: 'W123456789',
  groupNumber: '12345-ABC',
  priorityRank: EdenInsurancePriority.primary,
  subscriberName: 'Alex Alpha',
  subscriberRelation: EdenSubscriberRelation.self,
  frontImageUrl: 'https://placehold.co/640x400/0066cc/ffffff/png?text=Aetna+Front',
  backImageUrl: 'https://placehold.co/640x400/0066cc/ffffff/png?text=Aetna+Back',
);

const _demoSecondaryBcbsHdhp = EdenInsurancePolicy(
  id: 'demo-policy-bcbs-001',
  patientId: 'demo-policy-alpha',
  planName: 'BCBS HDHP Silver',
  planType: EdenInsurancePlanType.hdhp,
  payerId: '00510',
  memberId: 'ZBC987654',
  priorityRank: EdenInsurancePriority.secondary,
  subscriberName: 'Beta Spouse',
  subscriberRelation: EdenSubscriberRelation.spouse,
);

const _demoMedicareTraditional = EdenInsurancePolicy(
  id: 'demo-policy-medicare-001',
  patientId: 'demo-policy-bravo',
  planName: 'Medicare Part B',
  planType: EdenInsurancePlanType.medicare,
  payerId: 'MEDICARE',
  memberId: '1AB2-CD3-EF45',
  priorityRank: EdenInsurancePriority.primary,
  subscriberName: 'Brett Bravo',
  subscriberRelation: EdenSubscriberRelation.self,
  frontImageUrl: 'https://placehold.co/640x400/1976d2/ffffff/png?text=Medicare+Front',
);

final _demoExpiredHdhp = EdenInsurancePolicy(
  id: 'demo-policy-expired-001',
  patientId: 'demo-policy-charlie',
  planName: 'Anthem HDHP Bronze',
  planType: EdenInsurancePlanType.hdhp,
  payerId: '11111',
  memberId: 'XYZ112233',
  planEffectiveDate: DateTime(2019, 1, 1),
  planTerminationDate: DateTime(2020, 1, 1),
  priorityRank: EdenInsurancePriority.primary,
  subscriberName: 'Casey Charlie',
  subscriberRelation: EdenSubscriberRelation.self,
);

final _demoCrossVerticalCdl = EdenInsurancePolicy(
  id: 'demo-policy-trades-cdl-001',
  patientId: 'demo-policy-delta',
  planName: 'State of Texas DPS',
  planType: EdenInsurancePlanType.other,
  customPlanTypeLabel: 'Driver License — CDL Class A',
  payerId: 'TX-DPS',
  memberId: '12345678',
  planEffectiveDate: DateTime(2024, 6, 1),
  planTerminationDate: DateTime(2028, 6, 1),
  priorityRank: EdenInsurancePriority.primary,
  subscriberName: 'Drew Delta',
  subscriberRelation: EdenSubscriberRelation.self,
  frontImageUrl: 'https://placehold.co/640x400/2e7d32/ffffff/png?text=CDL+Class+A',
  verifiedAt: DateTime(2024, 7, 1),
);

// ────────────────────────── 017-03 demo ──────────────────────────

class _AppointmentStatusFlowDemo extends StatelessWidget {
  const _AppointmentStatusFlowDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subsection(
          label: 'Scheduled (future) — step 0 current; advance + terminal menu wired',
          child: EdenAppointmentStatusFlow(
            event: _demoScheduledFuture,
            now: DateTime(2026, 5, 17, 9, 0),
            onStatusAdvance: (s) =>
                debugPrint('Appt: advance to $s'),
            onTerminalStateRequest: (s) =>
                debugPrint('Appt: mark terminal as $s'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Arrived (waiting) — 32 minutes late, demonstrates late-arrival chip',
          child: EdenAppointmentStatusFlow(
            event: _demoArrivedLate,
            // 32min past scheduledFor 10:00 → triggers the >15min warning.
            now: DateTime(2026, 5, 17, 10, 32),
            onStatusAdvance: (s) =>
                debugPrint('Appt: advance to $s'),
            onTerminalStateRequest: (s) =>
                debugPrint('Appt: mark terminal as $s'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'In Room — step 3 current',
          child: EdenAppointmentStatusFlow(
            event: _demoInRoom,
            now: DateTime(2026, 5, 17, 11, 30),
            onStatusAdvance: (s) =>
                debugPrint('Appt: advance to $s'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Completed — terminal-success; advance + terminal menu hidden',
          child: EdenAppointmentStatusFlow(
            event: _demoCompleted,
            now: DateTime(2026, 5, 18),
            onStatusAdvance: (s) =>
                debugPrint('Appt: advance to $s'),
            onTerminalStateRequest: (s) =>
                debugPrint('Appt: mark terminal as $s'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'No-Show + Late Cancel + Cancelled — three terminal badges',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EdenAppointmentStatusFlow(
                event: _demoNoShow,
                now: DateTime(2026, 5, 17),
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenAppointmentStatusFlow(
                event: _demoLateCancel,
                now: DateTime(2026, 5, 18),
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenAppointmentStatusFlow(
                event: _demoCancelled,
                now: DateTime(2026, 5, 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),
        _Subsection(
          label: 'Cross-vertical: trades job ticket lifecycle '
              '(v1 ships medical-labeled; v2 will add stateLabels override)',
          child: EdenAppointmentStatusFlow(
            event: _demoTradesJobTicket,
            now: DateTime(2026, 5, 17, 11, 5),
          ),
        ),
      ],
    );
  }
}

// Inline catalog fixtures (no test/ imports from dev_app/).
final _demoScheduledFuture = EdenAppointmentEvent(
  id: 'demo-evt-001',
  patientId: 'demo-appt-alpha',
  appointmentId: 'demo-appt-001',
  scheduledFor: DateTime(2026, 6, 15, 14, 0),
  currentStatus: EdenAppointmentStatus.scheduled,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 17, 9, 0),
      actorName: 'Front desk',
    ),
  ],
  providerName: 'Dr. Smith, MD',
  locationName: 'Main Clinic Suite 200',
  visitType: 'Annual physical',
);

final _demoArrivedLate = EdenAppointmentEvent(
  id: 'demo-evt-002',
  patientId: 'demo-appt-alpha',
  appointmentId: 'demo-appt-002',
  scheduledFor: DateTime(2026, 5, 17, 10, 0),
  currentStatus: EdenAppointmentStatus.arrived,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 10, 9, 0),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.confirmed,
      timestamp: DateTime(2026, 5, 15, 18, 30),
      actorName: 'Patient self-service',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.arrived,
      timestamp: DateTime(2026, 5, 17, 10, 32),
      actorName: 'Front desk',
    ),
  ],
  providerName: 'Dr. Lee, MD',
  locationName: 'Main Clinic Suite 200',
  visitType: 'Annual physical',
);

final _demoInRoom = EdenAppointmentEvent(
  id: 'demo-evt-003',
  patientId: 'demo-appt-alpha',
  appointmentId: 'demo-appt-003',
  scheduledFor: DateTime(2026, 5, 17, 11, 0),
  currentStatus: EdenAppointmentStatus.inRoom,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 10, 9, 0),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.confirmed,
      timestamp: DateTime(2026, 5, 15, 18, 30),
      actorName: 'Patient self-service',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.arrived,
      timestamp: DateTime(2026, 5, 17, 10, 55),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.inRoom,
      timestamp: DateTime(2026, 5, 17, 11, 8),
      actorName: 'Front desk',
    ),
  ],
  providerName: 'Dr. Lee, MD',
  locationName: 'Main Clinic Suite 200',
  visitType: 'Annual physical',
);

final _demoCompleted = EdenAppointmentEvent(
  id: 'demo-evt-004',
  patientId: 'demo-appt-alpha',
  appointmentId: 'demo-appt-004',
  scheduledFor: DateTime(2026, 5, 16, 14, 0),
  currentStatus: EdenAppointmentStatus.completed,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 9, 9, 0),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.completed,
      timestamp: DateTime(2026, 5, 16, 14, 52),
      actorName: 'Dr. Smith',
      notes: 'Visit complete; follow-up in 12 months.',
    ),
  ],
  providerName: 'Dr. Smith, MD',
  locationName: 'Main Clinic Suite 200',
  visitType: 'Annual physical',
);

final _demoNoShow = EdenAppointmentEvent(
  id: 'demo-evt-005',
  patientId: 'demo-appt-bravo',
  appointmentId: 'demo-appt-005',
  scheduledFor: DateTime(2026, 5, 16, 9, 0),
  currentStatus: EdenAppointmentStatus.noShow,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 5, 11, 0),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.noShow,
      timestamp: DateTime(2026, 5, 16, 9, 30),
      actorName: 'Front desk',
      notes: 'Patient did not arrive, no contact.',
    ),
  ],
  providerName: 'Dr. Smith, MD',
  locationName: 'Main Clinic Suite 200',
  visitType: 'Behavioral health follow-up',
);

final _demoLateCancel = EdenAppointmentEvent(
  id: 'demo-evt-006',
  patientId: 'demo-appt-charlie',
  appointmentId: 'demo-appt-006',
  scheduledFor: DateTime(2026, 5, 18, 10, 0),
  currentStatus: EdenAppointmentStatus.lateCancel,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 11, 9, 0),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.lateCancel,
      timestamp: DateTime(2026, 5, 17, 21, 0),
      actorName: 'Patient self-service',
      notes: 'Cancelled via portal 4h before appointment.',
    ),
  ],
  providerName: 'Dr. Patel, ND',
  locationName: 'Wellness Clinic',
  visitType: 'Initial wellness consult',
);

final _demoCancelled = EdenAppointmentEvent(
  id: 'demo-evt-007',
  patientId: 'demo-appt-charlie',
  appointmentId: 'demo-appt-007',
  scheduledFor: DateTime(2026, 5, 22, 14, 0),
  currentStatus: EdenAppointmentStatus.cancelled,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 10, 9, 0),
      actorName: 'Front desk',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.cancelled,
      timestamp: DateTime(2026, 5, 15, 11, 0),
      actorName: 'Patient self-service',
      notes: 'Cancelled 5d in advance.',
    ),
  ],
  providerName: 'Dr. Patel, ND',
  locationName: 'Wellness Clinic',
  visitType: 'Initial wellness consult',
);

final _demoTradesJobTicket = EdenAppointmentEvent(
  id: 'demo-evt-trades-001',
  patientId: 'demo-job-12345',
  appointmentId: 'demo-job-12345',
  scheduledFor: DateTime(2026, 5, 17, 11, 0),
  currentStatus: EdenAppointmentStatus.arrived,
  statusHistory: [
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.scheduled,
      timestamp: DateTime(2026, 5, 15, 9, 0),
      actorName: 'Dispatch',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.confirmed,
      timestamp: DateTime(2026, 5, 16, 17, 0),
      actorName: 'Customer self-service',
    ),
    EdenAppointmentStatusEntry(
      status: EdenAppointmentStatus.arrived,
      timestamp: DateTime(2026, 5, 17, 11, 5),
      actorName: 'Tech Bob',
      notes: 'On site at customer location.',
    ),
  ],
  providerName: 'Tech Bob',
  locationName: '123 Main St',
  visitType: 'HVAC install',
);

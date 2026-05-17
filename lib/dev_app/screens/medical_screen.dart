import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../../src/widgets/eden_vitals_row.dart';
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

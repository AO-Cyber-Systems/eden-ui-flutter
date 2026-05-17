// Do NOT regenerate via LLM — hand-built clinical fixtures for EdenVitalsRow.
//
// Per global TDD Playbook habit 4: fixture generators, not LLM-generated test
// data. These are hand-curated realistic-but-non-PII clinical values:
// - BP normal: 128/82 (high-normal adult, range 90-140 / 60-90)
// - HR normal: 72 bpm (range 60-100)
// - Temp normal: 98.6°F (range 97.0-99.0)
// - SpO2 normal: 98% (range 95-100, critical below 90)
// - RR normal: 16 breaths/min (range 12-20)
// - Weight: realistic adult values
// - BMI: computed-by-consumer values
//
// Critical thresholds match JNC-8 / standard pediatric / COPD-flare clinical
// guidance. patientId values are opaque non-PII tokens ('pt-001', 'pt-002', ...).

import 'package:eden_ui_flutter/src/widgets/eden_vitals_row.dart';

class VitalsFixtures {
  VitalsFixtures._();

  // ──────────────────────────── BP fixtures ────────────────────────────

  /// Normal adult BP: 128/82, all in-range.
  static const bpNormal = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 128,
    diastolic: 82,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// Stage-1 hypertensive caution: 148/94.
  static const bpHypertensiveCaution = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 148,
    diastolic: 94,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// Hypertensive crisis: 192/124 (JNC-8 critical threshold).
  static const bpHypertensiveCrisis = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 192,
    diastolic: 124,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// Hypotensive crisis: 78/52.
  static const bpHypotensive = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 78,
    diastolic: 52,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// BP trending up (prior=128, now=148).
  static const bpTrendingUp = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 148,
    diastolic: 94,
    priorValue: 128,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// BP trending down (prior=148, now=118).
  static const bpTrendingDown = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 118,
    diastolic: 78,
    priorValue: 148,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// BP flat (prior=126, now=128 — within ±5%).
  static const bpFlat = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 128,
    diastolic: 82,
    priorValue: 126,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  /// BP with no prior value (no trend arrow expected).
  static const bpNoPrior = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.bloodPressure,
    unit: 'mmHg',
    systolic: 128,
    diastolic: 82,
    referenceMin: 90,
    referenceMax: 140,
    criticalMin: 60,
    criticalMax: 180,
  );

  // ──────────────────────────── HR fixtures ────────────────────────────

  /// Normal heart rate: 72 bpm.
  static const heartRateNormal = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 72,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 140,
  );

  /// Heart rate without reference range (neutral coloring expected).
  static const heartRateNoRange = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 72,
    // no referenceMin/Max — neutral surface expected
  );

  /// Elevated HR (caution).
  static const heartRateElevated = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 112,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 140,
  );

  // ──────────────────────────── Temp fixtures ──────────────────────────

  /// Normal temperature: 98.6°F.
  static const tempNormal = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.temperature,
    unit: '°F',
    value: 98.6,
    referenceMin: 97.0,
    referenceMax: 99.5,
    criticalMin: 95.0,
    criticalMax: 103.0,
  );

  /// Febrile temperature: 101.8°F (above ref max, below critical).
  static const tempFebrile = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.temperature,
    unit: '°F',
    value: 101.8,
    referenceMin: 97.0,
    referenceMax: 99.5,
    criticalMin: 95.0,
    criticalMax: 103.0,
  );

  // ──────────────────────────── SpO2 fixtures ──────────────────────────

  /// Normal SpO2: 98%.
  static const spo2Normal = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 98,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  );

  /// Critical SpO2: 87% (below criticalMin=90).
  static const spo2Critical = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 87,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  );

  /// Low-caution SpO2: 92% (below ref min, above critical).
  static const spo2LowCaution = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.spo2,
    unit: '%',
    value: 92,
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  );

  /// No SpO2 reading recorded (renders as '—' / neutral).
  static const spo2NoReading = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.spo2,
    unit: '%',
    referenceMin: 95,
    referenceMax: 100,
    criticalMin: 90,
  );

  // ──────────────────────────── RR fixtures ────────────────────────────

  /// Normal respiratory rate: 16 breaths/min.
  static const rrNormal = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.respiratoryRate,
    unit: 'breaths/min',
    value: 16,
    referenceMin: 12,
    referenceMax: 20,
    criticalMin: 8,
    criticalMax: 30,
  );

  /// Elevated RR (COPD flare): 28 breaths/min.
  static const rrElevated = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.respiratoryRate,
    unit: 'breaths/min',
    value: 28,
    referenceMin: 12,
    referenceMax: 20,
    criticalMin: 8,
    criticalMax: 30,
  );

  // ─────────────────────────── Weight fixtures ─────────────────────────

  static const weightNormal = EdenVitalSign(
    patientId: 'pt-001',
    kind: EdenVitalKind.weight,
    unit: 'kg',
    value: 76,
  );

  // ─────────────────────────── HIPAA isolation ─────────────────────────

  /// Patient 001's BP.
  static const bpPatient001 = bpNormal;

  /// Patient 002's HR — mixed-patient PHI bleed scenario.
  static const hrPatient002 = EdenVitalSign(
    patientId: 'pt-002',
    kind: EdenVitalKind.heartRate,
    unit: 'bpm',
    value: 88,
    referenceMin: 60,
    referenceMax: 100,
    criticalMin: 40,
    criticalMax: 140,
  );

  // ─────────────────────────── Multi-vital strips ──────────────────────

  /// Healthy adult full strip (6 vitals, all in-range).
  static const healthyAdultStrip = <EdenVitalSign>[
    bpNormal,
    heartRateNormal,
    tempNormal,
    spo2Normal,
    rrNormal,
    weightNormal,
  ];

  /// COPD-flare adult: BP normal, HR elevated, RR elevated, SpO2 low-caution.
  static const copdFlareStrip = <EdenVitalSign>[
    bpNormal,
    heartRateElevated,
    tempNormal,
    spo2LowCaution,
    rrElevated,
    weightNormal,
  ];

  /// Hypertensive elderly: BP crisis, HR elevated, others normal.
  static const hypertensiveElderlyStrip = <EdenVitalSign>[
    bpHypertensiveCrisis,
    heartRateElevated,
    tempNormal,
    spo2Normal,
    rrNormal,
    weightNormal,
  ];

  /// Febrile pediatric: BP normal-low, HR elevated, Temp febrile.
  /// Pediatric ranges differ from adult; for fixture simplicity we use
  /// adult ranges but the values are illustrative-only.
  static const febrilePediatricStrip = <EdenVitalSign>[
    EdenVitalSign(
      patientId: 'pt-pedi-01',
      kind: EdenVitalKind.bloodPressure,
      unit: 'mmHg',
      systolic: 100,
      diastolic: 64,
      referenceMin: 90,
      referenceMax: 140,
      criticalMin: 60,
      criticalMax: 180,
    ),
    EdenVitalSign(
      patientId: 'pt-pedi-01',
      kind: EdenVitalKind.heartRate,
      unit: 'bpm',
      value: 130,
      referenceMin: 60,
      referenceMax: 100,
      criticalMin: 40,
      criticalMax: 160,
    ),
    EdenVitalSign(
      patientId: 'pt-pedi-01',
      kind: EdenVitalKind.temperature,
      unit: '°F',
      value: 102.4,
      referenceMin: 97.0,
      referenceMax: 99.5,
      criticalMin: 95.0,
      criticalMax: 104.5,
    ),
    EdenVitalSign(
      patientId: 'pt-pedi-01',
      kind: EdenVitalKind.spo2,
      unit: '%',
      value: 97,
      referenceMin: 95,
      referenceMax: 100,
      criticalMin: 90,
    ),
    EdenVitalSign(
      patientId: 'pt-pedi-01',
      kind: EdenVitalKind.respiratoryRate,
      unit: 'breaths/min',
      value: 24,
      referenceMin: 12,
      referenceMax: 20,
      criticalMin: 8,
      criticalMax: 30,
    ),
    EdenVitalSign(
      patientId: 'pt-pedi-01',
      kind: EdenVitalKind.weight,
      unit: 'kg',
      value: 22,
    ),
  ];
}

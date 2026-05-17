// Do NOT regenerate via LLM — hand-built composite chart-scaffold fixtures for EdenPatientChartScaffold.
//
// Realistic 5-year polychronic patient: T2DM + HTN + Hyperlipidemia + GERD + OSA.

import 'package:eden_ui_flutter/src/widgets/eden_allergy_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_audit_log_viewer.dart';
import 'package:eden_ui_flutter/src/widgets/eden_blocking_alerts.dart';
import 'package:eden_ui_flutter/src/widgets/eden_chart_timeline.dart';
import 'package:eden_ui_flutter/src/widgets/eden_lab_result_table.dart';
import 'package:eden_ui_flutter/src/widgets/eden_medication_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_patient_chart_scaffold.dart';
import 'package:eden_ui_flutter/src/widgets/eden_problem_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';
import 'package:eden_ui_flutter/src/widgets/eden_vitals_row.dart';

class ChartFixtures {
  ChartFixtures._();

  static const _patientId = 'pt-001';

  static final demographics = EdenPatientDemographics(
    patientId: _patientId,
    name: 'Jane Doe',
    mrn: '123456',
    dob: DateTime(1979, 3, 4),
    sex: 'F',
    payer: 'Aetna',
    pcp: 'Dr. Chen',
  );

  static final vitals = <EdenVitalSign>[
    EdenVitalSign(
      patientId: _patientId,
      kind: EdenVitalKind.bloodPressure,
      unit: 'mmHg',
      systolic: 128,
      diastolic: 82,
      referenceMin: 90,
      referenceMax: 140,
      criticalMin: 60,
      criticalMax: 180,
    ),
    EdenVitalSign(
      patientId: _patientId,
      kind: EdenVitalKind.heartRate,
      unit: 'bpm',
      value: 72,
      referenceMin: 60,
      referenceMax: 100,
    ),
    EdenVitalSign(
      patientId: _patientId,
      kind: EdenVitalKind.temperature,
      unit: '°F',
      value: 98.6,
      referenceMin: 97.0,
      referenceMax: 99.5,
    ),
    EdenVitalSign(
      patientId: _patientId,
      kind: EdenVitalKind.spo2,
      unit: '%',
      value: 98,
      referenceMin: 95,
      referenceMax: 100,
      criticalMin: 90,
    ),
  ];

  static final medications = <EdenMedicationStatement>[
    EdenMedicationStatement(
      id: 'med-1',
      patientId: _patientId,
      drugName: 'Metformin',
      doseLabel: '500mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Twice daily',
      prescriber: 'Dr. Chen',
      startDate: DateTime(2022, 8, 14),
    ),
    EdenMedicationStatement(
      id: 'med-2',
      patientId: _patientId,
      drugName: 'Lisinopril',
      doseLabel: '10mg',
      route: EdenMedicationRoute.oral,
      frequency: 'Once daily',
      prescriber: 'Dr. Chen',
      startDate: DateTime(2024, 1, 8),
    ),
    EdenMedicationStatement(
      id: 'med-3',
      patientId: _patientId,
      drugName: 'Atorvastatin',
      doseLabel: '40mg',
      route: EdenMedicationRoute.oral,
      frequency: 'At bedtime',
      prescriber: 'Dr. Chen',
      startDate: DateTime(2023, 5, 10),
    ),
  ];

  static final problems = <EdenCondition>[
    EdenCondition(
      id: 'cond-1',
      patientId: _patientId,
      code: 'E11.9',
      codeSystem: 'ICD-10-CM',
      description: 'Type 2 diabetes mellitus without complications',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2022, 8, 14),
      diagnosedBy: 'Dr. Chen',
    ),
    EdenCondition(
      id: 'cond-2',
      patientId: _patientId,
      code: 'I10',
      codeSystem: 'ICD-10-CM',
      description: 'Essential (primary) hypertension',
      status: EdenConditionStatus.active,
      onsetDate: DateTime(2021, 3, 2),
      diagnosedBy: 'Dr. Chen',
    ),
  ];

  static final allergies = <EdenAllergyIntolerance>[
    EdenAllergyIntolerance(
      id: 'all-1',
      patientId: _patientId,
      allergen: 'Penicillin',
      type: EdenAllergenType.medication,
      reaction: 'Anaphylaxis',
      severity: EdenAllergySeverity.severe,
      criticality: EdenAllergyCriticality.high,
      verifiedBy: 'Dr. Chen',
    ),
  ];

  static final labs = <EdenLabResult>[
    EdenLabResult(
      id: 'lab-1',
      patientId: _patientId,
      testName: 'Hemoglobin',
      testCode: 'HGB',
      value: 14.2,
      unit: 'g/dL',
      referenceMin: 12.0,
      referenceMax: 16.0,
      flag: EdenLabFlag.normal,
      panelName: 'CBC',
      collectedAt: DateTime(2026, 5, 17),
    ),
    EdenLabResult(
      id: 'lab-2',
      patientId: _patientId,
      testName: 'Glucose',
      testCode: 'GLU',
      value: 145,
      unit: 'mg/dL',
      referenceMin: 70,
      referenceMax: 99,
      flag: EdenLabFlag.high,
      panelName: 'CMP',
      collectedAt: DateTime(2026, 5, 17),
    ),
  ];

  static const notes = <EdenSoapNoteData>[
    EdenSoapNoteData(
      patientId: _patientId,
      subjective: 'Patient here for annual physical, no complaints.',
      objective: 'BP 128/82, HR 72, BMI 23.',
      assessment: 'Z00.00 — annual physical.',
      plan: '1. Continue meds. 2. RTC 12mo.',
      signedBy: 'Dr. Chen',
    ),
  ];

  static final timelineEvents = <EdenChartTimelineEvent>[
    EdenChartTimelineEvent(
      id: 'evt-1',
      patientId: _patientId,
      category: EdenChartEventCategory.encounter,
      title: 'Annual Physical',
      occurredAt: DateTime(2026, 5, 17),
      provider: 'Dr. Chen',
    ),
    EdenChartTimelineEvent(
      id: 'evt-2',
      patientId: _patientId,
      category: EdenChartEventCategory.problem,
      title: 'Diagnosed T2DM',
      subtitle: 'E11.9',
      occurredAt: DateTime(2022, 8, 14),
      provider: 'Dr. Chen',
    ),
  ];

  static const blockingAlerts = <EdenBlockingAlertData>[
    EdenBlockingAlertData(
      task: 'Dose-check: Warfarin + Aspirin',
      context: 'Drug-drug interaction',
      reason: 'Increased bleeding risk — monitor INR',
    ),
  ];

  static final auditEvents = <EdenAuditLogEntry>[
    EdenAuditLogEntry(
      id: 'aud-1',
      timestamp: DateTime(2026, 5, 17, 8, 30),
      actor: 'dr.chen@example.com',
      action: 'VIEW_CHART',
      target: 'Patient pt-001',
    ),
    EdenAuditLogEntry(
      id: 'aud-2',
      timestamp: DateTime(2026, 5, 16, 14, 12),
      actor: 'mary.johnson@example.com',
      action: 'EDIT_NOTE',
      target: 'SOAP note 2026-05-16',
    ),
  ];

  static final polychronicPatient5Year = EdenPatientChartData(
    patientId: _patientId,
    demographics: demographics,
    vitals: vitals,
    medications: medications,
    problems: problems,
    allergies: allergies,
    labs: labs,
    notes: notes,
    timelineEvents: timelineEvents,
    blockingAlerts: blockingAlerts,
    auditEvents: auditEvents,
  );

  /// Same patient EXCEPT one med is for pt-002 (PHI bleed scenario).
  static final polychronicWithBleededMed = EdenPatientChartData(
    patientId: _patientId,
    demographics: demographics,
    vitals: vitals,
    medications: [
      ...medications,
      EdenMedicationStatement(
        id: 'med-bleed',
        patientId: 'pt-002', // PHI bleed!
        drugName: 'BLEED-DRUG-PT002',
        doseLabel: '0mg',
        route: EdenMedicationRoute.oral,
        frequency: 'NEVER',
      ),
    ],
    problems: problems,
    allergies: allergies,
    labs: labs,
    notes: notes,
    timelineEvents: timelineEvents,
    blockingAlerts: blockingAlerts,
    auditEvents: auditEvents,
  );
}

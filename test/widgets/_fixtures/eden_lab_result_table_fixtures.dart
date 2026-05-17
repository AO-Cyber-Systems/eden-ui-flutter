// Do NOT regenerate via LLM — hand-built clinical fixtures for EdenLabResultTable.
//
// Realistic-but-non-PII lab values at standard adult ranges:
// CBC: WBC 4.5-11 k/uL, RBC 4.5-5.5 M/uL, Hgb 12-16 g/dL, Hct 36-46%, Plt 150-400 k/uL
// CMP: Na 135-145, K 3.5-5.0, Cl 98-107, CO2 22-29, BUN 7-20, Cr 0.6-1.3, Glu 70-99
// Lipid: TC <200, LDL <100, HDL >40, TG <150

import 'package:eden_ui_flutter/src/widgets/eden_lab_result_table.dart';

class LabFixtures {
  LabFixtures._();

  // ─────────────────────────── CBC fixtures ───────────────────────────

  static final hgbNormal = EdenLabResult(
    id: 'lab-001',
    patientId: 'pt-001',
    testName: 'Hemoglobin',
    testCode: 'HGB',
    value: 14.2,
    unit: 'g/dL',
    referenceMin: 12.0,
    referenceMax: 16.0,
    flag: EdenLabFlag.normal,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final hgbLow = EdenLabResult(
    id: 'lab-002',
    patientId: 'pt-001',
    testName: 'Hemoglobin',
    testCode: 'HGB',
    value: 8.2,
    unit: 'g/dL',
    referenceMin: 12.0,
    referenceMax: 16.0,
    flag: EdenLabFlag.low,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final hgbWithTrend = EdenLabResult(
    id: 'lab-003',
    patientId: 'pt-001',
    testName: 'Hemoglobin',
    testCode: 'HGB',
    value: 14.2,
    unit: 'g/dL',
    referenceMin: 12.0,
    referenceMax: 16.0,
    flag: EdenLabFlag.normal,
    panelName: 'CBC',
    trendValues: [13.8, 14.0, 14.1, 14.0],
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final hgbNoTrend = hgbNormal;

  static final wbcNormal = EdenLabResult(
    id: 'lab-004',
    patientId: 'pt-001',
    testName: 'White Blood Cells',
    testCode: 'WBC',
    value: 7.5,
    unit: 'k/uL',
    referenceMin: 4.5,
    referenceMax: 11.0,
    flag: EdenLabFlag.normal,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final rbcNormal = EdenLabResult(
    id: 'lab-005',
    patientId: 'pt-001',
    testName: 'Red Blood Cells',
    testCode: 'RBC',
    value: 4.8,
    unit: 'M/uL',
    referenceMin: 4.5,
    referenceMax: 5.5,
    flag: EdenLabFlag.normal,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final hctNormal = EdenLabResult(
    id: 'lab-006',
    patientId: 'pt-001',
    testName: 'Hematocrit',
    testCode: 'HCT',
    value: 42.0,
    unit: '%',
    referenceMin: 36.0,
    referenceMax: 46.0,
    flag: EdenLabFlag.normal,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final pltNormal = EdenLabResult(
    id: 'lab-007',
    patientId: 'pt-001',
    testName: 'Platelets',
    testCode: 'PLT',
    value: 245,
    unit: 'k/uL',
    referenceMin: 150,
    referenceMax: 400,
    flag: EdenLabFlag.normal,
    panelName: 'CBC',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  // ─────────────────────────── CMP fixtures ───────────────────────────

  static final glucoseNormal = EdenLabResult(
    id: 'lab-010',
    patientId: 'pt-001',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 88,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    flag: EdenLabFlag.normal,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final glucoseHigh = EdenLabResult(
    id: 'lab-011',
    patientId: 'pt-001',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 145,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    criticalMax: 400,
    flag: EdenLabFlag.high,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final glucoseCriticalHigh = EdenLabResult(
    id: 'lab-012',
    patientId: 'pt-001',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 420,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    criticalMax: 400,
    flag: EdenLabFlag.criticalHigh,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final glucoseCriticalLow = EdenLabResult(
    id: 'lab-013',
    patientId: 'pt-001',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 42,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    criticalMin: 50,
    flag: EdenLabFlag.criticalLow,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final potassiumCriticalHigh = EdenLabResult(
    id: 'lab-014',
    patientId: 'pt-001',
    testName: 'Potassium',
    testCode: 'K',
    value: 6.8,
    unit: 'mEq/L',
    referenceMin: 3.5,
    referenceMax: 5.0,
    criticalMax: 6.0,
    flag: EdenLabFlag.criticalHigh,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final sodiumNormal = EdenLabResult(
    id: 'lab-015',
    patientId: 'pt-001',
    testName: 'Sodium',
    testCode: 'NA',
    value: 140,
    unit: 'mEq/L',
    referenceMin: 135,
    referenceMax: 145,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final chlorideNormal = EdenLabResult(
    id: 'lab-016',
    patientId: 'pt-001',
    testName: 'Chloride',
    testCode: 'CL',
    value: 102,
    unit: 'mEq/L',
    referenceMin: 98,
    referenceMax: 107,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final co2Normal = EdenLabResult(
    id: 'lab-017',
    patientId: 'pt-001',
    testName: 'CO2',
    testCode: 'CO2',
    value: 26,
    unit: 'mEq/L',
    referenceMin: 22,
    referenceMax: 29,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final bunNormal = EdenLabResult(
    id: 'lab-018',
    patientId: 'pt-001',
    testName: 'BUN',
    testCode: 'BUN',
    value: 14,
    unit: 'mg/dL',
    referenceMin: 7,
    referenceMax: 20,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final creatinineNormal = EdenLabResult(
    id: 'lab-019',
    patientId: 'pt-001',
    testName: 'Creatinine',
    testCode: 'CR',
    value: 0.9,
    unit: 'mg/dL',
    referenceMin: 0.6,
    referenceMax: 1.3,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  // ─────────────────────────── Lipid fixtures ──────────────────────────

  static final totalCholHigh = EdenLabResult(
    id: 'lab-020',
    patientId: 'pt-001',
    testName: 'Total Cholesterol',
    testCode: 'TC',
    value: 245,
    unit: 'mg/dL',
    referenceMin: 0,
    referenceMax: 200,
    flag: EdenLabFlag.high,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final ldlHigh = EdenLabResult(
    id: 'lab-021',
    patientId: 'pt-001',
    testName: 'LDL Cholesterol',
    testCode: 'LDL',
    value: 168,
    unit: 'mg/dL',
    referenceMin: 0,
    referenceMax: 100,
    flag: EdenLabFlag.high,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final hdlNormal = EdenLabResult(
    id: 'lab-022',
    patientId: 'pt-001',
    testName: 'HDL Cholesterol',
    testCode: 'HDL',
    value: 52,
    unit: 'mg/dL',
    referenceMin: 40,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  static final tgHigh = EdenLabResult(
    id: 'lab-023',
    patientId: 'pt-001',
    testName: 'Triglycerides',
    testCode: 'TG',
    value: 195,
    unit: 'mg/dL',
    referenceMin: 0,
    referenceMax: 150,
    flag: EdenLabFlag.high,
    panelName: 'Lipid Panel',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );

  // ───────────────────────── Panel collections ────────────────────────

  static List<EdenLabResult> get cbcPanel => [
        wbcNormal,
        rbcNormal,
        hgbNormal,
        hctNormal,
        pltNormal,
      ];

  static List<EdenLabResult> get cmpPanel => [
        sodiumNormal,
        EdenLabResult(
          id: 'lab-016b',
          patientId: 'pt-001',
          testName: 'Potassium',
          testCode: 'K',
          value: 4.1,
          unit: 'mEq/L',
          referenceMin: 3.5,
          referenceMax: 5.0,
          panelName: 'CMP',
          collectedAt: DateTime(2026, 5, 17, 8, 30),
        ),
        chlorideNormal,
        co2Normal,
        bunNormal,
        creatinineNormal,
        glucoseNormal,
      ];

  static List<EdenLabResult> get lipidPanel => [
        totalCholHigh,
        ldlHigh,
        hdlNormal,
        tgHigh,
      ];

  static List<EdenLabResult> get cbcAndCmpPanels => [...cbcPanel, ...cmpPanel];

  static List<EdenLabResult> get fullPanelDay => [
        ...cbcPanel,
        ...cmpPanel,
        ...lipidPanel,
        glucoseCriticalHigh,
        potassiumCriticalHigh,
      ];

  // HIPAA isolation
  static final hgbPatient001 = hgbNormal;
  static final gluPatient002 = EdenLabResult(
    id: 'lab-mix-1',
    patientId: 'pt-002',
    testName: 'Glucose',
    testCode: 'GLU',
    value: 88,
    unit: 'mg/dL',
    referenceMin: 70,
    referenceMax: 99,
    flag: EdenLabFlag.normal,
    panelName: 'CMP',
    collectedAt: DateTime(2026, 5, 17, 8, 30),
  );
}

// Do NOT regenerate via LLM — hand-built AVS fixtures for EdenAVSGenerator.
// Synthetic patient identifiers + realistic-but-fabricated clinical content.
//
// Reusable ICD-10 codes (verified real):
//   F41.1  — Generalized anxiety disorder
//   R53.83 — Other fatigue
//   E78.5  — Hyperlipidemia, unspecified
//   I10    — Essential (primary) hypertension
//   J06.9  — Acute upper respiratory infection (URI), unspecified
//
// Patient identifiers (synthetic, not real PHI):
//   patient-alpha  — behavioral health follow-up patient
//   patient-bravo  — naturopath new-patient eval
//   patient-charlie — concierge annual physical patient

import 'package:eden_ui_flutter/src/widgets/eden_avs_generator.dart';
import 'package:eden_ui_flutter/src/widgets/eden_medication_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_problem_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';

class AvsFixtures {
  AvsFixtures._();

  /// SKU A flagship: anxiety / depression follow-up visit (behavioral
  /// health). GAD-7 score documented in SOAP. 1 active med (sertraline)
  /// + 1 discontinued med (trazodone). 1 active problem (F41.1).
  static EdenAvsDocument behavioralHealthFollowUp({
    String patientId = 'patient-alpha',
  }) {
    return EdenAvsDocument(
      patientId: patientId,
      patientDisplayName: 'Alex Alpha',
      encounterDate: DateTime(2026, 5, 17, 10, 30),
      providerName: 'Dr. Jane Smith',
      providerCredentials: 'PsyD',
      facilityName: 'Eden Behavioral Health Center',
      visitReason: 'Anxiety follow-up',
      soapData: EdenSoapNoteData(
        patientId: patientId,
        subjective:
            'Patient reports improvement in anxiety since starting sertraline 50mg daily 6 weeks ago. '
            'GAD-7 score down from 14 to 8. Sleep improved with morning dosing. Denies side effects.',
        objective: 'Affect brighter than prior visit. Speech normal rate + rhythm. '
            'No SI/HI. GAD-7 administered today: score 8 (mild).',
        assessment: 'F41.1 — Generalized anxiety disorder, improving on sertraline.',
        plan:
            '1. Continue sertraline 50mg daily. 2. Discontinue trazodone (sleep restored). '
            '3. Continue weekly CBT with Dr. Lee. 4. RTC in 4 weeks.',
        encounterId: 'enc-2026-05-17-001',
      ),
      medications: [
        EdenMedicationStatement(
          id: 'med-001',
          patientId: patientId,
          drugName: 'Sertraline',
          doseLabel: '50mg',
          route: EdenMedicationRoute.oral,
          frequency: 'Once daily, morning',
          prescriber: 'Dr. Jane Smith',
          startDate: DateTime(2026, 4, 5),
          status: EdenMedicationStatus.active,
        ),
        EdenMedicationStatement(
          id: 'med-002',
          patientId: patientId,
          drugName: 'Trazodone',
          doseLabel: '50mg',
          route: EdenMedicationRoute.oral,
          frequency: 'At bedtime PRN',
          prescriber: 'Dr. Jane Smith',
          startDate: DateTime(2026, 4, 5),
          endDate: DateTime(2026, 5, 17),
          status: EdenMedicationStatus.discontinued,
        ),
      ],
      problems: [
        EdenCondition(
          id: 'cond-001',
          patientId: patientId,
          code: 'F41.1',
          codeSystem: 'ICD-10-CM',
          description: 'Generalized anxiety disorder',
          status: EdenConditionStatus.active,
          onsetDate: DateTime(2025, 11, 1),
          diagnosedBy: 'Dr. Jane Smith',
        ),
      ],
      followUpInstructions:
          'Continue sertraline 50mg daily, follow up in 4 weeks for medication '
          'review. Contact the office if anxiety worsens or you experience any '
          'unusual side effects.',
      nextAppointmentAt: DateTime(2026, 6, 14, 10, 30),
    );
  }

  /// Naturopath new-patient consult (cash-pay). No prior meds. 1 active
  /// problem (R53.83 fatigue). Labs ordered, no follow-up booked yet.
  static EdenAvsDocument cashPayNewPatientEval({
    String patientId = 'patient-bravo',
  }) {
    return EdenAvsDocument(
      patientId: patientId,
      patientDisplayName: 'Blake Bravo',
      encounterDate: DateTime(2026, 5, 17, 13, 0),
      providerName: 'Dr. Maya Patel',
      providerCredentials: 'ND',
      facilityName: 'Eden Wellness Clinic',
      visitReason: 'Initial wellness consult',
      soapData: EdenSoapNoteData(
        patientId: patientId,
        subjective:
            'Patient is a 34yo presenting for initial wellness eval. Chief concern: '
            'persistent fatigue x 4 months despite 8h sleep nightly. Diet primarily '
            'plant-based. No medications. No tobacco/alcohol. Exercise: 30min walking 3x/wk.',
        objective:
            'Vitals: BP 118/72, HR 68, BMI 22.1. Exam: well-appearing, NAD. '
            'No thyromegaly. Lungs CTA. Heart RRR. Abdomen soft, non-tender.',
        assessment:
            'R53.83 — Other fatigue. Differential includes anemia, hypothyroidism, '
            'vitamin D deficiency, sleep-disordered breathing.',
        plan:
            '1. CBC, CMP, TSH, vitamin D, ferritin. 2. Patient education on '
            'iron-rich foods + sleep hygiene. 3. RTC for lab review in 2 weeks.',
      ),
      medications: const [],
      problems: [
        EdenCondition(
          id: 'cond-002',
          patientId: patientId,
          code: 'R53.83',
          codeSystem: 'ICD-10-CM',
          description: 'Other fatigue',
          status: EdenConditionStatus.active,
          onsetDate: DateTime(2026, 1, 15),
          diagnosedBy: 'Dr. Maya Patel',
        ),
      ],
      followUpInstructions:
          'Lab orders sent to your portal. Schedule labs at your convenience '
          'within the next week. Return for lab review in 2 weeks.',
    );
  }

  /// Concierge primary-care annual physical. Stable polychronic adult.
  /// 2 active meds + 2 active problems + 1 resolved problem (excluded
  /// from default render to verify active-filter).
  static EdenAvsDocument conciergeAnnualPhysical({
    String patientId = 'patient-charlie',
  }) {
    return EdenAvsDocument(
      patientId: patientId,
      patientDisplayName: 'Casey Charlie',
      encounterDate: DateTime(2026, 5, 17, 8, 0),
      providerName: 'Dr. Robert Kim',
      providerCredentials: 'MD',
      facilityName: 'Eden Concierge Health',
      visitReason: 'Annual physical',
      soapData: EdenSoapNoteData(
        patientId: patientId,
        subjective:
            '58yo M here for annual physical. No new complaints. Adherent to '
            'atorvastatin + lisinopril. Recovered well from URI 3 months ago. '
            'Exercise 4x/wk, diet improved per nutritionist plan.',
        objective:
            'BP 128/78 (improved from 138/86 last year). HR 72. BMI 26.1. '
            'Full ROS negative. Exam: NAD, lungs CTA, heart RRR, '
            'abdomen soft, peripheral pulses intact, no edema.',
        assessment:
            '1. E78.5 — Hyperlipidemia, controlled on statin. '
            '2. I10 — Essential hypertension, well-controlled. '
            '3. Annual physical, no abnormal findings.',
        plan:
            '1. Continue atorvastatin 40mg daily. 2. Continue lisinopril 10mg daily. '
            '3. Repeat lipid panel + CMP in 6 months. 4. Continue exercise + diet plan. '
            '5. Annual physical RTC in 12 months.',
        signedBy: 'Dr. Robert Kim, MD',
      ),
      medications: [
        EdenMedicationStatement(
          id: 'med-003',
          patientId: patientId,
          drugName: 'Atorvastatin',
          doseLabel: '40mg',
          route: EdenMedicationRoute.oral,
          frequency: 'Once daily, evening',
          prescriber: 'Dr. Robert Kim',
          startDate: DateTime(2024, 6, 1),
          status: EdenMedicationStatus.active,
        ),
        EdenMedicationStatement(
          id: 'med-004',
          patientId: patientId,
          drugName: 'Lisinopril',
          doseLabel: '10mg',
          route: EdenMedicationRoute.oral,
          frequency: 'Once daily, morning',
          prescriber: 'Dr. Robert Kim',
          startDate: DateTime(2023, 9, 12),
          status: EdenMedicationStatus.active,
        ),
      ],
      problems: [
        EdenCondition(
          id: 'cond-003',
          patientId: patientId,
          code: 'E78.5',
          codeSystem: 'ICD-10-CM',
          description: 'Hyperlipidemia, unspecified',
          status: EdenConditionStatus.active,
          onsetDate: DateTime(2024, 6, 1),
          diagnosedBy: 'Dr. Robert Kim',
        ),
        EdenCondition(
          id: 'cond-004',
          patientId: patientId,
          code: 'I10',
          codeSystem: 'ICD-10-CM',
          description: 'Essential (primary) hypertension',
          status: EdenConditionStatus.active,
          onsetDate: DateTime(2023, 9, 12),
          diagnosedBy: 'Dr. Robert Kim',
        ),
        EdenCondition(
          id: 'cond-005',
          patientId: patientId,
          code: 'J06.9',
          codeSystem: 'ICD-10-CM',
          description: 'Acute upper respiratory infection (URI), unspecified',
          status: EdenConditionStatus.resolved,
          onsetDate: DateTime(2026, 2, 14),
          resolvedDate: DateTime(2026, 2, 28),
          diagnosedBy: 'Dr. Robert Kim',
        ),
      ],
      followUpInstructions:
          'Continue current medications. Repeat lipid panel in 6 months. '
          'Annual physical scheduled in 12 months.',
      nextAppointmentAt: DateTime(2027, 5, 17, 8, 0),
    );
  }
}

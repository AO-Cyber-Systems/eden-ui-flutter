// Do NOT regenerate via LLM — hand-built SOAP-note fixtures for EdenSOAPNote.
//
// Realistic-but-non-PII clinical visit notes.

import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';

class SoapFixtures {
  SoapFixtures._();

  static const empty = EdenSoapNoteData(patientId: 'pt-001');

  static const annualPhysicalDraft = EdenSoapNoteData(
    patientId: 'pt-001',
    subjective:
        '52yo F here for annual physical, no complaints. ROS negative.',
    objective:
        'BP 124/78, HR 68, BMI 23. Exam: well-appearing, NAD. Lungs CTA. Heart RRR. Abdomen soft.',
  );

  static final annualPhysicalSigned = EdenSoapNoteData(
    patientId: 'pt-001',
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
    encounterId: 'enc-2026-05-17-001',
    providerId: 'prov-chen',
  );

  static const uriVisitSigned = EdenSoapNoteData(
    patientId: 'pt-001',
    subjective:
        '38yo M, 4-day cough + sore throat, low-grade fever to 100.2°F. No SOB. No exposure to TB or COVID-positives.',
    objective:
        'T 99.4°F, HR 84, BP 122/76, SpO2 98%. HEENT: erythematous pharynx, no exudate. Lungs CTA. Heart RRR. Abdomen soft.',
    assessment: 'J00 — Acute nasopharyngitis (common cold). Viral URI.',
    plan:
        '1. Supportive care. 2. Saline gargle PRN. 3. Return if fever > 101°F x 3d or new SOB.',
    signedBy: 'Dr. Lee',
  );

  static const t2dmFollowUp = EdenSoapNoteData(
    patientId: 'pt-001',
    subjective:
        '64yo M T2DM x 4 years. Reports good adherence to metformin 500mg BID. Home glucose 110-140 fasting. No polyuria/polydipsia. No vision changes.',
    objective:
        'BP 132/82, HR 76, weight 86kg (down 2kg from last visit). A1c 6.9 (was 7.4).',
    assessment:
        'E11.9 — T2DM, improving control (A1c 6.9). Z79.84 long-term use of oral hypoglycemic.',
    plan:
        '1. Continue metformin 500mg BID. 2. Continue lisinopril 10mg daily. 3. Annual diabetic foot exam — performed today, normal. 4. RTC 3mo with repeat A1c.',
  );

  // HIPAA isolation
  static const patient001Empty = EdenSoapNoteData(patientId: 'pt-001');
  static const patient002Empty = EdenSoapNoteData(patientId: 'pt-002');
}

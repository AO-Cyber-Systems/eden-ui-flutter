// Do NOT regenerate via LLM — hand-built visit-encounter fixtures for EdenVisitEncounterScaffold.

import 'package:eden_ui_flutter/src/widgets/eden_blocking_alerts.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';
import 'package:eden_ui_flutter/src/widgets/eden_visit_encounter_scaffold.dart';
import 'package:eden_ui_flutter/src/widgets/eden_vitals_row.dart';

class VisitFixtures {
  VisitFixtures._();

  static const _pid = 'pt-001';

  static final annualPhysicalEmpty = EdenVisitEncounterData(
    patientId: _pid,
    encounterId: 'enc-2026-05-17-001',
    encounterDate: DateTime(2026, 5, 17, 10, 30),
    provider: 'Dr. Chen',
    encounterType: 'Annual Physical',
    vitals: [
      EdenVitalSign(
        patientId: _pid,
        kind: EdenVitalKind.bloodPressure,
        unit: 'mmHg',
        systolic: 124,
        diastolic: 78,
        referenceMin: 90,
        referenceMax: 140,
      ),
      EdenVitalSign(
        patientId: _pid,
        kind: EdenVitalKind.heartRate,
        unit: 'bpm',
        value: 68,
        referenceMin: 60,
        referenceMax: 100,
      ),
    ],
  );

  static final uriMidVisit = EdenVisitEncounterData(
    patientId: _pid,
    encounterId: 'enc-2026-05-17-002',
    encounterDate: DateTime(2026, 5, 17, 14, 0),
    provider: 'Dr. Chen',
    encounterType: 'URI Visit',
    chiefComplaint: 'Cough × 5d, sore throat, low-grade fever to 100.2°F.',
    vitals: [
      EdenVitalSign(
        patientId: _pid,
        kind: EdenVitalKind.bloodPressure,
        unit: 'mmHg',
        systolic: 122,
        diastolic: 76,
        referenceMin: 90,
        referenceMax: 140,
      ),
      EdenVitalSign(
        patientId: _pid,
        kind: EdenVitalKind.temperature,
        unit: '°F',
        value: 99.4,
        referenceMin: 97.0,
        referenceMax: 99.5,
      ),
    ],
    soapNote: const EdenSoapNoteData(
      patientId: _pid,
      subjective:
          '38yo M, 4-day cough + sore throat, low-grade fever. No SOB.',
    ),
    blockingAlerts: const [
      EdenBlockingAlertData(
        task: 'Penicillin allergy',
        context: 'Patient PHI',
        reason: 'Anaphylaxis to PCN documented — do not prescribe Augmentin',
      ),
    ],
  );

  static final patient002Visit = EdenVisitEncounterData(
    patientId: 'pt-002',
    encounterId: 'enc-pt2-001',
    encounterDate: DateTime(2026, 5, 17, 15, 0),
    provider: 'Dr. Khan',
    encounterType: 'New patient intake',
  );
}

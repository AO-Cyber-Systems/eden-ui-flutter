// Do NOT regenerate via LLM — hand-built clinical fixtures for EdenAllergyList.
//
// Common drug + food + environmental allergies. Severity per typical
// presentation; criticality per clinical-decision-support convention.

import 'package:eden_ui_flutter/src/widgets/eden_allergy_list.dart';

class AllergyFixtures {
  AllergyFixtures._();

  static final penicillinAnaphylaxis = EdenAllergyIntolerance(
    id: 'all-001',
    patientId: 'pt-001',
    allergen: 'Penicillin',
    type: EdenAllergenType.medication,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.severe,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Chen',
    onsetDate: DateTime(2015, 4, 12),
  );

  static final latexHivesHigh = EdenAllergyIntolerance(
    id: 'all-002',
    patientId: 'pt-001',
    allergen: 'Latex',
    type: EdenAllergenType.environmental,
    reaction: 'Hives',
    severity: EdenAllergySeverity.severe,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Chen',
    onsetDate: DateTime(2018, 9, 21),
  );

  static final peanutLifeThreatening = EdenAllergyIntolerance(
    id: 'all-003',
    patientId: 'pt-001',
    allergen: 'Peanuts',
    type: EdenAllergenType.food,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.lifeThreatening,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Patient-reported',
    onsetDate: DateTime(2008, 3, 1),
  );

  static final sulfaRashModerate = EdenAllergyIntolerance(
    id: 'all-004',
    patientId: 'pt-001',
    allergen: 'Sulfa drugs',
    type: EdenAllergenType.medication,
    reaction: 'Rash',
    severity: EdenAllergySeverity.moderate,
    criticality: EdenAllergyCriticality.low,
    verifiedBy: 'Dr. Lee',
  );

  static final codeineMildNausea = EdenAllergyIntolerance(
    id: 'all-005',
    patientId: 'pt-001',
    allergen: 'Codeine',
    type: EdenAllergenType.medication,
    reaction: 'GI upset / nausea',
    severity: EdenAllergySeverity.mild,
    criticality: EdenAllergyCriticality.low,
    verifiedBy: 'Patient-reported',
  );

  static final shellfishUnconfirmed = EdenAllergyIntolerance(
    id: 'all-006',
    patientId: 'pt-001',
    allergen: 'Shellfish',
    type: EdenAllergenType.food,
    reaction: 'Hives',
    severity: EdenAllergySeverity.moderate,
    criticality: EdenAllergyCriticality.low,
    verificationStatus: EdenAllergyVerificationStatus.unconfirmed,
    verifiedBy: 'Patient-reported',
  );

  static final penicillinRefuted = EdenAllergyIntolerance(
    id: 'all-007',
    patientId: 'pt-001',
    allergen: 'Penicillin',
    type: EdenAllergenType.medication,
    reaction: 'Reported rash (excluded via challenge test)',
    severity: EdenAllergySeverity.mild,
    criticality: EdenAllergyCriticality.low,
    verificationStatus: EdenAllergyVerificationStatus.refuted,
    verifiedBy: 'Dr. Patel — Allergy & Immunology',
  );

  static final pollenSeasonalMild = EdenAllergyIntolerance(
    id: 'all-008',
    patientId: 'pt-001',
    allergen: 'Pollen (seasonal)',
    type: EdenAllergenType.environmental,
    reaction: 'Rhinitis',
    severity: EdenAllergySeverity.mild,
    criticality: EdenAllergyCriticality.low,
    verifiedBy: 'Patient-reported',
  );

  static final beeVenomHigh = EdenAllergyIntolerance(
    id: 'all-009',
    patientId: 'pt-elderly',
    allergen: 'Bee venom',
    type: EdenAllergenType.environmental,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.severe,
    criticality: EdenAllergyCriticality.high,
    verifiedBy: 'Dr. Park',
  );

  static final iodineContrastModerate = EdenAllergyIntolerance(
    id: 'all-010',
    patientId: 'pt-elderly',
    allergen: 'Iodine contrast',
    type: EdenAllergenType.medication,
    reaction: 'Hives',
    severity: EdenAllergySeverity.moderate,
    criticality: EdenAllergyCriticality.low,
    verifiedBy: 'Dr. Park',
  );

  // Inactive sample
  static final inactiveAllergyOnly = EdenAllergyIntolerance(
    id: 'all-011',
    patientId: 'pt-001',
    allergen: 'Aspirin (childhood, outgrown)',
    type: EdenAllergenType.medication,
    reaction: 'Hives',
    severity: EdenAllergySeverity.mild,
    criticality: EdenAllergyCriticality.low,
    clinicalStatus: EdenAllergyClinicalStatus.inactive,
    verifiedBy: 'Dr. Patel',
  );

  // Multi-allergy collections
  static List<EdenAllergyIntolerance> get singleAnaphylaxis =>
      [penicillinAnaphylaxis];

  static List<EdenAllergyIntolerance> get multiAllergyAdult => [
        penicillinAnaphylaxis,
        latexHivesHigh,
        peanutLifeThreatening,
        codeineMildNausea,
      ];

  static List<EdenAllergyIntolerance> get multiAllergyElderly {
    // 4 allergies, 3 high-criticality + 1 low — exercises banner.
    return [
      EdenAllergyIntolerance(
        id: 'all-elder-1',
        patientId: 'pt-elderly',
        allergen: 'Penicillin',
        type: EdenAllergenType.medication,
        reaction: 'Anaphylaxis',
        severity: EdenAllergySeverity.severe,
        criticality: EdenAllergyCriticality.high,
        verifiedBy: 'Dr. Lee',
      ),
      EdenAllergyIntolerance(
        id: 'all-elder-2',
        patientId: 'pt-elderly',
        allergen: 'Codeine',
        type: EdenAllergenType.medication,
        reaction: 'GI upset',
        severity: EdenAllergySeverity.mild,
        criticality: EdenAllergyCriticality.low,
        verifiedBy: 'Patient-reported',
      ),
      EdenAllergyIntolerance(
        id: 'all-elder-3',
        patientId: 'pt-elderly',
        allergen: 'Latex',
        type: EdenAllergenType.environmental,
        reaction: 'Contact dermatitis',
        severity: EdenAllergySeverity.severe,
        criticality: EdenAllergyCriticality.high,
        verifiedBy: 'Dr. Lee',
      ),
      EdenAllergyIntolerance(
        id: 'all-elder-4',
        patientId: 'pt-elderly',
        allergen: 'Peanuts',
        type: EdenAllergenType.food,
        reaction: 'Anaphylaxis',
        severity: EdenAllergySeverity.lifeThreatening,
        criticality: EdenAllergyCriticality.high,
        verifiedBy: 'Dr. Lee',
      ),
    ];
  }

  static List<EdenAllergyIntolerance> get mixedActiveAndInactive => [
        penicillinAnaphylaxis,
        codeineMildNausea,
        sulfaRashModerate,
        inactiveAllergyOnly,
        EdenAllergyIntolerance(
          id: 'all-mai-1',
          patientId: 'pt-001',
          allergen: 'Erythromycin',
          type: EdenAllergenType.medication,
          reaction: 'GI upset',
          severity: EdenAllergySeverity.mild,
          criticality: EdenAllergyCriticality.low,
          clinicalStatus: EdenAllergyClinicalStatus.inactive,
        ),
      ];

  static List<EdenAllergyIntolerance> get fiveHighCriticality => [
        penicillinAnaphylaxis,
        peanutLifeThreatening,
        latexHivesHigh,
        EdenAllergyIntolerance(
          id: 'all-five-4',
          patientId: 'pt-001',
          allergen: 'Bee venom',
          type: EdenAllergenType.environmental,
          reaction: 'Anaphylaxis',
          severity: EdenAllergySeverity.severe,
          criticality: EdenAllergyCriticality.high,
          verifiedBy: 'Dr. Chen',
        ),
        EdenAllergyIntolerance(
          id: 'all-five-5',
          patientId: 'pt-001',
          allergen: 'Iodine contrast',
          type: EdenAllergenType.medication,
          reaction: 'Anaphylaxis',
          severity: EdenAllergySeverity.severe,
          criticality: EdenAllergyCriticality.high,
          verifiedBy: 'Dr. Chen',
        ),
      ];

  // HIPAA isolation
  static final penicillinPatient001 = penicillinAnaphylaxis;
  static final peanutPatient002 = EdenAllergyIntolerance(
    id: 'all-mix-1',
    patientId: 'pt-002',
    allergen: 'Peanuts',
    type: EdenAllergenType.food,
    reaction: 'Anaphylaxis',
    severity: EdenAllergySeverity.lifeThreatening,
    criticality: EdenAllergyCriticality.high,
  );
}

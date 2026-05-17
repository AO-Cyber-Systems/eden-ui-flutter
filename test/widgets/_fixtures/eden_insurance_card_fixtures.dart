// Do NOT regenerate via LLM — hand-built insurance card fixtures for EdenInsuranceCard.
// Realistic-but-fabricated plan names + payer IDs + member IDs.
//
// PHI hygiene: member IDs are synthetic but follow real-world shape
// patterns (alphanumeric prefix + digits). Payer IDs use known plan
// brand names (Aetna, BCBS, Medicare, UHC) — public identifiers, NOT
// patient data.
//
// Patient identifiers (synthetic):
//   patient-alpha     — primary Aetna PPO + secondary BCBS HDHP
//   patient-bravo     — Medicare traditional
//   patient-charlie   — expired HDHP
//   patient-delta     — cross-vertical trades CDL driver license

import 'package:eden_ui_flutter/src/widgets/eden_insurance_card.dart';

class InsuranceCardFixtures {
  InsuranceCardFixtures._();

  /// Aetna Choice POS II — active primary PPO with both card images.
  /// Used as the canonical "happy path" fixture for compose + verified tests.
  static EdenInsurancePolicy primaryAetnaPpoActive({
    String patientId = 'patient-alpha',
    DateTime? verifiedAt,
  }) {
    return EdenInsurancePolicy(
      id: 'policy-aetna-001',
      patientId: patientId,
      planName: 'Aetna Choice POS II',
      planType: EdenInsurancePlanType.ppo,
      payerId: '60054',
      memberId: 'W123456789',
      groupNumber: '12345-ABC',
      planEffectiveDate: DateTime(2026, 1, 1),
      planTerminationDate: DateTime(2026, 12, 31),
      priorityRank: EdenInsurancePriority.primary,
      subscriberName: 'Alex Alpha',
      subscriberRelation: EdenSubscriberRelation.self,
      frontImageUrl: 'https://example.invalid/cards/aetna-front.png',
      backImageUrl: 'https://example.invalid/cards/aetna-back.png',
      verifiedAt: verifiedAt ?? DateTime(2026, 5, 17),
    );
  }

  /// BCBS HDHP secondary — no card images (tests empty-image branch).
  static EdenInsurancePolicy secondaryBcbsHdhpActive({
    String patientId = 'patient-alpha',
  }) {
    return EdenInsurancePolicy(
      id: 'policy-bcbs-001',
      patientId: patientId,
      planName: 'BCBS HDHP Silver',
      planType: EdenInsurancePlanType.hdhp,
      payerId: '00510',
      memberId: 'ZBC987654',
      planEffectiveDate: DateTime(2026, 1, 1),
      planTerminationDate: DateTime(2026, 12, 31),
      priorityRank: EdenInsurancePriority.secondary,
      subscriberName: 'Beta Spouse',
      subscriberRelation: EdenSubscriberRelation.spouse,
    );
  }

  /// Medicare Part B — single-sided card (no backImage). Medicare cards
  /// don't expire annually (no planTerminationDate).
  static EdenInsurancePolicy medicareTraditional({
    String patientId = 'patient-bravo',
  }) {
    return EdenInsurancePolicy(
      id: 'policy-medicare-001',
      patientId: patientId,
      planName: 'Medicare Part B',
      planType: EdenInsurancePlanType.medicare,
      payerId: 'MEDICARE',
      memberId: '1AB2-CD3-EF45',
      planEffectiveDate: DateTime(2024, 1, 1),
      priorityRank: EdenInsurancePriority.primary,
      subscriberName: 'Brett Bravo',
      subscriberRelation: EdenSubscriberRelation.self,
      frontImageUrl: 'https://example.invalid/cards/medicare-front.png',
      verifiedAt: DateTime(2026, 1, 15),
    );
  }

  /// Expired HDHP policy with planTerminationDate=2020-01-01. Verified-at
  /// is null → renders "Not verified" warning chip.
  static EdenInsurancePolicy expiredHdhp({
    String patientId = 'patient-charlie',
  }) {
    return EdenInsurancePolicy(
      id: 'policy-expired-001',
      patientId: patientId,
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
  }

  /// Cross-vertical: trades CDL driver license capture. Uses same widget
  /// shape with planType=other + customPlanTypeLabel override.
  static EdenInsurancePolicy crossVerticalDriverLicense({
    String patientId = 'patient-delta',
  }) {
    return EdenInsurancePolicy(
      id: 'policy-trades-cdl-001',
      patientId: patientId,
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
      frontImageUrl: 'https://example.invalid/cards/cdl-front.png',
      verifiedAt: DateTime(2024, 7, 1),
    );
  }
}

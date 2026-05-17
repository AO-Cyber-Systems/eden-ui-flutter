// Do NOT regenerate via LLM — hand-built eligibility fixtures for EdenEligibilityResultCard.
// Realistic-but-fabricated payer scenarios for testing.
//
// All dollar amounts stored as int cents (matches EdenCurrencyDisplay
// API: `cents: int + currencyCode: String`).
//
// Synthetic patient identifiers:
//   patient-alpha   — Aetna PPO PCP visit (canonical happy path)
//   patient-bravo   — UHC out-of-network denied
//   patient-charlie — Cigna OAP TMS therapy (needs auth)
//   patient-delta   — Medicare stale check

import 'package:eden_ui_flutter/src/widgets/eden_eligibility_result_card.dart';

class EligibilityFixtures {
  EligibilityFixtures._();

  /// In-network PCP visit, $25 copay, deductible fully met. Canonical
  /// "happy path" fixture.
  static EdenEligibilityResult coveredInNetworkLowCopay({
    String patientId = 'patient-alpha',
    String policyId = 'policy-aetna-001',
    DateTime? checkedAt,
  }) {
    return EdenEligibilityResult(
      id: 'elig-alpha-001',
      patientId: patientId,
      policyId: policyId,
      checkedAt: checkedAt ?? DateTime(2026, 5, 15),
      coverageStatus: EdenCoverageStatus.covered,
      planName: 'Aetna Choice POS II',
      serviceType: 'Office visit (PCP)',
      copayCents: 2500, // $25
      deductibleAmountCents: 250000, // $2,500
      deductibleMetCents: 250000, // $2,500 met
      deductibleRemainingCents: 0,
      outOfPocketMaxCents: 750000, // $7,500
      outOfPocketMetCents: 250000, // $2,500
      outOfPocketRemainingCents: 500000, // $5,000
      networkStatus: EdenInsuranceNetworkStatus.inNetwork,
    );
  }

  /// Behavioral health outpatient (90837), HDHP with deductible NOT yet
  /// met — patient pays full coinsurance.
  static EdenEligibilityResult partialDeductibleNotMet({
    String patientId = 'patient-alpha',
    String policyId = 'policy-bcbs-001',
  }) {
    return EdenEligibilityResult(
      id: 'elig-alpha-002',
      patientId: patientId,
      policyId: policyId,
      checkedAt: DateTime(2026, 5, 16),
      coverageStatus: EdenCoverageStatus.partiallyCovered,
      planName: 'BCBS HDHP Silver',
      serviceType: 'Behavioral health outpatient (90837)',
      coinsurancePercent: 20.0,
      deductibleAmountCents: 350000, // $3,500
      deductibleMetCents: 120000, // $1,200 met
      deductibleRemainingCents: 230000, // $2,300 remaining
      outOfPocketMaxCents: 700000, // $7,000
      outOfPocketMetCents: 120000,
      outOfPocketRemainingCents: 580000, // $5,800
      networkStatus: EdenInsuranceNetworkStatus.inNetwork,
    );
  }

  /// Out-of-network specialist visit, denied.
  static EdenEligibilityResult outOfNetworkDenied({
    String patientId = 'patient-bravo',
    String policyId = 'policy-uhc-001',
  }) {
    return EdenEligibilityResult(
      id: 'elig-bravo-001',
      patientId: patientId,
      policyId: policyId,
      checkedAt: DateTime(2026, 5, 16),
      coverageStatus: EdenCoverageStatus.notCovered,
      planName: 'UnitedHealthcare Choice Plus',
      serviceType: 'Specialist visit (psychiatry)',
      networkStatus: EdenInsuranceNetworkStatus.outOfNetwork,
    );
  }

  /// TMS therapy under Cigna OAP — coverage exists but prior auth pending.
  static EdenEligibilityResult needsAuthPending({
    String patientId = 'patient-charlie',
    String policyId = 'policy-cigna-001',
  }) {
    return EdenEligibilityResult(
      id: 'elig-charlie-001',
      patientId: patientId,
      policyId: policyId,
      checkedAt: DateTime(2026, 5, 14),
      coverageStatus: EdenCoverageStatus.needsAuth,
      planName: 'Cigna Open Access Plus',
      serviceType: 'TMS therapy (90867)',
      coinsurancePercent: 30.0,
      deductibleAmountCents: 150000, // $1,500
      deductibleMetCents: 150000,
      deductibleRemainingCents: 0,
      networkStatus: EdenInsuranceNetworkStatus.inNetwork,
      priorAuthRequired: true,
      priorAuthStatus: EdenPriorAuthStatus.pending,
    );
  }

  /// Medicare Part B with a 90-day-old check — triggers stale-check warning.
  static EdenEligibilityResult staleCheckNinetyDaysOld({
    String patientId = 'patient-delta',
    String policyId = 'policy-medicare-001',
  }) {
    return EdenEligibilityResult(
      id: 'elig-delta-001',
      patientId: patientId,
      policyId: policyId,
      checkedAt: DateTime(2026, 2, 15), // 91 days before 2026-05-17 anchor
      coverageStatus: EdenCoverageStatus.covered,
      planName: 'Medicare Part B',
      serviceType: 'Office visit (99213)',
      coinsurancePercent: 20.0,
      networkStatus: EdenInsuranceNetworkStatus.inNetwork,
    );
  }

  /// Aetna HMO specialist referral required.
  static EdenEligibilityResult referralRequired({
    String patientId = 'patient-alpha',
    String policyId = 'policy-aetna-001',
  }) {
    return EdenEligibilityResult(
      id: 'elig-alpha-003',
      patientId: patientId,
      policyId: policyId,
      checkedAt: DateTime(2026, 5, 16),
      coverageStatus: EdenCoverageStatus.covered,
      planName: 'Aetna HMO',
      serviceType: 'Specialist visit (cardiology)',
      copayCents: 5000, // $50
      networkStatus: EdenInsuranceNetworkStatus.inNetwork,
      referralRequired: true,
    );
  }
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenCommissionsEditor.
//
// Vertical-archetype commission rules used across the test suite and dev
// catalog for obj 015-04. Percents are stored as fractions 0..1.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenCommissionsEditorFixtures {
  /// Salon — senior stylist 50% flat percent.
  static const EdenCommissionRule percentRuleSalon = EdenCommissionRule(
    id: 'r-1',
    label: 'Senior stylist — 50%',
    mode: EdenCommissionMode.percent,
    percent: 0.50,
  );

  /// Retail — \$3 flat per qualifying sale.
  static const EdenCommissionRule fixedRuleRetail = EdenCommissionRule(
    id: 'r-2',
    label: 'Retail associate — \$3 flat',
    mode: EdenCommissionMode.fixed,
    fixedAmount: 3.00,
  );

  /// Trades — HVAC technician tiered 5/8/10/12% over thresholds.
  static const EdenCommissionRule tieredRuleTrades = EdenCommissionRule(
    id: 'r-3',
    label: 'HVAC technician tiered',
    mode: EdenCommissionMode.tiered,
    tiers: <EdenCommissionTier>[
      EdenCommissionTier(thresholdAmount: 0.0, rate: 0.05),
      EdenCommissionTier(thresholdAmount: 1000.0, rate: 0.08),
      EdenCommissionTier(thresholdAmount: 2500.0, rate: 0.10),
      EdenCommissionTier(thresholdAmount: 5000.0, rate: 0.12),
    ],
  );

  /// Salon chair split — stylist 80% / assistant 15% / chair 5%.
  static const EdenCommissionRule splitRuleSalonChair = EdenCommissionRule(
    id: 'r-4',
    label: 'Salon chair — 80/15/5 split',
    mode: EdenCommissionMode.split,
    splits: <EdenCommissionSplitParticipant>[
      EdenCommissionSplitParticipant(
        id: 'sarah',
        displayName: 'Sarah',
        sharePercent: 0.80,
      ),
      EdenCommissionSplitParticipant(
        id: 'mia',
        displayName: 'Mia',
        sharePercent: 0.15,
      ),
      EdenCommissionSplitParticipant(
        id: 'chair',
        displayName: 'Chair',
        sharePercent: 0.05,
      ),
    ],
  );
}

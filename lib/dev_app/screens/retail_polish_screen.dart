import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 018 — Retail-Specific Polish.
///
/// TRD 018-01 creates the file with the [EdenLoyaltyMemberDetail] section.
/// TRDs 018-02 through 018-06 each append additional `Section(...)` entries
/// at the marked anchor comments — they do NOT re-create the file.
class RetailPolishScreen extends StatelessWidget {
  const RetailPolishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B-Retail — Customer & Service Flows')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // ─── Wave 1 — Atomic primitives ────────────────────────────────
          Section(
            title:
                'EdenLoyaltyMemberDetail — loyalty profile (tier + points + recent purchases)',
            child: _LoyaltyMemberDetailDemoBlock(),
          ),
          // TRD 018-02 will append:
          // TRD 018-03 will append:
          // ─── Wave 2 — Multi-step flows ─────────────────────────────────
          // TRD 018-04 will append:
          // TRD 018-05 will append:
          // TRD 018-06 will append:
        ],
      ),
    );
  }
}

/// Hand-built sample data — mirrors
/// test/widgets/_fixtures/eden_loyalty_member_detail_fixtures.dart::janeGold().
/// Do NOT regenerate via LLM.
class _LoyaltyMemberDetailDemoBlock extends StatelessWidget {
  const _LoyaltyMemberDetailDemoBlock();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final member = EdenLoyaltyMember(
      id: 'c-1',
      name: 'Jane Doe',
      tier: EdenMembershipTier.gold,
      points: 1247,
      lifetimeSpendCents: 18950,
      birthday: DateTime(now.year - 32, now.month, now.day + 3),
      joinedAt: DateTime(now.year - 2, now.month, 1),
      recentPurchases: [
        EdenLoyaltyPurchase(
          id: 'p-1',
          occurredAt: now.subtract(const Duration(days: 1)),
          totalCents: 1875,
          lineCount: 3,
          locationName: 'Downtown',
        ),
        EdenLoyaltyPurchase(
          id: 'p-2',
          occurredAt: now.subtract(const Duration(days: 7)),
          totalCents: 4200,
          lineCount: 5,
          locationName: 'Downtown',
        ),
        EdenLoyaltyPurchase(
          id: 'p-3',
          occurredAt: now.subtract(const Duration(days: 21)),
          totalCents: 950,
          lineCount: 1,
          locationName: 'Airport',
        ),
      ],
    );
    return SizedBox(
      width: 600,
      child: EdenLoyaltyMemberDetail(member: member),
    );
  }
}

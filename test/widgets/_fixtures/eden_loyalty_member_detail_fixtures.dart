// Do NOT regenerate via LLM — hand-built fixtures for EdenLoyaltyMemberDetail.
//
// Anchor time `_t0` keeps relative-time / birthday-window / days-since-visit
// computations deterministic across the suite. Tests inject `now: _t0`
// explicitly into `EdenLoyaltyMemberDetail.now`.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenLoyaltyMemberFixtures {
  EdenLoyaltyMemberFixtures._();

  /// Deterministic anchor time used by every fixture + every test that
  /// renders one of these members.
  static DateTime get t0 => DateTime(2026, 5, 17, 12, 0, 0);

  /// Jane Doe — gold tier, birthday +3 days, joined 2 years ago, 3 recents.
  static EdenLoyaltyMember janeGold({DateTime? now}) {
    final n = now ?? t0;
    return EdenLoyaltyMember(
      id: 'c-1',
      name: 'Jane Doe',
      tier: EdenMembershipTier.gold,
      points: 1247,
      lifetimeSpendCents: 18950,
      birthday: DateTime(n.year - 32, n.month, n.day + 3),
      joinedAt: DateTime(n.year - 2, n.month, 1),
      recentPurchases: [
        EdenLoyaltyPurchase(
          id: 'p-1',
          occurredAt: n.subtract(const Duration(days: 1)),
          totalCents: 1875,
          lineCount: 3,
          locationName: 'Downtown',
        ),
        EdenLoyaltyPurchase(
          id: 'p-2',
          occurredAt: n.subtract(const Duration(days: 7)),
          totalCents: 4200,
          lineCount: 5,
          locationName: 'Downtown',
        ),
        EdenLoyaltyPurchase(
          id: 'p-3',
          occurredAt: n.subtract(const Duration(days: 21)),
          totalCents: 950,
          lineCount: 1,
          locationName: 'Airport',
        ),
      ],
    );
  }

  /// Silver / budget customer — no birthday, no joinedAt, 1 recent.
  static EdenLoyaltyMember silverBudget({DateTime? now}) {
    final n = now ?? t0;
    return EdenLoyaltyMember(
      id: 'c-2',
      name: 'Sam Lee',
      tier: EdenMembershipTier.silver,
      points: 80,
      lifetimeSpendCents: 4200,
      recentPurchases: [
        EdenLoyaltyPurchase(
          id: 'p-10',
          occurredAt: n.subtract(const Duration(days: 3)),
          totalCents: 4200,
          lineCount: 2,
        ),
      ],
    );
  }

  /// Platinum customer whose birthday is exactly today (now).
  static EdenLoyaltyMember platinumWithBirthday({DateTime? now}) {
    final n = now ?? t0;
    return EdenLoyaltyMember(
      id: 'c-3',
      name: 'Olivia Martinez',
      tier: EdenMembershipTier.platinum,
      points: 5800,
      lifetimeSpendCents: 250000,
      birthday: DateTime(n.year - 40, n.month, n.day),
      joinedAt: DateTime(n.year - 5, 1, 1),
      recentPurchases: [
        EdenLoyaltyPurchase(
          id: 'p-20',
          occurredAt: n.subtract(const Duration(hours: 2)),
          totalCents: 12000,
          lineCount: 4,
          locationName: 'Flagship',
        ),
      ],
    );
  }

  /// No preset tier + no custom tier label — header should hide the badge.
  static EdenLoyaltyMember tierless() {
    return const EdenLoyaltyMember(
      id: 'c-4',
      name: 'Pat Nguyen',
      recentPurchases: [],
    );
  }

  /// Custom (non-preset) tier — "Concierge" label with caller-supplied colors.
  static EdenLoyaltyMember customTier({DateTime? now}) {
    final n = now ?? t0;
    return EdenLoyaltyMember(
      id: 'c-5',
      name: 'Riley Park',
      customTierLabel: 'Concierge',
      customTierBackground: const Color(0xFF1F2937),
      customTierForeground: const Color(0xFFFEF3C7),
      points: 320,
      lifetimeSpendCents: 75000,
      joinedAt: DateTime(n.year - 1, 3, 15),
    );
  }

  /// Dec 30 birthday — exercises year-wrap window check when `now` is Jan 5.
  static EdenLoyaltyMember yearWrapBirthday() {
    return EdenLoyaltyMember(
      id: 'c-6',
      name: 'Casey Brown',
      tier: EdenMembershipTier.bronze,
      birthday: _decThirtyBirthday,
    );
  }

  /// Same shape as janeGold but with no purchase history.
  static EdenLoyaltyMember emptyHistory({DateTime? now}) {
    final n = now ?? t0;
    return EdenLoyaltyMember(
      id: 'c-7',
      name: 'Jane Doe',
      tier: EdenMembershipTier.gold,
      points: 1247,
      lifetimeSpendCents: 18950,
      joinedAt: DateTime(n.year - 2, n.month, 1),
      recentPurchases: const [],
    );
  }

  static final DateTime _decThirtyBirthday = DateTime(1990, 12, 30);
}

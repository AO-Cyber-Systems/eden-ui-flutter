// Do NOT regenerate via LLM — hand-built fixtures for EdenMembershipManager + EdenPackageRedeem.
//
// Powers obj 016-03 tests. Susan M. Goldman is the canonical persona — Gold
// tier with realistic salon benefits: 2 haircuts/month + Color unlimited +
// 5 add-ons/month. Status fixtures cover all 4 EdenMembershipStatus values.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenMembershipManagerFixtures {
  EdenMembershipManagerFixtures._();

  static EdenMembership goldActive() {
    return EdenMembership(
      id: 'mem-001',
      customerId: 'cust-susan',
      customerDisplayName: 'Susan M. Goldman',
      tier: EdenMembershipTier.gold,
      tierLabel: 'Gold',
      monthlyPriceCents: 8900,
      startedAt: DateTime(2025, 11, 17),
      nextBillingAt: DateTime(2026, 6, 17),
      status: EdenMembershipStatus.active,
      benefits: const [
        EdenMembershipBenefit(
          id: 'b-cut',
          label: 'Haircuts',
          remainingThisCycle: 1,
          totalThisCycle: 2,
        ),
        EdenMembershipBenefit(id: 'b-color', label: 'Color'),
        EdenMembershipBenefit(
          id: 'b-addon',
          label: 'Add-ons',
          remainingThisCycle: 3,
          totalThisCycle: 5,
        ),
      ],
    );
  }

  static EdenMembership silverPaused() {
    return EdenMembership(
      id: 'mem-002',
      customerId: 'cust-paul',
      customerDisplayName: 'Paul P. Patterson',
      tier: EdenMembershipTier.silver,
      tierLabel: 'Silver',
      monthlyPriceCents: 4900,
      startedAt: DateTime(2025, 9, 1),
      nextBillingAt: DateTime(2026, 6, 1),
      status: EdenMembershipStatus.paused,
    );
  }

  static EdenMembership platinumCancelled() {
    return EdenMembership(
      id: 'mem-003',
      customerId: 'cust-carla',
      customerDisplayName: 'Carla C. Cancelled',
      tier: EdenMembershipTier.platinum,
      tierLabel: 'Platinum',
      monthlyPriceCents: 14900,
      startedAt: DateTime(2024, 6, 1),
      nextBillingAt: DateTime(2026, 6, 1),
      status: EdenMembershipStatus.cancelled,
    );
  }

  static EdenMembership vipPastDue() {
    return EdenMembership(
      id: 'mem-004',
      customerId: 'cust-victor',
      customerDisplayName: 'Victor V. PastDue',
      tier: EdenMembershipTier.vip,
      tierLabel: 'VIP',
      monthlyPriceCents: 29900,
      startedAt: DateTime(2024, 1, 1),
      nextBillingAt: DateTime(2026, 5, 1),
      status: EdenMembershipStatus.pastDue,
    );
  }
}

class EdenPackageRedeemFixtures {
  EdenPackageRedeemFixtures._();

  static List<EdenPackage> susanPackages() {
    return [
      EdenPackage(
        id: 'pkg-cutcolor-6',
        customerId: 'cust-susan',
        name: 'Cut & Color 6-Pack',
        totalVisits: 6,
        remainingVisits: 3,
        purchasedAt: DateTime(2026, 3, 15),
        expiresAt: DateTime(2026, 9, 15),
        applicableServices: const ['srv-haircut-women', 'srv-full-color'],
      ),
      EdenPackage(
        id: 'pkg-bday',
        customerId: 'cust-susan',
        name: 'Birthday Special',
        totalVisits: 1,
        remainingVisits: 1,
        purchasedAt: DateTime(2026, 2, 3),
        expiresAt: DateTime(2026, 8, 3),
        applicableServices: const ['srv-haircut-women'],
      ),
      EdenPackage(
        id: 'pkg-facial-10',
        customerId: 'cust-susan',
        name: 'Facial 10-Pack',
        totalVisits: 10,
        remainingVisits: 7,
        purchasedAt: DateTime(2026, 1, 1),
        applicableServices: const ['srv-facial-basic'],
      ),
    ];
  }

  static const EdenServiceCatalogEntry haircutEntry = EdenServiceCatalogEntry(
    id: 'srv-haircut-women',
    name: "Women's Haircut",
    durationMinutes: 45,
    priceCents: 8500,
  );

  static const EdenServiceCatalogEntry facialEntry = EdenServiceCatalogEntry(
    id: 'srv-facial-basic',
    name: 'Express Facial',
    durationMinutes: 30,
    priceCents: 5500,
  );

  static const EdenServiceCatalogEntry unmatchableEntry =
      EdenServiceCatalogEntry(
    id: 'srv-massage',
    name: 'Massage',
    durationMinutes: 60,
    priceCents: 8500,
  );

  static EdenPackage packageExpired() {
    return EdenPackage(
      id: 'pkg-expired',
      customerId: 'cust-x',
      name: 'Old Pack',
      totalVisits: 5,
      remainingVisits: 2,
      purchasedAt: DateTime(2024, 1, 1),
      expiresAt: DateTime(2025, 1, 1),
      applicableServices: const ['srv-haircut-women'],
    );
  }

  static EdenPackage packageNoExpiry() {
    return EdenPackage(
      id: 'pkg-no-expiry',
      customerId: 'cust-x',
      name: 'Lifetime',
      totalVisits: 100,
      remainingVisits: 50,
      purchasedAt: DateTime(2024, 1, 1),
      applicableServices: const ['srv-haircut-women'],
    );
  }

  static EdenPackage packageFutureExpiry() {
    return EdenPackage(
      id: 'pkg-future',
      customerId: 'cust-x',
      name: 'Future-Expiry',
      totalVisits: 5,
      remainingVisits: 4,
      purchasedAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2027, 1, 1),
      applicableServices: const ['srv-haircut-women'],
    );
  }
}

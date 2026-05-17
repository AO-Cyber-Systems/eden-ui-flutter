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
          // TRD 018-02 appended above.
          Section(
            title:
                'EdenStoreCreditLedger — store-credit balance + history + holds',
            child: _StoreCreditLedgerDemoBlock(),
          ),
          // TRD 018-03 appended above.
          Section(
            title:
                'EdenGiftCardBalanceLookup — gift-card balance + activity',
            child: _GiftCardBalanceLookupDemoBlock(),
          ),
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

/// Hand-built sample data — mirrors
/// test/widgets/_fixtures/eden_store_credit_ledger_fixtures.dart::activeWithHolds().
/// Do NOT regenerate via LLM.
class _StoreCreditLedgerDemoBlock extends StatelessWidget {
  const _StoreCreditLedgerDemoBlock();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final data = EdenStoreCreditLedgerData(
      customerId: 'c-1',
      customerName: 'Jane Doe',
      balanceCents: 8750,
      holds: [
        EdenStoreCreditHold(
          id: 'h-1',
          holdAmountCents: 1500,
          holdReason: 'Pending refund verification',
          placedAt: now.subtract(const Duration(hours: 6)),
        ),
      ],
      history: [
        EdenStoreCreditEntry(
          id: 'e-1',
          occurredAt: now.subtract(const Duration(days: 2)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 5000,
          reason: 'No-receipt return',
          receiptRef: 'R-1003',
        ),
        EdenStoreCreditEntry(
          id: 'e-2',
          occurredAt: now.subtract(const Duration(days: 5)),
          type: EdenStoreCreditEntryType.spent,
          amountCents: -2250,
          reason: 'Applied to sale',
          receiptRef: 'R-1011',
        ),
        EdenStoreCreditEntry(
          id: 'e-3',
          occurredAt: now.subtract(const Duration(days: 15)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 6000,
          reason: 'Loyalty bonus',
        ),
        EdenStoreCreditEntry(
          id: 'e-4',
          occurredAt: now.subtract(const Duration(days: 30)),
          type: EdenStoreCreditEntryType.adjustment,
          amountCents: -750,
          reason: 'Manager correction',
        ),
      ],
    );
    return SizedBox(width: 800, child: EdenStoreCreditLedger(data: data));
  }
}

/// Hand-built demo lookup function for EdenGiftCardBalanceLookup.
/// Do NOT regenerate via LLM.
class _GiftCardBalanceLookupDemoBlock extends StatelessWidget {
  const _GiftCardBalanceLookupDemoBlock();

  static Future<EdenGiftCardBalanceResult?> _demoLookup(
      String cardNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final clean = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    if (clean.endsWith('0000')) return null; // not found
    if (clean.endsWith('1111')) {
      return EdenGiftCardBalanceResult(
        cardNumber: clean,
        balanceCents: 0,
        status: EdenGiftCardStatus.deactivated,
      );
    }
    final now = DateTime.now();
    return EdenGiftCardBalanceResult(
      cardNumber: clean,
      balanceCents: 4250,
      status: EdenGiftCardStatus.active,
      lastUsedAt: now.subtract(const Duration(days: 5)),
      expiresAt: DateTime(now.year + 2, now.month, now.day),
      recentActivity: [
        EdenGiftCardActivity(
          id: 'a-1',
          occurredAt: now.subtract(const Duration(days: 5)),
          type: EdenGiftCardActivityType.redeemed,
          amountCents: -1500,
          reason: 'POS sale',
          receiptRef: 'R-2103',
        ),
        EdenGiftCardActivity(
          id: 'a-2',
          occurredAt: now.subtract(const Duration(days: 12)),
          type: EdenGiftCardActivityType.loaded,
          amountCents: 5000,
          reason: 'New card',
          receiptRef: 'R-2087',
        ),
        EdenGiftCardActivity(
          id: 'a-3',
          occurredAt: now.subtract(const Duration(days: 18)),
          type: EdenGiftCardActivityType.adjustment,
          amountCents: 750,
          reason: 'Promo bonus',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 600,
      child: EdenGiftCardBalanceLookup(onLookup: _demoLookup),
    );
  }
}

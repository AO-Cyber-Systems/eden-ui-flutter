// Do NOT regenerate via LLM — hand-built fixtures for EdenGiftCardManager.
//
// Sample cards + ledger entries used across the test suite and dev
// catalog for obj 015-03.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenGiftCardManagerFixtures {
  static final EdenGiftCardRecord sampleGiftCard = EdenGiftCardRecord(
    code: 'GC123456789',
    initialAmount: 100.0,
    currentBalance: 67.50,
    issuedAt: DateTime(2026, 1, 15),
    recipientName: 'Maya Rivera',
    recipientContact: 'maya@example.com',
  );

  static final EdenGiftCardRecord zeroBalanceCard = EdenGiftCardRecord(
    code: 'GC987654321',
    initialAmount: 50.0,
    currentBalance: 0.0,
    issuedAt: DateTime(2025, 12, 10),
    recipientName: 'Devon Park',
  );

  static final EdenGiftCardRecord expiringSoonCard = EdenGiftCardRecord(
    code: 'GC555444333',
    initialAmount: 25.0,
    currentBalance: 12.75,
    issuedAt: DateTime(2025, 5, 20),
    expiresAt: DateTime(2026, 5, 30),
    recipientName: 'Jordan Lee',
  );

  static final List<EdenGiftCardLedgerEntry> sampleLedger = [
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 1, 15, 10, 30),
      action: EdenGiftCardLedgerAction.issue,
      amount: 100.0,
      balanceAfter: 100.0,
      memo: 'Original sale',
    ),
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 1, 20, 14, 15),
      action: EdenGiftCardLedgerAction.redeem,
      amount: -25.0,
      balanceAfter: 75.0,
      memo: 'Haircut',
    ),
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 2, 5, 11, 0),
      action: EdenGiftCardLedgerAction.redeem,
      amount: -7.50,
      balanceAfter: 67.50,
      memo: 'Tip add-on',
    ),
    EdenGiftCardLedgerEntry(
      occurredAt: DateTime(2026, 3, 14, 9, 0),
      action: EdenGiftCardLedgerAction.adjustment,
      amount: 0.0,
      balanceAfter: 67.50,
      memo: 'Manager review (no change)',
    ),
  ];
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenStoreCreditLedger.
//
// Anchor time `t0` keeps history-sort + date-format computations deterministic.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenStoreCreditLedgerFixtures {
  EdenStoreCreditLedgerFixtures._();

  static DateTime get t0 => DateTime(2026, 5, 17, 12, 0, 0);

  /// No history, no holds, zero balance.
  static EdenStoreCreditLedgerData empty() {
    return const EdenStoreCreditLedgerData(
      customerId: 'c-empty',
      customerName: 'Pat Nguyen',
      balanceCents: 0,
    );
  }

  /// $87.50 balance, 1 hold @ $15, 4 history entries with mixed signs/types.
  static EdenStoreCreditLedgerData activeWithHolds({DateTime? now}) {
    final n = now ?? t0;
    return EdenStoreCreditLedgerData(
      customerId: 'c-1',
      customerName: 'Jane Doe',
      balanceCents: 8750,
      holds: [
        EdenStoreCreditHold(
          id: 'h-1',
          holdAmountCents: 1500,
          holdReason: 'Pending refund verification',
          placedAt: n.subtract(const Duration(hours: 6)),
        ),
      ],
      history: [
        EdenStoreCreditEntry(
          id: 'e-1',
          occurredAt: n.subtract(const Duration(days: 2)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 5000,
          reason: 'No-receipt return',
          receiptRef: 'R-1003',
        ),
        EdenStoreCreditEntry(
          id: 'e-2',
          occurredAt: n.subtract(const Duration(days: 5)),
          type: EdenStoreCreditEntryType.spent,
          amountCents: -2250,
          reason: 'Applied to sale',
          receiptRef: 'R-1011',
        ),
        EdenStoreCreditEntry(
          id: 'e-3',
          occurredAt: n.subtract(const Duration(days: 15)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 6000,
          reason: 'Loyalty bonus',
        ),
        EdenStoreCreditEntry(
          id: 'e-4',
          occurredAt: n.subtract(const Duration(days: 30)),
          type: EdenStoreCreditEntryType.adjustment,
          amountCents: -750,
          reason: 'Manager correction',
        ),
      ],
    );
  }

  /// Balance 0, 2 history entries ($50 issued then -$50 spent).
  static EdenStoreCreditLedgerData zeroBalance({DateTime? now}) {
    final n = now ?? t0;
    return EdenStoreCreditLedgerData(
      customerId: 'c-zero',
      customerName: 'Sam Lee',
      balanceCents: 0,
      history: [
        EdenStoreCreditEntry(
          id: 'z-1',
          occurredAt: n.subtract(const Duration(days: 1)),
          type: EdenStoreCreditEntryType.spent,
          amountCents: -5000,
          reason: 'Purchase #889',
          receiptRef: 'R-889',
        ),
        EdenStoreCreditEntry(
          id: 'z-2',
          occurredAt: n.subtract(const Duration(days: 10)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 5000,
          reason: 'Birthday credit',
        ),
      ],
    );
  }

  /// Negative balance.
  static EdenStoreCreditLedgerData overdrawn({DateTime? now}) {
    final n = now ?? t0;
    return EdenStoreCreditLedgerData(
      customerId: 'c-over',
      customerName: 'Casey Brown',
      balanceCents: -500,
      history: [
        EdenStoreCreditEntry(
          id: 'o-1',
          occurredAt: n.subtract(const Duration(days: 1)),
          type: EdenStoreCreditEntryType.adjustment,
          amountCents: -500,
          reason: 'Reversal',
        ),
      ],
    );
  }

  /// 15 entries with mixed types for narrow-mode overflow tests.
  static EdenStoreCreditLedgerData longHistory({DateTime? now}) {
    final n = now ?? t0;
    final entries = <EdenStoreCreditEntry>[];
    for (var i = 0; i < 15; i++) {
      final isIssued = i % 3 == 0;
      final isSpent = i % 3 == 1;
      final type = isIssued
          ? EdenStoreCreditEntryType.issued
          : (isSpent
              ? EdenStoreCreditEntryType.spent
              : EdenStoreCreditEntryType.adjustment);
      final amount =
          isIssued ? 1000 + (i * 100) : -(500 + (i * 50));
      entries.add(EdenStoreCreditEntry(
        id: 'long-$i',
        occurredAt: n.subtract(Duration(days: i)),
        type: type,
        amountCents: amount,
        reason: 'Entry $i',
      ));
    }
    return EdenStoreCreditLedgerData(
      customerId: 'c-long',
      customerName: 'Riley Park',
      balanceCents: 25000,
      history: entries,
    );
  }

  /// Holds present + history empty (exercises empty-state + holds-row combo).
  static EdenStoreCreditLedgerData emptyHistoryWithHolds({DateTime? now}) {
    final n = now ?? t0;
    return EdenStoreCreditLedgerData(
      customerId: 'c-eh',
      customerName: 'Olivia Martinez',
      balanceCents: 2000,
      holds: [
        EdenStoreCreditHold(
          id: 'eh-1',
          holdAmountCents: 500,
          holdReason: 'Awaiting refund',
          placedAt: n.subtract(const Duration(hours: 2)),
        ),
      ],
      history: const [],
    );
  }

  /// No customerName → header falls back to 'Customer #c-anon'.
  static EdenStoreCreditLedgerData unnamed() {
    return const EdenStoreCreditLedgerData(
      customerId: 'c-anon',
      balanceCents: 0,
    );
  }
}

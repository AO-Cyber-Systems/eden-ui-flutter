import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_badge.dart';
import 'eden_currency_display.dart';
import 'eden_data_table.dart';
import 'eden_empty_state.dart';

// ─────────────────────────────────────────────────────────────────────────
// Enum + value classes
// ─────────────────────────────────────────────────────────────────────────

/// Store-credit ledger entry type. Drives the Type-column badge color/label.
/// The SIGN of [EdenStoreCreditEntry.amountCents] (not the type) determines
/// the +/- color on the amount cell.
enum EdenStoreCreditEntryType { issued, spent, adjustment, expired }

@immutable
class EdenStoreCreditEntry {
  const EdenStoreCreditEntry({
    required this.id,
    required this.occurredAt,
    required this.type,
    required this.amountCents,
    this.reason,
    this.receiptRef,
  });

  final String id;
  final DateTime occurredAt;
  final EdenStoreCreditEntryType type;

  /// Signed amount in cents. Issued / positive-adjustment are positive;
  /// spent / expired / negative-adjustment are negative. Render color follows
  /// the sign — `type` does NOT determine sign.
  final int amountCents;

  final String? reason;
  final String? receiptRef;
}

@immutable
class EdenStoreCreditHold {
  const EdenStoreCreditHold({
    required this.id,
    required this.holdAmountCents,
    required this.holdReason,
    required this.placedAt,
    this.expiresAt,
  });

  final String id;

  /// Always positive — the absolute amount reserved against the balance.
  final int holdAmountCents;

  final String holdReason;
  final DateTime placedAt;
  final DateTime? expiresAt;
}

@immutable
class EdenStoreCreditLedgerData {
  const EdenStoreCreditLedgerData({
    required this.customerId,
    this.customerName,
    required this.balanceCents,
    this.history = const [],
    this.holds = const [],
  });

  final String customerId;
  final String? customerName;

  /// Signed balance. Consumer policy decides whether negative is legal.
  final int balanceCents;

  final List<EdenStoreCreditEntry> history;
  final List<EdenStoreCreditHold> holds;
}

// ─────────────────────────────────────────────────────────────────────────
// Library-private top-level helpers (exposed for unit tests; not part of
// the public API surface — prefix `edenStoreCredit*`).
// ─────────────────────────────────────────────────────────────────────────

int edenStoreCreditHoldsTotal(List<EdenStoreCreditHold> holds) =>
    holds.fold<int>(0, (acc, h) => acc + h.holdAmountCents);

/// Signed dollar formatting. 0 → '+\$0.00' (positive sign for zero).
String edenStoreCreditFormatSignedMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : '+'}\$$dollars.$fraction';
}

String edenStoreCreditTypeLabel(EdenStoreCreditEntryType t) {
  switch (t) {
    case EdenStoreCreditEntryType.issued:
      return 'Issued';
    case EdenStoreCreditEntryType.spent:
      return 'Spent';
    case EdenStoreCreditEntryType.adjustment:
      return 'Adjustment';
    case EdenStoreCreditEntryType.expired:
      return 'Expired';
  }
}

EdenBadgeVariant edenStoreCreditTypeBadgeVariant(EdenStoreCreditEntryType t) {
  switch (t) {
    case EdenStoreCreditEntryType.issued:
      return EdenBadgeVariant.success;
    case EdenStoreCreditEntryType.spent:
      return EdenBadgeVariant.info;
    case EdenStoreCreditEntryType.adjustment:
      return EdenBadgeVariant.warning;
    case EdenStoreCreditEntryType.expired:
      return EdenBadgeVariant.neutral;
  }
}

const List<String> _kStoreCreditMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String edenStoreCreditFormatDate(DateTime d, DateTime now) {
  if (d.year == now.year) {
    return '${_kStoreCreditMonths[d.month - 1]} ${d.day}';
  }
  return '${_kStoreCreditMonths[d.month - 1]} ${d.day}, ${d.year}';
}

/// Stable DESC sort by `occurredAt`.
List<EdenStoreCreditEntry> edenStoreCreditSortedHistory(
  List<EdenStoreCreditEntry> h,
) {
  final copy = [...h];
  copy.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return copy;
}

// ─────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────

/// Customer-attached store-credit balance + history surface.
///
/// Layout (top → bottom):
///   1. Header: customer name (or `Customer #${customerId}` fallback) +
///      large balance via [EdenCurrencyDisplay].
///   2. Holds sub-row (conditional, when `data.holds.isNotEmpty`): hold-total
///      + 'Available: balance - holdsTotal' + count of active holds.
///   3. History:
///      - ≥`narrowBreakpoint`: [EdenDataTable] with 5 columns.
///      - <`narrowBreakpoint`: vertical [Card] stack (one Card per entry).
///      - empty: [EdenEmptyState].
///
/// Pure data — no callbacks, no validation, no balance/hold integrity checks.
/// Consumer policy concerns (overdraft, hold-vs-balance, expiry filtering).
class EdenStoreCreditLedger extends StatelessWidget {
  const EdenStoreCreditLedger({
    super.key,
    required this.data,
    this.now,
    this.narrowBreakpoint = 700,
  });

  final EdenStoreCreditLedgerData data;

  /// Injectable clock for deterministic tests. Defaults to `DateTime.now()`.
  final DateTime? now;

  /// Width below which the history view collapses to a [Card] stack.
  /// Default 700pt.
  final double narrowBreakpoint;

  DateTime _now() => now ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        _buildHoldsRow(context),
        const SizedBox(height: EdenSpacing.space4),
        _buildHistoryView(context),
      ],
    );
  }

  // ───── Header ─────
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final name = data.customerName ?? 'Customer #${data.customerId}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Store credit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        EdenCurrencyDisplay(
          cents: data.balanceCents,
          style: theme.textTheme.headlineMedium,
        ),
      ],
    );
  }

  // ───── Holds sub-row ─────
  Widget _buildHoldsRow(BuildContext context) {
    if (data.holds.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final total = edenStoreCreditHoldsTotal(data.holds);
    final available = data.balanceCents - total;
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space3),
      child: Wrap(
        spacing: EdenSpacing.space4,
        runSpacing: EdenSpacing.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EdenBadge(
                label: 'On hold',
                variant: EdenBadgeVariant.warning,
                size: EdenBadgeSize.sm,
              ),
              const SizedBox(width: 8),
              EdenCurrencyDisplay(cents: total),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              EdenCurrencyDisplay(cents: available),
            ],
          ),
          Text(
            '${data.holds.length} active hold(s)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ───── History view ─────
  Widget _buildHistoryView(BuildContext context) {
    if (data.history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EdenEmptyState(
          icon: Icons.history_toggle_off,
          title: 'No store-credit history',
          description:
              'This customer has no recorded credit activity yet.',
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= narrowBreakpoint) {
          return _buildHistoryTable(context);
        }
        return _buildHistoryCards(context);
      },
    );
  }

  Widget _buildHistoryTable(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = edenStoreCreditSortedHistory(data.history);
    final n = _now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('History', style: theme.textTheme.titleMedium),
        ),
        EdenDataTable(
          columns: const [
            EdenTableColumn(label: 'Date'),
            EdenTableColumn(label: 'Type', flex: 2),
            EdenTableColumn(label: 'Amount'),
            EdenTableColumn(label: 'Reason', flex: 2),
            EdenTableColumn(label: 'Receipt #'),
          ],
          rows: [
            for (final e in sorted)
              EdenTableRow(cells: [
                Text(edenStoreCreditFormatDate(e.occurredAt, n)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: EdenBadge(
                      label: edenStoreCreditTypeLabel(e.type),
                      variant: edenStoreCreditTypeBadgeVariant(e.type),
                      size: EdenBadgeSize.sm,
                    ),
                  ),
                ),
                Text(
                  edenStoreCreditFormatSignedMoney(e.amountCents),
                  style: TextStyle(
                    color: e.amountCents >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(e.reason ?? '—', overflow: TextOverflow.ellipsis),
                Text(e.receiptRef ?? '—', overflow: TextOverflow.ellipsis),
              ]),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryCards(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = edenStoreCreditSortedHistory(data.history);
    final n = _now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('History', style: theme.textTheme.titleMedium),
        ),
        for (final e in sorted)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EdenBadge(
                        label: edenStoreCreditTypeLabel(e.type),
                        variant: edenStoreCreditTypeBadgeVariant(e.type),
                        size: EdenBadgeSize.sm,
                      ),
                      const Spacer(),
                      Text(
                        edenStoreCreditFormatSignedMoney(e.amountCents),
                        style: TextStyle(
                          color: e.amountCents >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    edenStoreCreditFormatDate(e.occurredAt, n),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (e.reason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(e.reason!),
                    ),
                  if (e.receiptRef != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Receipt: ${e.receiptRef}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

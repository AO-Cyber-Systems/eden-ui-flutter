import 'package:flutter/material.dart';

import 'eden_currency_display.dart';

/// A named extra row to add to [EdenCostSummaryCard].
///
/// Extra rows are rendered as additional line items between the canonical
/// labor / materials / equipment rows and the total. **Their cents value
/// does NOT contribute to the displayed total** — this matches donor
/// behaviour (`trades-flutter`) where the total is intentionally the
/// labor+material+equipment subtotal so consumers can present taxes /
/// permits / subcontractor pass-throughs separately without inflating the
/// "core" total. If a consumer needs an inclusive total, they should sum
/// the rows themselves and override the title rather than mutate this widget.
class EdenCostRow {
  const EdenCostRow({required this.label, required this.cents});

  final String label;
  final int cents;
}

/// Cross-vertical cost-breakdown card.
///
/// Renders a Material `Card` showing four monetary lines:
/// 1. Labor
/// 2. Materials
/// 3. Equipment
/// 4. Each `extraRows` entry (in order; NOT included in total)
/// followed by a `Divider` and a bold **Total** row tinted with
/// `theme.colorScheme.primary`.
///
/// All values are in cents and render via [EdenCurrencyDisplay].
///
/// Cross-vertical examples:
/// - Trades: work-order cost summary, bid breakdowns.
/// - Salon: service-package breakdown.
/// - Medical: treatment cost.
/// - Legal: matter billing summary.
/// - Government: budget rollup.
/// - Retail: cart breakdown.
///
/// Donor: `trades-flutter/lib/shared/widgets/cost_summary_card.dart`.
///
/// Example:
/// ```dart
/// EdenCostSummaryCard(
///   laborCents: 120000,
///   materialCents: 45000,
///   equipmentCents: 25000,
///   extraRows: [
///     EdenCostRow(label: 'Subcontractor', cents: 50000),
///   ],
/// )
/// // Total displays \$1,900.00 — subcontractor NOT included.
/// ```
class EdenCostSummaryCard extends StatelessWidget {
  const EdenCostSummaryCard({
    super.key,
    required this.laborCents,
    required this.materialCents,
    required this.equipmentCents,
    this.title = 'Cost Summary',
    this.extraRows = const <EdenCostRow>[],
  });

  /// Labor portion in cents.
  final int laborCents;

  /// Materials portion in cents.
  final int materialCents;

  /// Equipment portion in cents.
  final int equipmentCents;

  /// Card title. Default is "Cost Summary".
  final String title;

  /// Additional named rows rendered before the divider/total. **Not included
  /// in [totalCents].**
  final List<EdenCostRow> extraRows;

  /// Displayed total = labor + materials + equipment (NOT extraRows).
  int get totalCents => laborCents + materialCents + equipmentCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _CostLineItem(label: 'Labor', cents: laborCents),
            _CostLineItem(label: 'Materials', cents: materialCents),
            _CostLineItem(label: 'Equipment', cents: equipmentCents),
            for (final row in extraRows)
              _CostLineItem(label: row.label, cents: row.cents),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                EdenCurrencyDisplay(
                  cents: totalCents,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CostLineItem extends StatelessWidget {
  const _CostLineItem({required this.label, required this.cents});

  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          EdenCurrencyDisplay(
            cents: cents,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A line in the order summary.
class EdenOrderSummaryLine {
  const EdenOrderSummaryLine({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isDiscount = false,
  });

  final String label;
  final String amount;
  final bool isTotal;
  final bool isDiscount;
}

/// Order/invoice summary with line items and totals.
///
/// ```dart
/// EdenOrderSummary(
///   lines: [
///     EdenOrderSummaryLine(label: 'Subtotal', amount: '\$1,200.00'),
///     EdenOrderSummaryLine(label: 'Tax (8%)', amount: '\$96.00'),
///     EdenOrderSummaryLine(label: 'Discount', amount: '-\$50.00', isDiscount: true),
///     EdenOrderSummaryLine(label: 'Total', amount: '\$1,246.00', isTotal: true),
///   ],
/// )
/// ```
class EdenOrderSummary extends StatelessWidget {
  const EdenOrderSummary({
    super.key,
    required this.lines,
    this.title,
    this.padding = const EdgeInsets.all(16),
  });

  final List<EdenOrderSummaryLine> lines;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ],
          for (int i = 0; i < lines.length; i++) ...[
            if (lines[i].isTotal && i > 0) ...[
              const SizedBox(height: 4),
              Divider(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5)),
              const SizedBox(height: 4),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lines[i].label,
                    style: lines[i].isTotal
                        ? theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)
                        : theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    lines[i].amount,
                    style: lines[i].isTotal
                        ? theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: lines[i].isDiscount
                                ? Colors.green.shade700
                                : null,
                            fontWeight: FontWeight.w500,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

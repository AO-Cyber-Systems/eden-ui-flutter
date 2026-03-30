import 'package:flutter/material.dart';

/// Payment/transaction history item.
///
/// ```dart
/// EdenTransactionItem(
///   title: 'Payment Received',
///   amount: '\$1,246.00',
///   date: 'Mar 24, 2026',
///   method: 'Credit Card',
///   isPositive: true,
///   onTap: () => viewTransaction(id),
/// )
/// ```
class EdenTransactionItem extends StatelessWidget {
  const EdenTransactionItem({
    super.key,
    required this.title,
    required this.amount,
    this.date,
    this.method,
    this.reference,
    this.isPositive = true,
    this.icon,
    this.onTap,
  });

  final String title;
  final String amount;
  final String? date;
  final String? method;
  final String? reference;
  final bool isPositive;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = isPositive ? Colors.green.shade700 : theme.colorScheme.error;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isPositive ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
              ),
              child: Icon(
                icon ??
                    (isPositive
                        ? Icons.arrow_downward
                        : Icons.arrow_upward),
                size: 20,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [date, method, reference]
                        .whereType<String>()
                        .join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : '-'}$amount',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

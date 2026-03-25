import 'package:flutter/material.dart';

/// A single line item in an invoice or order.
///
/// ```dart
/// EdenInvoiceItem(
///   description: 'HVAC Installation Labor',
///   quantity: 8,
///   unitLabel: 'hrs',
///   unitPrice: 7500, // in cents
///   total: 60000,    // in cents
/// )
/// ```
class EdenInvoiceItem extends StatelessWidget {
  const EdenInvoiceItem({
    super.key,
    required this.description,
    this.quantity,
    this.unitLabel,
    this.unitPrice,
    this.total,
    this.note,
    this.formatCurrency,
  });

  final String description;
  final double? quantity;
  final String? unitLabel;

  /// Price per unit in cents.
  final int? unitPrice;

  /// Line total in cents.
  final int? total;

  final String? note;

  /// Custom currency formatter. Defaults to $X.XX.
  final String Function(int cents)? formatCurrency;

  String _defaultFormat(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = formatCurrency ?? _defaultFormat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (quantity != null)
            SizedBox(
              width: 60,
              child: Text(
                '${quantity!.toStringAsFixed(quantity! == quantity!.roundToDouble() ? 0 : 1)} ${unitLabel ?? ''}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          if (unitPrice != null)
            SizedBox(
              width: 80,
              child: Text(
                fmt(unitPrice!),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            ),
          if (total != null)
            SizedBox(
              width: 90,
              child: Text(
                fmt(total!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}

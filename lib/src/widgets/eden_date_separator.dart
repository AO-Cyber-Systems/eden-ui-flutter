import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Inline date label divider for timelines and message lists.
class EdenDateSeparator extends StatelessWidget {
  const EdenDateSeparator({
    super.key,
    required this.date,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: EdenSpacing.space4),
  });

  final DateTime date;
  final String? label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final textColor = EdenColors.neutral[500]!;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Divider(color: lineColor, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
            child: Text(
              label ?? _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Expanded(child: Divider(color: lineColor, height: 1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}

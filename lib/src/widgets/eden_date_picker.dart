import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Date picker input that opens the platform date picker dialog.
///
/// Displays the selected date in a styled read-only input field.
/// Tapping opens the Material date picker. Supports label, helper,
/// error, and date range constraints.
///
/// ```dart
/// EdenDatePicker(
///   label: 'Start Date',
///   value: startDate,
///   onChanged: (date) => setState(() => startDate = date),
///   firstDate: DateTime.now(),
///   lastDate: DateTime.now().add(Duration(days: 365)),
/// )
/// ```
class EdenDatePicker extends StatelessWidget {
  const EdenDatePicker({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hint = 'Select date',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? label;
  final String hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Custom date formatter. Defaults to M/d/yyyy.
  final String Function(DateTime)? dateFormat;

  String _formatDate(DateTime date) {
    if (dateFormat != null) return dateFormat!(date);
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: enabled ? () => _showPicker(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              errorStyle: const TextStyle(fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              enabled: enabled,
            ),
            child: value != null
                ? Text(
                    _formatDate(value!),
                    style: const TextStyle(fontSize: 14),
                  )
                : null,
          ),
        ),
        if (helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

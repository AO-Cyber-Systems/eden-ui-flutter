import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Time picker input that opens the platform time picker dialog.
///
/// Displays the selected time in a styled read-only input field.
/// Tapping opens the Material time picker.
///
/// ```dart
/// EdenTimePicker(
///   label: 'Start Time',
///   value: startTime,
///   onChanged: (time) => setState(() => startTime = time),
/// )
/// ```
class EdenTimePicker extends StatelessWidget {
  const EdenTimePicker({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hint = 'Select time',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.use24HourFormat = false,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String? label;
  final String hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool use24HourFormat;

  String _formatTime(BuildContext context, TimeOfDay time) {
    return time.format(context);
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      builder: use24HourFormat
          ? (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!,
              )
          : null,
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
              suffixIcon: const Icon(Icons.access_time_outlined, size: 20),
              enabled: enabled,
            ),
            child: value != null
                ? Text(
                    _formatTime(context, value!),
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

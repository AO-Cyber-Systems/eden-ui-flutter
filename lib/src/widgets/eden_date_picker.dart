import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// A date picker field styled to match [EdenInput].
///
/// Tapping the field opens the platform date picker. Optionally includes
/// time selection when [includeTime] is true.
class EdenDatePicker extends StatefulWidget {
  const EdenDatePicker({
    super.key,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.firstDate,
    this.lastDate,
    this.includeTime = false,
    this.dateFormat,
    this.enabled = true,
    this.clearable = true,
  });

  /// The currently selected date.
  final DateTime? value;

  /// Called when the user selects or clears a date.
  final ValueChanged<DateTime?>? onChanged;

  /// Label displayed above the field.
  final String? label;

  /// Placeholder text when no date is selected.
  final String? hint;

  /// Error text displayed below the field.
  final String? errorText;

  /// Helper text displayed below the field.
  final String? helperText;

  /// Earliest selectable date.
  final DateTime? firstDate;

  /// Latest selectable date.
  final DateTime? lastDate;

  /// Whether to also pick a time after the date.
  final bool includeTime;

  /// Custom date format string. If null, uses a sensible default.
  final String? dateFormat;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether to show a clear button when a date is selected.
  final bool clearable;

  @override
  State<EdenDatePicker> createState() => _EdenDatePickerState();
}

class _EdenDatePickerState extends State<EdenDatePicker> {
  Future<void> _openPicker() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(2000);
    final last = widget.lastDate ?? DateTime(2100);
    final initial = widget.value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
    );

    if (date == null || !mounted) return;

    if (widget.includeTime) {
      final time = await showTimePicker(
        context: context,
        initialTime: widget.value != null
            ? TimeOfDay.fromDateTime(widget.value!)
            : TimeOfDay.now(),
      );
      if (time == null || !mounted) return;
      widget.onChanged?.call(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
    } else {
      widget.onChanged?.call(date);
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final base = '${date.year}-$month-$day';
    if (widget.includeTime) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$base $hour:$minute';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final hasValue = widget.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: _openPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.hint ?? (widget.includeTime ? 'Select date & time' : 'Select date'),
              errorText: widget.errorText,
              errorStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(
                widget.includeTime ? Icons.event : Icons.calendar_today,
                size: 20,
              ),
              suffixIcon: hasValue && widget.clearable && widget.enabled
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => widget.onChanged?.call(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    )
                  : null,
              enabled: widget.enabled,
            ),
            isEmpty: !hasValue,
            child: hasValue
                ? Text(
                    _formatDate(widget.value!),
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// A date range picker field styled to match [EdenInput].
///
/// Tapping the field opens the platform date range picker.
class EdenDateRangePicker extends StatefulWidget {
  const EdenDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.clearable = true,
  });

  /// Start of the selected range.
  final DateTime? startDate;

  /// End of the selected range.
  final DateTime? endDate;

  /// Called when the user selects or clears a range.
  final void Function(DateTime? start, DateTime? end)? onChanged;

  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final bool clearable;

  @override
  State<EdenDateRangePicker> createState() => _EdenDateRangePickerState();
}

class _EdenDateRangePickerState extends State<EdenDateRangePicker> {
  Future<void> _openPicker() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(2000);
    final last = widget.lastDate ?? DateTime(2100);

    final result = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
      currentDate: now,
    );

    if (result == null || !mounted) return;
    widget.onChanged?.call(result.start, result.end);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? get _displayText {
    if (widget.startDate != null && widget.endDate != null) {
      return '${_formatDate(widget.startDate!)}  --  ${_formatDate(widget.endDate!)}';
    }
    if (widget.startDate != null) {
      return '${_formatDate(widget.startDate!)}  --  ...';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final hasValue = widget.startDate != null;
    final display = _displayText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: _openPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Select date range',
              errorText: widget.errorText,
              errorStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.date_range, size: 20),
              suffixIcon: hasValue && widget.clearable && widget.enabled
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          widget.onChanged?.call(null, null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    )
                  : null,
              enabled: widget.enabled,
            ),
            isEmpty: display == null,
            child: display != null
                ? Text(
                    display,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

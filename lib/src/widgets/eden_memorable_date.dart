import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// USWDS-conformant memorable-date input.
///
/// Three separate Month / Day / Year fields per USWDS v3.13 spec.
/// Section 508 accessibility-optimized alternative to calendar pickers
/// for date-of-birth and similar inputs where users know the date but
/// find calendar pickers cognitively expensive (especially via keyboard
/// or screen reader).
///
/// Civilian re-use: date-of-birth on any intake form (medical / legal /
/// retail age-verify). Federal use: USWDS-mandatory for federal apps.
///
/// Validation:
///   - Per-field (Invalid month / Invalid day / Invalid year) inline.
///   - Composite (e.g. Feb 30 → rollover detection → 'Invalid date').
///   - Range (firstDate / lastDate) → 'Date out of range'.
///
/// Emits `DateTime?` via [onChanged]: a non-null value when all three
/// fields are valid AND composite + range checks pass; `null` otherwise.
class EdenMemorableDate extends StatefulWidget {
  const EdenMemorableDate({
    super.key,
    this.value,
    this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.monthAsText = false,
  });

  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// When true, render the Month field as a 2-digit text input rather
  /// than a dropdown. Useful when consumers want consistent typing UX
  /// across all three fields.
  final bool monthAsText;

  @override
  State<EdenMemorableDate> createState() => _EdenMemorableDateState();
}

class _EdenMemorableDateState extends State<EdenMemorableDate> {
  int? _month;
  int? _day;
  int? _year;
  String? _monthError;
  String? _dayError;
  String? _yearError;
  String? _compositeError;

  late TextEditingController _monthController;
  late TextEditingController _dayController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _month = widget.value!.month;
      _day = widget.value!.day;
      _year = widget.value!.year;
    }
    _monthController =
        TextEditingController(text: _month?.toString().padLeft(2, '0') ?? '');
    _dayController = TextEditingController(text: _day?.toString() ?? '');
    _yearController = TextEditingController(text: _year?.toString() ?? '');
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _validateAndEmit() {
    setState(() {
      _monthError = (_month != null && (_month! < 1 || _month! > 12))
          ? 'Invalid month'
          : null;
      _dayError = (_day != null && (_day! < 1 || _day! > 31))
          ? 'Invalid day'
          : null;
      _yearError = (_year != null && (_year! < 1900 || _year! > 9999))
          ? 'Invalid year'
          : null;
      _compositeError = null;

      if (_month == null ||
          _day == null ||
          _year == null ||
          _monthError != null ||
          _dayError != null ||
          _yearError != null) {
        widget.onChanged?.call(null);
        return;
      }
      final candidate = DateTime(_year!, _month!, _day!);
      if (candidate.month != _month || candidate.day != _day) {
        _compositeError = 'Invalid date';
        widget.onChanged?.call(null);
        return;
      }
      if (widget.firstDate != null && candidate.isBefore(widget.firstDate!)) {
        _compositeError = 'Date out of range';
        widget.onChanged?.call(null);
        return;
      }
      if (widget.lastDate != null && candidate.isAfter(widget.lastDate!)) {
        _compositeError = 'Date out of range';
        widget.onChanged?.call(null);
        return;
      }
      widget.onChanged?.call(candidate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;
        final fields = <Widget>[
          _MonthField(
            value: _month,
            controller: _monthController,
            asText: widget.monthAsText,
            errorText: _monthError,
            onChanged: (v) {
              _month = v;
              _validateAndEmit();
            },
          ),
          _DayField(
            controller: _dayController,
            errorText: _dayError,
            onChanged: (v) {
              _day = int.tryParse(v);
              _validateAndEmit();
            },
          ),
          _YearField(
            controller: _yearController,
            errorText: _yearError,
            onChanged: (v) {
              _year = int.tryParse(v);
              _validateAndEmit();
            },
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
            ],
            if (isNarrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in fields) ...[f, const SizedBox(height: 8)],
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 8),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 8),
                  Expanded(child: fields[2]),
                ],
              ),
            if (_compositeError != null) ...[
              const SizedBox(height: 4),
              Text(
                _compositeError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (widget.errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (widget.helperText != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.helperText!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MonthField extends StatelessWidget {
  const _MonthField({
    required this.value,
    required this.controller,
    required this.asText,
    required this.errorText,
    required this.onChanged,
  });

  final int? value;
  final TextEditingController controller;
  final bool asText;
  final String? errorText;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Month',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Month', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          if (asText)
            TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'MM',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (v) => onChanged(int.tryParse(v)),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: value,
              isDense: true,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(
                      _monthNames[m - 1],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _DayField extends StatelessWidget {
  const _DayField({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Day', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'DD',
              errorText: errorText,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _YearField extends StatelessWidget {
  const _YearField({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Year',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Year', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'YYYY',
              errorText: errorText,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

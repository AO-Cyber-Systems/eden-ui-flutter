import 'package:flutter/material.dart';
import 'eden_select.dart';

/// Compact preset selector for common date ranges (last 7 / 30 / 90 days,
/// MTD, YTD). Pairs naturally with [EdenDateRangePicker] in dashboards
/// where users want a one-click way to switch between standard windows.
///
/// The string values are admin/ops convention: `7d`, `30d`, `90d`, `mtd`,
/// `ytd`. Consumers interpret them server-side or convert to concrete
/// ranges in their own provider layer — this widget is presentation-only.
class EdenQuickDateRange extends StatelessWidget {
  const EdenQuickDateRange({
    super.key,
    required this.selectedRange,
    required this.onChanged,
  });

  /// Currently selected preset key (`7d`, `30d`, `90d`, `mtd`, `ytd`).
  final String selectedRange;

  /// Called when the user picks a different preset.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return EdenSelect<String>(
      value: selectedRange,
      options: const [
        EdenSelectOption(value: '7d', label: 'Last 7 days'),
        EdenSelectOption(value: '30d', label: 'Last 30 days'),
        EdenSelectOption(value: '90d', label: 'Last 90 days'),
        EdenSelectOption(value: 'mtd', label: 'Month to date'),
        EdenSelectOption(value: 'ytd', label: 'Year to date'),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      size: EdenSelectSize.sm,
    );
  }
}

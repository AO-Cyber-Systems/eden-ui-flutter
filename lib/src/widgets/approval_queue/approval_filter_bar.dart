import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_approval_queue.dart';

// ---------------------------------------------------------------------------
// Summary stats row
// ---------------------------------------------------------------------------

class SummaryStatsRow extends StatelessWidget {
  const SummaryStatsRow({
    super.key,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.changesRequested,
    required this.isDark,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int changesRequested;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      child: Row(
        children: [
          StatChip(label: 'Pending', count: pending, color: EdenColors.warning, isDark: isDark),
          const SizedBox(width: EdenSpacing.space2),
          StatChip(label: 'Approved', count: approved, color: EdenColors.success, isDark: isDark),
          const SizedBox(width: EdenSpacing.space2),
          StatChip(label: 'Rejected', count: rejected, color: EdenColors.error, isDark: isDark),
          const SizedBox(width: EdenSpacing.space2),
          StatChip(label: 'Changes', count: changesRequested, color: EdenColors.info, isDark: isDark),
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: EdenSpacing.space1),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.statusFilter,
    required this.priorityFilter,
    required this.submitterFilter,
    required this.submitters,
    required this.isDark,
    required this.theme,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSubmitterChanged,
  });

  final EdenApprovalStatus? statusFilter;
  final EdenApprovalPriority? priorityFilter;
  final String? submitterFilter;
  final List<String> submitters;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<EdenApprovalStatus?> onStatusChanged;
  final ValueChanged<EdenApprovalPriority?> onPriorityChanged;
  final ValueChanged<String?> onSubmitterChanged;

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;
    final chipBorder = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final textColor = isDark ? EdenColors.neutral[300]! : EdenColors.neutral[700]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      child: Wrap(
        spacing: EdenSpacing.space2,
        runSpacing: EdenSpacing.space2,
        children: [
          DropdownChip<EdenApprovalStatus?>(
            label: 'Status',
            value: statusFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...EdenApprovalStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(statusLabel(s)))),
            ],
            onChanged: onStatusChanged,
            chipBg: chipBg,
            chipBorder: chipBorder,
            textColor: textColor,
          ),
          DropdownChip<EdenApprovalPriority?>(
            label: 'Priority',
            value: priorityFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...EdenApprovalPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(priorityLabel(p)))),
            ],
            onChanged: onPriorityChanged,
            chipBg: chipBg,
            chipBorder: chipBorder,
            textColor: textColor,
          ),
          if (submitters.length > 1)
            DropdownChip<String?>(
              label: 'Submitter',
              value: submitterFilter,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...submitters.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: onSubmitterChanged,
              chipBg: chipBg,
              chipBorder: chipBorder,
              textColor: textColor,
            ),
        ],
      ),
    );
  }

  static String statusLabel(EdenApprovalStatus status) {
    switch (status) {
      case EdenApprovalStatus.pending: return 'Pending';
      case EdenApprovalStatus.approved: return 'Approved';
      case EdenApprovalStatus.rejected: return 'Rejected';
      case EdenApprovalStatus.changesRequested: return 'Changes Requested';
    }
  }

  static String priorityLabel(EdenApprovalPriority priority) {
    switch (priority) {
      case EdenApprovalPriority.low: return 'Low';
      case EdenApprovalPriority.normal: return 'Normal';
      case EdenApprovalPriority.high: return 'High';
      case EdenApprovalPriority.urgent: return 'Urgent';
    }
  }
}

class DropdownChip<T> extends StatelessWidget {
  const DropdownChip({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.chipBg,
    required this.chipBorder,
    required this.textColor,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color chipBg;
  final Color chipBorder;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3, vertical: EdenSpacing.space1),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: (v) => onChanged(v),
              isDense: true,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Batch action bar
// ---------------------------------------------------------------------------

class BatchActionBar extends StatelessWidget {
  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.isDark,
    required this.theme,
    required this.onApprove,
    required this.onReject,
    required this.onRequestChanges,
    required this.onClear,
  });

  final int selectedCount;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestChanges;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[50]!;
    final border = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4, vertical: EdenSpacing.space2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Text(
              '$selectedCount selected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? EdenColors.neutral[200] : EdenColors.neutral[700],
              ),
            ),
            const Spacer(),
            SmallActionButton(label: 'Approve', icon: Icons.check, color: EdenColors.success, onTap: onApprove),
            const SizedBox(width: EdenSpacing.space2),
            SmallActionButton(label: 'Reject', icon: Icons.close, color: EdenColors.error, onTap: onReject),
            const SizedBox(width: EdenSpacing.space2),
            SmallActionButton(label: 'Changes', icon: Icons.edit_outlined, color: EdenColors.info, onTap: onRequestChanges),
            const SizedBox(width: EdenSpacing.space3),
            GestureDetector(
              onTap: onClear,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(Icons.clear, size: 18, color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallActionButton extends StatelessWidget {
  const SmallActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3, vertical: EdenSpacing.space1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: EdenRadii.borderRadiusFull,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: EdenSpacing.space1),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

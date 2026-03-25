import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class SchedulerToolbar extends StatelessWidget {
  const SchedulerToolbar({
    super.key,
    required this.view,
    required this.focusedDate,
    required this.isDark,
    required this.theme,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onViewChanged,
  });

  final EdenSchedulerView view;
  final DateTime focusedDate;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<EdenSchedulerView> onViewChanged;

  static const _months = [
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

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _title {
    switch (view) {
      case EdenSchedulerView.month:
        return '${_months[focusedDate.month - 1]} ${focusedDate.year}';
      case EdenSchedulerView.week:
        final start = focusedDate
            .subtract(Duration(days: focusedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${_months[start.month - 1]} ${start.day}–${end.day}, ${start.year}';
        }
        return '${_months[start.month - 1]} ${start.day} – ${_months[end.month - 1]} ${end.day}, ${end.year}';
      case EdenSchedulerView.day:
        return '${_shortDays[focusedDate.weekday - 1]}, ${_months[focusedDate.month - 1]} ${focusedDate.day}, ${focusedDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Navigation
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: onPrev,
            tooltip: 'Previous',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: onNext,
            tooltip: 'Next',
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: EdenSpacing.space2),
          TodayButton(onPressed: onToday, isDark: isDark),
          SizedBox(width: EdenSpacing.space4),
          // Title
          Expanded(
            child: Text(
              _title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // View toggle
          ViewToggle(
            view: view,
            isDark: isDark,
            theme: theme,
            onChanged: onViewChanged,
          ),
        ],
      ),
    );
  }
}

class TodayButton extends StatelessWidget {
  const TodayButton({super.key, required this.onPressed, required this.isDark});

  final VoidCallback onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;

    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: EdenRadii.borderRadiusMd,
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        child: const Text('Today'),
      ),
    );
  }
}

class ViewToggle extends StatelessWidget {
  const ViewToggle({
    super.key,
    required this.view,
    required this.isDark,
    required this.theme,
    required this.onChanged,
  });

  final EdenSchedulerView view;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<EdenSchedulerView> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;
    final selectedBg =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: EdenSchedulerView.values.map((v) {
          final isActive = v == view;
          final label = switch (v) {
            EdenSchedulerView.month => 'Month',
            EdenSchedulerView.week => 'Week',
            EdenSchedulerView.day => 'Day',
          };
          return GestureDetector(
            onTap: () => onChanged(v),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? selectedBg : Colors.transparent,
                  border: v != EdenSchedulerView.values.first
                      ? Border(left: BorderSide(color: borderColor))
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assignee filter row
// ---------------------------------------------------------------------------

class AssigneeFilterRow extends StatelessWidget {
  const AssigneeFilterRow({
    super.key,
    required this.assignees,
    required this.selected,
    required this.isDark,
    required this.theme,
    required this.onChanged,
  });

  final List<String> assignees;
  final Set<String> selected;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Assignee:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: EdenSpacing.space2),
            ...assignees.map((name) {
              final isSelected = selected.contains(name);
              return Padding(
                padding: EdgeInsets.only(right: EdenSpacing.space1),
                child: FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (v) {
                    final next = Set<String>.from(selected);
                    if (v) {
                      next.add(name);
                    } else {
                      next.remove(name);
                    }
                    onChanged(next);
                  },
                  labelStyle: TextStyle(fontSize: 12),
                  padding: EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';
import 'scheduler_controller.dart';

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
    this.visibleViews,
  });

  /// Build a SchedulerToolbar wired to an [EdenSchedulerController]. The
  /// toolbar reads `view` + `focusedDate` from the controller and routes
  /// `onPrev`/`onNext`/`onToday`/`onViewChanged` through it.
  ///
  /// Wraps an [AnimatedBuilder] internally so the toolbar rebuilds when the
  /// controller notifies.
  static Widget fromController({
    Key? key,
    required EdenSchedulerController controller,
    required bool isDark,
    required ThemeData theme,
    List<EdenSchedulerView>? visibleViews,
    ValueChanged<EdenSchedulerView>? onViewChanged,
  }) {
    return AnimatedBuilder(
      key: key,
      animation: controller,
      builder: (context, _) {
        return SchedulerToolbar(
          view: controller.view,
          focusedDate: controller.focusedDate,
          isDark: isDark,
          theme: theme,
          onPrev: () => controller.navigate(-1),
          onNext: () => controller.navigate(1),
          onToday: controller.goToday,
          onViewChanged: (v) {
            controller.setView(v);
            onViewChanged?.call(v);
          },
          visibleViews: visibleViews,
        );
      },
    );
  }

  final EdenSchedulerView view;
  final DateTime focusedDate;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<EdenSchedulerView> onViewChanged;

  /// When non-null, restrict the ViewToggle to these variants. Default = all.
  final List<EdenSchedulerView>? visibleViews;

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

  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _title {
    switch (view) {
      case EdenSchedulerView.month:
        return '${_months[focusedDate.month - 1]} ${focusedDate.year}';
      case EdenSchedulerView.workWeek:
        return _rangeTitle(_weekStart(focusedDate), 4);
      case EdenSchedulerView.week:
        return _rangeTitle(_weekStart(focusedDate), 6);
      case EdenSchedulerView.list:
        final start = _weekStart(focusedDate);
        return 'Week of ${_monthsShort[start.month - 1]} ${start.day}, ${start.year}';
      case EdenSchedulerView.swimlane:
        // Donor TruckAvailabilityView spans 3 weeks (20 days inclusive); we
        // anchor on the Monday of the focused week and show a 3-week range.
        return _rangeTitle(_weekStart(focusedDate), 20);
      case EdenSchedulerView.day:
      case EdenSchedulerView.mobile:
        return '${_shortDays[focusedDate.weekday - 1]}, '
            '${_monthsShort[focusedDate.month - 1]} '
            '${focusedDate.day}, ${focusedDate.year}';
    }
  }

  DateTime _weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  String _rangeTitle(DateTime start, int dayDelta) {
    final end = start.add(Duration(days: dayDelta));
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${_monthsShort[start.month - 1]} ${start.day}–${end.day}, ${start.year}';
      }
      return '${_monthsShort[start.month - 1]} ${start.day} – '
          '${_monthsShort[end.month - 1]} ${end.day}, ${start.year}';
    }
    return '${_monthsShort[start.month - 1]} ${start.day}, ${start.year} – '
        '${_monthsShort[end.month - 1]} ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return LayoutBuilder(
      builder: (context, c) {
        // With 7 view variants the labeled toggle is ~500-600pt wide. Collapse
        // to icon-only when the toolbar's available width drops below 1100pt
        // so 800pt / 600pt / 390pt phone viewports stay overflow-free. (TRD
        // 004-02 may revisit this threshold with finer responsive breakpoints.)
        final iconOnly = c.maxWidth.isFinite && c.maxWidth < 1100;
        // At iPhone-narrow widths, also collapse the title (let the toggle +
        // nav fill the row) so 7-icon toggle + Prev/Next/Today still fit.
        final isNarrow = c.maxWidth.isFinite && c.maxWidth < 480;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? EdenSpacing.space2 : EdenSpacing.space4,
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
              if (!isNarrow) ...[
                const SizedBox(width: EdenSpacing.space2),
                TodayButton(onPressed: onToday, isDark: isDark),
              ] else
                IconButton(
                  icon: const Icon(Icons.today_outlined, size: 18),
                  onPressed: onToday,
                  tooltip: 'Today',
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: EdenSpacing.space2),
              // Title — hidden at iPhone-narrow widths to make room.
              if (!isNarrow)
                Expanded(
                  child: Text(
                    _title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              // View toggle
              ViewToggle(
                view: view,
                isDark: isDark,
                theme: theme,
                onChanged: onViewChanged,
                iconOnly: iconOnly,
                visibleViews: visibleViews,
              ),
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
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
    this.visibleViews,
    this.iconOnly,
  });

  final EdenSchedulerView view;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<EdenSchedulerView> onChanged;

  /// When non-null, only these view variants render. Default = all variants.
  final List<EdenSchedulerView>? visibleViews;

  /// When true, render icon-only (label hidden) regardless of available width.
  /// When null (default), auto-collapse to icon-only at narrow widths via
  /// LayoutBuilder.
  final bool? iconOnly;

  static const Map<EdenSchedulerView, String> _labels = {
    EdenSchedulerView.month: 'Month',
    EdenSchedulerView.week: 'Week',
    EdenSchedulerView.workWeek: 'Work Week',
    EdenSchedulerView.day: 'Day',
    EdenSchedulerView.list: 'List',
    EdenSchedulerView.mobile: 'Mobile',
    EdenSchedulerView.swimlane: 'Swimlane',
  };

  static const Map<EdenSchedulerView, IconData> _icons = {
    EdenSchedulerView.month: Icons.calendar_month,
    EdenSchedulerView.week: Icons.view_week,
    EdenSchedulerView.workWeek: Icons.business_center,
    EdenSchedulerView.day: Icons.view_day,
    EdenSchedulerView.list: Icons.view_list,
    EdenSchedulerView.mobile: Icons.smartphone,
    EdenSchedulerView.swimlane: Icons.view_column,
  };

  @override
  Widget build(BuildContext context) {
    final views = visibleViews ?? EdenSchedulerView.values;
    final borderColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;
    final selectedBg =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return LayoutBuilder(
      builder: (context, c) {
        // Width-based collapse threshold. When the toolbar surrounding this
        // toggle gets narrow, an explicit `iconOnly` wins; otherwise auto-
        // collapse below 600pt available toggle width — roughly the point
        // where 7 word-labels stop fitting on a 390pt screen.
        final hostWidth = c.hasBoundedWidth ? c.maxWidth : null;
        final autoCollapse = hostWidth != null && hostWidth < 280;
        final useIconOnly = iconOnly ?? autoCollapse;

        return Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: EdenRadii.borderRadiusMd,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: views.map((v) {
              final isActive = v == view;
              final label = _labels[v]!;
              final icon = _icons[v]!;
              return Semantics(
                button: true,
                label: '$label view',
                selected: isActive,
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: useIconOnly
                            ? EdenSpacing.space2
                            : EdenSpacing.space3,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? selectedBg : Colors.transparent,
                        border: v != views.first
                            ? Border(left: BorderSide(color: borderColor))
                            : null,
                      ),
                      child: useIconOnly
                          ? Tooltip(
                              message: '$label view',
                              child: Icon(
                                icon,
                                size: 16,
                                color: isActive
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(
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
            const SizedBox(width: EdenSpacing.space2),
            ...assignees.map((name) {
              final isSelected = selected.contains(name);
              return Padding(
                padding: const EdgeInsets.only(right: EdenSpacing.space1),
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
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
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

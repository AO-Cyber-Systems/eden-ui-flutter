import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';

// ---------------------------------------------------------------------------
// Month view
// ---------------------------------------------------------------------------

class MonthView extends StatelessWidget {
  const MonthView({
    super.key,
    required this.focusedDate,
    required this.today,
    required this.events,
    required this.isDark,
    required this.theme,
    required this.onDateSelected,
    this.onEventTap,
  });

  final DateTime focusedDate;
  final DateTime today;
  final List<EdenSchedulerEvent> events;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final daysInMonth =
        DateTime(focusedDate.year, focusedDate.month + 1, 0).day;

    // Monday = 1, Sunday = 7
    final startWeekday = firstOfMonth.weekday; // 1-based, Mon=1
    final leadingBlanks = startWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    // Build event lookup by date.
    final eventsByDate = <int, List<EdenSchedulerEvent>>{};
    for (final e in events) {
      final key = _dateKey(e.start);
      (eventsByDate[key] ??= []).add(e);
    }

    return Column(
      children: [
        // Day-of-week headers
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: _dayLabels.map((d) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: EdenSpacing.space2),
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Grid
        Expanded(
          child: Column(
            children: List.generate(rowCount, (row) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: row < rowCount - 1
                        ? Border(bottom: BorderSide(color: borderColor))
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (col) {
                      final cellIndex = row * 7 + col;
                      final dayNum = cellIndex - leadingBlanks + 1;
                      final isValid =
                          dayNum >= 1 && dayNum <= daysInMonth;

                      if (!isValid) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: col < 6
                                  ? Border(
                                      right: BorderSide(color: borderColor))
                                  : null,
                            ),
                          ),
                        );
                      }

                      final cellDate = DateTime(
                          focusedDate.year, focusedDate.month, dayNum);
                      final isToday = cellDate == today;
                      final isFocused = cellDate == focusedDate;
                      final dayEvents =
                          eventsByDate[_dateKey(cellDate)] ?? const [];

                      return Expanded(
                        child: MonthDayCell(
                          date: cellDate,
                          dayNum: dayNum,
                          isToday: isToday,
                          isFocused: isFocused,
                          events: dayEvents,
                          isDark: isDark,
                          theme: theme,
                          showRightBorder: col < 6,
                          borderColor: borderColor,
                          onTap: () => onDateSelected(cellDate),
                          onEventTap: onEventTap,
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  int _dateKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}

class MonthDayCell extends StatelessWidget {
  const MonthDayCell({
    super.key,
    required this.date,
    required this.dayNum,
    required this.isToday,
    required this.isFocused,
    required this.events,
    required this.isDark,
    required this.theme,
    required this.showRightBorder,
    required this.borderColor,
    required this.onTap,
    this.onEventTap,
  });

  final DateTime date;
  final int dayNum;
  final bool isToday;
  final bool isFocused;
  final List<EdenSchedulerEvent> events;
  final bool isDark;
  final ThemeData theme;
  final bool showRightBorder;
  final Color borderColor;
  final VoidCallback onTap;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    final focusBg = isDark
        ? theme.colorScheme.primary.withAlpha(30)
        : theme.colorScheme.primary.withAlpha(20);

    return Semantics(
      button: true,
      label: 'Select ${date.month}/${date.day}/${date.year}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
          color: isFocused ? focusBg : null,
          border: showRightBorder
              ? Border(right: BorderSide(color: borderColor))
              : null,
        ),
        padding: EdgeInsets.all(EdenSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Day number
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isToday || isFocused ? FontWeight.w700 : FontWeight.w400,
                  color: isToday
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: EdenSpacing.space1),
            // Event dots
            if (events.isNotEmpty)
              Wrap(
                spacing: 3,
                runSpacing: 3,
                alignment: WrapAlignment.center,
                children: events.take(5).map((e) {
                  return Semantics(
                    button: onEventTap != null,
                    label: 'Event: ${e.title}',
                    child: GestureDetector(
                      onTap: onEventTap != null ? () => onEventTap!(e) : null,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: e.color ?? theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (events.length > 5)
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '+${events.length - 5}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A calendar event with a date and color indicator.
class EdenCalendarEvent {
  const EdenCalendarEvent({required this.date, this.color});
  final DateTime date;
  final Color? color;
}

/// Mirrors the eden_calendar Rails component.
///
/// Monthly calendar view with event dot indicators.
class EdenCalendar extends StatefulWidget {
  const EdenCalendar({
    super.key,
    this.initialDate,
    this.events = const [],
    this.onDateSelected,
    this.startOnMonday = false,
  });

  final DateTime? initialDate;
  final List<EdenCalendarEvent> events;
  final ValueChanged<DateTime>? onDateSelected;
  final bool startOnMonday;

  @override
  State<EdenCalendar> createState() => _EdenCalendarState();
}

class _EdenCalendarState extends State<EdenCalendar> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
  void _nextMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateTime.now();
    final dayNames = widget.startOnMonday
        ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startWeekday = widget.startOnMonday
        ? (firstOfMonth.weekday - 1) % 7
        : firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][_currentMonth.month - 1];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Icon(Icons.chevron_left, size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
              Text('$monthName ${_currentMonth.year}', style: theme.textTheme.titleSmall),
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space3),
          // Day names
          Row(
            children: dayNames.map((d) => Expanded(
              child: Center(
                child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 4),
          // Day grid
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (day) {
                final dayIndex = week * 7 + day - startWeekday + 1;
                final isCurrentMonth = dayIndex >= 1 && dayIndex <= daysInMonth;
                final date = DateTime(_currentMonth.year, _currentMonth.month, dayIndex);
                final isToday = isCurrentMonth && date.year == today.year && date.month == today.month && date.day == today.day;
                final isSelected = _selectedDate != null && isCurrentMonth && date.year == _selectedDate!.year && date.month == _selectedDate!.month && date.day == _selectedDate!.day;
                final events = isCurrentMonth
                    ? widget.events.where((e) => e.date.year == date.year && e.date.month == date.month && e.date.day == date.day).take(3).toList()
                    : <EdenCalendarEvent>[];

                return Expanded(
                  child: GestureDetector(
                    onTap: isCurrentMonth ? () {
                      setState(() => _selectedDate = date);
                      widget.onDateSelected?.call(date);
                    } : null,
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : null,
                        borderRadius: EdenRadii.borderRadiusMd,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isCurrentMonth ? '$dayIndex' : '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : isCurrentMonth
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          if (events.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: events.map((e) => Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : (e.color ?? theme.colorScheme.primary),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

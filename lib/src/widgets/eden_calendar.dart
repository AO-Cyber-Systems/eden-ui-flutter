import 'dart:async';

import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Calendar view mode.
enum EdenCalendarView { month, week, day }

/// A calendar event with a date and color indicator.
///
/// All new fields are optional to preserve backward compatibility.
/// `EdenCalendarEvent(date: DateTime(...), color: Colors.red)` still works.
class EdenCalendarEvent {
  const EdenCalendarEvent({
    required this.date,
    this.color,
    this.id,
    this.title,
    this.description,
    this.endDate,
  });

  final DateTime date;
  final Color? color;
  final String? id;
  final String? title;
  final String? description;

  /// End date for multi-day or timed events. If null, treated as a point event.
  final DateTime? endDate;

  /// Whether this event spans the given [day] (inclusive).
  bool spansDay(DateTime day) {
    final startDay = DateTime(date.year, date.month, date.day);
    final endDay = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : startDay;
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(startDay) && !target.isAfter(endDay);
  }

  /// Whether the event spans more than one calendar day.
  bool get isMultiDay {
    if (endDate == null) return false;
    final startDay = DateTime(date.year, date.month, date.day);
    final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return endDay.isAfter(startDay);
  }
}

/// Mirrors the eden_calendar Rails component.
///
/// Monthly calendar view with event dot indicators, plus optional week and day
/// views with hour-row layouts.
///
/// Fully backward-compatible: all original constructor parameters keep their
/// existing defaults. New features are opt-in.
class EdenCalendar extends StatefulWidget {
  const EdenCalendar({
    super.key,
    this.initialDate,
    this.events = const [],
    this.onDateSelected,
    this.startOnMonday = false,
    // New optional parameters
    this.view,
    this.onViewChanged,
    this.showViewToggle = false,
    this.showTodayButton = false,
    this.onEventTap,
    this.startHour = 0,
    this.endHour = 24,
    this.showCurrentTimeIndicator = true,
  });

  final DateTime? initialDate;
  final List<EdenCalendarEvent> events;
  final ValueChanged<DateTime>? onDateSelected;
  final bool startOnMonday;

  /// Current view mode. If null, defaults to [EdenCalendarView.month].
  final EdenCalendarView? view;

  /// Called when the user switches views via the segmented control.
  final ValueChanged<EdenCalendarView>? onViewChanged;

  /// Show a segmented control to toggle between month / week / day views.
  final bool showViewToggle;

  /// Show a "Today" button in the header.
  final bool showTodayButton;

  /// Called when the user taps an event in week/day view or the event list.
  final ValueChanged<EdenCalendarEvent>? onEventTap;

  /// First visible hour in week / day views (0–23). Defaults to 0.
  final int startHour;

  /// Last visible hour in week / day views (1–24). Defaults to 24.
  final int endHour;

  /// Show a red current-time indicator line in week / day views.
  final bool showCurrentTimeIndicator;

  @override
  State<EdenCalendar> createState() => _EdenCalendarState();
}

class _EdenCalendarState extends State<EdenCalendar> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  late EdenCalendarView _view;
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = widget.initialDate;
    _view = widget.view ?? EdenCalendarView.month;
    // Refresh every 60s so the current-time indicator stays accurate.
    _timeTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(covariant EdenCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view != null && widget.view != _view) {
      _view = widget.view!;
    }
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _prevMonth() => setState(
      () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
  void _nextMonth() => setState(
      () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
    widget.onDateSelected?.call(_selectedDate!);
  }

  void _setView(EdenCalendarView v) {
    setState(() => _view = v);
    widget.onViewChanged?.call(v);
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<EdenCalendarEvent> _eventsForDay(DateTime day) =>
      widget.events.where((e) => e.spansDay(day)).toList();

  DateTime get _weekStart {
    final ref = _selectedDate ?? DateTime.now();
    final weekday = widget.startOnMonday
        ? (ref.weekday - 1) % 7
        : ref.weekday % 7;
    return DateTime(ref.year, ref.month, ref.day - weekday);
  }

  DateTime get _dayViewDate => _selectedDate ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Month names / day names
  // ---------------------------------------------------------------------------

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<String> get _dayNames => widget.startOnMonday
      ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
      : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          _buildHeader(theme),
          if (widget.showViewToggle) ...[
            const SizedBox(height: EdenSpacing.space2),
            _buildViewToggle(theme),
          ],
          const SizedBox(height: EdenSpacing.space3),
          if (_view == EdenCalendarView.month) _buildMonthView(theme),
          if (_view == EdenCalendarView.week) _buildWeekView(theme),
          if (_view == EdenCalendarView.day) _buildDayView(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header with nav arrows, title, optional Today button
  // ---------------------------------------------------------------------------

  Widget _buildHeader(ThemeData theme) {
    String title;
    VoidCallback onPrev;
    VoidCallback onNext;

    switch (_view) {
      case EdenCalendarView.month:
        title = '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';
        onPrev = _prevMonth;
        onNext = _nextMonth;
        break;
      case EdenCalendarView.week:
        final ws = _weekStart;
        final we = ws.add(const Duration(days: 6));
        final sameMonth = ws.month == we.month && ws.year == we.year;
        if (sameMonth) {
          title = '${_monthNames[ws.month - 1]} ${ws.day}–${we.day}, ${ws.year}';
        } else {
          title =
              '${_monthNames[ws.month - 1]} ${ws.day} – ${_monthNames[we.month - 1]} ${we.day}, ${we.year}';
        }
        onPrev = () {
          final ref = _selectedDate ?? DateTime.now();
          final prev = ref.subtract(const Duration(days: 7));
          setState(() {
            _selectedDate = prev;
            _currentMonth = DateTime(prev.year, prev.month);
          });
          widget.onDateSelected?.call(prev);
        };
        onNext = () {
          final ref = _selectedDate ?? DateTime.now();
          final next = ref.add(const Duration(days: 7));
          setState(() {
            _selectedDate = next;
            _currentMonth = DateTime(next.year, next.month);
          });
          widget.onDateSelected?.call(next);
        };
        break;
      case EdenCalendarView.day:
        final d = _dayViewDate;
        title =
            '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';
        onPrev = () {
          final prev = _dayViewDate.subtract(const Duration(days: 1));
          setState(() {
            _selectedDate = prev;
            _currentMonth = DateTime(prev.year, prev.month);
          });
          widget.onDateSelected?.call(prev);
        };
        onNext = () {
          final next = _dayViewDate.add(const Duration(days: 1));
          setState(() {
            _selectedDate = next;
            _currentMonth = DateTime(next.year, next.month);
          });
          widget.onDateSelected?.call(next);
        };
        break;
    }

    return Row(
      children: [
        GestureDetector(
          onTap: onPrev,
          child: Icon(Icons.chevron_left,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Text(title,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center),
        ),
        if (widget.showTodayButton) ...[
          GestureDetector(
            onTap: _goToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2, vertical: EdenSpacing.space1),
              decoration: BoxDecoration(
                borderRadius: EdenRadii.borderRadiusSm,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text('Today',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
        ],
        GestureDetector(
          onTap: onNext,
          child: Icon(Icons.chevron_right,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // View toggle (segmented control)
  // ---------------------------------------------------------------------------

  Widget _buildViewToggle(ThemeData theme) {
    Widget chip(String label, EdenCalendarView v) {
      final selected = _view == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setView(v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          chip('Month', EdenCalendarView.month),
          chip('Week', EdenCalendarView.week),
          chip('Day', EdenCalendarView.day),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Month view
  // ---------------------------------------------------------------------------

  Widget _buildMonthView(ThemeData theme) {
    final today = DateTime.now();
    final firstOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startWeekday = widget.startOnMonday
        ? (firstOfMonth.weekday - 1) % 7
        : firstOfMonth.weekday % 7;
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // Collect multi-day events that overlap this month for bar rendering.
    final multiDayEvents = widget.events.where((e) => e.isMultiDay).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day name headers
        Row(
          children: _dayNames
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Multi-day event bars
        ..._buildMultiDayBars(theme, multiDayEvents, startWeekday, daysInMonth),
        // Day grid
        ...List.generate(6, (week) {
          return Row(
            children: List.generate(7, (day) {
              final dayIndex = week * 7 + day - startWeekday + 1;
              final isCurrentMonth =
                  dayIndex >= 1 && dayIndex <= daysInMonth;
              final date = DateTime(
                  _currentMonth.year, _currentMonth.month, dayIndex);
              final isToday = isCurrentMonth &&
                  _sameDay(date, today);
              final isSelected = _selectedDate != null &&
                  isCurrentMonth &&
                  _sameDay(date, _selectedDate!);
              // Only single-day (dot) events for the grid — multi-day shown as bars.
              final dotEvents = isCurrentMonth
                  ? widget.events
                      .where((e) =>
                          !e.isMultiDay &&
                          e.date.year == date.year &&
                          e.date.month == date.month &&
                          e.date.day == date.day)
                      .take(3)
                      .toList()
                  : <EdenCalendarEvent>[];

              return Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth
                      ? () {
                          setState(() => _selectedDate = date);
                          widget.onDateSelected?.call(date);
                        }
                      : null,
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isToday
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.1)
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
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                          ),
                        ),
                        if (dotEvents.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dotEvents
                                .map((e) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.white
                                            : (e.color ??
                                                theme.colorScheme.primary),
                                      ),
                                    ))
                                .toList(),
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
        // Event list for selected date
        if (_selectedDate != null) _buildEventList(theme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Multi-day bars in month view
  // ---------------------------------------------------------------------------

  List<Widget> _buildMultiDayBars(
    ThemeData theme,
    List<EdenCalendarEvent> multiDayEvents,
    int startWeekday,
    int daysInMonth,
  ) {
    if (multiDayEvents.isEmpty) return [];

    // Filter to events that actually overlap this month.
    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month, daysInMonth);
    final visible = multiDayEvents.where((e) {
      final eStart = DateTime(e.date.year, e.date.month, e.date.day);
      final eEnd = e.endDate != null
          ? DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day)
          : eStart;
      return !eEnd.isBefore(monthStart) && !eStart.isAfter(monthEnd);
    }).toList();

    if (visible.isEmpty) return [];

    return [
      ...visible.map((event) {
        final eStart = DateTime(event.date.year, event.date.month, event.date.day);
        final eEnd = event.endDate != null
            ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
            : eStart;

        // Clamp to month boundaries.
        final clampedStart = eStart.isBefore(monthStart) ? monthStart : eStart;
        final clampedEnd = eEnd.isAfter(monthEnd) ? monthEnd : eEnd;

        final startIdx = clampedStart.day - 1 + startWeekday;
        final endIdx = clampedEnd.day - 1 + startWeekday;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final left = (startIdx % 7) * cellWidth;
              // Bar may span multiple weeks — for simplicity, show on the first
              // week row only, spanning from start column to end column or end of
              // row, whichever is smaller.
              final startRow = startIdx ~/ 7;
              final endRow = endIdx ~/ 7;
              // Only render within first row of the event for compactness.
              final rowEndCol =
                  (startRow == endRow) ? endIdx % 7 : 6;
              final barWidth =
                  (rowEndCol - startIdx % 7 + 1) * cellWidth - 4;

              return SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned(
                      left: left + 2,
                      child: GestureDetector(
                        onTap: widget.onEventTap != null
                            ? () => widget.onEventTap!(event)
                            : null,
                        child: Container(
                          width: barWidth.clamp(0, constraints.maxWidth),
                          height: 14,
                          decoration: BoxDecoration(
                            color: (event.color ?? theme.colorScheme.primary)
                                .withValues(alpha: 0.8),
                            borderRadius: EdenRadii.borderRadiusSm,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.centerLeft,
                          child: event.title != null
                              ? Text(
                                  event.title!,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
      const SizedBox(height: 2),
    ];
  }

  // ---------------------------------------------------------------------------
  // Event list (shown below month grid when a date is selected)
  // ---------------------------------------------------------------------------

  Widget _buildEventList(ThemeData theme) {
    final events = _eventsForDay(_selectedDate!);
    if (events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: EdenSpacing.space2),
          ...events.map((e) => _buildEventListTile(theme, e)),
        ],
      ),
    );
  }

  Widget _buildEventListTile(ThemeData theme, EdenCalendarEvent event) {
    return GestureDetector(
      onTap: widget.onEventTap != null ? () => widget.onEventTap!(event) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: event.color ?? theme.colorScheme.primary,
                borderRadius: EdenRadii.borderRadiusFull,
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'Event',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null)
                    Text(
                      event.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              _formatTime(event.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ---------------------------------------------------------------------------
  // Week view
  // ---------------------------------------------------------------------------

  Widget _buildWeekView(ThemeData theme) {
    final ws = _weekStart;
    final days = List.generate(7, (i) => ws.add(Duration(days: i)));
    final today = DateTime.now();
    final hourCount = widget.endHour - widget.startHour;
    const hourHeight = 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day headers
        Row(
          children: [
            const SizedBox(width: 40), // gutter for hour labels
            ...days.map((d) {
              final isToday = _sameDay(d, today);
              final isSelected =
                  _selectedDate != null && _sameDay(d, _selectedDate!);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = d);
                    widget.onDateSelected?.call(d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: EdenSpacing.space1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                      borderRadius: EdenRadii.borderRadiusSm,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _dayNames[days.indexOf(d)],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: EdenSpacing.space1),
        // Hour grid
        SizedBox(
          height: hourCount * hourHeight,
          child: Stack(
            children: [
              // Hour rows
              ...List.generate(hourCount, (i) {
                final hour = widget.startHour + i;
                return Positioned(
                  top: i * hourHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          _formatHourLabel(hour),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: hourHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Events
              ...days.asMap().entries.expand((entry) {
                final colIndex = entry.key;
                final day = entry.value;
                final dayEvents = _eventsForDay(day)
                    .where((e) => !e.isMultiDay)
                    .toList();
                return dayEvents.map((event) =>
                    _buildTimeBlockEvent(theme, event, colIndex, hourHeight, 7));
              }),
              // Current time indicator
              if (widget.showCurrentTimeIndicator)
                _buildCurrentTimeIndicator(
                    theme, today, days, hourHeight, 7, 40),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Day view
  // ---------------------------------------------------------------------------

  Widget _buildDayView(ThemeData theme) {
    final day = _dayViewDate;
    final today = DateTime.now();
    final hourCount = widget.endHour - widget.startHour;
    const hourHeight = 56.0;

    final dayEvents =
        _eventsForDay(day).where((e) => !e.isMultiDay).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: hourCount * hourHeight,
          child: Stack(
            children: [
              // Hour rows
              ...List.generate(hourCount, (i) {
                final hour = widget.startHour + i;
                return Positioned(
                  top: i * hourHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          _formatHourLabel(hour),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space2),
                      Expanded(
                        child: Container(
                          height: hourHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Events
              ...dayEvents.map((event) =>
                  _buildTimeBlockEvent(theme, event, 0, hourHeight, 1,
                      gutterWidth: 56)),
              // Current time indicator
              if (widget.showCurrentTimeIndicator && _sameDay(day, today))
                _buildCurrentTimeIndicatorSingle(theme, today, hourHeight, 56),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared: time-block event rendering
  // ---------------------------------------------------------------------------

  Widget _buildTimeBlockEvent(
    ThemeData theme,
    EdenCalendarEvent event,
    int colIndex,
    double hourHeight,
    int totalCols, {
    double gutterWidth = 40,
  }) {
    final startMinutes =
        (event.date.hour - widget.startHour) * 60 + event.date.minute;
    final endMinutes = event.endDate != null
        ? (event.endDate!.hour - widget.startHour) * 60 +
            event.endDate!.minute
        : startMinutes + 30; // Default 30-minute block.
    final clampedStart = startMinutes.clamp(0, (widget.endHour - widget.startHour) * 60).toDouble();
    final clampedEnd = endMinutes.clamp(0, (widget.endHour - widget.startHour) * 60).toDouble();
    final top = clampedStart * hourHeight / 60;
    final height = ((clampedEnd - clampedStart) * hourHeight / 60).clamp(8.0, double.infinity);

    return Positioned(
      top: top,
      left: gutterWidth + 2,
      right: 0,
      child: LayoutBuilder(builder: (context, constraints) {
        final colWidth = constraints.maxWidth / totalCols;
        return Padding(
          padding: EdgeInsets.only(left: colIndex * colWidth),
          child: SizedBox(
            width: colWidth - 4,
            height: height,
            child: GestureDetector(
              onTap: widget.onEventTap != null
                  ? () => widget.onEventTap!(event)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: (event.color ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.85),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space1,
                    vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.title != null)
                      Text(
                        event.title!,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (height > 24)
                      Text(
                        '${_formatTime(event.date)}${event.endDate != null ? ' – ${_formatTime(event.endDate!)}' : ''}',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Current time indicator
  // ---------------------------------------------------------------------------

  Widget _buildCurrentTimeIndicator(
    ThemeData theme,
    DateTime now,
    List<DateTime> days,
    double hourHeight,
    int totalCols,
    double gutterWidth,
  ) {
    // Only show if today is within the visible days.
    final todayIndex = days.indexWhere((d) => _sameDay(d, now));
    if (todayIndex < 0) return const SizedBox.shrink();

    final minutesSinceStart =
        (now.hour - widget.startHour) * 60 + now.minute;
    if (minutesSinceStart < 0 ||
        minutesSinceStart > (widget.endHour - widget.startHour) * 60) {
      return const SizedBox.shrink();
    }
    final top = minutesSinceStart * hourHeight / 60;

    return Positioned(
      top: top,
      left: gutterWidth,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: EdenColors.error,
            ),
          ),
          Expanded(
            child: Container(height: 1.5, color: EdenColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeIndicatorSingle(
    ThemeData theme,
    DateTime now,
    double hourHeight,
    double gutterWidth,
  ) {
    final minutesSinceStart =
        (now.hour - widget.startHour) * 60 + now.minute;
    if (minutesSinceStart < 0 ||
        minutesSinceStart > (widget.endHour - widget.startHour) * 60) {
      return const SizedBox.shrink();
    }
    final top = minutesSinceStart * hourHeight / 60;

    return Positioned(
      top: top,
      left: gutterWidth,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: EdenColors.error,
            ),
          ),
          Expanded(
            child: Container(height: 1.5, color: EdenColors.error),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _formatHourLabel(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

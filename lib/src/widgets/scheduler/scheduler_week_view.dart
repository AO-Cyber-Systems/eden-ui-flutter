import 'dart:async';

import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';
import 'scheduler_controller.dart';
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';
import 'scheduler_week_day_views.dart' show HourLabelColumn, TimeColumn;

/// Week-view mode — distinguishes Mon-Fri (workWeek) from Sun-Sat (week).
///
/// Donor `EnhancedCalendar.tsx` declares `'workWeek'` and `'week'` as two
/// distinct view modes; library combines them into one widget parameterized
/// over [EdenSchedulerWeekMode].
enum EdenSchedulerWeekMode {
  /// Mon-Fri, 5 columns (business week).
  workWeek,

  /// Sun-Sat, 7 columns (full-week US-locale convention).
  week,
}

/// Multi-column time grid for one week. Renders day headers + hour-axis ruler
/// + N day columns with events, today-column tint, and a now-indicator scoped
/// to today's column only.
///
/// Mirrors donor `Schedule.tsx` Week / Work Week views (parity rows V-2, V-3,
/// TG-9). The now-indicator is positioned over today's column only (parity
/// row TG-4 generalized to multi-column).
class EdenSchedulerWeekView extends StatefulWidget {
  const EdenSchedulerWeekView({
    super.key,
    this.focusedDate,
    this.controller,
    required this.events,
    this.mode = EdenSchedulerWeekMode.week,
    this.config = const EdenSchedulerConfig(),
    this.clock,
    this.onEventTap,
    this.onTimeSlotTap,
    this.onDateSelected,
    this.scrollController,
  }) : assert(focusedDate != null || controller != null,
            'Either focusedDate or controller must be provided');

  /// The reference date — any date within the desired week. Ignored when
  /// [controller] is non-null.
  final DateTime? focusedDate;

  /// Optional state controller; when present, drives focusedDate.
  final EdenSchedulerController? controller;

  /// Events to render. Filtered per-column by date.
  final List<EdenSchedulerEvent> events;

  /// Mon-Fri vs Sun-Sat layout.
  final EdenSchedulerWeekMode mode;

  /// Business-hours + slot config.
  final EdenSchedulerConfig config;

  /// Injectable clock for deterministic now-indicator testing.
  final DateTime Function()? clock;

  /// Fires when the user taps an event block.
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  /// Fires when the user taps an empty slot.
  final ValueChanged<DateTime>? onTimeSlotTap;

  /// Fires when the user taps a day header (e.g. to navigate to that day).
  final ValueChanged<DateTime>? onDateSelected;

  /// Optional scroll controller for the vertical hour-grid.
  final ScrollController? scrollController;

  @override
  State<EdenSchedulerWeekView> createState() => _EdenSchedulerWeekViewState();
}

class _EdenSchedulerWeekViewState extends State<EdenSchedulerWeekView> {
  Timer? _nowTimer;
  ScrollController? _ownedScrollController;

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double _hourLabelWidth = 56;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    _nowTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant EdenSchedulerWeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    widget.controller?.removeListener(_onControllerChanged);
    _ownedScrollController?.dispose();
    super.dispose();
  }

  ScrollController _resolveScrollController() {
    if (widget.scrollController != null) return widget.scrollController!;
    _ownedScrollController ??= ScrollController();
    return _ownedScrollController!;
  }

  DateTime get _focusedDate {
    final raw = widget.controller?.focusedDate ?? widget.focusedDate!;
    return EdenSchedulerTimeMath.stripTime(raw);
  }

  DateTime _today() {
    final c = widget.clock ?? DateTime.now;
    return EdenSchedulerTimeMath.stripTime(c());
  }

  List<DateTime> _daysForMode() {
    final monday = EdenSchedulerTimeMath.startOfWeek(_focusedDate);
    final start = widget.mode == EdenSchedulerWeekMode.week
        ? monday.subtract(const Duration(days: 1)) // Sunday-start
        : monday; // Monday-start
    final count = widget.mode == EdenSchedulerWeekMode.workWeek ? 5 : 7;
    return List.generate(count, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = _today();
    final days = _daysForMode();
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      children: [
        // Day headers.
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              const SizedBox(width: _hourLabelWidth),
              ...days.map((d) => Expanded(
                    child: _DayHeader(
                      day: d,
                      isToday: d == today,
                      shortName: _shortDays[d.weekday - 1],
                      onTap: widget.onDateSelected,
                    ),
                  )),
            ],
          ),
        ),
        // Time grid.
        Expanded(
          child: SingleChildScrollView(
            controller: _resolveScrollController(),
            child: SizedBox(
              height: widget.config.totalHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HourLabelColumn(
                    config: widget.config,
                    isDark: isDark,
                    theme: theme,
                    width: _hourLabelWidth,
                  ),
                  ...days.map((d) {
                    final isTodayCol = d == today;
                    final dayEvents = widget.events.where((e) {
                      final eDay = EdenSchedulerTimeMath.stripTime(e.start);
                      return eDay == d;
                    }).toList();
                    return Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isTodayCol
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: TimeColumn(
                          date: d,
                          events: dayEvents,
                          config: widget.config,
                          isDark: isDark,
                          theme: theme,
                          showNowLine: isTodayCol,
                          compact: true,
                          onEventTap: widget.onEventTap,
                          onTimeSlotTap: widget.onTimeSlotTap,
                          clock: widget.clock,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.isToday,
    required this.shortName,
    this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final String shortName;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth.isFinite && c.maxWidth < 60;
        return Semantics(
          button: onTap != null,
          label: '$shortName ${day.day}',
          child: GestureDetector(
            onTap: onTap == null ? null : () => onTap!(day),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        narrow ? shortName.substring(0, 1) : shortName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!narrow && onTap != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_full,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
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
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';

// ---------------------------------------------------------------------------
// Week view
// ---------------------------------------------------------------------------

class WeekView extends StatelessWidget {
  const WeekView({
    super.key,
    required this.focusedDate,
    required this.today,
    required this.events,
    required this.config,
    required this.isDark,
    required this.theme,
    required this.scrollController,
    this.onDateSelected,
    this.onEventTap,
    this.onTimeSlotTap,
  });

  final DateTime focusedDate;
  final DateTime today;
  final List<EdenSchedulerEvent> events;
  final EdenSchedulerConfig config;
  final bool isDark;
  final ThemeData theme;
  final ScrollController scrollController;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;
  final ValueChanged<DateTime>? onTimeSlotTap;

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double _hourLabelWidth = 56;

  @override
  Widget build(BuildContext context) {
    final weekStart =
        focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
    final days =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      children: [
        // Day headers
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              SizedBox(width: _hourLabelWidth),
              ...days.map((d) {
                final isToday = d == today;
                return Expanded(
                  child: Semantics(
                    button: onDateSelected != null,
                    label: '${_shortDays[d.weekday - 1]} ${d.day}',
                    child: GestureDetector(
                      onTap: onDateSelected != null
                          ? () => onDateSelected!(d)
                          : null,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: EdenSpacing.space2),
                        child: Column(
                        children: [
                          Text(
                            _shortDays[d.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
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
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
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
                  ),
                );
              }),
            ],
          ),
        ),
        // Time grid
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(
              height: config.totalHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour labels
                  HourLabelColumn(
                    config: config,
                    isDark: isDark,
                    theme: theme,
                    width: _hourLabelWidth,
                  ),
                  // Day columns
                  ...days.map((d) {
                    final dayEvents = _eventsForDay(d);
                    return Expanded(
                      child: TimeColumn(
                        date: d,
                        events: dayEvents,
                        config: config,
                        isDark: isDark,
                        theme: theme,
                        showNowLine: d == today,
                        compact: true,
                        onEventTap: onEventTap,
                        onTimeSlotTap: onTimeSlotTap,
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

  List<EdenSchedulerEvent> _eventsForDay(DateTime day) {
    return events.where((e) {
      final eDay = DateTime(e.start.year, e.start.month, e.start.day);
      return eDay == day;
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Day view
// ---------------------------------------------------------------------------

class DayView extends StatelessWidget {
  const DayView({
    super.key,
    required this.focusedDate,
    required this.today,
    required this.events,
    required this.config,
    required this.isDark,
    required this.theme,
    required this.scrollController,
    this.onEventTap,
    this.onTimeSlotTap,
  });

  final DateTime focusedDate;
  final DateTime today;
  final List<EdenSchedulerEvent> events;
  final EdenSchedulerConfig config;
  final bool isDark;
  final ThemeData theme;
  final ScrollController scrollController;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;
  final ValueChanged<DateTime>? onTimeSlotTap;

  static const double _hourLabelWidth = 56;

  @override
  Widget build(BuildContext context) {
    final dayEvents = events.where((e) {
      final eDay = DateTime(e.start.year, e.start.month, e.start.day);
      return eDay == focusedDate;
    }).toList();

    return SingleChildScrollView(
      controller: scrollController,
      child: SizedBox(
        height: config.totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HourLabelColumn(
              config: config,
              isDark: isDark,
              theme: theme,
              width: _hourLabelWidth,
            ),
            Expanded(
              child: TimeColumn(
                date: focusedDate,
                events: dayEvents,
                config: config,
                isDark: isDark,
                theme: theme,
                showNowLine: focusedDate == today,
                compact: false,
                onEventTap: onEventTap,
                onTimeSlotTap: onTimeSlotTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared time-grid components
// ---------------------------------------------------------------------------

/// Left-side hour labels.
class HourLabelColumn extends StatelessWidget {
  const HourLabelColumn({
    super.key,
    required this.config,
    required this.isDark,
    required this.theme,
    required this.width,
  });

  final EdenSchedulerConfig config;
  final bool isDark;
  final ThemeData theme;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: config.totalHeight,
      child: Stack(
        children: List.generate(config.hourCount, (i) {
          final hour = config.startHour + i;
          final label = _formatHour(hour);
          return Positioned(
            top: i * config.slotHeight - 7,
            left: 0,
            right: EdenSpacing.space2,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? EdenColors.neutral[500]!
                    : EdenColors.neutral[400]!,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

/// A single day column with hour gridlines, event blocks, and optional
/// now-indicator.
class TimeColumn extends StatelessWidget {
  const TimeColumn({
    super.key,
    required this.date,
    required this.events,
    required this.config,
    required this.isDark,
    required this.theme,
    required this.showNowLine,
    required this.compact,
    this.onEventTap,
    this.onTimeSlotTap,
  });

  final DateTime date;
  final List<EdenSchedulerEvent> events;
  final EdenSchedulerConfig config;
  final bool isDark;
  final ThemeData theme;
  final bool showNowLine;
  final bool compact;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;
  final ValueChanged<DateTime>? onTimeSlotTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    // Lay out events with conflict detection.
    final columns = _layoutConflictColumns(events);

    return GestureDetector(
      onTapUp: (details) {
        if (onTimeSlotTap == null) return;
        final dy = details.localPosition.dy;
        final fractionalHour = dy / config.slotHeight;
        final hour = config.startHour + fractionalHour.floor();
        final minute = ((fractionalHour - fractionalHour.floor()) * 60)
            .round()
            .clamp(0, 59);
        onTimeSlotTap!(
          DateTime(date.year, date.month, date.day, hour, minute),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth = constraints.maxWidth;
            return Stack(
              children: [
                // Hour gridlines
                ...List.generate(config.hourCount, (i) {
                  return Positioned(
                    top: i * config.slotHeight,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: borderColor,
                    ),
                  );
                }),
                // Event blocks
                ..._buildEventBlocks(columns, columnWidth),
                // Now indicator
                if (showNowLine) _buildNowIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Groups overlapping events into columns for side-by-side rendering.
  ///
  /// Each inner list represents a "lane". Events within the same lane do not
  /// overlap. When two events overlap in time they are placed into different
  /// lanes and rendered side-by-side.
  List<List<EdenSchedulerEvent>> _layoutConflictColumns(
      List<EdenSchedulerEvent> events) {
    if (events.isEmpty) return [];

    final sorted = List<EdenSchedulerEvent>.from(events)
      ..sort((a, b) => a.start.compareTo(b.start));

    final List<List<EdenSchedulerEvent>> columns = [];

    for (final event in sorted) {
      bool placed = false;
      for (final col in columns) {
        // Check if this event overlaps with the last event in the column.
        if (col.last.end.isAfter(event.start)) {
          continue; // overlaps, try next column
        }
        col.add(event);
        placed = true;
        break;
      }
      if (!placed) {
        columns.add([event]);
      }
    }

    return columns;
  }

  List<Widget> _buildEventBlocks(
      List<List<EdenSchedulerEvent>> columns, double availableWidth) {
    if (columns.isEmpty) return [];

    final totalColumns = columns.length;
    final padding = EdenSpacing.space1;
    final usableWidth = availableWidth - padding * 2;
    final colWidth = usableWidth / totalColumns;
    final List<Widget> widgets = [];

    for (int colIndex = 0; colIndex < totalColumns; colIndex++) {
      for (final event in columns[colIndex]) {
        final top = _timeToOffset(event.start);
        final height = math.max(
          (event.durationMinutes / 60.0) * config.slotHeight,
          compact ? 16.0 : 24.0,
        );
        final left = padding + colIndex * colWidth;

        widgets.add(
          Positioned(
            top: top,
            left: left,
            width: colWidth,
            height: height,
            child: EventBlock(
              event: event,
              height: height,
              compact: compact,
              theme: theme,
              isDark: isDark,
              onTap: onEventTap != null ? () => onEventTap!(event) : null,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  double _timeToOffset(DateTime time) {
    final hours = time.hour + time.minute / 60.0 - config.startHour;
    return hours.clamp(0.0, config.hourCount.toDouble()) * config.slotHeight;
  }

  Widget _buildNowIndicator() {
    final now = DateTime.now();
    if (now.hour < config.startHour || now.hour >= config.endHour) {
      return const SizedBox.shrink();
    }
    final top = _timeToOffset(now);

    return Positioned(
      top: top - 5,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: EdenColors.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 2, color: EdenColors.error),
          ),
        ],
      ),
    );
  }
}

/// A single rendered event block.
///
/// Sizing and positioning are handled by the parent [Positioned] widget.
/// This widget only handles content, decoration, and interaction.
class EventBlock extends StatelessWidget {
  const EventBlock({
    super.key,
    required this.event,
    required this.height,
    required this.compact,
    required this.theme,
    required this.isDark,
    this.onTap,
  });

  final EdenSchedulerEvent event;
  final double height;
  final bool compact;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = event.color ?? theme.colorScheme.primary;
    final bgColor = isDark ? color.withAlpha(50) : color.withAlpha(30);
    final textColor = color;

    return Semantics(
      button: onTap != null,
      label: 'Event: ${event.title}',
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: EdenRadii.borderRadiusSm,
              border: Border(
                left: BorderSide(color: color, width: 3),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              if (!compact && height > 36)
                Text(
                  _formatTimeRange(event.start, event.end),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withAlpha(180),
                    height: 1.3,
                  ),
                ),
              if (!compact && event.description != null && height > 56)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    event.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              if (!compact && event.assignee != null && height > 72)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.assignee!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} – ${_formatTime(end)}';
  }

  String _formatTime(DateTime t) {
    final hour = t.hour;
    final minute = t.minute;
    final suffix = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return minute == 0 ? '$h $suffix' : '$h:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

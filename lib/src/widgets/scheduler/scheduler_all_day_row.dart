import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';

/// Horizontal strip above the time grid holding events where `allDay == true`.
/// Each cell maps to a day column. Multi-day events span multiple cells.
///
/// Mirrors donor's all-day row (parity row TG-8). Cross-day drag mirrors
/// donor's `handleAllDayDragOver/Drop` (parity row DR-5).
class EdenSchedulerAllDayRow extends StatelessWidget {
  const EdenSchedulerAllDayRow({
    super.key,
    required this.days,
    required this.events,
    this.gutterWidth = 56,
    this.onEventTap,
    this.onEventMove,
    this.onConvertToAllDay,
  });

  /// Visible days. Length = number of cells in the row.
  final List<DateTime> days;

  /// All-day events to render. Non-all-day events are ignored (caller pre-filters).
  final List<EdenSchedulerEvent> events;

  /// Leading gutter width matching the time-axis ruler in DayView/WeekView.
  final double gutterWidth;

  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  /// Cross-day move callback. Receives event + new start/end (all-day,
  /// preserved range length).
  final void Function(
    EdenSchedulerEvent event,
    DateTime newStart,
    DateTime newEnd,
  )? onEventMove;

  /// Convert-to-all-day callback. Fires when an hour-grid event is dragged
  /// into this row.
  final void Function(EdenSchedulerEvent event, DateTime day)?
      onConvertToAllDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    final allDayEvents = events.where((e) => e.allDay).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final cellWidth =
            ((c.maxWidth - gutterWidth) / days.length).clamp(20, 1000);
        // Determine row height — at least 24pt for "Notes" label, more if any
        // events span this range.
        final rowHeight = allDayEvents.isEmpty ? 24.0 : 36.0;

        return Container(
          height: rowHeight,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: gutterWidth,
                child: allDayEvents.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: EdenSpacing.space2,
                        ),
                        child: Text(
                          'Notes',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Cell dividers + drag targets.
                    Row(
                      children: List.generate(days.length, (i) {
                        final day = days[i];
                        return Expanded(
                          child: DragTarget<EdenSchedulerEvent>(
                            onAcceptWithDetails: (details) {
                              final event = details.data;
                              if (event.allDay) {
                                final duration =
                                    event.end.difference(event.start);
                                final newStart =
                                    EdenSchedulerTimeMath.stripTime(day);
                                onEventMove?.call(
                                  event,
                                  newStart,
                                  newStart.add(duration),
                                );
                              } else {
                                onConvertToAllDay?.call(event, day);
                              }
                            },
                            builder: (context, candidate, rejected) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: candidate.isNotEmpty
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.10)
                                      : null,
                                  border: i < days.length - 1
                                      ? Border(
                                          right: BorderSide(color: borderColor),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                    // All-day event bars (multi-day spanning supported).
                    ...allDayEvents.map((e) {
                      final startDay = EdenSchedulerTimeMath.stripTime(e.start);
                      final endDay = EdenSchedulerTimeMath.stripTime(e.end);
                      final firstIdx = days.indexWhere(
                          (d) => !d.isBefore(startDay) && !d.isAfter(endDay));
                      if (firstIdx < 0) return const SizedBox.shrink();
                      var lastIdx = firstIdx;
                      for (var i = firstIdx + 1; i < days.length; i++) {
                        if (days[i].isAfter(endDay)) break;
                        lastIdx = i;
                      }
                      final span = lastIdx - firstIdx + 1;
                      final cellW = cellWidth as double;
                      final color = e.color ?? theme.colorScheme.primary;
                      return Positioned(
                        left: firstIdx * cellW,
                        top: 4,
                        width: span * cellW - 4,
                        height: rowHeight - 8,
                        child: GestureDetector(
                          onTap: onEventTap == null
                              ? null
                              : () => onEventTap!(e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EdenSpacing.space2,
                            ),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: EdenRadii.borderRadiusSm,
                              border: Border(
                                left: BorderSide(color: color, width: 2),
                              ),
                            ),
                            child: Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

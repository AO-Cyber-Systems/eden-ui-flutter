import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';
import 'scheduler_models.dart';

// ---------------------------------------------------------------------------
// Month view — calendar grid with event chip overflow + bottom-sheet drilldown
// ---------------------------------------------------------------------------

/// Calendar month grid for [EdenScheduler]. Renders a 6-row × 7-column grid of
/// day cells with event chip / dot indicators. Per-cell overflow shows a
/// `+N more` affordance that opens a Material modal bottom sheet listing all
/// events on that day.
///
/// Mirrors donor month view (parity row V-4) with light event-chip color
/// rendering (TG-6 light variant). The now-indicator does NOT render in month
/// view — month is date-precision, not time-precision.
class EdenSchedulerMonthView extends StatelessWidget {
  const EdenSchedulerMonthView({
    super.key,
    required this.focusedDate,
    required this.today,
    required this.events,
    required this.isDark,
    required this.theme,
    required this.onDateSelected,
    this.onEventTap,
    this.maxEventsPerCell = 3,
  });

  final DateTime focusedDate;
  final DateTime today;
  final List<EdenSchedulerEvent> events;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  /// Maximum number of event chips visible per cell. When exceeded the
  /// `+N more` overflow affordance is shown. Default 3.
  final int maxEventsPerCell;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final daysInMonth =
        DateTime(focusedDate.year, focusedDate.month + 1, 0).day;
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
        // Day-of-week headers.
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: _dayLabels.map((d) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: EdenSpacing.space2,
                  ),
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
        // Grid.
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
                      final isValid = dayNum >= 1 && dayNum <= daysInMonth;

                      if (!isValid) {
                        // Render Apr/Jun outside-of-month days as muted.
                        return Expanded(
                          child: _OutsideMonthCell(
                            cellIndex: cellIndex,
                            leadingBlanks: leadingBlanks,
                            daysInMonth: daysInMonth,
                            focusedDate: focusedDate,
                            borderColor: borderColor,
                            showRightBorder: col < 6,
                            theme: theme,
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
                        child: _MonthDayCell(
                          date: cellDate,
                          dayNum: dayNum,
                          isToday: isToday,
                          isFocused: isFocused,
                          isMuted: false,
                          events: dayEvents,
                          maxEventsPerCell: maxEventsPerCell,
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

  static int _dateKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}

/// Back-compat typedef so existing `MonthView` imports keep compiling.
@Deprecated('Use EdenSchedulerMonthView')
typedef MonthView = EdenSchedulerMonthView;

class _OutsideMonthCell extends StatelessWidget {
  const _OutsideMonthCell({
    required this.cellIndex,
    required this.leadingBlanks,
    required this.daysInMonth,
    required this.focusedDate,
    required this.borderColor,
    required this.showRightBorder,
    required this.theme,
  });

  final int cellIndex;
  final int leadingBlanks;
  final int daysInMonth;
  final DateTime focusedDate;
  final Color borderColor;
  final bool showRightBorder;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Compute the date that falls outside the focused month.
    final dayNum = cellIndex - leadingBlanks + 1;
    DateTime cellDate;
    if (dayNum < 1) {
      final prev = DateTime(focusedDate.year, focusedDate.month, 0);
      cellDate = DateTime(prev.year, prev.month, prev.day + dayNum);
    } else {
      cellDate = DateTime(focusedDate.year, focusedDate.month + 1,
          dayNum - daysInMonth);
    }
    return Container(
      decoration: BoxDecoration(
        border: showRightBorder
            ? Border(right: BorderSide(color: borderColor))
            : null,
      ),
      padding: const EdgeInsets.all(EdenSpacing.space1),
      alignment: Alignment.topCenter,
      child: Text(
        '${cellDate.day}',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.dayNum,
    required this.isToday,
    required this.isFocused,
    required this.isMuted,
    required this.events,
    required this.maxEventsPerCell,
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
  final bool isMuted;
  final List<EdenSchedulerEvent> events;
  final int maxEventsPerCell;
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

    return LayoutBuilder(
      builder: (context, c) {
        final cellWidth = c.maxWidth;
        final useDots = cellWidth < 80;
        final useShortCount = cellWidth < 60;

        // Height-aware chip cap. The cell column stacks:
        //   - day-number area: Container(height:24) + SizedBox(height:2) = 26pt
        //   - outer padding: EdgeInsets.all(EdenSpacing.space1) = 4pt top + 4pt bottom = 8pt
        //   - each chip: Container(height:16) + Padding.bottom(2) = 18pt
        //   - "+N more" overflow chip: Text + 2pt top padding ≈ 18pt
        // We compute how many 18pt chips fit in the remaining height, with an
        // overflow-chip reservation when not all events fit. The result is
        // clamped to [0, maxEventsPerCell] so the consumer-specified upper
        // bound is still respected. When c.maxHeight is not finite
        // (defensive — `EdenSchedulerMonthView`'s own outer Column+Expanded
        // bounds height in practice, but a synthetic unbounded parent could
        // surface this branch), we fall back to the width-only behavior.
        const double dayNumberAreaHeight = 26;
        const double verticalPadding = 8;
        const double perChipHeight = 18;
        const double overflowChipHeight = 18;

        int heightCap;
        if (!c.maxHeight.isFinite) {
          heightCap = maxEventsPerCell;
        } else {
          final available =
              c.maxHeight - dayNumberAreaHeight - verticalPadding;
          // If the available room can hold every event without an overflow
          // chip, no reservation is needed. Otherwise reserve room for the
          // "+N more" chip so chip + overflow indicator don't both exceed
          // the cell.
          final fitsAll = events.length * perChipHeight <= available;
          final availableForChips =
              fitsAll ? available : available - overflowChipHeight;
          heightCap = (availableForChips ~/ perChipHeight)
              .clamp(0, maxEventsPerCell);
        }

        // Width-based dot mode still wins for narrow cells (existing
        // behavior). ALSO: when the height cap collapses chip space to 0
        // while events exist, fall through to dot mode so the cell surfaces
        // event presence without overflowing the column.
        final effectiveUseDots =
            useDots || (heightCap == 0 && events.isNotEmpty);
        // Limit the number of titled chips at narrow widths to keep cells
        // legible; switch to colored dots when really narrow.
        final cap = effectiveUseDots ? 6 : heightCap;
        final visible = events.take(cap).toList();
        final overflow = events.length - visible.length;

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
              padding: const EdgeInsets.all(EdenSpacing.space1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Day number.
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 24,
                      height: 24,
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
                          fontSize: 12,
                          fontWeight: isToday || isFocused
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday
                              ? Colors.white
                              : isMuted
                                  ? theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.45)
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Event indicators.
                  if (visible.isNotEmpty)
                    effectiveUseDots
                        ? Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            alignment: WrapAlignment.center,
                            children: visible.map((e) {
                              return Semantics(
                                button: onEventTap != null,
                                label: 'Event: ${e.title}',
                                child: GestureDetector(
                                  onTap: onEventTap != null
                                      ? () => onEventTap!(e)
                                      : null,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: e.color ??
                                          theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: visible.map((e) {
                              final color =
                                  e.color ?? theme.colorScheme.primary;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: GestureDetector(
                                  onTap: onEventTap != null
                                      ? () => onEventTap!(e)
                                      : null,
                                  child: Container(
                                    height: 16,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
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
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  if (overflow > 0)
                    Semantics(
                      button: true,
                      label: '$overflow more events',
                      child: GestureDetector(
                        onTap: () => _openOverflowSheet(context),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            useShortCount ? '+$overflow' : '+$overflow more',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
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

  void _openOverflowSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(EdenSpacing.space4),
                child: Text(
                  'Events on ${date.month}/${date.day}/${date.year}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = events[i];
                    final color = e.color ?? theme.colorScheme.primary;
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(e.title),
                      subtitle: e.description != null
                          ? Text(e.description!)
                          : null,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onEventTap?.call(e);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

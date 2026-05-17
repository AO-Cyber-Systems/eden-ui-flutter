import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// 7-day enum for weekly templates.
enum EdenWeekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

extension EdenWeekdayLabel on EdenWeekday {
  String get shortLabel {
    switch (this) {
      case EdenWeekday.monday:
        return 'Mon';
      case EdenWeekday.tuesday:
        return 'Tue';
      case EdenWeekday.wednesday:
        return 'Wed';
      case EdenWeekday.thursday:
        return 'Thu';
      case EdenWeekday.friday:
        return 'Fri';
      case EdenWeekday.saturday:
        return 'Sat';
      case EdenWeekday.sunday:
        return 'Sun';
    }
  }
}

@immutable
class EdenStaffBreak {
  const EdenStaffBreak({
    required this.startTime,
    required this.endTime,
    this.label,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? label;
}

/// One weekly-template entry — staff member's hours + breaks for a specific
/// weekday. Generic across verticals (salon stylists, trades technicians,
/// medical providers).
@immutable
class EdenStaffWeeklyShift {
  const EdenStaffWeeklyShift({
    required this.staffId,
    required this.weekday,
    this.working = true,
    this.startTime,
    this.endTime,
    this.breaks = const [],
  });

  final String staffId;
  final EdenWeekday weekday;
  final bool working;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<EdenStaffBreak> breaks;

  EdenStaffWeeklyShift copyWith({
    String? staffId,
    EdenWeekday? weekday,
    bool? working,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<EdenStaffBreak>? breaks,
  }) {
    return EdenStaffWeeklyShift(
      staffId: staffId ?? this.staffId,
      weekday: weekday ?? this.weekday,
      working: working ?? this.working,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breaks: breaks ?? this.breaks,
    );
  }
}

double _timeToPx(TimeOfDay t, int openingHour, double hourPxWidth) {
  return ((t.hour + t.minute / 60.0) - openingHour) * hourPxWidth;
}

/// Per-staff weekly template editor — 7 day rows × hourly columns, shift
/// blocks rendered as colored spans, breaks overlaid as semi-transparent
/// striping. Tap day row to expand inline editor. Distinct from
/// [EdenScheduler] (obj 004) which manages actual appointments.
class EdenStaffSchedule extends StatefulWidget {
  const EdenStaffSchedule({
    super.key,
    required this.shifts,
    required this.onShiftChanged,
    this.openingHour = 8,
    this.closingHour = 20,
  });

  final List<EdenStaffWeeklyShift> shifts;
  final ValueChanged<EdenStaffWeeklyShift> onShiftChanged;
  final int openingHour;
  final int closingHour;

  @override
  State<EdenStaffSchedule> createState() => _EdenStaffScheduleState();
}

class _EdenStaffScheduleState extends State<EdenStaffSchedule> {
  EdenWeekday? _expandedDay;

  EdenStaffWeeklyShift _shiftFor(EdenWeekday day) {
    return widget.shifts.firstWhere(
      (s) => s.weekday == day,
      orElse: () => EdenStaffWeeklyShift(
        staffId:
            widget.shifts.isNotEmpty ? widget.shifts.first.staffId : 'unknown',
        weekday: day,
        working: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final hours = widget.closingHour - widget.openingHour;
        // Reserve 60pt for day label
        final hourPxWidth = ((c.maxWidth - 60).clamp(40, 9999).toDouble()) / hours;
        return ListView(
          children: [
            // Header row — hour labels
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 60),
                  for (var h = widget.openingHour; h < widget.closingHour; h++)
                    SizedBox(
                      width: hourPxWidth,
                      child: Text(
                        _formatHour(h),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            for (final day in EdenWeekday.values)
              _DayRow(
                key: ValueKey('day-${day.name}'),
                day: day,
                shift: _shiftFor(day),
                expanded: _expandedDay == day,
                openingHour: widget.openingHour,
                hourPxWidth: hourPxWidth,
                onToggleExpand: () => setState(
                  () => _expandedDay = _expandedDay == day ? null : day,
                ),
                onShiftChanged: widget.onShiftChanged,
              ),
          ],
        );
      },
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    super.key,
    required this.day,
    required this.shift,
    required this.expanded,
    required this.openingHour,
    required this.hourPxWidth,
    required this.onToggleExpand,
    required this.onShiftChanged,
  });

  final EdenWeekday day;
  final EdenStaffWeeklyShift shift;
  final bool expanded;
  final int openingHour;
  final double hourPxWidth;
  final VoidCallback onToggleExpand;
  final ValueChanged<EdenStaffWeeklyShift> onShiftChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    day.shortLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: shift.working &&
                            shift.startTime != null &&
                            shift.endTime != null
                        ? Stack(
                            children: [
                              Positioned(
                                key: ValueKey('shift-block-${day.name}'),
                                left: _timeToPx(
                                    shift.startTime!, openingHour, hourPxWidth),
                                width: (_timeToPx(shift.endTime!, openingHour,
                                            hourPxWidth) -
                                        _timeToPx(shift.startTime!,
                                            openingHour, hourPxWidth))
                                    .clamp(0.0, double.infinity),
                                top: 4,
                                bottom: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              for (var i = 0; i < shift.breaks.length; i++)
                                Positioned(
                                  key: ValueKey('break-overlay-${day.name}-$i'),
                                  left: _timeToPx(shift.breaks[i].startTime,
                                      openingHour, hourPxWidth),
                                  width: (_timeToPx(shift.breaks[i].endTime,
                                              openingHour, hourPxWidth) -
                                          _timeToPx(shift.breaks[i].startTime,
                                              openingHour, hourPxWidth))
                                      .clamp(0.0, double.infinity),
                                  top: 4,
                                  bottom: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme
                                          .surfaceContainerHigh
                                          .withValues(alpha: 0.7),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Text(
                              'OFF',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          _DayEditor(shift: shift, onShiftChanged: onShiftChanged),
      ],
    );
  }
}

class _DayEditor extends StatelessWidget {
  const _DayEditor({required this.shift, required this.onShiftChanged});

  final EdenStaffWeeklyShift shift;
  final ValueChanged<EdenStaffWeeklyShift> onShiftChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Working'),
              const Spacer(),
              Switch(
                value: shift.working,
                onChanged: (v) => onShiftChanged(shift.copyWith(working: v)),
              ),
            ],
          ),
          if (shift.working) ...[
            const SizedBox(height: EdenSpacing.space2),
            Row(
              children: [
                Text('Start: ${_formatTime(shift.startTime)}'),
                const SizedBox(width: EdenSpacing.space3),
                Text('End: ${_formatTime(shift.endTime)}'),
              ],
            ),
            const SizedBox(height: EdenSpacing.space2),
            const Text('Breaks:'),
            for (final brk in shift.breaks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                        '${_formatTime(brk.startTime)} - ${_formatTime(brk.endTime)}'),
                    if (brk.label != null) ...[
                      const SizedBox(width: EdenSpacing.space2),
                      Text('(${brk.label})'),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      onPressed: () => onShiftChanged(
                        shift.copyWith(
                          breaks: shift.breaks.where((b) => b != brk).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add break'),
              onPressed: () => onShiftChanged(
                shift.copyWith(
                  breaks: [
                    ...shift.breaks,
                    const EdenStaffBreak(
                      startTime: TimeOfDay(hour: 12, minute: 0),
                      endTime: TimeOfDay(hour: 13, minute: 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatHour(int h) {
  if (h == 0) return '12am';
  if (h == 12) return '12pm';
  return h < 12 ? '${h}am' : '${h - 12}pm';
}

String _formatTime(TimeOfDay? t) {
  if (t == null) return '—';
  final h = t.hour > 12
      ? t.hour - 12
      : (t.hour == 0 ? 12 : t.hour);
  final m = t.minute.toString().padLeft(2, '0');
  final ampm = t.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

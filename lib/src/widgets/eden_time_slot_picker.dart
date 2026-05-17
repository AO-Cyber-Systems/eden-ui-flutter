import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_service_catalog_tile.dart';

/// Staff column for [EdenTimeSlotPicker]. Distinct from [EdenServiceStaff]
/// (from 016-01) which is service-capability metadata — this is the column
/// header value class for the picker's grid.
@immutable
class EdenTimeSlotStaff {
  const EdenTimeSlotStaff({
    required this.id,
    required this.displayName,
    required this.initials,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final String? avatarUrl;
}

/// One bookable slot at a (staff, startTime). The widget snaps to 15-min grid
/// for visual rendering BUT slot.durationMinutes may declare longer durations
/// (multi-cell spanning deferred to v2).
@immutable
class EdenTimeSlot {
  const EdenTimeSlot({
    required this.id,
    required this.staffId,
    required this.startTime,
    this.durationMinutes = 15,
    this.available = true,
    this.blockedReason,
  });

  final String id;
  final String staffId;
  final DateTime startTime;
  final int durationMinutes;
  final bool available;
  final String? blockedReason;
}

/// Pure helper — formats the day header ("Thursday, May 21").
@visibleForTesting
String formatDayHeader(DateTime day) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
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
  return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
}

/// Pure helper — generates the time-row list (TimeOfDay) from openingHour
/// to closingHour in slotMinutes increments. Exclusive of closingHour.
@visibleForTesting
List<TimeOfDay> timeRowsFor({
  required int openingHour,
  required int closingHour,
  int slotMinutes = 15,
}) {
  final out = <TimeOfDay>[];
  for (var h = openingHour; h < closingHour; h++) {
    for (var m = 0; m < 60; m += slotMinutes) {
      out.add(TimeOfDay(hour: h, minute: m));
    }
  }
  return out;
}

/// Customer-facing booking widget — staff × time-of-day slot grid. Distinct
/// from admin [EdenScheduler] (obj 004): no drag, slot-based granularity,
/// staff-as-column always.
///
/// Composes [EdenServiceCatalogEntry] from 016-01 — when [serviceEntry] is
/// provided, only capable staff appear as columns.
class EdenTimeSlotPicker extends StatefulWidget {
  const EdenTimeSlotPicker({
    super.key,
    required this.currentDay,
    required this.allStaff,
    required this.slots,
    required this.onSlotSelected,
    this.selectedSlotId,
    this.onDayChanged,
    this.serviceEntry,
    this.openingHour = 9,
    this.closingHour = 18,
    this.slotMinutes = 15,
    this.dayHeaderBuilder,
    this.emptyStaffLabel = 'No staff available for this service',
  });

  final DateTime currentDay;
  final List<EdenTimeSlotStaff> allStaff;
  final List<EdenTimeSlot> slots;
  final ValueChanged<EdenTimeSlot> onSlotSelected;
  final String? selectedSlotId;
  final ValueChanged<DateTime>? onDayChanged;
  final EdenServiceCatalogEntry? serviceEntry;
  final int openingHour;
  final int closingHour;
  final int slotMinutes;
  final Widget Function(BuildContext, DateTime)? dayHeaderBuilder;
  final String emptyStaffLabel;

  @override
  State<EdenTimeSlotPicker> createState() => _EdenTimeSlotPickerState();
}

class _EdenTimeSlotPickerState extends State<EdenTimeSlotPicker> {
  String? _activeStaffId;

  List<EdenTimeSlotStaff> get _visibleStaff {
    if (widget.serviceEntry == null) return widget.allStaff;
    final capableIds =
        widget.serviceEntry!.capableStaff.map((s) => s.id).toSet();
    return widget.allStaff.where((s) => capableIds.contains(s.id)).toList();
  }

  Map<String, EdenTimeSlot> _slotByKey(List<EdenTimeSlotStaff> visible) {
    final m = <String, EdenTimeSlot>{};
    for (final s in widget.slots) {
      m['${s.staffId}|${s.startTime.hour}:${s.startTime.minute}'] = s;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleStaff;
    if (visible.isEmpty) {
      return Column(
        children: [
          _DayHeader(
            day: widget.currentDay,
            onDayChanged: widget.onDayChanged,
            customBuilder: widget.dayHeaderBuilder,
          ),
          Expanded(
            child: Center(child: Text(widget.emptyStaffLabel)),
          ),
        ],
      );
    }
    // Reset active staff if it was filtered out.
    _activeStaffId ??= visible.first.id;
    if (!visible.any((s) => s.id == _activeStaffId)) {
      _activeStaffId = visible.first.id;
    }

    final rows = timeRowsFor(
      openingHour: widget.openingHour,
      closingHour: widget.closingHour,
      slotMinutes: widget.slotMinutes,
    );
    final byKey = _slotByKey(visible);

    return LayoutBuilder(
      builder: (ctx, c) {
        final useTabStrip = c.maxWidth < 600 || visible.length > 4;
        return Column(
          children: [
            _DayHeader(
              day: widget.currentDay,
              onDayChanged: widget.onDayChanged,
              customBuilder: widget.dayHeaderBuilder,
            ),
            if (useTabStrip)
              _StaffTabStrip(
                staff: visible,
                activeId: _activeStaffId!,
                onTap: (id) => setState(() => _activeStaffId = id),
              ),
            Expanded(
              child: useTabStrip
                  ? _SingleStaffSlotList(
                      activeStaff:
                          visible.firstWhere((s) => s.id == _activeStaffId),
                      rows: rows,
                      slotByKey: byKey,
                      selectedSlotId: widget.selectedSlotId,
                      onSlotSelected: widget.onSlotSelected,
                    )
                  : _StaffGrid(
                      staff: visible,
                      rows: rows,
                      slotByKey: byKey,
                      selectedSlotId: widget.selectedSlotId,
                      onSlotSelected: widget.onSlotSelected,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, this.onDayChanged, this.customBuilder});

  final DateTime day;
  final ValueChanged<DateTime>? onDayChanged;
  final Widget Function(BuildContext, DateTime)? customBuilder;

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) return customBuilder!(context, day);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onDayChanged == null
              ? null
              : () => onDayChanged!(day.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: Center(
            child: Text(
              formatDayHeader(day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onDayChanged == null
              ? null
              : () => onDayChanged!(day.add(const Duration(days: 1))),
        ),
      ],
    );
  }
}

class _StaffTabStrip extends StatelessWidget {
  const _StaffTabStrip({
    required this.staff,
    required this.activeId,
    required this.onTap,
  });

  final List<EdenTimeSlotStaff> staff;
  final String activeId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2, vertical: EdenSpacing.space2),
        child: Row(
          children: [
            for (final s in staff)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(s.displayName),
                  selected: s.id == activeId,
                  onSelected: (_) => onTap(s.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffGrid extends StatelessWidget {
  const _StaffGrid({
    required this.staff,
    required this.rows,
    required this.slotByKey,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  final List<EdenTimeSlotStaff> staff;
  final List<TimeOfDay> rows;
  final Map<String, EdenTimeSlot> slotByKey;
  final String? selectedSlotId;
  final ValueChanged<EdenTimeSlot> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: 80),
            for (final s in staff)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.initials, style: theme.textTheme.labelSmall),
                    Text(
                      s.displayName,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (ctx, i) {
              final row = rows[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        _formatTimeOfDay(row),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    for (final s in staff)
                      Expanded(
                        child: _SlotCell(
                          key: ValueKey(
                              'slot-${s.id}-${row.hour.toString().padLeft(2, '0')}-${row.minute.toString().padLeft(2, '0')}'),
                          slot: slotByKey['${s.id}|${row.hour}:${row.minute}'],
                          selected: slotByKey[
                                      '${s.id}|${row.hour}:${row.minute}']
                                  ?.id ==
                              selectedSlotId,
                          onTap: () {
                            final slot = slotByKey[
                                '${s.id}|${row.hour}:${row.minute}'];
                            if (slot != null && slot.available) {
                              onSlotSelected(slot);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SingleStaffSlotList extends StatelessWidget {
  const _SingleStaffSlotList({
    required this.activeStaff,
    required this.rows,
    required this.slotByKey,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  final EdenTimeSlotStaff activeStaff;
  final List<TimeOfDay> rows;
  final Map<String, EdenTimeSlot> slotByKey;
  final String? selectedSlotId;
  final ValueChanged<EdenTimeSlot> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final row = rows[i];
        final slot = slotByKey['${activeStaff.id}|${row.hour}:${row.minute}'];
        return Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 2, horizontal: EdenSpacing.space2),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  _formatTimeOfDay(row),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: _SlotCell(
                  key: ValueKey(
                      'slot-${activeStaff.id}-${row.hour.toString().padLeft(2, '0')}-${row.minute.toString().padLeft(2, '0')}'),
                  slot: slot,
                  selected: slot?.id == selectedSlotId,
                  onTap: () {
                    if (slot != null && slot.available) {
                      onSlotSelected(slot);
                    }
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

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    super.key,
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final EdenTimeSlot? slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    if (selected) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (slot == null) {
      bg = cs.surface;
      fg = cs.onSurfaceVariant;
    } else if (!slot!.available) {
      bg = cs.surfaceContainerHigh;
      fg = cs.onSurfaceVariant;
    } else {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    }

    final label = slot == null
        ? ''
        : (slot!.available ? 'Open' : (slot!.blockedReason ?? 'Booked'));

    final cell = Container(
      height: 32,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border:
            selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
      ),
      child: InkWell(
        onTap: slot != null && slot!.available ? onTap : null,
        child: Center(
          child: Text(label, style: TextStyle(color: fg, fontSize: 11)),
        ),
      ),
    );
    if (slot != null && !slot!.available) {
      return Tooltip(message: slot!.blockedReason ?? 'Booked', child: cell);
    }
    return cell;
  }
}

String _formatTimeOfDay(TimeOfDay t) {
  final h = t.hour > 12
      ? t.hour - 12
      : (t.hour == 0 ? 12 : t.hour);
  final m = t.minute.toString().padLeft(2, '0');
  final ampm = t.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

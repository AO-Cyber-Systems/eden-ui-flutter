import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import 'scheduler_controller.dart';
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';

/// Chronological list of events grouped under date headers. Renders a flat
/// list sorted by start time with "Today" / "Tomorrow" / "Yesterday" /
/// "Mon, May 18, 2026" date headers.
///
/// Supports controller-driven search and resource filtering (parity rows
/// V-5, T-12, T-9).
///
/// **Range:** from the focused date's week-start through [dateRange]
/// (default 14 days). Recurring events are expanded across the range via
/// [EdenSchedulerTimeMath.expandRecurrence].
class EdenSchedulerListView extends StatefulWidget {
  const EdenSchedulerListView({
    super.key,
    this.focusedDate,
    this.controller,
    required this.events,
    this.dateRange = const Duration(days: 14),
    this.clock,
    this.onEventTap,
  }) : assert(focusedDate != null || controller != null,
            'Either focusedDate or controller must be provided');

  final DateTime? focusedDate;
  final EdenSchedulerController? controller;
  final List<EdenSchedulerEvent> events;
  final Duration dateRange;
  final DateTime Function()? clock;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  @override
  State<EdenSchedulerListView> createState() => _EdenSchedulerListViewState();
}

class _EdenSchedulerListViewState extends State<EdenSchedulerListView> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant EdenSchedulerListView oldWidget) {
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
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  DateTime get _focusedDate {
    final raw = widget.controller?.focusedDate ?? widget.focusedDate!;
    return EdenSchedulerTimeMath.stripTime(raw);
  }

  DateTime get _today {
    final c = widget.clock ?? DateTime.now;
    return EdenSchedulerTimeMath.stripTime(c());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = EdenSchedulerTimeMath.startOfWeek(_focusedDate);
    final end = EdenSchedulerTimeMath.addDays(start, widget.dateRange.inDays);

    final expanded = <EdenSchedulerEvent>[];
    for (final e in widget.events) {
      expanded.addAll(
        EdenSchedulerTimeMath.expandRecurrence(e, start, end),
      );
    }

    final search = (widget.controller?.search ?? '').toLowerCase();
    final selectedResources = widget.controller?.selectedResources ?? const {};

    final filtered = expanded.where((e) {
      if (e.start.isBefore(start) || !e.start.isBefore(end)) return false;
      if (search.isNotEmpty) {
        final hay = [
          e.title,
          e.description ?? '',
          e.assignee ?? '',
          e.location?.name ?? '',
          e.location?.address ?? '',
        ].join(' ').toLowerCase();
        if (!hay.contains(search)) return false;
      }
      if (selectedResources.isNotEmpty) {
        final ids = e.resourceIds ?? const <String>[];
        if (!ids.any(selectedResources.contains)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: EdenSpacing.space2),
            Text(
              'No events in this range.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date.
    final grouped = <DateTime, List<EdenSchedulerEvent>>{};
    for (final e in filtered) {
      final key = EdenSchedulerTimeMath.stripTime(e.start);
      (grouped[key] ??= []).add(e);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedDates.fold<int>(
        0,
        (sum, d) => sum + 1 + grouped[d]!.length,
      ),
      itemBuilder: (context, index) {
        var cursor = 0;
        for (final d in sortedDates) {
          if (index == cursor) {
            return _DateHeader(date: d, today: _today, theme: theme);
          }
          cursor += 1;
          final list = grouped[d]!;
          if (index < cursor + list.length) {
            final event = list[index - cursor];
            return _EventRow(
              event: event,
              theme: theme,
              onTap: widget.onEventTap,
            );
          }
          cursor += list.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.today,
    required this.theme,
  });

  final DateTime date;
  final DateTime today;
  final ThemeData theme;

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _label() {
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${_shortDays[date.weekday - 1]}, '
        '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? EdenColors.neutral[800] : EdenColors.neutral[50];
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      child: Text(
        _label(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.theme,
    this.onTap,
  });

  final EdenSchedulerEvent event;
  final ThemeData theme;
  final ValueChanged<EdenSchedulerEvent>? onTap;

  String _timeLabel() {
    if (event.allDay) return 'All day';
    final start = EdenSchedulerTimeMath.formatTime(
      '${event.start.hour.toString().padLeft(2, '0')}:'
      '${event.start.minute.toString().padLeft(2, '0')}',
    );
    final end = EdenSchedulerTimeMath.formatTime(
      '${event.end.hour.toString().padLeft(2, '0')}:'
      '${event.end.minute.toString().padLeft(2, '0')}',
    );
    return '$start–$end';
  }

  @override
  Widget build(BuildContext context) {
    final color = event.color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(event),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                _timeLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 4,
              height: 32,
              margin: const EdgeInsets.only(right: EdenSpacing.space2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location != null)
                    Text(
                      event.location!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (event.assignee != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  event.assignee!,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

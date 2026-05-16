import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scheduler/scheduler_controller.dart';
import 'scheduler/scheduler_models.dart';
import 'scheduler/scheduler_toolbar.dart';
import 'scheduler/scheduler_month_view.dart';
import 'scheduler/scheduler_week_day_views.dart';

// Re-export the new data models / controller so consumers continue to import
// `package:eden_ui_flutter/eden_ui.dart` and see `EdenSchedulerEvent`,
// `EdenSchedulerView`, etc. unchanged.
export 'scheduler/scheduler_models.dart';
export 'scheduler/scheduler_controller.dart';

/// Configuration for [EdenScheduler] business hours and slot sizing.
class EdenSchedulerConfig {
  /// Creates a scheduler configuration.
  const EdenSchedulerConfig({
    this.startHour = 6,
    this.endHour = 20,
    this.slotHeight = 60.0,
  });

  /// First visible hour (inclusive, 0-23). Defaults to 6 (6 AM).
  final int startHour;

  /// Last visible hour (exclusive, 1-24). Defaults to 20 (8 PM).
  final int endHour;

  /// Pixel height of one hour row. Defaults to 60.
  final double slotHeight;

  /// Total number of visible hours.
  int get hourCount => endHour - startHour;

  /// Total pixel height of the time grid body.
  double get totalHeight => hourCount * slotHeight;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// A multi-view scheduler supporting month, week, and day views.
///
/// Designed for field-service and resource-management UIs. Supports event
/// rendering, time-slot tapping, assignee filtering, conflict detection
/// (side-by-side layout), and a live "now" indicator.
///
/// ```dart
/// EdenScheduler(
///   events: myEvents,
///   view: EdenSchedulerView.week,
///   onEventTap: (event) => print(event.title),
///   onTimeSlotTap: (dateTime) => createEvent(dateTime),
/// )
/// ```
class EdenScheduler extends StatefulWidget {
  /// Creates an Eden scheduler.
  const EdenScheduler({
    super.key,
    this.events = const [],
    this.view = EdenSchedulerView.week,
    this.config = const EdenSchedulerConfig(),
    this.initialDate,
    this.assignees,
    this.selectedAssignees,
    this.onDateSelected,
    this.onEventTap,
    this.onTimeSlotTap,
    this.onViewChanged,
    this.onAssigneeFilterChanged,
  });

  /// Events to display.
  final List<EdenSchedulerEvent> events;

  /// Initial view mode.
  final EdenSchedulerView view;

  /// Time grid configuration.
  final EdenSchedulerConfig config;

  /// The initially focused date. Defaults to today.
  final DateTime? initialDate;

  /// Available assignee names for the filter chip row.
  /// When null the filter row is hidden.
  final List<String>? assignees;

  /// Currently selected assignees. When empty, all events are shown.
  final Set<String>? selectedAssignees;

  /// Called when a date cell is tapped (month view) or a day header is tapped
  /// (week view).
  final ValueChanged<DateTime>? onDateSelected;

  /// Called when an event block is tapped.
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  /// Called when an empty time slot is tapped, providing the slot start time.
  final ValueChanged<DateTime>? onTimeSlotTap;

  /// Called when the user switches view modes.
  final ValueChanged<EdenSchedulerView>? onViewChanged;

  /// Called when the assignee filter selection changes.
  final ValueChanged<Set<String>>? onAssigneeFilterChanged;

  @override
  State<EdenScheduler> createState() => _EdenSchedulerState();
}

class _EdenSchedulerState extends State<EdenScheduler> {
  late EdenSchedulerView _view;
  late DateTime _focusedDate;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _view = widget.view;
    _focusedDate = _stripTime(widget.initialDate ?? DateTime.now());
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ---- helpers ----

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today => _stripTime(DateTime.now());

  Set<String> get _activeAssignees =>
      widget.selectedAssignees ?? const <String>{};

  /// Events filtered by active assignees.
  List<EdenSchedulerEvent> get _filteredEvents {
    if (_activeAssignees.isEmpty) return widget.events;
    return widget.events
        .where((e) => e.assignee != null && _activeAssignees.contains(e.assignee))
        .toList();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final config = widget.config;
    if (now.hour < config.startHour || now.hour >= config.endHour) return;
    final offset =
        ((now.hour - config.startHour) + now.minute / 60.0) * config.slotHeight;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        math.min(offset - config.slotHeight, _scrollController.position.maxScrollExtent),
      );
    }
  }

  void _navigateDate(int delta) {
    setState(() {
      switch (_view) {
        case EdenSchedulerView.month:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month + delta,
            1,
          );
          break;
        case EdenSchedulerView.week:
        case EdenSchedulerView.workWeek:
        case EdenSchedulerView.list:
        case EdenSchedulerView.swimlane:
          _focusedDate = _focusedDate.add(Duration(days: 7 * delta));
          break;
        case EdenSchedulerView.day:
        case EdenSchedulerView.mobile:
          _focusedDate = _focusedDate.add(Duration(days: delta));
          break;
      }
    });
  }

  void _goToday() {
    setState(() {
      _focusedDate = _today;
    });
    if (_view != EdenSchedulerView.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  void _setView(EdenSchedulerView v) {
    if (v == _view) return;
    setState(() => _view = v);
    widget.onViewChanged?.call(v);
    if (v != EdenSchedulerView.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final body = _buildBody(theme, isDark);
        final wrappedBody = hasBoundedHeight
            ? Expanded(child: body)
            : SizedBox(height: 500, child: body);
        return Column(
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            SchedulerToolbar(
              view: _view,
              focusedDate: _focusedDate,
              isDark: isDark,
              theme: theme,
              onPrev: () => _navigateDate(-1),
              onNext: () => _navigateDate(1),
              onToday: _goToday,
              onViewChanged: _setView,
            ),
            if (widget.assignees != null && widget.assignees!.isNotEmpty)
              AssigneeFilterRow(
                assignees: widget.assignees!,
                selected: _activeAssignees,
                isDark: isDark,
                theme: theme,
                onChanged: (s) {
                  widget.onAssigneeFilterChanged?.call(s);
                },
              ),
            wrappedBody,
          ],
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    switch (_view) {
      case EdenSchedulerView.month:
        return MonthView(
          focusedDate: _focusedDate,
          today: _today,
          events: _filteredEvents,
          isDark: isDark,
          theme: theme,
          onDateSelected: (d) {
            setState(() => _focusedDate = d);
            widget.onDateSelected?.call(d);
          },
          onEventTap: widget.onEventTap,
        );
      case EdenSchedulerView.week:
        return WeekView(
          focusedDate: _focusedDate,
          today: _today,
          events: _filteredEvents,
          config: widget.config,
          isDark: isDark,
          theme: theme,
          scrollController: _scrollController,
          onDateSelected: widget.onDateSelected,
          onEventTap: widget.onEventTap,
          onTimeSlotTap: widget.onTimeSlotTap,
        );
      case EdenSchedulerView.day:
      case EdenSchedulerView.mobile:
        return DayView(
          focusedDate: _focusedDate,
          today: _today,
          events: _filteredEvents,
          config: widget.config,
          isDark: isDark,
          theme: theme,
          scrollController: _scrollController,
          onEventTap: widget.onEventTap,
          onTimeSlotTap: widget.onTimeSlotTap,
        );
      case EdenSchedulerView.workWeek:
      case EdenSchedulerView.list:
      case EdenSchedulerView.swimlane:
        // Wave 2/3 will replace these with dedicated views. For now, fall
        // through to the existing WeekView so the new variants render
        // something rather than crashing back-compat consumers that opt in.
        return WeekView(
          focusedDate: _focusedDate,
          today: _today,
          events: _filteredEvents,
          config: widget.config,
          isDark: isDark,
          theme: theme,
          scrollController: _scrollController,
          onDateSelected: widget.onDateSelected,
          onEventTap: widget.onEventTap,
          onTimeSlotTap: widget.onTimeSlotTap,
        );
    }
  }
}

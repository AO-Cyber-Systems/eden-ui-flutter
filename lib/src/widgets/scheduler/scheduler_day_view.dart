import 'dart:async';

import 'package:flutter/material.dart';

import '../eden_scheduler.dart';
import 'scheduler_controller.dart';
import 'scheduler_models.dart';
import 'scheduler_week_day_views.dart';

/// Single-column time grid for one day. Renders a left hour-axis ruler, hourly
/// gridlines, absolutely-positioned event blocks, and a red now-indicator
/// when [focusedDate] equals [clock] today.
///
/// **Now-indicator updates every 60 seconds** via [Timer.periodic]. The timer
/// is cancelled in [State.dispose].
///
/// **Clock injection.** Inject `clock: () => DateTime(...)` for deterministic
/// tests. Production callers should leave [clock] null and the widget will use
/// `DateTime.now`.
///
/// **Controller integration.** When [controller] is supplied, the widget
/// reads `focusedDate` from the controller and listens for changes. Otherwise
/// the explicit [focusedDate] argument is used (back-compat path).
///
/// Mirrors donor `Schedule.tsx` Day view (parity row V-1) with the now-line
/// affordance (parity row TG-4) and time-axis ruler (parity row TG-5).
class EdenSchedulerDayView extends StatefulWidget {
  const EdenSchedulerDayView({
    super.key,
    this.focusedDate,
    this.controller,
    required this.events,
    this.config = const EdenSchedulerConfig(),
    this.clock,
    this.onEventTap,
    this.onTimeSlotTap,
    this.scrollController,
  }) : assert(focusedDate != null || controller != null,
            'Either focusedDate or controller must be provided');

  /// The date to render. Ignored when [controller] is non-null (controller
  /// drives the date).
  final DateTime? focusedDate;

  /// Optional state controller. When supplied, the widget reads focusedDate
  /// from it and rebuilds on notify.
  final EdenSchedulerController? controller;

  /// Events to render. Filtered to those whose date matches [focusedDate].
  final List<EdenSchedulerEvent> events;

  /// Business-hours + slot config.
  final EdenSchedulerConfig config;

  /// Injectable clock for deterministic now-indicator testing.
  final DateTime Function()? clock;

  /// Fires when the user taps an event block.
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  /// Fires when the user taps an empty slot. Receives slot start time
  /// (15-min-snapped).
  final ValueChanged<DateTime>? onTimeSlotTap;

  /// Optional scroll controller for the vertical hour-grid.
  final ScrollController? scrollController;

  @override
  State<EdenSchedulerDayView> createState() => _EdenSchedulerDayViewState();
}

class _EdenSchedulerDayViewState extends State<EdenSchedulerDayView> {
  Timer? _nowTimer;
  ScrollController? _ownedScrollController;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    // Refresh the now-indicator every 60 seconds.
    _nowTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant EdenSchedulerDayView oldWidget) {
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

  DateTime get _effectiveFocusedDate {
    final raw = widget.controller?.focusedDate ?? widget.focusedDate!;
    return DateTime(raw.year, raw.month, raw.day);
  }

  DateTime _today() {
    final c = widget.clock ?? DateTime.now;
    final now = c();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final focusedDate = _effectiveFocusedDate;
    final today = _today();
    final isToday = focusedDate == today;

    final dayEvents = widget.events.where((e) {
      final eDay = DateTime(e.start.year, e.start.month, e.start.day);
      return eDay == focusedDate;
    }).toList();

    return SingleChildScrollView(
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
              width: 56,
            ),
            Expanded(
              child: TimeColumn(
                date: focusedDate,
                events: dayEvents,
                config: widget.config,
                isDark: isDark,
                theme: theme,
                showNowLine: isToday,
                compact: false,
                onEventTap: widget.onEventTap,
                onTimeSlotTap: widget.onTimeSlotTap,
                clock: widget.clock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

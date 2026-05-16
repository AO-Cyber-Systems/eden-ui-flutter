import 'package:flutter/material.dart';

import '../../tokens/spacing.dart';
import '../eden_scheduler.dart';
import 'scheduler_controller.dart';
import 'scheduler_day_view.dart';
import 'scheduler_models.dart';
import 'scheduler_month_view.dart';
import 'scheduler_week_view.dart';

/// Compact mobile composite for [EdenScheduler]. Adapts to the controller's
/// current view (day / week / month) with a tab strip at the top, optional
/// resource chip strip, pinch-zoom on the time grid, and swipe-to-navigate
/// dates on the day mode.
///
/// Parity row V-7 (donor `MobileScheduleView` family). Companion-mode
/// integration (lock E rule 3): when `EdenScheduler` runs at logical width
/// `< 1200pt` OR `forceMobileView == true`, this view is auto-mounted.
class EdenSchedulerMobileView extends StatefulWidget {
  const EdenSchedulerMobileView({
    super.key,
    required this.controller,
    required this.events,
    this.config = const EdenSchedulerConfig(),
    this.resources,
    this.clock,
    this.onEventTap,
    this.onTimeSlotTap,
  });

  final EdenSchedulerController controller;
  final List<EdenSchedulerEvent> events;
  final EdenSchedulerConfig config;
  final List<EdenSchedulerResource>? resources;
  final DateTime Function()? clock;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;
  final ValueChanged<DateTime>? onTimeSlotTap;

  @override
  State<EdenSchedulerMobileView> createState() =>
      _EdenSchedulerMobileViewState();
}

class _EdenSchedulerMobileViewState extends State<EdenSchedulerMobileView> {
  double _zoom = 1.0;
  double _pendingZoom = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant EdenSchedulerMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  EdenSchedulerConfig get _scaledConfig => EdenSchedulerConfig(
        startHour: widget.config.startHour,
        endHour: widget.config.endHour,
        slotHeight: widget.config.slotHeight * _zoom,
        fullDay: widget.config.fullDay,
      );

  Widget _buildBody() {
    final view = widget.controller.view;
    switch (view) {
      case EdenSchedulerView.month:
        return EdenSchedulerMonthView(
          focusedDate: widget.controller.focusedDate,
          today: widget.clock?.call() ?? DateTime.now(),
          events: widget.events,
          isDark: Theme.of(context).brightness == Brightness.dark,
          theme: Theme.of(context),
          onDateSelected: widget.controller.setFocusedDate,
          onEventTap: widget.onEventTap,
          maxEventsPerCell: 1,
        );
      case EdenSchedulerView.week:
      case EdenSchedulerView.workWeek:
      case EdenSchedulerView.swimlane:
        return EdenSchedulerWeekView(
          controller: widget.controller,
          events: widget.events,
          mode: view == EdenSchedulerView.workWeek
              ? EdenSchedulerWeekMode.workWeek
              : EdenSchedulerWeekMode.week,
          config: _scaledConfig,
          clock: widget.clock,
          onEventTap: widget.onEventTap,
          onTimeSlotTap: widget.onTimeSlotTap,
          onDateSelected: widget.controller.setFocusedDate,
        );
      case EdenSchedulerView.day:
      case EdenSchedulerView.mobile:
      case EdenSchedulerView.list:
        return EdenSchedulerDayView(
          controller: widget.controller,
          events: widget.events,
          config: _scaledConfig,
          clock: widget.clock,
          onEventTap: widget.onEventTap,
          onTimeSlotTap: widget.onTimeSlotTap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeTabStrip(controller: widget.controller),
        if (widget.resources != null && widget.resources!.isNotEmpty)
          EdenSchedulerResourceChipStrip(
            controller: widget.controller,
            resources: widget.resources!,
          ),
        Expanded(
          child: EdenSchedulerPinchZoom(
            zoom: _pendingZoom,
            min: 0.5,
            max: 2.0,
            onScaleStart: () => _pendingZoom = _zoom,
            onScaleUpdate: (s) {
              setState(() {
                _pendingZoom = (_zoom * s).clamp(0.5, 2.0);
              });
            },
            onScaleEnd: () {
              setState(() {
                _zoom = _pendingZoom;
              });
            },
            child: _buildBody(),
          ),
        ),
      ],
    );
  }
}

/// Day / Week / Month tab strip at the top of [EdenSchedulerMobileView].
class _ModeTabStrip extends StatelessWidget {
  const _ModeTabStrip({required this.controller});

  final EdenSchedulerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const modes = [
      EdenSchedulerView.day,
      EdenSchedulerView.week,
      EdenSchedulerView.month,
    ];
    final labels = {
      EdenSchedulerView.day: 'Day',
      EdenSchedulerView.week: 'Week',
      EdenSchedulerView.month: 'Month',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: modes.map((m) {
          final isActive = controller.view == m;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.setView(m),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[m]!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Horizontal scrolling row of resource chips with multi-select on tap.
/// Mirrors donor `TruckChipStrip`.
class EdenSchedulerResourceChipStrip extends StatelessWidget {
  const EdenSchedulerResourceChipStrip({
    super.key,
    required this.controller,
    required this.resources,
  });

  final EdenSchedulerController controller;
  final List<EdenSchedulerResource> resources;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            itemCount: resources.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              final r = resources[i];
              final selected = controller.selectedResources.contains(r.id);
              final color = r.color ?? Theme.of(context).colorScheme.primary;
              return FilterChip(
                label: Text(r.name),
                selected: selected,
                onSelected: (_) => controller.toggleResourceFilter(r.id),
                avatar: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Pinch-to-zoom wrapper. Reports zoom factor via callbacks. Clamps zoom to
/// `[min, max]`.
class EdenSchedulerPinchZoom extends StatelessWidget {
  const EdenSchedulerPinchZoom({
    super.key,
    required this.child,
    required this.zoom,
    this.min = 0.5,
    this.max = 2.0,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  final Widget child;
  final double zoom;
  final double min;
  final double max;
  final VoidCallback? onScaleStart;
  final ValueChanged<double>? onScaleUpdate;
  final VoidCallback? onScaleEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onScaleStart: (_) => onScaleStart?.call(),
      onScaleUpdate: (d) => onScaleUpdate?.call(d.scale),
      onScaleEnd: (_) => onScaleEnd?.call(),
      child: child,
    );
  }
}

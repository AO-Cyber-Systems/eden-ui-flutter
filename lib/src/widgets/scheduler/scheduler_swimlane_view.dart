import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'scheduler_controller.dart';
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';

/// Resource-as-column swimlane view. Trucks (or other resources) span columns;
/// dates span rows. Mirrors donor `TruckAvailabilityView` (parity row V-6).
///
/// Requires a minimum logical width of [minWidth] (default 1200pt). At
/// narrower viewports renders a fallback message instead of overflowing.
class EdenSchedulerSwimlaneView extends StatefulWidget {
  const EdenSchedulerSwimlaneView({
    super.key,
    required this.controller,
    required this.resources,
    required this.events,
    this.availabilityBlocks = const [],
    this.dateRange = const Duration(days: 21),
    this.minWidth = 1200,
    this.clock,
    this.onEventTap,
    this.onSwitchToMobile,
  });

  final EdenSchedulerController controller;
  final List<EdenSchedulerResource> resources;
  final List<EdenSchedulerEvent> events;
  final List<EdenSchedulerAvailabilityBlock> availabilityBlocks;
  final Duration dateRange;
  final double minWidth;
  final DateTime Function()? clock;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;
  final VoidCallback? onSwitchToMobile;

  @override
  State<EdenSchedulerSwimlaneView> createState() =>
      _EdenSchedulerSwimlaneViewState();
}

class _EdenSchedulerSwimlaneViewState extends State<EdenSchedulerSwimlaneView> {
  final Set<String> _collapsed = <String>{};

  static const double _dateColWidth = 120;
  static const double _resourceColWidth = 160;
  static const double _collapsedColWidth = 40;
  static const double _rowHeight = 80;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant EdenSchedulerSwimlaneView oldWidget) {
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

  DateTime get _today {
    final c = widget.clock ?? DateTime.now;
    return EdenSchedulerTimeMath.stripTime(c());
  }

  List<EdenSchedulerResource> _sortedResources() {
    final list = [...widget.resources];
    list.sort((a, b) {
      final ag = a.group?.sortOrder ?? 9999;
      final bg = b.group?.sortOrder ?? 9999;
      if (ag != bg) return ag.compareTo(bg);
      return a.name.compareTo(b.name);
    });
    return list;
  }

  List<DateTime> _days() {
    final start = EdenSchedulerTimeMath.startOfWeek(
      widget.controller.focusedDate,
    );
    return List.generate(
      widget.dateRange.inDays,
      (i) => EdenSchedulerTimeMath.addDays(start, i),
    );
  }

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _dateLabel(DateTime d) =>
      '${_shortDays[d.weekday - 1]}, '
      '${_shortMonths[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth.isFinite && c.maxWidth < widget.minWidth) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(EdenSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  Text(
                    'Swimlane view requires ≥${widget.minWidth.toInt()}pt logical width.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  if (widget.onSwitchToMobile != null)
                    FilledButton(
                      onPressed: widget.onSwitchToMobile,
                      child: const Text('Switch to mobile view'),
                    ),
                ],
              ),
            ),
          );
        }

        if (widget.resources.isEmpty) {
          return Center(
            child: Text(
              'No resources to display.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        final resources = _sortedResources();
        final days = _days();
        final isDark = theme.brightness == Brightness.dark;
        final borderColor =
            isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

        return Column(
          children: [
            // Resource header row.
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _dateColWidth,
                    height: 48,
                    child: Center(
                      child: Text(
                        'Date',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  ...resources.map((r) {
                    final collapsed = _collapsed.contains(r.id);
                    return _ResourceHeaderCell(
                      resource: r,
                      collapsed: collapsed,
                      width:
                          collapsed ? _collapsedColWidth : _resourceColWidth,
                      onToggle: () {
                        setState(() {
                          if (collapsed) {
                            _collapsed.remove(r.id);
                          } else {
                            _collapsed.add(r.id);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            // Date rows.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: days.map((d) {
                    final isToday = d == _today;
                    return Container(
                      height: _rowHeight,
                      decoration: BoxDecoration(
                        color: isToday
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.06)
                            : null,
                        border: Border(
                          bottom: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: _dateColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                EdenSpacing.space2,
                              ),
                              child: Text(
                                _dateLabel(d),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isToday
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          ...resources.map((r) {
                            final collapsed = _collapsed.contains(r.id);
                            return _SwimlaneCell(
                              resource: r,
                              date: d,
                              collapsed: collapsed,
                              width: collapsed
                                  ? _collapsedColWidth
                                  : _resourceColWidth,
                              events: widget.events.where((e) {
                                final eDay = EdenSchedulerTimeMath.stripTime(
                                    e.start);
                                return eDay == d &&
                                    (e.resourceIds?.contains(r.id) ?? false);
                              }).toList(),
                              availabilityBlocks:
                                  widget.availabilityBlocks.where((b) {
                                final bDay = EdenSchedulerTimeMath.stripTime(
                                    b.start);
                                return bDay == d && b.resourceId == r.id;
                              }).toList(),
                              borderColor: borderColor,
                              theme: theme,
                              onEventTap: widget.onEventTap,
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResourceHeaderCell extends StatelessWidget {
  const _ResourceHeaderCell({
    required this.resource,
    required this.collapsed,
    required this.width,
    required this.onToggle,
  });

  final EdenSchedulerResource resource;
  final bool collapsed;
  final double width;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 48,
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space1),
          child: collapsed
              ? Center(
                  child: Text(
                    resource.name.isNotEmpty
                        ? resource.name.substring(0, 1)
                        : '?',
                    style: theme.textTheme.labelMedium,
                  ),
                )
              : Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: resource.color ?? theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space1),
                    Expanded(
                      child: Text(
                        resource.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SwimlaneCell extends StatelessWidget {
  const _SwimlaneCell({
    required this.resource,
    required this.date,
    required this.collapsed,
    required this.width,
    required this.events,
    required this.availabilityBlocks,
    required this.borderColor,
    required this.theme,
    this.onEventTap,
  });

  final EdenSchedulerResource resource;
  final DateTime date;
  final bool collapsed;
  final double width;
  final List<EdenSchedulerEvent> events;
  final List<EdenSchedulerAvailabilityBlock> availabilityBlocks;
  final Color borderColor;
  final ThemeData theme;
  final ValueChanged<EdenSchedulerEvent>? onEventTap;

  Color _availabilityTint(EdenSchedulerAvailabilityKind kind) {
    switch (kind) {
      case EdenSchedulerAvailabilityKind.available:
        return Colors.transparent;
      case EdenSchedulerAvailabilityKind.blocked:
        return EdenColors.error.withValues(alpha: 0.10);
      case EdenSchedulerAvailabilityKind.maintenance:
        return EdenColors.warning.withValues(alpha: 0.10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = resource.color ?? theme.colorScheme.primary;
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Stack(
        children: [
          // Availability blocks (background).
          ...availabilityBlocks.map((b) => Positioned.fill(
                child: Container(color: _availabilityTint(b.kind)),
              )),
          // Event bars.
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: events.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: GestureDetector(
                      onTap: onEventTap == null ? null : () => onEventTap!(e),
                      child: Container(
                        height: 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: EdenSpacing.space1,
                        ),
                        decoration: BoxDecoration(
                          color: (e.color ?? color).withValues(alpha: 0.18),
                          borderRadius: EdenRadii.borderRadiusSm,
                          border: Border(
                            left: BorderSide(
                              color: e.color ?? color,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: e.color ?? color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

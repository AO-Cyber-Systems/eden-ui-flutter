import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'scheduler_controller.dart';
import 'scheduler_mobile_view.dart' show EdenSchedulerResourceChipStrip;
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';

/// Density palette for [EdenSchedulerMiniCalendar] heatmap + density legend.
class EdenSchedulerDensityColors {
  const EdenSchedulerDensityColors._();
  static const Color open = Color(0xFFCBD5E1); // light slate
  static const Color low = Color(0xFFA7F3D0); // mint
  static const Color medium = Color(0xFFFCD34D); // amber
  static const Color high = Color(0xFFF87171); // rose
  static const Color full = Color(0xFFDC2626); // red
  static const List<Color> levels = [open, low, medium, high, full];
}

/// Small month grid with optional density-coded day cells (heatmap). Parity
/// row T-7. Renders 6-row × 7-col cells; cells outside the focused month are
/// muted. Tap on a day fires [onDateTap].
class EdenSchedulerMiniCalendar extends StatelessWidget {
  const EdenSchedulerMiniCalendar({
    super.key,
    required this.focusedDate,
    required this.today,
    this.eventDensity = const {},
    this.onDateTap,
    this.onMonthChange,
  });

  final DateTime focusedDate;
  final DateTime today;
  final Map<DateTime, double> eventDensity;
  final ValueChanged<DateTime>? onDateTap;
  final ValueChanged<int>? onMonthChange;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Color _densityColor(double d) {
    if (d <= 0) return Colors.transparent;
    if (d <= 0.2) return EdenSchedulerDensityColors.low;
    if (d <= 0.45) return EdenSchedulerDensityColors.medium;
    if (d <= 0.75) return EdenSchedulerDensityColors.high;
    return EdenSchedulerDensityColors.full;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final daysInMonth =
        DateTime(focusedDate.year, focusedDate.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday; // Mon=1..Sun=7
    final leadingBlanks = (startWeekday - 1) % 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 16),
              onPressed: onMonthChange == null
                  ? null
                  : () => onMonthChange!(-1),
              visualDensity: VisualDensity.compact,
              tooltip: 'Previous month',
            ),
            Expanded(
              child: Text(
                '${_months[focusedDate.month - 1]} ${focusedDate.year}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 16),
              onPressed: onMonthChange == null
                  ? null
                  : () => onMonthChange!(1),
              visualDensity: VisualDensity.compact,
              tooltip: 'Next month',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _miniCalDayHeaderColor,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        ...List.generate(6, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - leadingBlanks + 1;
              final isValid = dayNum >= 1 && dayNum <= daysInMonth;
              if (!isValid) {
                return const Expanded(child: SizedBox(height: 24));
              }
              final cellDate =
                  DateTime(focusedDate.year, focusedDate.month, dayNum);
              final isToday = cellDate == today;
              final density = eventDensity[cellDate] ?? 0.0;
              return Expanded(
                child: GestureDetector(
                  onTap: onDateTap == null ? null : () => onDateTap!(cellDate),
                  child: Container(
                    height: 24,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: _densityColor(density),
                      borderRadius: BorderRadius.circular(2),
                      border: isToday
                          ? Border.all(color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

/// 'Open ●●●●● Full' density legend (parity row T-11).
class EdenSchedulerDensityLegend extends StatelessWidget {
  const EdenSchedulerDensityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Open',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(width: 4),
        ...EdenSchedulerDensityColors.levels.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                ),
              ),
            )),
        const SizedBox(width: 4),
        Text(
          'Full',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Zoom indicator chip with +/- controls (parity row T-4).
class EdenSchedulerZoomIndicator extends StatelessWidget {
  const EdenSchedulerZoomIndicator({
    super.key,
    required this.zoom,
    this.onZoomChange,
    this.step = 0.25,
    this.min = 0.5,
    this.max = 2.0,
  });

  final double zoom;
  final ValueChanged<double>? onZoomChange;
  final double step;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final pct = (zoom * 100).round();
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(color: EdenColors.neutral[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 14),
            onPressed: onZoomChange == null
                ? null
                : () => onZoomChange!((zoom - step).clamp(min, max)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom out',
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$pct%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 14),
            onPressed: onZoomChange == null
                ? null
                : () => onZoomChange!((zoom + step).clamp(min, max)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom in',
          ),
        ],
      ),
    );
  }
}

/// Debounced search text field wired to [EdenSchedulerController.setSearch].
class EdenSchedulerSearchField extends StatefulWidget {
  const EdenSchedulerSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search events…',
    this.debounce = const Duration(milliseconds: 200),
  });

  final EdenSchedulerController controller;
  final String hintText;
  final Duration debounce;

  @override
  State<EdenSchedulerSearchField> createState() =>
      _EdenSchedulerSearchFieldState();
}

class _EdenSchedulerSearchFieldState extends State<EdenSchedulerSearchField> {
  Timer? _timer;
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.controller.search);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () {
      if (mounted) widget.controller.setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _text,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18),
          border: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space2,
          ),
        ),
      ),
    );
  }
}

/// Focus-scoped keyboard shortcuts: 1/2/3/4 keys → switch view to
/// day/workWeek/week/month (parity row T-13).
class EdenSchedulerKeyboardShortcuts extends StatelessWidget {
  const EdenSchedulerKeyboardShortcuts({
    super.key,
    required this.controller,
    required this.child,
    this.autofocus = false,
  });

  final EdenSchedulerController controller;
  final Widget child;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.digit1): _ViewIntent.day,
          SingleActivator(LogicalKeyboardKey.digit2): _ViewIntent.workWeek,
          SingleActivator(LogicalKeyboardKey.digit3): _ViewIntent.week,
          SingleActivator(LogicalKeyboardKey.digit4): _ViewIntent.month,
        },
        child: Actions(
          actions: {
            _ViewIntent: CallbackAction<_ViewIntent>(
              onInvoke: (intent) {
                controller.setView(intent.target);
                return null;
              },
            ),
          },
          child: child,
        ),
      ),
    );
  }
}

class _ViewIntent extends Intent {
  const _ViewIntent._(this.target);
  final EdenSchedulerView target;
  static const _ViewIntent day = _ViewIntent._(EdenSchedulerView.day);
  static const _ViewIntent workWeek = _ViewIntent._(EdenSchedulerView.workWeek);
  static const _ViewIntent week = _ViewIntent._(EdenSchedulerView.week);
  static const _ViewIntent month = _ViewIntent._(EdenSchedulerView.month);
}

/// Three-dot overflow popup (parity row T-5).
class EdenSchedulerOverflowMenu extends StatelessWidget {
  const EdenSchedulerOverflowMenu({
    super.key,
    required this.items,
  });

  final List<PopupMenuItem<String>> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      tooltip: 'More actions',
      itemBuilder: (_) => items,
    );
  }
}

/// Composite sidebar (parity rows T-7, T-8, T-10, T-11). Vertical layout:
/// mini-calendar at top → resource chip strip (vertical scrolling) → density
/// legend → toggles slot.
class EdenSchedulerSidebar extends StatelessWidget {
  const EdenSchedulerSidebar({
    super.key,
    required this.controller,
    required this.resources,
    this.eventDensity = const {},
    this.showUnassigned = false,
    this.showMaintenance = false,
    this.onShowUnassignedChanged,
    this.onShowMaintenanceChanged,
    this.todayClock,
    this.width = 240,
  });

  final EdenSchedulerController controller;
  final List<EdenSchedulerResource> resources;
  final Map<DateTime, double> eventDensity;
  final bool showUnassigned;
  final bool showMaintenance;
  final ValueChanged<bool>? onShowUnassignedChanged;
  final ValueChanged<bool>? onShowMaintenanceChanged;
  final DateTime Function()? todayClock;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = EdenSchedulerTimeMath.stripTime(
      (todayClock ?? DateTime.now).call(),
    );
    return SizedBox(
      width: width,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(EdenSpacing.space2),
                child: EdenSchedulerMiniCalendar(
                  focusedDate: controller.focusedDate,
                  today: today,
                  eventDensity: eventDensity,
                  onDateTap: controller.setFocusedDate,
                  onMonthChange: (delta) {
                    final f = controller.focusedDate;
                    controller.setFocusedDate(
                      DateTime(f.year, f.month + delta, 1),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              if (resources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(EdenSpacing.space2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resources',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      EdenSchedulerResourceChipStrip(
                        controller: controller,
                        resources: resources,
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(EdenSpacing.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: showUnassigned,
                      onChanged: onShowUnassignedChanged == null
                          ? null
                          : (v) => onShowUnassignedChanged!(v ?? false),
                      title: const Text('Show unassigned'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: showMaintenance,
                      onChanged: onShowMaintenanceChanged == null
                          ? null
                          : (v) => onShowMaintenanceChanged!(v ?? false),
                      title: const Text('Show maintenance'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(EdenSpacing.space2),
                child: EdenSchedulerDensityLegend(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Tiny helper to inline a theme reference without a closure.
const Color _miniCalDayHeaderColor = Color(0xFF64748B);

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single day of contribution data.
class EdenContributionDay {
  /// Creates a contribution day.
  const EdenContributionDay({
    required this.date,
    required this.count,
  });

  /// The calendar date for this contribution.
  final DateTime date;

  /// Number of contributions on this date.
  final int count;
}

/// Intensity level for contribution cells.
enum _Intensity { none, low, medium, high, max }

/// A GitHub-style calendar heatmap showing contribution frequency over time.
///
/// Displays a 52-week x 7-day grid of colored cells where color intensity
/// maps to contribution count. Includes month labels, day-of-week labels,
/// a legend, and tap/hover tooltips.
class EdenContributionGraph extends StatefulWidget {
  /// Creates an Eden contribution graph.
  const EdenContributionGraph({
    super.key,
    required this.days,
    this.baseColor,
    this.onDayTap,
  });

  /// The list of contribution days to display.
  final List<EdenContributionDay> days;

  /// The base color used for cell intensity. Defaults to [EdenColors.emerald].
  final MaterialColor? baseColor;

  /// Called when a contribution cell is tapped, with the corresponding day.
  final ValueChanged<EdenContributionDay>? onDayTap;

  @override
  State<EdenContributionGraph> createState() => _EdenContributionGraphState();
}

class _EdenContributionGraphState extends State<EdenContributionGraph> {
  OverlayEntry? _tooltipEntry;

  static const double _cellSize = 13;
  static const double _cellGap = 3;
  static const double _labelWidth = 28;
  static const double _headerHeight = 20;
  static const List<String> _dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', ''];
  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Map<String, EdenContributionDay> get _dayMap {
    final map = <String, EdenContributionDay>{};
    for (final day in widget.days) {
      map[_key(day.date)] = day;
    }
    return map;
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  MaterialColor get _color => widget.baseColor ?? EdenColors.emerald;

  _Intensity _intensity(int count) {
    if (count == 0) return _Intensity.none;
    if (count <= 3) return _Intensity.low;
    if (count <= 7) return _Intensity.medium;
    if (count <= 11) return _Intensity.high;
    return _Intensity.max;
  }

  Color _cellColor(_Intensity intensity, bool isDark) {
    switch (intensity) {
      case _Intensity.none:
        return isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
      case _Intensity.low:
        return isDark ? _color[800]! : _color[200]!;
      case _Intensity.medium:
        return isDark ? _color[600]! : _color[400]!;
      case _Intensity.high:
        return isDark ? _color[500]! : _color[600]!;
      case _Intensity.max:
        return isDark ? _color[400]! : _color[800]!;
    }
  }

  void _showTooltip(
      BuildContext cellContext, EdenContributionDay day, bool isDark) {
    _hideTooltip();
    final overlay = Overlay.of(context);
    final box = cellContext.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    _tooltipEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: offset.dx - 40,
          top: offset.dy - 36,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[900],
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                child: Text(
                  '${day.count} contributions on ${_monthNames[day.date.month - 1]} ${day.date.day}, ${day.date.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? EdenColors.neutral[200]
                        : EdenColors.neutral[50],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_tooltipEntry!);
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  /// Computes the 52 weeks (columns) ending on the most recent Saturday.
  List<List<DateTime>> _buildWeeks() {
    final today = DateTime.now();
    // Find the most recent Sunday (start of week row 0).
    final endSunday = today.subtract(Duration(days: today.weekday % 7));
    final startSunday =
        endSunday.subtract(const Duration(days: 51 * 7));

    final weeks = <List<DateTime>>[];
    for (int w = 0; w < 52; w++) {
      final weekStart = startSunday.add(Duration(days: w * 7));
      final week = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        week.add(weekStart.add(Duration(days: d)));
      }
      weeks.add(week);
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dayMap = _dayMap;
    final weeks = _buildWeeks();
    final labelColor = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    const labelStyle = TextStyle(fontSize: 10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels row
        Padding(
          padding: const EdgeInsets.only(left: _labelWidth),
          child: SizedBox(
            height: _headerHeight,
            child: Row(
              children: _buildMonthLabels(weeks, labelColor, labelStyle),
            ),
          ),
        ),
        // Grid with day labels
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day-of-week labels
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (i) {
                return SizedBox(
                  width: _labelWidth,
                  height: _cellSize + _cellGap,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _dayLabels[i],
                      style: labelStyle.copyWith(color: labelColor),
                    ),
                  ),
                );
              }),
            ),
            // Cells
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks.length, (w) {
                return Padding(
                  padding: const EdgeInsets.only(right: _cellGap),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(7, (d) {
                      final date = weeks[w][d];
                      final day = dayMap[_key(date)];
                      final count = day?.count ?? 0;
                      final intensity = _intensity(count);
                      final cellDay = day ??
                          EdenContributionDay(date: date, count: 0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: _cellGap),
                        child: MouseRegion(
                          onEnter: (_) =>
                              _showTooltip(context, cellDay, isDark),
                          onExit: (_) => _hideTooltip(),
                          child: GestureDetector(
                            onTap: () {
                              widget.onDayTap?.call(cellDay);
                            },
                            onLongPressStart: (_) =>
                                _showTooltip(context, cellDay, isDark),
                            onLongPressEnd: (_) => _hideTooltip(),
                            child: Container(
                              width: _cellSize,
                              height: _cellSize,
                              decoration: BoxDecoration(
                                color: _cellColor(intensity, isDark),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space3),
        // Legend
        Padding(
          padding: const EdgeInsets.only(left: _labelWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Less', style: labelStyle.copyWith(color: labelColor)),
              const SizedBox(width: EdenSpacing.space1),
              for (final intensity in _Intensity.values)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                    width: _cellSize,
                    height: _cellSize,
                    decoration: BoxDecoration(
                      color: _cellColor(intensity, isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const SizedBox(width: EdenSpacing.space1),
              Text('More', style: labelStyle.copyWith(color: labelColor)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMonthLabels(
    List<List<DateTime>> weeks,
    Color labelColor,
    TextStyle labelStyle,
  ) {
    final labels = <Widget>[];
    int? lastMonth;
    for (int w = 0; w < weeks.length; w++) {
      final month = weeks[w][0].month;
      if (month != lastMonth) {
        labels.add(
          SizedBox(
            width: _cellSize + _cellGap,
            child: Text(
              _monthNames[month - 1],
              style: labelStyle.copyWith(color: labelColor),
            ),
          ),
        );
        lastMonth = month;
      } else {
        labels.add(const SizedBox(width: _cellSize + _cellGap));
      }
    }
    return labels;
  }
}

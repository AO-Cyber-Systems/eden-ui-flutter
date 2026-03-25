import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single item on the roadmap timeline.
class EdenRoadmapItem {
  /// Creates a roadmap item.
  const EdenRoadmapItem({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.progress = 0,
    this.color,
    this.children = const [],
  });

  /// Unique identifier for this item.
  final String id;

  /// Display title of the item.
  final String title;

  /// The start date of this item.
  final DateTime startDate;

  /// The end date of this item.
  final DateTime endDate;

  /// Completion progress from 0.0 to 1.0.
  final double progress;

  /// Optional color override for this item's bar.
  final Color? color;

  /// Sub-items that can be collapsed/expanded under this item.
  final List<EdenRoadmapItem> children;
}

/// A Gantt-style roadmap timeline view.
///
/// Displays roadmap items as horizontal bars positioned along a time axis,
/// with month/week markers, progress fill, a today marker, collapsible
/// groups, and both horizontal (time) and vertical (items) scrolling.
class EdenRoadmapView extends StatefulWidget {
  /// Creates an Eden roadmap view.
  const EdenRoadmapView({
    super.key,
    required this.items,
    this.onItemTap,
    this.rowHeight = 40,
    this.dayWidth = 4,
  });

  /// The top-level roadmap items.
  final List<EdenRoadmapItem> items;

  /// Called when an item bar is tapped.
  final ValueChanged<EdenRoadmapItem>? onItemTap;

  /// Height of each item row in pixels.
  final double rowHeight;

  /// Width of a single day in pixels.
  final double dayWidth;

  @override
  State<EdenRoadmapView> createState() => _EdenRoadmapViewState();
}

class _EdenRoadmapViewState extends State<EdenRoadmapView> {
  final Set<String> _collapsed = {};
  late ScrollController _horizontalController;
  late ScrollController _verticalController;
  late ScrollController _headerScrollController;
  late ScrollController _labelScrollController;

  static const double _labelWidth = 200;
  static const double _headerHeight = 44;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    _headerScrollController = ScrollController();
    _labelScrollController = ScrollController();

    _horizontalController.addListener(_syncHorizontalScroll);
    _verticalController.addListener(_syncVerticalScroll);
  }

  void _syncHorizontalScroll() {
    if (_headerScrollController.hasClients) {
      _headerScrollController.jumpTo(_horizontalController.offset);
    }
  }

  void _syncVerticalScroll() {
    if (_labelScrollController.hasClients) {
      _labelScrollController.jumpTo(_verticalController.offset);
    }
  }

  @override
  void dispose() {
    _horizontalController.removeListener(_syncHorizontalScroll);
    _verticalController.removeListener(_syncVerticalScroll);
    _horizontalController.dispose();
    _verticalController.dispose();
    _headerScrollController.dispose();
    _labelScrollController.dispose();
    super.dispose();
  }

  /// Flatten the item tree respecting collapsed state.
  List<_FlatItem> _flatten() {
    final result = <_FlatItem>[];
    void walk(List<EdenRoadmapItem> items, int depth) {
      for (final item in items) {
        final hasChildren = item.children.isNotEmpty;
        result.add(_FlatItem(item: item, depth: depth, hasChildren: hasChildren));
        if (hasChildren && !_collapsed.contains(item.id)) {
          walk(item.children, depth + 1);
        }
      }
    }

    walk(widget.items, 0);
    return result;
  }

  /// Compute the full date range across all items.
  (DateTime, DateTime) _dateRange() {
    DateTime earliest = DateTime(2999);
    DateTime latest = DateTime(1970);
    void walk(List<EdenRoadmapItem> items) {
      for (final item in items) {
        if (item.startDate.isBefore(earliest)) earliest = item.startDate;
        if (item.endDate.isAfter(latest)) latest = item.endDate;
        walk(item.children);
      }
    }

    walk(widget.items);
    // Add padding of 1 week on each side.
    earliest = earliest.subtract(const Duration(days: 7));
    latest = latest.add(const Duration(days: 7));
    return (earliest, latest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flatItems = _flatten();
    final (rangeStart, rangeEnd) = _dateRange();
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    final totalWidth = totalDays * widget.dayWidth;
    final totalHeight = flatItems.length * widget.rowHeight;
    final labelColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final gridColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row: empty corner + time header
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              // Corner
              Container(
                width: _labelWidth,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: gridColor),
                    right: BorderSide(color: gridColor),
                  ),
                ),
              ),
              // Time axis header
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: CustomPaint(
                    size: Size(totalWidth, _headerHeight),
                    painter: _TimeHeaderPainter(
                      rangeStart: rangeStart,
                      totalDays: totalDays,
                      dayWidth: widget.dayWidth,
                      labelColor: labelColor,
                      gridColor: gridColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Body: label column + chart area
        Expanded(
          child: Row(
            children: [
              // Labels column
              SizedBox(
                width: _labelWidth,
                child: ListView.builder(
                  controller: _labelScrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: flatItems.length,
                  itemExtent: widget.rowHeight,
                  itemBuilder: (context, index) => _buildLabel(
                    flatItems[index],
                    isDark,
                    theme,
                    gridColor,
                  ),
                ),
              ),
              // Chart area
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    height: totalHeight,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: CustomPaint(
                        size: Size(totalWidth, totalHeight),
                        painter: _RoadmapPainter(
                          items: flatItems,
                          rangeStart: rangeStart,
                          totalDays: totalDays,
                          dayWidth: widget.dayWidth,
                          rowHeight: widget.rowHeight,
                          isDark: isDark,
                          gridColor: gridColor,
                        ),
                        child: SizedBox(
                          width: totalWidth,
                          height: totalHeight,
                          child: Stack(
                            children: [
                              for (int i = 0; i < flatItems.length; i++)
                                _buildBar(
                                    flatItems[i], i, rangeStart, totalDays, isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(
    _FlatItem flat,
    bool isDark,
    ThemeData theme,
    Color gridColor,
  ) {
    return Container(
      height: widget.rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: gridColor, width: 0.5),
          right: BorderSide(color: gridColor),
        ),
      ),
      padding: EdgeInsets.only(
        left: EdenSpacing.space3 + flat.depth * EdenSpacing.space4,
        right: EdenSpacing.space2,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flat.hasChildren)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_collapsed.contains(flat.item.id)) {
                    _collapsed.remove(flat.item.id);
                  } else {
                    _collapsed.add(flat.item.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: EdenSpacing.space1),
                child: Icon(
                  _collapsed.contains(flat.item.id)
                      ? Icons.chevron_right
                      : Icons.expand_more,
                  size: 16,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ),
            ),
          Flexible(
            child: Text(
              flat.item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight:
                    flat.hasChildren ? FontWeight.w600 : FontWeight.normal,
                color: isDark
                    ? EdenColors.neutral[200]
                    : EdenColors.neutral[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    _FlatItem flat,
    int rowIndex,
    DateTime rangeStart,
    int totalDays,
    bool isDark,
  ) {
    final item = flat.item;
    final startOffset = item.startDate.difference(rangeStart).inDays;
    final duration = item.endDate.difference(item.startDate).inDays;
    final left = startOffset * widget.dayWidth;
    final width = math.max(duration * widget.dayWidth, 8.0);
    final top = rowIndex * widget.rowHeight + 8;
    final barHeight = widget.rowHeight - 16;
    final barColor = item.color ??
        (isDark ? EdenColors.blue[600]! : EdenColors.blue[500]!);

    return Positioned(
      left: left,
      top: top.toDouble(),
      child: GestureDetector(
        onTap: () => widget.onItemTap?.call(item),
        child: Container(
          width: width,
          height: barHeight.toDouble(),
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.25),
            borderRadius: EdenRadii.borderRadiusSm,
            border: Border.all(
              color: barColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: EdenRadii.borderRadiusSm,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: width * item.progress.clamp(0, 1),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.6),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatItem {
  const _FlatItem({
    required this.item,
    required this.depth,
    required this.hasChildren,
  });

  final EdenRoadmapItem item;
  final int depth;
  final bool hasChildren;
}

class _TimeHeaderPainter extends CustomPainter {
  _TimeHeaderPainter({
    required this.rangeStart,
    required this.totalDays,
    required this.dayWidth,
    required this.labelColor,
    required this.gridColor,
    required this.isDark,
  });

  final DateTime rangeStart;
  final int totalDays;
  final double dayWidth;
  final Color labelColor;
  final Color gridColor;
  final bool isDark;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Bottom border
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      linePaint,
    );

    // Month labels and vertical lines
    int? lastMonth;
    for (int d = 0; d < totalDays; d++) {
      final date = rangeStart.add(Duration(days: d));
      if (date.month != lastMonth) {
        lastMonth = date.month;
        final x = d * dayWidth;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          linePaint,
        );
        final label = '${_months[date.month - 1]} ${date.year}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 11, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 4, size.height / 2 - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeHeaderPainter old) =>
      old.rangeStart != rangeStart ||
      old.totalDays != totalDays ||
      old.isDark != isDark;
}

class _RoadmapPainter extends CustomPainter {
  _RoadmapPainter({
    required this.items,
    required this.rangeStart,
    required this.totalDays,
    required this.dayWidth,
    required this.rowHeight,
    required this.isDark,
    required this.gridColor,
  });

  final List<_FlatItem> items;
  final DateTime rangeStart;
  final int totalDays;
  final double dayWidth;
  final double rowHeight;
  final bool isDark;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Row dividers
    for (int i = 0; i <= items.length; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Month vertical gridlines
    int? lastMonth;
    for (int d = 0; d < totalDays; d++) {
      final date = rangeStart.add(Duration(days: d));
      if (date.month != lastMonth) {
        lastMonth = date.month;
        final x = d * dayWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
    }

    // Today marker
    final today = DateTime.now();
    final todayOffset = today.difference(rangeStart).inDays;
    if (todayOffset >= 0 && todayOffset <= totalDays) {
      final x = todayOffset * dayWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = EdenColors.red[500]!
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadmapPainter old) =>
      old.items != items || old.isDark != isDark;
}

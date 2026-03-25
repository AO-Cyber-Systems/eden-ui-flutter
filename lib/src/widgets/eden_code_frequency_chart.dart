import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A week of code frequency data.
class EdenCodeFrequencyWeek {
  /// Creates a code frequency week.
  const EdenCodeFrequencyWeek({
    required this.weekStart,
    required this.additions,
    required this.deletions,
  });

  /// The start date of this week.
  final DateTime weekStart;

  /// Number of lines added this week (positive).
  final int additions;

  /// Number of lines deleted this week (positive value, rendered below axis).
  final int deletions;
}

/// A dual area chart showing lines added and deleted per week.
///
/// Additions are rendered as a green area above the x-axis and deletions
/// as a red area below the x-axis, similar to GitHub's code frequency graph.
/// Uses [CustomPainter] for rendering axes, gridlines, area fills, and tooltips.
class EdenCodeFrequencyChart extends StatefulWidget {
  /// Creates an Eden code frequency chart.
  const EdenCodeFrequencyChart({
    super.key,
    required this.weeks,
    this.additionsColor,
    this.deletionsColor,
    this.onWeekTap,
    this.height = 220,
  });

  /// The weekly code frequency data.
  final List<EdenCodeFrequencyWeek> weeks;

  /// Color for the additions area. Defaults to [EdenColors.emerald].
  final Color? additionsColor;

  /// Color for the deletions area. Defaults to [EdenColors.red].
  final Color? deletionsColor;

  /// Called when a week column is tapped.
  final ValueChanged<EdenCodeFrequencyWeek>? onWeekTap;

  /// The height of the chart area.
  final double height;

  @override
  State<EdenCodeFrequencyChart> createState() =>
      _EdenCodeFrequencyChartState();
}

class _EdenCodeFrequencyChartState extends State<EdenCodeFrequencyChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addColor = widget.additionsColor ?? EdenColors.emerald[500]!;
    final delColor = widget.deletionsColor ?? EdenColors.red[500]!;
    final labelColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final gridColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(addColor, 'Additions', isDark),
            const SizedBox(width: EdenSpacing.space4),
            _legendItem(delColor, 'Deletions', isDark),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _handleTap(details, constraints),
                child: MouseRegion(
                  onHover: (event) => _handleHover(event, constraints),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, widget.height),
                    painter: _CodeFrequencyPainter(
                      weeks: widget.weeks,
                      additionsColor: addColor,
                      deletionsColor: delColor,
                      gridColor: gridColor,
                      labelColor: labelColor,
                      isDark: isDark,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
        ),
      ],
    );
  }

  int? _hitTest(Offset pos, BoxConstraints constraints) {
    if (widget.weeks.isEmpty) return null;
    const padding = _CodeFrequencyPainter.chartPadding;
    final chartW = constraints.maxWidth - padding.left - padding.right;
    final n = widget.weeks.length;
    if (n == 0) return null;
    final barW = chartW / n;
    final x = pos.dx - padding.left;
    if (x < 0 || x > chartW) return null;
    final idx = (x / barW).floor().clamp(0, n - 1);
    return idx;
  }

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    final idx = _hitTest(details.localPosition, constraints);
    if (idx != null) {
      widget.onWeekTap?.call(widget.weeks[idx]);
    }
  }

  void _handleHover(PointerEvent event, BoxConstraints constraints) {
    final idx = _hitTest(event.localPosition, constraints);
    if (idx != _hoveredIndex) {
      setState(() => _hoveredIndex = idx);
    }
  }
}

class _CodeFrequencyPainter extends CustomPainter {
  _CodeFrequencyPainter({
    required this.weeks,
    required this.additionsColor,
    required this.deletionsColor,
    required this.gridColor,
    required this.labelColor,
    required this.isDark,
    this.hoveredIndex,
  });

  final List<EdenCodeFrequencyWeek> weeks;
  final Color additionsColor;
  final Color deletionsColor;
  final Color gridColor;
  final Color labelColor;
  final bool isDark;
  final int? hoveredIndex;

  static const EdgeInsets chartPadding =
      EdgeInsets.fromLTRB(50, 8, 12, 32);

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.isEmpty) return;

    final chartRect = Rect.fromLTRB(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.right,
      size.height - chartPadding.bottom,
    );

    final maxAdd =
        weeks.map((w) => w.additions).reduce(math.max).toDouble();
    final maxDel =
        weeks.map((w) => w.deletions).reduce(math.max).toDouble();
    final maxVal = math.max(maxAdd, maxDel).clamp(1.0, double.infinity);

    // The zero line sits at the vertical center.
    final zeroY = chartRect.top + chartRect.height / 2;
    final halfH = chartRect.height / 2;

    _drawGrid(canvas, chartRect, zeroY, maxVal);
    _drawAreas(canvas, chartRect, zeroY, halfH, maxVal);
    _drawXLabels(canvas, chartRect);

    if (hoveredIndex != null) {
      _drawTooltip(canvas, chartRect, size, zeroY, halfH, maxVal);
    }
  }

  void _drawGrid(Canvas canvas, Rect rect, double zeroY, double maxVal) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    // Zero line
    canvas.drawLine(
      Offset(rect.left, zeroY),
      Offset(rect.right, zeroY),
      Paint()
        ..color = labelColor
        ..strokeWidth = 1,
    );
    // Grid lines above and below
    for (int i = 1; i <= 2; i++) {
      final dy = (rect.height / 4) * i;
      canvas.drawLine(
        Offset(rect.left, zeroY - dy),
        Offset(rect.right, zeroY - dy),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left, zeroY + dy),
        Offset(rect.right, zeroY + dy),
        paint,
      );
    }
    // Y labels
    for (int i = -2; i <= 2; i++) {
      final value = (maxVal * i / 2).round();
      final y = zeroY - (rect.height / 4) * i;
      final label = value >= 0 ? '+$value' : '$value';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(rect.left - tp.width - 6, y - tp.height / 2));
    }
  }

  void _drawAreas(
    Canvas canvas,
    Rect rect,
    double zeroY,
    double halfH,
    double maxVal,
  ) {
    final n = weeks.length;
    final barW = rect.width / n;

    // Additions area (above zero line)
    final addPath = Path()..moveTo(rect.left, zeroY);
    for (int i = 0; i < n; i++) {
      final x = rect.left + (i + 0.5) * barW;
      final h = (weeks[i].additions / maxVal) * halfH;
      addPath.lineTo(x, zeroY - h);
    }
    addPath.lineTo(rect.right, zeroY);
    addPath.close();
    canvas.drawPath(
      addPath,
      Paint()..color = additionsColor.withValues(alpha: 0.35),
    );
    // Additions stroke
    final addStroke = Path()..moveTo(rect.left, zeroY);
    for (int i = 0; i < n; i++) {
      final x = rect.left + (i + 0.5) * barW;
      final h = (weeks[i].additions / maxVal) * halfH;
      addStroke.lineTo(x, zeroY - h);
    }
    canvas.drawPath(
      addStroke,
      Paint()
        ..color = additionsColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Deletions area (below zero line)
    final delPath = Path()..moveTo(rect.left, zeroY);
    for (int i = 0; i < n; i++) {
      final x = rect.left + (i + 0.5) * barW;
      final h = (weeks[i].deletions / maxVal) * halfH;
      delPath.lineTo(x, zeroY + h);
    }
    delPath.lineTo(rect.right, zeroY);
    delPath.close();
    canvas.drawPath(
      delPath,
      Paint()..color = deletionsColor.withValues(alpha: 0.35),
    );
    // Deletions stroke
    final delStroke = Path()..moveTo(rect.left, zeroY);
    for (int i = 0; i < n; i++) {
      final x = rect.left + (i + 0.5) * barW;
      final h = (weeks[i].deletions / maxVal) * halfH;
      delStroke.lineTo(x, zeroY + h);
    }
    canvas.drawPath(
      delStroke,
      Paint()
        ..color = deletionsColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Highlight hovered column
    if (hoveredIndex != null && hoveredIndex! < n) {
      final x = rect.left + hoveredIndex! * barW;
      canvas.drawRect(
        Rect.fromLTWH(x, rect.top, barW, rect.height),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.06),
      );
    }
  }

  void _drawXLabels(Canvas canvas, Rect rect) {
    final n = weeks.length;
    if (n == 0) return;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final barW = rect.width / n;
    int? lastMonth;
    for (int i = 0; i < n; i++) {
      final month = weeks[i].weekStart.month;
      if (month != lastMonth) {
        lastMonth = month;
        final x = rect.left + (i + 0.5) * barW;
        final tp = TextPainter(
          text: TextSpan(
            text: months[month - 1],
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, rect.bottom + 6));
      }
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Rect rect,
    Size size,
    double zeroY,
    double halfH,
    double maxVal,
  ) {
    final i = hoveredIndex!;
    if (i < 0 || i >= weeks.length) return;
    final week = weeks[i];
    final barW = rect.width / weeks.length;
    final x = rect.left + (i + 0.5) * barW;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final text =
        '${months[week.weekStart.month - 1]} ${week.weekStart.day}: '
        '+${week.additions}  -${week.deletions}';

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? EdenColors.neutral[200] : EdenColors.neutral[50],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final boxW = tp.width + 12;
    final boxH = tp.height + 8;
    var left = x - boxW / 2;
    if (left < 0) left = 0;
    if (left + boxW > size.width) left = size.width - boxW;
    final top = rect.top;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, boxW, boxH),
        const Radius.circular(EdenRadii.sm),
      ),
      Paint()
        ..color =
            isDark ? EdenColors.neutral[800]! : EdenColors.neutral[900]!,
    );
    tp.paint(canvas, Offset(left + 6, top + 4));
  }

  @override
  bool shouldRepaint(covariant _CodeFrequencyPainter old) =>
      old.weeks != weeks ||
      old.hoveredIndex != hoveredIndex ||
      old.isDark != isDark;
}

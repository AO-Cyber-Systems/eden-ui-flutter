import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single data point on the burndown chart.
class EdenBurndownPoint {
  /// Creates a burndown point.
  const EdenBurndownPoint({
    required this.date,
    required this.idealRemaining,
    required this.actualRemaining,
  });

  /// The date for this data point.
  final DateTime date;

  /// The ideal remaining items at this date.
  final double idealRemaining;

  /// The actual remaining items at this date.
  final double actualRemaining;
}

/// A burndown chart showing ideal vs actual progress over a sprint or iteration.
///
/// Renders two line series using [CustomPainter]: a straight ideal line from
/// total to zero, and a jagged actual line with markers. Includes area fill
/// under the ideal line, axis labels, gridlines, and a title.
class EdenBurndownChart extends StatefulWidget {
  /// Creates an Eden burndown chart.
  const EdenBurndownChart({
    super.key,
    required this.points,
    this.title,
    this.totalPoints,
    this.idealColor,
    this.actualColor,
    this.onPointTap,
    this.height = 240,
  });

  /// The data points to plot.
  final List<EdenBurndownPoint> points;

  /// An optional title displayed above the chart.
  final String? title;

  /// The total number of points/items at sprint start.
  /// If null, derived from the first point's idealRemaining.
  final double? totalPoints;

  /// Color for the ideal line and area fill. Defaults to primary blue.
  final Color? idealColor;

  /// Color for the actual line and markers. Defaults to warning amber.
  final Color? actualColor;

  /// Called when a data point marker is tapped.
  final ValueChanged<EdenBurndownPoint>? onPointTap;

  /// The height of the chart area.
  final double height;

  @override
  State<EdenBurndownChart> createState() => _EdenBurndownChartState();
}

class _EdenBurndownChartState extends State<EdenBurndownChart> {
  int? _hoveredIndex;

  double get _totalPoints =>
      widget.totalPoints ??
      (widget.points.isNotEmpty ? widget.points.first.idealRemaining : 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final idealColor = widget.idealColor ?? EdenColors.blue[500]!;
    final actualColor = widget.actualColor ?? EdenColors.warning;
    final labelColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final gridColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? EdenColors.neutral[100] : EdenColors.neutral[900],
            ),
          ),
          const SizedBox(height: EdenSpacing.space1),
          _buildSubtitle(isDark),
          const SizedBox(height: EdenSpacing.space3),
        ],
        // Legend
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(idealColor, 'Ideal', isDark),
            const SizedBox(width: EdenSpacing.space4),
            _legendItem(actualColor, 'Actual', isDark),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) =>
                    _handleTap(details, constraints, idealColor, actualColor),
                child: MouseRegion(
                  onHover: (event) =>
                      _handleHover(event, constraints),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, widget.height),
                    painter: _BurndownPainter(
                      points: widget.points,
                      totalPoints: _totalPoints,
                      idealColor: idealColor,
                      actualColor: actualColor,
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

  Widget _buildSubtitle(bool isDark) {
    if (widget.points.isEmpty) return const SizedBox.shrink();
    final first = widget.points.first.date;
    final last = widget.points.last.date;
    const fmt = _formatDate;
    return Text(
      '${fmt(first)} — ${fmt(last)}  ·  ${_totalPoints.toInt()} points',
      style: TextStyle(
        fontSize: 12,
        color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  Widget _legendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: EdenRadii.borderRadiusFull,
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

  void _handleTap(
    TapDownDetails details,
    BoxConstraints constraints,
    Color idealColor,
    Color actualColor,
  ) {
    final idx = _hitTestPoint(details.localPosition, constraints);
    if (idx != null) {
      widget.onPointTap?.call(widget.points[idx]);
    }
  }

  void _handleHover(PointerEvent event, BoxConstraints constraints) {
    final idx = _hitTestPoint(event.localPosition, constraints);
    if (idx != _hoveredIndex) {
      setState(() => _hoveredIndex = idx);
    }
  }

  int? _hitTestPoint(Offset position, BoxConstraints constraints) {
    if (widget.points.isEmpty) return null;
    const padding = _BurndownPainter.chartPadding;
    final chartW = constraints.maxWidth - padding.left - padding.right;
    final chartH = widget.height - padding.top - padding.bottom;
    final n = widget.points.length;
    if (n < 2) return null;

    for (int i = 0; i < n; i++) {
      final x = padding.left + (i / (n - 1)) * chartW;
      final y = padding.top +
          (1 - widget.points[i].actualRemaining / _totalPoints) * chartH;
      if ((Offset(x, y) - position).distance < 14) return i;
    }
    return null;
  }
}

class _BurndownPainter extends CustomPainter {
  _BurndownPainter({
    required this.points,
    required this.totalPoints,
    required this.idealColor,
    required this.actualColor,
    required this.gridColor,
    required this.labelColor,
    required this.isDark,
    this.hoveredIndex,
  });

  final List<EdenBurndownPoint> points;
  final double totalPoints;
  final Color idealColor;
  final Color actualColor;
  final Color gridColor;
  final Color labelColor;
  final bool isDark;
  final int? hoveredIndex;

  static const EdgeInsets chartPadding =
      EdgeInsets.fromLTRB(40, 8, 12, 32);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || totalPoints <= 0) return;

    final chartRect = Rect.fromLTRB(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.right,
      size.height - chartPadding.bottom,
    );
    final n = points.length;

    _drawGrid(canvas, chartRect);
    _drawYLabels(canvas, chartRect);
    _drawXLabels(canvas, chartRect, n);
    _drawIdealArea(canvas, chartRect, n);
    _drawIdealLine(canvas, chartRect, n);
    _drawActualLine(canvas, chartRect, n);
    _drawMarkers(canvas, chartRect, n);
    if (hoveredIndex != null) {
      _drawTooltip(canvas, chartRect, size, n);
    }
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = rect.top + (rect.height / gridLines) * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawYLabels(Canvas canvas, Rect rect) {
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final value = totalPoints * (1 - i / gridLines);
      final y = rect.top + (rect.height / gridLines) * i;
      final tp = TextPainter(
        text: TextSpan(
          text: value.toInt().toString(),
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left - tp.width - 6, y - tp.height / 2));
    }
  }

  void _drawXLabels(Canvas canvas, Rect rect, int n) {
    if (n < 2) return;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    // Show up to 6 evenly spaced date labels.
    final step = (n / 6).ceil().clamp(1, n);
    for (int i = 0; i < n; i += step) {
      final x = rect.left + (i / (n - 1)) * rect.width;
      final d = points[i].date;
      final label = '${months[d.month - 1]} ${d.day}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, rect.bottom + 6));
    }
  }

  Offset _pointAt(Rect rect, int n, int i, double value) {
    final x = rect.left + (i / (n - 1)) * rect.width;
    final y = rect.top + (1 - value / totalPoints) * rect.height;
    return Offset(x, y);
  }

  void _drawIdealArea(Canvas canvas, Rect rect, int n) {
    if (n < 2) return;
    final path = Path();
    path.moveTo(rect.left, rect.top);
    for (int i = 0; i < n; i++) {
      final p = _pointAt(rect, n, i, points[i].idealRemaining);
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = idealColor.withValues(alpha: 0.08),
    );
  }

  void _drawIdealLine(Canvas canvas, Rect rect, int n) {
    if (n < 2) return;
    final paint = Paint()
      ..color = idealColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < n; i++) {
      final p = _pointAt(rect, n, i, points[i].idealRemaining);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawActualLine(Canvas canvas, Rect rect, int n) {
    if (n < 2) return;
    final paint = Paint()
      ..color = actualColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < n; i++) {
      final p = _pointAt(rect, n, i, points[i].actualRemaining);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawMarkers(Canvas canvas, Rect rect, int n) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < n; i++) {
      final p = _pointAt(rect, n, i, points[i].actualRemaining);
      final isHovered = i == hoveredIndex;
      final radius = isHovered ? 5.0 : 3.5;
      fill.color = actualColor;
      stroke.color = isDark ? EdenColors.neutral[900]! : Colors.white;
      canvas.drawCircle(p, radius + 1.5, stroke);
      canvas.drawCircle(p, radius, fill);
    }
  }

  void _drawTooltip(Canvas canvas, Rect rect, Size size, int n) {
    final i = hoveredIndex!;
    if (i < 0 || i >= n) return;
    final pt = points[i];
    final p = _pointAt(rect, n, i, pt.actualRemaining);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final text = '${months[pt.date.month - 1]} ${pt.date.day}: '
        '${pt.actualRemaining.toInt()} remaining';

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
    var left = p.dx - boxW / 2;
    if (left < 0) left = 0;
    if (left + boxW > size.width) left = size.width - boxW;
    final top = p.dy - boxH - 10;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxW, boxH),
      const Radius.circular(EdenRadii.sm),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[900]!,
    );
    tp.paint(canvas, Offset(left + 6, top + 4));
  }

  @override
  bool shouldRepaint(covariant _BurndownPainter old) =>
      old.points != points ||
      old.hoveredIndex != hoveredIndex ||
      old.isDark != isDark;
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Shared data types
// ---------------------------------------------------------------------------

/// A single labeled data point used across chart types.
class EdenChartDataPoint {
  const EdenChartDataPoint({required this.label, required this.value});
  final String label;
  final double value;
}

/// A named series of data points with an optional color override.
class EdenChartSeries {
  const EdenChartSeries({
    required this.name,
    required this.data,
    this.color,
  });
  final String name;
  final List<EdenChartDataPoint> data;
  final Color? color;
}

/// Default chart color palette derived from Eden brand colors.
const List<Color> _kDefaultPalette = [
  EdenColors.blue,
  EdenColors.emerald,
  EdenColors.purple,
  EdenColors.gold,
  EdenColors.red,
  Color(0xFF06B6D4), // cyan
];

Color _seriesColor(int index, Color? override) =>
    override ?? _kDefaultPalette[index % _kDefaultPalette.length];

// ---------------------------------------------------------------------------
// EdenLineChart
// ---------------------------------------------------------------------------

/// A line chart rendered with [CustomPaint].
///
/// Supports multiple series, smooth curves, area fills, grid lines, axis
/// labels, dots, and a tooltip overlay on tap/hover.
class EdenLineChart extends StatefulWidget {
  const EdenLineChart({
    super.key,
    required this.series,
    this.height = 300,
    this.showGrid = true,
    this.showLabels = true,
    this.smooth = true,
    this.showArea = false,
    this.showDots = true,
    this.animate = true,
  });

  final List<EdenChartSeries> series;
  final double height;
  final bool showGrid;
  final bool showLabels;
  final bool smooth;
  final bool showArea;
  final bool showDots;
  final bool animate;

  @override
  State<EdenLineChart> createState() => _EdenLineChartState();
}

class _EdenLineChartState extends State<EdenLineChart>
    with SingleTickerProviderStateMixin {
  Offset? _pointer;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.animate) {
      _anim.forward();
    } else {
      _anim.value = 1;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelPad = widget.showLabels ? 40.0 : 0.0;

    return MouseRegion(
      onHover: (e) => setState(() => _pointer = e.localPosition),
      onExit: (_) => setState(() => _pointer = null),
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _pointer = d.localPosition),
        onPanEnd: (_) => setState(() => _pointer = null),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _LineChartPainter(
              series: widget.series,
              showGrid: widget.showGrid,
              showLabels: widget.showLabels,
              smooth: widget.smooth,
              showArea: widget.showArea,
              showDots: widget.showDots,
              pointer: _pointer,
              progress: _anim.value,
              gridColor: theme.colorScheme.outlineVariant,
              labelColor: theme.colorScheme.onSurfaceVariant,
              tooltipBg: theme.colorScheme.surfaceContainerHighest,
              tooltipFg: theme.colorScheme.onSurface,
              labelPad: labelPad,
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.series,
    required this.showGrid,
    required this.showLabels,
    required this.smooth,
    required this.showArea,
    required this.showDots,
    required this.pointer,
    required this.progress,
    required this.gridColor,
    required this.labelColor,
    required this.tooltipBg,
    required this.tooltipFg,
    required this.labelPad,
  });

  final List<EdenChartSeries> series;
  final bool showGrid, showLabels, smooth, showArea, showDots;
  final Offset? pointer;
  final double progress;
  final Color gridColor, labelColor, tooltipBg, tooltipFg;
  final double labelPad;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final allValues = series.expand((s) => s.data.map((d) => d.value));
    if (allValues.isEmpty) return;

    final minV = allValues.reduce(math.min);
    final maxV = allValues.reduce(math.max);
    final range = maxV == minV ? 1.0 : maxV - minV;

    final left = showLabels ? labelPad : 0.0;
    final bottom = showLabels ? 24.0 : 0.0;
    final chartW = size.width - left - EdenSpacing.space2;
    final chartH = size.height - bottom - EdenSpacing.space2;

    // Grid & Y labels
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.5;
      const gridLines = 5;
      for (var i = 0; i <= gridLines; i++) {
        final y = EdenSpacing.space1 + chartH * (1 - i / gridLines);
        canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
        if (showLabels) {
          final val = minV + range * (i / gridLines);
          _drawText(
            canvas,
            val.toStringAsFixed(0),
            Offset(0, y - 6),
            labelColor,
            10,
          );
        }
      }
    }

    // Series
    final maxLen = series.fold<int>(0, (m, s) => math.max(m, s.data.length));
    int? hoverIdx;
    if (pointer != null && maxLen > 1) {
      final step = chartW / (maxLen - 1);
      hoverIdx = ((pointer!.dx - left) / step).round().clamp(0, maxLen - 1);
    }

    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      final color = _seriesColor(si, s.color);
      if (s.data.length < 2) continue;

      final step = chartW / (s.data.length - 1);
      final points = <Offset>[];
      for (var i = 0; i < s.data.length; i++) {
        final t = (s.data[i].value - minV) / range;
        final x = left + i * step;
        final y = EdenSpacing.space1 + chartH * (1 - t * progress);
        points.add(Offset(x, y));
      }

      final path = _buildPath(points, smooth);

      // Area fill
      if (showArea) {
        final areaPath = Path.from(path)
          ..lineTo(points.last.dx, EdenSpacing.space1 + chartH)
          ..lineTo(points.first.dx, EdenSpacing.space1 + chartH)
          ..close();
        final gradient = ui.Gradient.linear(
          const Offset(0, EdenSpacing.space1),
          Offset(0, EdenSpacing.space1 + chartH),
          [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        );
        canvas.drawPath(
          areaPath,
          Paint()..shader = gradient,
        );
      }

      // Line
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      // Dots
      if (showDots) {
        for (final p in points) {
          canvas.drawCircle(p, 3, Paint()..color = color);
        }
      }
    }

    // X labels
    if (showLabels && series.isNotEmpty) {
      final labels = series.first.data;
      final step = maxLen > 1 ? chartW / (maxLen - 1) : 0.0;
      for (var i = 0; i < labels.length; i++) {
        _drawText(
          canvas,
          labels[i].label,
          Offset(left + i * step - 12, size.height - 16),
          labelColor,
          10,
        );
      }
    }

    // Tooltip
    if (hoverIdx != null) {
      final step = chartW / (maxLen - 1);
      final x = left + hoverIdx * step;
      canvas.drawLine(
        Offset(x, EdenSpacing.space1),
        Offset(x, EdenSpacing.space1 + chartH),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
      var ty = 12.0;
      for (var si = 0; si < series.length; si++) {
        final s = series[si];
        if (hoverIdx < s.data.length) {
          final dp = s.data[hoverIdx];
          final text = '${s.name}: ${dp.value.toStringAsFixed(1)}';
          _drawTooltip(canvas, text, Offset(x + 8, ty), tooltipBg, tooltipFg);
          ty += 20;
        }
      }
    }
  }

  Path _buildPath(List<Offset> pts, bool smooth) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (!smooth || pts.length < 3) {
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
    } else {
      for (var i = 1; i < pts.length; i++) {
        final p0 = pts[math.max(0, i - 2)];
        final p1 = pts[i - 1];
        final p2 = pts[i];
        final p3 = pts[math.min(pts.length - 1, i + 1)];
        final cp1 = Offset(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
        );
        final cp2 = Offset(
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
        );
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      }
    }
    return path;
  }

  void _drawTooltip(
    Canvas canvas,
    String text,
    Offset pos,
    Color bg,
    Color fg,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: fg, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx, pos.dy, tp.width + 8, tp.height + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = bg);
    tp.paint(canvas, Offset(pos.dx + 4, pos.dy + 2));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => true;
}

// ---------------------------------------------------------------------------
// EdenBarChart
// ---------------------------------------------------------------------------

/// A vertical (or horizontal) bar chart supporting grouped and stacked modes.
class EdenBarChart extends StatelessWidget {
  const EdenBarChart({
    super.key,
    required this.series,
    this.height = 300,
    this.showLabels = true,
    this.showValues = true,
    this.stacked = false,
    this.horizontal = false,
    this.barWidth = 20,
    this.barSpacing = 4,
  });

  final List<EdenChartSeries> series;
  final double height;
  final bool showLabels;
  final bool showValues;
  final bool stacked;
  final bool horizontal;
  final double barWidth;
  final double barSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _BarChartPainter(
        series: series,
        showLabels: showLabels,
        showValues: showValues,
        stacked: stacked,
        horizontal: horizontal,
        barWidth: barWidth,
        barSpacing: barSpacing,
        gridColor: theme.colorScheme.outlineVariant,
        labelColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.series,
    required this.showLabels,
    required this.showValues,
    required this.stacked,
    required this.horizontal,
    required this.barWidth,
    required this.barSpacing,
    required this.gridColor,
    required this.labelColor,
  });

  final List<EdenChartSeries> series;
  final bool showLabels, showValues, stacked, horizontal;
  final double barWidth, barSpacing;
  final Color gridColor, labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series.first.data.isEmpty) return;

    final catCount = series.first.data.length;
    final left = showLabels ? 40.0 : 0.0;
    final bottom = showLabels ? 24.0 : 0.0;
    final chartW = size.width - left - EdenSpacing.space2;
    final chartH = size.height - bottom - EdenSpacing.space2;

    // Compute max value
    double maxV = 0;
    if (stacked) {
      for (var ci = 0; ci < catCount; ci++) {
        double sum = 0;
        for (final s in series) {
          if (ci < s.data.length) sum += s.data[ci].value;
        }
        if (sum > maxV) maxV = sum;
      }
    } else {
      for (final s in series) {
        for (final d in s.data) {
          if (d.value > maxV) maxV = d.value;
        }
      }
    }
    if (maxV == 0) maxV = 1;

    // Grid
    const gridLines = 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i <= gridLines; i++) {
      final y = EdenSpacing.space1 + chartH * (1 - i / gridLines);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      if (showLabels) {
        final val = maxV * (i / gridLines);
        _drawText(
          canvas,
          val.toStringAsFixed(0),
          Offset(0, y - 6),
          labelColor,
          10,
        );
      }
    }

    final groupWidth = stacked
        ? barWidth
        : series.length * barWidth + (series.length - 1) * barSpacing;
    final catStep = chartW / catCount;

    for (var ci = 0; ci < catCount; ci++) {
      final catCenter = left + catStep * ci + catStep / 2;
      double stackY = EdenSpacing.space1 + chartH;

      for (var si = 0; si < series.length; si++) {
        final s = series[si];
        if (ci >= s.data.length) continue;
        final val = s.data[ci].value;
        final barH = (val / maxV) * chartH;
        final color = _seriesColor(si, s.color);

        double bx, by;
        if (stacked) {
          bx = catCenter - barWidth / 2;
          by = stackY - barH;
          stackY = by;
        } else {
          final groupStart = catCenter - groupWidth / 2;
          bx = groupStart + si * (barWidth + barSpacing);
          by = EdenSpacing.space1 + chartH - barH;
        }

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, barWidth, barH),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, Paint()..color = color);

        if (showValues && barH > 14) {
          _drawText(
            canvas,
            val.toStringAsFixed(0),
            Offset(bx + barWidth / 2 - 8, by + 2),
            Colors.white,
            9,
          );
        }
      }

      // X label
      if (showLabels) {
        final label = series.first.data[ci].label;
        _drawText(
          canvas,
          label,
          Offset(catCenter - 12, size.height - 16),
          labelColor,
          10,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => true;
}

// ---------------------------------------------------------------------------
// EdenPieChart
// ---------------------------------------------------------------------------

/// A pie/donut chart with legend and tap-to-highlight.
class EdenPieChart extends StatefulWidget {
  const EdenPieChart({
    super.key,
    required this.data,
    this.size = 200,
    this.donut = false,
    this.donutWidth = 40,
    this.centerLabel,
    this.showLabels = true,
    this.showLegend = true,
    this.colors,
  });

  final List<EdenChartDataPoint> data;
  final double size;
  final bool donut;
  final double donutWidth;
  final String? centerLabel;
  final bool showLabels;
  final bool showLegend;
  final List<Color>? colors;

  @override
  State<EdenPieChart> createState() => _EdenPieChartState();
}

class _EdenPieChartState extends State<EdenPieChart> {
  int? _highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = widget.colors ?? _kDefaultPalette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (details) => _hitTest(details.localPosition, palette),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _PieChartPainter(
                data: widget.data,
                donut: widget.donut,
                donutWidth: widget.donutWidth,
                centerLabel: widget.centerLabel,
                showLabels: widget.showLabels,
                colors: palette,
                highlighted: _highlighted,
                labelColor: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(width: EdenSpacing.space4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.data.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.data[i].label,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _hitTest(Offset pos, List<Color> palette) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final radius = widget.size / 2;

    if (widget.donut && dist < radius - widget.donutWidth) {
      setState(() => _highlighted = null);
      return;
    }
    if (dist > radius) {
      setState(() => _highlighted = null);
      return;
    }

    var angle = math.atan2(dy, dx) - (-math.pi / 2);
    if (angle < 0) angle += 2 * math.pi;

    final total = widget.data.fold(0.0, (s, d) => s + d.value);
    double cumulative = 0;
    for (var i = 0; i < widget.data.length; i++) {
      cumulative += widget.data[i].value;
      if (angle <= (cumulative / total) * 2 * math.pi) {
        setState(() => _highlighted = _highlighted == i ? null : i);
        return;
      }
    }
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.data,
    required this.donut,
    required this.donutWidth,
    required this.centerLabel,
    required this.showLabels,
    required this.colors,
    required this.highlighted,
    required this.labelColor,
  });

  final List<EdenChartDataPoint> data;
  final bool donut, showLabels;
  final double donutWidth;
  final String? centerLabel;
  final List<Color> colors;
  final int? highlighted;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final total = data.fold(0.0, (s, d) => s + d.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = (data[i].value / total) * 2 * math.pi;
      final isHl = highlighted == i;
      final paint = Paint()
        ..color = colors[i % colors.length]
            .withValues(alpha: isHl ? 1.0 : (highlighted != null ? 0.5 : 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweep, !donut, paint);

      // Segment label
      if (showLabels) {
        final midAngle = startAngle + sweep / 2;
        final labelR = radius * 0.65;
        final lx = center.dx + labelR * math.cos(midAngle);
        final ly = center.dy + labelR * math.sin(midAngle);
        final pct = (data[i].value / total * 100).toStringAsFixed(0);
        if (sweep > 0.3) {
          _drawText(canvas, '$pct%', Offset(lx - 10, ly - 6), Colors.white, 10,
              fontWeight: FontWeight.w600);
        }
      }

      startAngle += sweep;
    }

    // Donut hole
    if (donut) {
      canvas.drawCircle(
        center,
        radius - donutWidth,
        Paint()..color = Colors.transparent,
      );
      canvas.drawCircle(
        center,
        radius - donutWidth,
        Paint()
          ..color = Colors.black
          ..blendMode = BlendMode.dstOut,
      );
      // Draw the center over as the canvas background to "cut out" the donut.
      // Use saveLayer/restore to handle transparency properly.
    }

    // Center label
    if (donut && centerLabel != null) {
      _drawText(
        canvas,
        centerLabel!,
        Offset(center.dx - 16, center.dy - 7),
        labelColor,
        13,
        fontWeight: FontWeight.w700,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) =>
      old.highlighted != highlighted || old.data != data;
}

// ---------------------------------------------------------------------------
// EdenSparkline
// ---------------------------------------------------------------------------

/// A minimal inline line chart intended for stat cards and compact contexts.
class EdenSparkline extends StatelessWidget {
  const EdenSparkline({
    super.key,
    required this.values,
    this.height = 40,
    this.width,
    this.color,
    this.showArea = true,
    this.lineWidth = 2,
  });

  final List<double> values;
  final double height;
  final double? width;
  final Color? color;
  final bool showArea;
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return CustomPaint(
      size: Size(width ?? double.infinity, height),
      painter: _SparklinePainter(
        values: values,
        color: c,
        showArea: showArea,
        lineWidth: lineWidth,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.showArea,
    required this.lineWidth,
  });

  final List<double> values;
  final Color color;
  final bool showArea;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = maxV == minV ? 1.0 : maxV - minV;
    final step = size.width / (values.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final t = (values[i] - minV) / range;
      points.add(Offset(i * step, size.height * (1 - t)));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Area gradient
    if (showArea) {
      final areaPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      final gradient = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      );
      canvas.drawPath(areaPath, Paint()..shader = gradient);
    }

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

void _drawText(
  Canvas canvas,
  String text,
  Offset pos,
  Color color,
  double fontSize, {
  FontWeight fontWeight = FontWeight.normal,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, pos);
}

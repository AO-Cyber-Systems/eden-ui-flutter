// EdenInsightCard — renders rich AI insight content based on EdenInsightType.
//
// Supports 6 content types: summary, metric, alert, suggestion, chart, diagram.
// Uses CustomPainter for chart rendering — no external charting dependency.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'eden_ai_models.dart';

/// Renders a single AI insight as a styled card.
///
/// Content layout adapts based on [EdenInsightContent.type]:
///
/// | Type | Layout |
/// |---|---|
/// | summary | icon + title + subtitle |
/// | metric | large value + trend arrow + change pct |
/// | alert | severity-tinted left border + icon + message |
/// | suggestion | gold lightbulb icon + text + action buttons |
/// | chart | [CustomPainter] mock (bar/line/sparkline/pie) |
/// | diagram | placeholder with label |
///
/// Action buttons:
/// - When [EdenInsightAction.onTap] is non-null, fires the callback.
/// - When `onTap` is null, shows a "Coming soon — \$label" [SnackBar] (donor
///   parity — gives planners a UX path for not-yet-implemented features).
///
/// iPhone-narrow safety: tested at `SizedBox(width: 280)` (typical sidebar
/// width). Chart container is fixed-height (80) with `Size(infinity, height)`
/// painter — safe at any horizontal viewport ≥ ~150pt.
///
/// Donor: `trades-flutter/lib/shared/widgets/eden_insight_card.dart` (545 LOC;
/// rebound to library-owned [EdenInsightContent] types per cross-vertical
/// decoupling constraint).
class EdenInsightCard extends StatelessWidget {
  const EdenInsightCard({
    super.key,
    required this.content,
    this.compact = false,
  });

  final EdenInsightContent content;

  /// When true, renders a more compact version suitable for sidebars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {}, // hover highlight only
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: _buildContent(context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return switch (content.type) {
      EdenInsightType.summary => _SummaryContent(
          content: content, theme: theme, compact: compact),
      EdenInsightType.metric =>
        _MetricContent(content: content, theme: theme, compact: compact),
      EdenInsightType.alert =>
        _AlertContent(content: content, theme: theme, compact: compact),
      EdenInsightType.suggestion =>
        _SuggestionContent(content: content, theme: theme, compact: compact),
      EdenInsightType.chart => _ChartContent(content: content, theme: theme),
      EdenInsightType.diagram =>
        _DiagramContent(content: content, theme: theme),
    };
  }
}

// ── Summary ──

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.content,
    required this.theme,
    required this.compact,
  });
  final EdenInsightContent content;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.article_outlined,
            size: compact ? 16 : 18, color: theme.colorScheme.primary),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (content.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  content.subtitle!,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (content.actions.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ActionButtons(actions: content.actions, theme: theme),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Metric ──

class _MetricContent extends StatelessWidget {
  const _MetricContent({
    required this.content,
    required this.theme,
    required this.compact,
  });
  final EdenInsightContent content;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final trend = content.data['trend'] as String? ?? 'flat';
    final trendIcon = switch (trend) {
      'up' => Icons.trending_up,
      'down' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    final trendColor = switch (trend) {
      'up' => const Color(0xFF22C55E),
      'down' => const Color(0xFFEF4444),
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              content.data['value']?.toString() ?? '-',
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(trendIcon, size: 18, color: trendColor),
            if (content.data['change'] != null &&
                (content.data['change'] as String).isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                content.data['change'] as String,
                style: TextStyle(fontSize: 12, color: trendColor),
              ),
            ],
          ],
        ),
        if (content.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            content.subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Alert ──

class _AlertContent extends StatelessWidget {
  const _AlertContent({
    required this.content,
    required this.theme,
    required this.compact,
  });
  final EdenInsightContent content;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final severity = content.severity ?? EdenInsightSeverity.info;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: severity.color, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            severity == EdenInsightSeverity.critical
                ? Icons.error
                : Icons.warning_amber_rounded,
            size: compact ? 16 : 18,
            color: severity.color,
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (content.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    content.subtitle!,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (content.actions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _ActionButtons(actions: content.actions, theme: theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestion ──

class _SuggestionContent extends StatelessWidget {
  const _SuggestionContent({
    required this.content,
    required this.theme,
    required this.compact,
  });
  final EdenInsightContent content;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline,
            size: compact ? 16 : 18, color: const Color(0xFFF59E0B)),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (content.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  content.subtitle!,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (content.actions.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ActionButtons(actions: content.actions, theme: theme),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Chart (CustomPainter mock) ──

class _ChartContent extends StatelessWidget {
  const _ChartContent({required this.content, required this.theme});
  final EdenInsightContent content;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: CustomPaint(
            size: const Size(double.infinity, 80),
            painter: _MockChartPainter(
              chartType: content.chartType ?? EdenChartType.bar,
              values: _extractValues(),
              color: theme.colorScheme.primary,
              bgColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        if (content.data['labels'] != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (content.data['labels'] as List<dynamic>)
                .map((l) => Text(
                      l.toString(),
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  List<double> _extractValues() {
    final raw = content.data['values'];
    if (raw is List) {
      return raw.map((v) => (v as num).toDouble()).toList();
    }
    return <double>[30, 60, 45, 80, 55, 70, 40]; // fallback
  }
}

class _MockChartPainter extends CustomPainter {
  _MockChartPainter({
    required this.chartType,
    required this.values,
    required this.color,
    required this.bgColor,
  });

  final EdenChartType chartType;
  final List<double> values;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(math.max);
    if (maxVal == 0) return;

    switch (chartType) {
      case EdenChartType.bar:
        _paintBars(canvas, size, maxVal);
      case EdenChartType.line:
      case EdenChartType.sparkline:
        _paintLine(canvas, size, maxVal);
      case EdenChartType.pie:
        _paintPie(canvas, size);
    }
  }

  void _paintBars(Canvas canvas, Size size, double maxVal) {
    final barWidth = size.width / values.length * 0.7;
    final gap = size.width / values.length * 0.3;
    final paint = Paint()..color = color;
    final bgPaint = Paint()..color = bgColor;

    for (var i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap) + gap / 2;
      final barHeight = (values[i] / maxVal) * size.height;

      // Background bar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          const Radius.circular(3),
        ),
        bgPaint,
      );
      // Value bar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _paintLine(Canvas canvas, Size size, double maxVal) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (values[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _paintPie(Canvas canvas, Size size) {
    final total = values.fold(0.0, (s, v) => s + v);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    var startAngle = -math.pi / 2;
    final colors = [
      color,
      color.withValues(alpha: 0.7),
      color.withValues(alpha: 0.4),
      bgColor,
    ];

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MockChartPainter old) =>
      chartType != old.chartType || values != old.values;
}

// ── Diagram (placeholder) ──

class _DiagramContent extends StatelessWidget {
  const _DiagramContent({required this.content, required this.theme});
  final EdenInsightContent content;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              'Diagram preview',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Action buttons ──

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.actions, required this.theme});
  final List<EdenInsightAction> actions;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: actions.map((action) {
        return TextButton.icon(
          onPressed: action.onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coming soon — ${action.label}')),
                );
              },
          icon: action.icon != null
              ? Icon(action.icon, size: 14)
              : const SizedBox.shrink(),
          label: Text(action.label, style: const TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }).toList(),
    );
  }
}

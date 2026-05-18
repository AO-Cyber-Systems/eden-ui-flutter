import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_chart.dart';
import 'eden_currency_display.dart';
import 'eden_empty_state.dart';

// ───────────────────────────────────────────────────────────────────────────
// Value classes — sales analytics shell payload + sub-rows.
// ───────────────────────────────────────────────────────────────────────────

/// Top-level analytics payload. Consumer pre-computes and pre-formats all
/// values; widget renders verbatim. Generic across retail / salon / trades
/// / fuel / medical analytics dashboards.
@immutable
class EdenSalesAnalyticsData {
  const EdenSalesAnalyticsData({
    required this.kpis,
    required this.trendSeries,
    required this.topProducts,
    required this.topCategories,
    this.dateRangeLabel,
    this.currency = 'USD',
  });

  final List<EdenAnalyticsKpi> kpis;
  final List<EdenAnalyticsTrendPoint> trendSeries;
  final List<EdenAnalyticsTopProductRow> topProducts;
  final List<EdenAnalyticsCategorySlice> topCategories;
  final String? dateRangeLabel;
  final String currency;
}

@immutable
class EdenAnalyticsKpi {
  const EdenAnalyticsKpi({
    required this.label,
    required this.valueText,
    this.deltaPctSinceLastPeriod,
    this.icon,
  });

  final String label;

  /// Pre-formatted by consumer (e.g. `'$12,438'`, `'142 txns'`, `'4.2 min'`).
  final String valueText;

  /// `+0.12` = +12%, `-0.08` = -8%. `null` = no chip rendered.
  final double? deltaPctSinceLastPeriod;
  final IconData? icon;
}

@immutable
class EdenAnalyticsTrendPoint {
  const EdenAnalyticsTrendPoint({required this.label, required this.value});
  final String label;
  final double value;
}

@immutable
class EdenAnalyticsTopProductRow {
  const EdenAnalyticsTopProductRow({
    required this.rank,
    required this.name,
    required this.unitsSold,
    required this.revenueCents,
    this.trend,
  });

  final int rank;
  final String name;
  final int unitsSold;
  final int revenueCents;

  /// `'up'` / `'down'` / `'flat'` / null. String-based for portability across
  /// gen'd Dart types from protobuf.
  final String? trend;
}

@immutable
class EdenAnalyticsCategorySlice {
  const EdenAnalyticsCategorySlice({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}

enum EdenAnalyticsChartType { bar, line, sparkline }

// ───────────────────────────────────────────────────────────────────────────
// EdenSalesAnalyticsScaffold
// ───────────────────────────────────────────────────────────────────────────

/// Composite analytics shell for sales dashboards.
///
/// Sections, top-to-bottom:
/// 1. **Date range header** — consumer-injected via [dateRangeWidget] (or
///    default preset buttons). [onDateRangeChanged] fires whatever the
///    consumer's widget produces.
/// 2. **KPI strip** — Wrap of KPI cards. Each card: icon + label + valueText
///    + optional delta-percent chip (positive → green arrow_upward;
///    negative → red arrow_downward). Empty kpis → empty state.
/// 3. **Trend chart** — bar / line / sparkline via [trendChartType] enum.
///    Default `bar`.
/// 4. **Top products** — ranked rows with trend arrow per row.
/// 5. **Top categories** — private bar shim (LinearProgressIndicator per
///    slice). TODO swap to `EdenDonutChart` when widely adopted.
///
/// Responsive layout: `>= 1024pt` → 2-column (KPIs + trend left, products
/// + categories right); `< 1024pt` → single-column ListView. Composable
/// into other verticals — generic value class, no retail binding.
class EdenSalesAnalyticsScaffold extends StatelessWidget {
  const EdenSalesAnalyticsScaffold({
    super.key,
    required this.data,
    this.trendChartType,
    this.onDateRangeChanged,
    this.dateRangeWidget,
  });

  final EdenSalesAnalyticsData data;

  /// Defaults to [EdenAnalyticsChartType.bar].
  final EdenAnalyticsChartType? trendChartType;

  /// Fires when consumer's date-range widget changes selection. Generic
  /// `Object` so the widget doesn't assume any specific date-range type;
  /// consumer's widget emits whatever it wants.
  final ValueChanged<Object>? onDateRangeChanged;

  /// Consumer-injected date-range picker. When null, the widget renders
  /// a simple preset row.
  final Widget? dateRangeWidget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >=
            1024; // breakpoint: 1024 — analytics tablet-landscape floor
        final chartType = trendChartType ?? EdenAnalyticsChartType.bar;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(dateRangeWidget: dateRangeWidget),
            const SizedBox(height: 12),
            _KpiSection(data: data),
            const SizedBox(height: 16),
            _TrendSection(data: data, chartType: chartType),
          ],
        );
        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _TopProductsSection(data: data),
            const SizedBox(height: 16),
            _TopCategoriesSection(data: data),
          ],
        );
        if (isWide) {
          return Padding(
            key: const ValueKey('eden-analytics-wide-row'),
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: right),
              ],
            ),
          );
        }
        return ListView(
          key: const ValueKey('eden-analytics-narrow-list'),
          padding: const EdgeInsets.all(EdenSpacing.space3),
          children: [
            left,
            const SizedBox(height: 16),
            right,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.dateRangeWidget});
  final Widget? dateRangeWidget;

  @override
  Widget build(BuildContext context) {
    if (dateRangeWidget != null) return dateRangeWidget!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(onPressed: () {}, child: const Text('Today')),
        OutlinedButton(onPressed: () {}, child: const Text('7d')),
        OutlinedButton(onPressed: () {}, child: const Text('30d')),
        OutlinedButton(onPressed: () {}, child: const Text('Year')),
      ],
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.data});
  final EdenSalesAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    if (data.kpis.isEmpty) {
      return const SizedBox(
        height: 120,
        child: EdenEmptyState(title: 'No metrics for this range'),
      );
    }
    // TODO(obj-014->obj-012 swap): replace with EdenAggregateKpiStrip(...)
    // when its generic API is widely adopted across the codebase.
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final k in data.kpis) _KpiCard(kpi: k)],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final EdenAnalyticsKpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (kpi.icon != null) ...[
                    Icon(
                      kpi.icon,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      kpi.label,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                kpi.valueText,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (kpi.deltaPctSinceLastPeriod != null) ...[
                const SizedBox(height: 4),
                _DeltaChip(pct: kpi.deltaPctSinceLastPeriod!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final positive = pct >= 0;
    final bg = positive ? Colors.green.shade100 : Colors.red.shade100;
    final fg = positive ? Colors.green.shade800 : Colors.red.shade800;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        positive ? Icons.arrow_upward : Icons.arrow_downward,
        size: 14,
        color: fg,
      ),
      label: Text(
        '${(pct * 100).abs().toStringAsFixed(1)}%',
        style: TextStyle(color: fg),
      ),
      backgroundColor: bg,
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.data, required this.chartType});
  final EdenSalesAnalyticsData data;
  final EdenAnalyticsChartType chartType;

  @override
  Widget build(BuildContext context) {
    if (data.trendSeries.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EdenEmptyState(title: 'No trend data'),
      );
    }
    final points = data.trendSeries
        .map((p) => EdenChartDataPoint(label: p.label, value: p.value))
        .toList();
    final series = [EdenChartSeries(name: 'Sales', data: points)];
    switch (chartType) {
      case EdenAnalyticsChartType.bar:
        return SizedBox(
          height: 200,
          child: EdenBarChart(series: series, height: 200),
        );
      case EdenAnalyticsChartType.line:
        return SizedBox(
          height: 200,
          child: EdenLineChart(series: series, height: 200),
        );
      case EdenAnalyticsChartType.sparkline:
        return SizedBox(
          height: 80,
          child: EdenSparkline(
            values: data.trendSeries.map((p) => p.value).toList(),
          ),
        );
    }
  }
}

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection({required this.data});
  final EdenSalesAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.topProducts.isEmpty) {
      return const SizedBox(
        height: 120,
        child: EdenEmptyState(title: 'No top products'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Top products', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final row in data.topProducts)
          _TopProductRow(row: row, currency: data.currency),
      ],
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.row, required this.currency});
  final EdenAnalyticsTopProductRow row;
  final String currency;

  IconData _trendIcon() {
    switch (row.trend) {
      case 'up':
        return Icons.arrow_upward;
      case 'down':
        return Icons.arrow_downward;
      default:
        return Icons.horizontal_rule;
    }
  }

  Color? _trendColor(BuildContext context) {
    switch (row.trend) {
      case 'up':
        return Colors.green.shade700;
      case 'down':
        return Colors.red.shade700;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              row.rank.toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${row.unitsSold} sold',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          EdenCurrencyDisplay(
            cents: row.revenueCents,
            currencyCode: currency,
          ),
          const SizedBox(width: 8),
          Icon(_trendIcon(), size: 16, color: _trendColor(context)),
        ],
      ),
    );
  }
}

class _TopCategoriesSection extends StatelessWidget {
  const _TopCategoriesSection({required this.data});
  final EdenSalesAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.topCategories.isEmpty) {
      return const SizedBox(
        height: 120,
        child: EdenEmptyState(title: 'No categories'),
      );
    }
    // TODO(obj-014->obj-012 swap): replace with EdenDonutChart when
    // widely adopted.
    final maxVal =
        data.topCategories.map((c) => c.value).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Top categories', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final c in data.topCategories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    c.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxVal == 0 ? 0 : (c.value / maxVal).clamp(0.0, 1.0),
                    color: c.color ?? theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    c.value.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

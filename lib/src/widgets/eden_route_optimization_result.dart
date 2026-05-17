import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_accordion.dart';
import 'eden_aggregate_kpi_strip.dart';
import 'eden_card.dart';
import 'eden_empty_state.dart';
import 'eden_progress_ring.dart';
import 'eden_route_stop_list.dart';
import 'eden_status_badge.dart';

/// Top-line metrics for an optimization run.
@immutable
class EdenRouteOptimizationMetrics {
  const EdenRouteOptimizationMetrics({
    required this.totalStopsBefore,
    required this.totalStopsAfter,
    required this.totalMilesBefore,
    required this.totalMilesAfter,
    required this.totalTimeBefore,
    required this.totalTimeAfter,
    required this.capacityUtilizationAfter,
  });

  final int totalStopsBefore;
  final int totalStopsAfter;
  final double totalMilesBefore;
  final double totalMilesAfter;
  final Duration totalTimeBefore;
  final Duration totalTimeAfter;
  final double capacityUtilizationAfter;
}

/// Per-truck utilization snapshot for the bottom strip.
@immutable
class EdenRouteOptimizationTruckUtil {
  const EdenRouteOptimizationTruckUtil({
    required this.truckId,
    required this.truckLabel,
    required this.capacityGal,
    required this.scheduledGal,
  });

  final String truckId;
  final String truckLabel;
  final double capacityGal;
  final double scheduledGal;

  /// `scheduledGal / capacityGal` clamped to `[0, 1]`.
  double get utilizationPct {
    if (capacityGal <= 0) return 0.0;
    return (scheduledGal / capacityGal).clamp(0.0, 1.0);
  }

  bool get isOverCapacity => scheduledGal > capacityGal;
}

/// Optional driver-supplied notes section.
@immutable
class EdenRouteOptimizationDriverNotes {
  const EdenRouteOptimizationDriverNotes({
    required this.driverId,
    required this.driverName,
    required this.notes,
    this.submittedAt,
  });

  final String driverId;
  final String driverName;
  final List<String> notes;
  final DateTime? submittedAt;
}

/// Immutable container for the before/after optimization snapshot.
@immutable
class EdenRouteOptimizationData {
  const EdenRouteOptimizationData({
    required this.before,
    required this.after,
    required this.metrics,
    required this.truckUtilizations,
    this.infeasibleStopIds = const [],
    this.notes,
  });

  final List<EdenRouteStopData> before;
  final List<EdenRouteStopData> after;
  final EdenRouteOptimizationMetrics metrics;
  final List<EdenRouteOptimizationTruckUtil> truckUtilizations;
  final List<String> infeasibleStopIds;
  final String? notes;
}

/// Before/after route optimization visualization. Renders KPI strip + 2-column
/// stop diff + per-truck utilization rings + optional driver notes + accept/
/// reject action bar.
///
/// Composes obj 005-02 [EdenRouteStopList] (read-only), obj 012-02
/// [EdenAggregateKpiStrip], [EdenProgressRing], [EdenStatusBadge].
///
/// Generic: works for fuel multi-truck routes AND trades multi-stop tech day.
class EdenRouteOptimizationResult extends StatelessWidget {
  const EdenRouteOptimizationResult({
    super.key,
    required this.data,
    this.onAccept,
    this.onReject,
    this.onStopTap,
    this.driverNotes,
  });

  final EdenRouteOptimizationData data;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final ValueChanged<String>? onStopTap;
  final EdenRouteOptimizationDriverNotes? driverNotes;

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = data.before.isEmpty && data.after.isEmpty;
    if (isEmpty) {
      return const EdenEmptyState(
        title: 'No optimization results',
        description:
            'Run route optimization to see before/after comparisons here.',
      );
    }
    return LayoutBuilder(builder: (ctx, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final isTight = constraints.maxWidth < 500;
      return ListView(
        children: [
          // KPI strip (or stacked tiles at <500pt).
          if (isTight)
            _StackedKpiTiles(metrics: data.metrics)
          else
            SizedBox(
              height: 140,
              child: _buildKpiStrip(context),
            ),
          const SizedBox(height: EdenSpacing.space3),
          // Before/After 2-column body or stacked.
          if (isNarrow) ...[
            SizedBox(
              height: 320,
              child: _BeforePanel(data: data, onStopTap: onStopTap),
            ),
            const SizedBox(height: EdenSpacing.space3),
            SizedBox(
              height: 360,
              child: _AfterPanel(data: data, onStopTap: onStopTap),
            ),
          ] else
            SizedBox(
              height: 400,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BeforePanel(data: data, onStopTap: onStopTap),
                  ),
                  const SizedBox(width: EdenSpacing.space3),
                  Expanded(
                    child: _AfterPanel(data: data, onStopTap: onStopTap),
                  ),
                ],
              ),
            ),
          const SizedBox(height: EdenSpacing.space3),
          // Truck utilization (hidden when no trucks).
          if (data.truckUtilizations.isNotEmpty)
            _TruckUtilStrip(trucks: data.truckUtilizations),
          if (data.truckUtilizations.isNotEmpty)
            const SizedBox(height: EdenSpacing.space3),
          // Driver notes (optional).
          if (driverNotes != null) _DriverNotesCard(notes: driverNotes!),
          if (driverNotes != null) const SizedBox(height: EdenSpacing.space3),
          // Action bar (hidden when both callbacks null).
          if (onAccept != null || onReject != null)
            _ActionBar(onAccept: onAccept, onReject: onReject),
        ],
      );
    });
  }

  Widget _buildKpiStrip(BuildContext context) {
    final m = data.metrics;
    final stopsDelta = (m.totalStopsAfter - m.totalStopsBefore).toDouble();
    final milesDelta = m.totalMilesAfter - m.totalMilesBefore;
    final timeDeltaMin =
        (m.totalTimeAfter.inMinutes - m.totalTimeBefore.inMinutes).toDouble();
    return EdenAggregateKpiStrip(
      tiles: [
        EdenKpiTile(
          label: 'Stops',
          displayValue: '${m.totalStopsAfter}',
          secondaryLabel: 'was ${m.totalStopsBefore}',
          trend: stopsDelta,
          polarity: EdenKpiTrendPolarity.positiveIsGood,
        ),
        EdenKpiTile(
          label: 'Miles',
          displayValue: m.totalMilesAfter.toStringAsFixed(0),
          secondaryLabel: 'was ${m.totalMilesBefore.toStringAsFixed(0)}',
          trend: milesDelta,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
        EdenKpiTile(
          label: 'Time',
          displayValue: _formatDuration(m.totalTimeAfter),
          secondaryLabel: 'was ${_formatDuration(m.totalTimeBefore)}',
          trend: timeDeltaMin,
          polarity: EdenKpiTrendPolarity.negativeIsGood,
        ),
        EdenKpiTile(
          label: 'Capacity',
          displayValue:
              '${(m.capacityUtilizationAfter * 100).toStringAsFixed(0)}%',
          polarity: EdenKpiTrendPolarity.positiveIsGood,
        ),
      ],
    );
  }
}

class _StackedKpiTiles extends StatelessWidget {
  const _StackedKpiTiles({required this.metrics});

  final EdenRouteOptimizationMetrics metrics;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kpiRow(context, 'Stops', '${metrics.totalStopsAfter}',
            'was ${metrics.totalStopsBefore}'),
        _kpiRow(context, 'Miles', metrics.totalMilesAfter.toStringAsFixed(0),
            'was ${metrics.totalMilesBefore.toStringAsFixed(0)}'),
        _kpiRow(context, 'Time', _formatDuration(metrics.totalTimeAfter),
            'was ${_formatDuration(metrics.totalTimeBefore)}'),
        _kpiRow(
            context,
            'Capacity',
            '${(metrics.capacityUtilizationAfter * 100).toStringAsFixed(0)}%',
            ''),
      ],
    );
  }

  Widget _kpiRow(
      BuildContext context, String label, String value, String secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: EdenCard(
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (secondary.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(secondary,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BeforePanel extends StatelessWidget {
  const _BeforePanel({required this.data, this.onStopTap});

  final EdenRouteOptimizationData data;
  final ValueChanged<String>? onStopTap;

  @override
  Widget build(BuildContext context) {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Before',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: EdenSpacing.space2),
            Flexible(
              child: EdenRouteStopList(
                stops: data.before,
                reorderable: false,
                onStopTap: onStopTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AfterPanel extends StatelessWidget {
  const _AfterPanel({required this.data, this.onStopTap});

  final EdenRouteOptimizationData data;
  final ValueChanged<String>? onStopTap;

  @override
  Widget build(BuildContext context) {
    final infeasibleSet = data.infeasibleStopIds.toSet();
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('After',
                    style: Theme.of(context).textTheme.titleSmall),
                if (infeasibleSet.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Time window or capacity constraint violated for ${infeasibleSet.length} stop(s)',
                    child: const EdenStatusBadge(status: 'warning'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: EdenSpacing.space2),
            Flexible(
              child: EdenRouteStopList(
                stops: data.after,
                reorderable: false,
                onStopTap: onStopTap,
              ),
            ),
            if (infeasibleSet.isNotEmpty) ...[
              const SizedBox(height: EdenSpacing.space2),
              Text(
                'Infeasible: ${data.infeasibleStopIds.join(", ")}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EdenColors.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TruckUtilStrip extends StatelessWidget {
  const _TruckUtilStrip({required this.trucks});

  final List<EdenRouteOptimizationTruckUtil> trucks;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: trucks
              .map((t) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            EdenProgressRing(
                              value: t.utilizationPct,
                              label:
                                  '${(t.utilizationPct * 100).toStringAsFixed(0)}%',
                              sublabel:
                                  '${t.scheduledGal.toStringAsFixed(0)} / ${t.capacityGal.toStringAsFixed(0)} gal',
                              color: t.isOverCapacity
                                  ? EdenColors.warning
                                  : null,
                            ),
                            if (t.isOverCapacity)
                              const Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(Icons.warning_rounded,
                                    size: 16, color: EdenColors.warning),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 100,
                          child: Text(
                            t.truckLabel,
                            style: Theme.of(context).textTheme.labelSmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _DriverNotesCard extends StatelessWidget {
  const _DriverNotesCard({required this.notes});

  final EdenRouteOptimizationDriverNotes notes;

  @override
  Widget build(BuildContext context) {
    return EdenAccordion(
      items: [
        EdenAccordionItem(
          title: 'Driver notes from ${notes.driverName}',
          icon: Icons.notes,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final n in notes.notes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $n'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({this.onAccept, this.onReject});

  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onReject != null) ...[
            OutlinedButton(
              key: const Key('route-optimization-reject'),
              onPressed: onReject,
              child: const Text('Reject'),
            ),
            const SizedBox(width: 12),
          ],
          if (onAccept != null)
            ElevatedButton(
              key: const Key('route-optimization-accept'),
              onPressed: onAccept,
              child: const Text('Accept'),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
typedef _UnusedPaletteRef = EdenStatusPalette;

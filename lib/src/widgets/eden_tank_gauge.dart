import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_adaptive_layout.dart';

/// Rendering mode for [EdenTankGauge].
///
/// Linear is the most narrow-screen-friendly default. Segmented is a
/// 5-quarter discrete fill (popular in HVAC / oil control panels). Dial is a
/// 180° semicircle analog gauge.
enum EdenTankGaugeMode { linear, segmented, dial }

/// Generic value class for [EdenTankGauge]. Consumer maps domain rows
/// (`fuel_tanks`, `water_meters`, chemical-storage tanks, beverage stock, etc.)
/// to this class. The gauge knows nothing about fuel.
@immutable
class EdenTankGaugeData {
  const EdenTankGaugeData({
    required this.capacityGal,
    required this.currentGal,
    this.fuelTypeLabel,
    this.unitLabel = 'gal',
  });

  final double capacityGal;
  final double currentGal;

  /// Optional sub-caption above the gauge (e.g. 'Propane', 'Diesel').
  final String? fuelTypeLabel;

  /// Unit suffix for the capacity label ('gal' default; 'L' / 'm³' for metric
  /// consumers).
  final String unitLabel;

  /// Clamped fill ratio in `[0.0, 1.0]`. Defensive against zero/negative
  /// capacity and overfull (>1.0) inputs.
  double get fillRatio {
    if (capacityGal <= 0) return 0.0;
    final r = currentGal / capacityGal;
    if (r < 0) return 0.0;
    if (r > 1.0) return 1.0;
    return r;
  }

  /// True when `currentGal > capacityGal`. Renders an Overfull badge.
  bool get isOverfull => capacityGal > 0 && currentGal > capacityGal;
}

/// Vertical liquid-level meter primitive. Generic — used for fuel tanks, water
/// utilities, chemical storage, beverage stock, etc.
///
/// Three modes via [EdenTankGaugeMode]: `linear` (default vertical thermometer
/// fill), `segmented` (5 stacked quarter-segments), `dial` (180° analog
/// semicircle). When [mode] is null the widget consults
/// [EdenAdaptiveTierScope.maybeOf] — Compact tier always selects linear; any
/// other tier (or absence) also defaults to linear (lock-E rule-3 + narrow-
/// screen-friendly default). Explicit [mode] always overrides.
///
/// Color thresholds (configurable via [lowThresholdPct] / [warningThresholdPct]):
///   - fill ≤ low → red ([EdenColors.error])
///   - low < fill ≤ warning → amber ([EdenColors.warning])
///   - fill > warning → green ([EdenColors.success])
///
/// Low-threshold visual cue: when fill ≤ low, the linear container also
/// renders a 2pt red border (the "fill me up" signal). Overfull
/// (`currentGal > capacityGal`) renders an "Overfull" badge below the gauge
/// and clamps the fill display to 100%.
class EdenTankGauge extends StatelessWidget {
  const EdenTankGauge({
    super.key,
    required this.data,
    this.mode,
    this.lowThresholdPct = 0.20,
    this.warningThresholdPct = 0.50,
  });

  final EdenTankGaugeData data;

  /// Explicit mode override. When null, auto-selects via
  /// [EdenAdaptiveTierScope] (compact → linear; otherwise linear default).
  final EdenTankGaugeMode? mode;

  final double lowThresholdPct;
  final double warningThresholdPct;

  EdenTankGaugeMode _resolveMode(BuildContext context) {
    if (mode != null) return mode!;
    final tier = EdenAdaptiveTierScope.maybeOf(context);
    if (tier == EdenAdaptiveTier.compact) return EdenTankGaugeMode.linear;
    return EdenTankGaugeMode.linear;
  }

  Color _fillColor(double ratio) {
    if (ratio <= lowThresholdPct) return EdenColors.error;
    if (ratio <= warningThresholdPct) return EdenColors.warning;
    return EdenColors.success;
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = _resolveMode(context);
    final ratio = data.fillRatio;
    final isLow = ratio <= lowThresholdPct;
    final color = _fillColor(ratio);
    final label =
        '${_fmt(data.currentGal)}/${_fmt(data.capacityGal)} ${data.unitLabel}';

    final Widget body = switch (resolved) {
      EdenTankGaugeMode.linear =>
        _LinearBody(ratio: ratio, color: color, isLow: isLow),
      EdenTankGaugeMode.segmented => _SegmentedBody(ratio: ratio, color: color),
      EdenTankGaugeMode.dial => _DialBody(ratio: ratio, color: color),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.fuelTypeLabel != null) ...[
          Text(
            data.fuelTypeLabel!,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: EdenSpacing.space1),
        ],
        body,
        const SizedBox(height: EdenSpacing.space1),
        Text(
          label,
          style: theme.textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (data.isOverfull)
          Padding(
            padding: const EdgeInsets.only(top: EdenSpacing.space1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: EdenColors.warning,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Overfull',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LinearBody extends StatelessWidget {
  const _LinearBody({
    required this.ratio,
    required this.color,
    required this.isLow,
  });

  final double ratio;
  final Color color;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusSm,
        border: Border.all(
          color:
              isLow ? EdenColors.error : Theme.of(context).colorScheme.outlineVariant,
          width: isLow ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: EdenRadii.borderRadiusSm,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            FractionallySizedBox(
              widthFactor: 1.0,
              heightFactor: ratio,
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedBody extends StatelessWidget {
  const _SegmentedBody({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Task 2 will flesh this out fully. Placeholder for Task 1.
    return const SizedBox(width: 80, height: 160);
  }
}

class _DialBody extends StatelessWidget {
  const _DialBody({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Task 2 will flesh this out fully. Placeholder for Task 1.
    return const SizedBox(width: 180, height: 100);
  }
}

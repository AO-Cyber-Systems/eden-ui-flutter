import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Kinds of vital signs supported by [EdenVitalsRow] / [EdenVitalSign].
///
/// FHIR-shape (NOT FHIR-bound) — these align with FHIR `Observation.code`
/// LOINC code categories but are library-owned (no `fhir_dart` dep).
enum EdenVitalKind {
  bloodPressure,
  heartRate,
  temperature,
  spo2,
  respiratoryRate,
  weight,
  bmi,
}

/// FHIR-shape vital-sign value class — library-owned (NOT FHIR-bound).
///
/// Consumer apps map their Epic / Cerner / athenahealth FHIR R4
/// `Observation` resources → [EdenVitalSign] at the integration boundary.
/// The widget knows nothing about Epic or Cerner.
///
/// **HIPAA isolation:** every vital carries a `patientId` (opaque string;
/// library doesn't decode). [EdenVitalsRow] asserts at construction time
/// that all vitals in its list share the same patientId; mismatches throw
/// `AssertionError` in debug. In release builds the widget defensively
/// filters non-matching vitals.
@immutable
class EdenVitalSign {
  const EdenVitalSign({
    required this.patientId,
    required this.kind,
    required this.unit,
    this.value,
    this.systolic,
    this.diastolic,
    this.priorValue,
    this.referenceMin,
    this.referenceMax,
    this.criticalMin,
    this.criticalMax,
    this.recordedAt,
  });

  /// HIPAA isolation key. Opaque to the library.
  final String patientId;

  /// The kind of vital sign (BP / HR / Temp / SpO2 / RR / Weight / BMI).
  final EdenVitalKind kind;

  /// Display unit ('mmHg' | 'bpm' | '°F' | '%' | 'breaths/min' | 'kg' | 'kg/m²').
  final String unit;

  /// Single numeric value. Null for [EdenVitalKind.bloodPressure] — use
  /// [systolic] / [diastolic] instead.
  final double? value;

  /// Systolic BP component (BP only).
  final double? systolic;

  /// Diastolic BP component (BP only).
  final double? diastolic;

  /// Prior reading for trend-arrow computation (BP uses [systolic] vs prior).
  final double? priorValue;

  /// Reference-range minimum (warning when value below).
  final double? referenceMin;

  /// Reference-range maximum (warning when value above).
  final double? referenceMax;

  /// Critical-low threshold (danger when value <= critical).
  final double? criticalMin;

  /// Critical-high threshold (danger when value >= critical).
  final double? criticalMax;

  /// When this reading was recorded; rendered as 'as of …' when
  /// [EdenVitalsRow.showTimestamps] is true.
  final DateTime? recordedAt;
}

/// Severity tier used by [EdenVitalsRow] internal coloring logic.
enum _Severity { neutral, success, warning, danger }

/// Clinical-density vital signs strip for medical Patient Chart screens.
///
/// Renders one tile per [EdenVitalSign] with numeric value (monospace),
/// unit, label, optional trend arrow, and reference-range tint via
/// [EdenStatusPalette]. Horizontal-scroll when tile widths exceed parent
/// width (iPhone-narrow ≥390pt baseline fits 4 tiles before scroll).
///
/// Per locked decision (objective 013 OBJECTIVE.md): library is
/// FHIR-shape, NOT FHIR-bound. Consumer maps backend models to
/// [EdenVitalSign] at the integration boundary.
class EdenVitalsRow extends StatelessWidget {
  EdenVitalsRow({
    super.key,
    required this.vitals,
    this.patientId,
    this.showTimestamps = false,
    this.padding,
  }) : assert(
          vitals.isEmpty ||
              vitals.every(
                (v) => v.patientId == (patientId ?? vitals.first.patientId),
              ),
          'EdenVitalsRow: vitals must share same patientId; received mixed PHI. '
          'Library widgets enforce HIPAA isolation: a single widget instance '
          'must only render PHI for one patientId.',
        );

  /// Vitals to render (0..N tiles, displayed in given order).
  final List<EdenVitalSign> vitals;

  /// Optional explicit isolation key. If null, resolves to
  /// `vitals.first.patientId`.
  final String? patientId;

  /// When true, each tile renders a tiny "as of {relative time}" caption
  /// underneath the trend arrow.
  final bool showTimestamps;

  /// Padding around the scrollable row.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox.shrink();

    // Defensive release-mode filter: in case asserts are disabled and the
    // caller passed mixed-patient data, only render vitals matching the
    // resolved patientId.
    final resolvedPatientId = patientId ?? vitals.first.patientId;
    final filtered = vitals
        .where((v) => v.patientId == resolvedPatientId)
        .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < filtered.length; i++) ...[
            if (i > 0) const SizedBox(width: EdenSpacing.space2),
            _VitalsTile(
              vital: filtered[i],
              showTimestamp: showTimestamps,
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalsTile extends StatelessWidget {
  const _VitalsTile({required this.vital, required this.showTimestamp});

  final EdenVitalSign vital;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    final severity = _severityFor(vital);
    final (bg, fg, border) = _tokensFor(severity, palette);

    final label = _labelFor(vital.kind);
    final valueText = _valueTextFor(vital);
    final trend = _trendArrowFor(vital);

    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(EdenRadii.sm),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (10pt)
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          // Value (22pt monospace)
          Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: EdenTypography.monoFont.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unit (10pt) — flexible so trend arrow can claim space.
              Flexible(
                child: Text(
                  vital.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.1,
                  ),
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 4),
                Icon(trend, size: 12, color: fg),
              ],
            ],
          ),
          if (showTimestamp && vital.recordedAt != null) ...[
            const SizedBox(height: 1),
            Text(
              'as of ${_formatRelative(vital.recordedAt!)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── helpers ────────────────────────────

String _labelFor(EdenVitalKind k) {
  switch (k) {
    case EdenVitalKind.bloodPressure:
      return 'BP';
    case EdenVitalKind.heartRate:
      return 'HR';
    case EdenVitalKind.temperature:
      return 'Temp';
    case EdenVitalKind.spo2:
      return 'SpO2';
    case EdenVitalKind.respiratoryRate:
      return 'RR';
    case EdenVitalKind.weight:
      return 'Weight';
    case EdenVitalKind.bmi:
      return 'BMI';
  }
}

String _valueTextFor(EdenVitalSign v) {
  if (v.kind == EdenVitalKind.bloodPressure) {
    if (v.systolic == null || v.diastolic == null) return '—';
    return '${_fmtNum(v.systolic!)}/${_fmtNum(v.diastolic!)}';
  }
  if (v.value == null) return '—';
  return _fmtNum(v.value!);
}

/// Format integer-valued doubles without ".0"; keep one decimal place
/// otherwise (Temp 98.6, SpO2 92.5 → '92.5').
String _fmtNum(double v) {
  if (v == v.truncateToDouble()) {
    return v.toInt().toString();
  }
  return v.toStringAsFixed(1);
}

_Severity _severityFor(EdenVitalSign v) {
  // No reading → neutral.
  if (v.kind == EdenVitalKind.bloodPressure) {
    if (v.systolic == null || v.diastolic == null) return _Severity.neutral;
    // Encoded JNC-8 defaults; consumer overrides via criticalMin/Max if set.
    final criticalMaxBP = v.criticalMax ?? 180;
    final criticalMinBP = v.criticalMin ?? 60;
    final refMaxBP = v.referenceMax ?? 140;
    final refMinBP = v.referenceMin ?? 90;
    if (v.systolic! >= criticalMaxBP ||
        v.diastolic! >= 120 ||
        v.systolic! < criticalMinBP ||
        v.diastolic! < 60) {
      return _Severity.danger;
    }
    if (v.systolic! > refMaxBP || v.diastolic! > 90) {
      return _Severity.warning;
    }
    if (v.systolic! < refMinBP) return _Severity.warning;
    return _Severity.success;
  }

  if (v.value == null) return _Severity.neutral;
  if (v.referenceMin == null && v.referenceMax == null) {
    return _Severity.neutral;
  }
  if (v.criticalMin != null && v.value! <= v.criticalMin!) {
    return _Severity.danger;
  }
  if (v.criticalMax != null && v.value! >= v.criticalMax!) {
    return _Severity.danger;
  }
  if (v.referenceMin != null && v.value! < v.referenceMin!) {
    return _Severity.warning;
  }
  if (v.referenceMax != null && v.value! > v.referenceMax!) {
    return _Severity.warning;
  }
  return _Severity.success;
}

(Color bg, Color fg, Color border) _tokensFor(
  _Severity s,
  EdenStatusPalette palette,
) {
  switch (s) {
    case _Severity.success:
      return (palette.successBg, palette.successFg, palette.successBorder);
    case _Severity.warning:
      return (palette.warningBg, palette.warningFg, palette.warningBorder);
    case _Severity.danger:
      return (palette.dangerBg, palette.dangerFg, palette.dangerBorder);
    case _Severity.neutral:
      return (palette.neutralBg, palette.neutralFg, palette.neutralBorder);
  }
}

IconData? _trendArrowFor(EdenVitalSign v) {
  if (v.priorValue == null) return null;
  final current = v.kind == EdenVitalKind.bloodPressure ? v.systolic : v.value;
  if (current == null) return null;
  final prior = v.priorValue!;
  // ±5% threshold for flat.
  if (current > prior * 1.05) return Icons.arrow_upward;
  if (current < prior * 0.95) return Icons.arrow_downward;
  return Icons.remove;
}

String _formatRelative(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 48) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

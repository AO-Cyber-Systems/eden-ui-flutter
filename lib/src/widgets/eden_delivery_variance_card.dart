import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_input.dart';
import 'eden_select.dart';
import 'eden_stat_card.dart';

/// Metric being reconciled in [EdenDeliveryVarianceCard]. Generic enough for
/// fuel-gallons (UC-E2 canonical), trades labor-hours, medical visit
/// duration, or any planned-vs-actual scalar.
enum EdenVarianceMetric { gallons, hours, minutes, fee, custom }

/// Why the actual deviates from the scheduled value.
enum EdenDeliveryVarianceReason {
  tankCapEarly,
  customerCanceled,
  telemetryStale,
  meterReadError,
  accessBlocked,
  weatherDelay,
  customerDispute,
  other,
}

/// Disposition state for a delivery variance review.
enum EdenDeliveryVarianceDisposition {
  unreviewed,
  driverFlagged,
  officeReviewed,
  accepted,
  disputed,
}

/// Severity classification used internally by the threshold band.
enum EdenVarianceSeverity { withinThreshold, borderline, exceedsThreshold }

/// Immutable container describing the variance being reviewed.
@immutable
class EdenDeliveryVarianceData {
  const EdenDeliveryVarianceData({
    required this.scheduled,
    required this.actual,
    required this.metric,
    this.thresholdPct = 0.10,
    this.unitLabel,
    this.deliveryAt,
    this.deliveryId,
  });

  final double scheduled;
  final double actual;
  final EdenVarianceMetric metric;
  final double thresholdPct;

  /// Required when [metric] is [EdenVarianceMetric.custom].
  final String? unitLabel;

  final DateTime? deliveryAt;
  final String? deliveryId;
}

/// Emit-only draft captured by [EdenDeliveryVarianceCard.onSubmit].
@immutable
class EdenDeliveryVarianceDraft {
  const EdenDeliveryVarianceDraft({
    required this.data,
    this.reason,
    this.reasonNote,
    this.photoUrls = const [],
    this.disposition = EdenDeliveryVarianceDisposition.unreviewed,
  });

  final EdenDeliveryVarianceData data;
  final EdenDeliveryVarianceReason? reason;
  final String? reasonNote;
  final List<String> photoUrls;
  final EdenDeliveryVarianceDisposition disposition;
}

/// Variance computation — `(actual - scheduled) / scheduled`. Returns `0`
/// for `scheduled == 0` (no divide-by-zero).
double computeVariancePct(double scheduled, double actual) {
  if (scheduled == 0) return 0;
  return (actual - scheduled) / scheduled;
}

/// Classify a signed variance fraction against a threshold.
///
/// * `|v| <= threshold` → within threshold (inclusive).
/// * `|v| <= 2 * threshold` → borderline.
/// * Otherwise → exceeds.
EdenVarianceSeverity classifyVariance(double variancePct, double thresholdPct) {
  final mag = variancePct.abs();
  if (mag <= thresholdPct) return EdenVarianceSeverity.withinThreshold;
  if (mag <= thresholdPct * 2) return EdenVarianceSeverity.borderline;
  return EdenVarianceSeverity.exceedsThreshold;
}

/// Per-delivery variance reconciliation card. Generic across fuel gallons /
/// trades labor hours / medical visit duration / any planned-vs-actual scalar.
class EdenDeliveryVarianceCard extends StatefulWidget {
  const EdenDeliveryVarianceCard({
    super.key,
    required this.data,
    required this.onSubmit,
    this.onCancel,
    this.onPickPhoto,
    this.readOnly = false,
    this.initialDraft,
  });

  final EdenDeliveryVarianceData data;
  final ValueChanged<EdenDeliveryVarianceDraft> onSubmit;
  final VoidCallback? onCancel;
  final Future<String> Function(BuildContext)? onPickPhoto;
  final bool readOnly;
  final EdenDeliveryVarianceDraft? initialDraft;

  @override
  State<EdenDeliveryVarianceCard> createState() =>
      _EdenDeliveryVarianceCardState();
}

class _EdenDeliveryVarianceCardState extends State<EdenDeliveryVarianceCard> {
  EdenDeliveryVarianceReason? _reason;
  late EdenDeliveryVarianceDisposition _disposition;
  late List<String> _photoUrls;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.initialDraft;
    _reason = init?.reason;
    _disposition = init?.disposition ?? EdenDeliveryVarianceDisposition.unreviewed;
    _photoUrls = List<String>.from(init?.photoUrls ?? const []);
    _noteCtrl = TextEditingController(text: init?.reasonNote ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  EdenDeliveryVarianceDraft _buildDraft() => EdenDeliveryVarianceDraft(
        data: widget.data,
        reason: _reason,
        reasonNote: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        photoUrls: List<String>.unmodifiable(_photoUrls),
        disposition: _disposition,
      );

  bool _canSubmit() {
    final v = computeVariancePct(widget.data.scheduled, widget.data.actual);
    final severity = classifyVariance(v, widget.data.thresholdPct);
    if (severity == EdenVarianceSeverity.withinThreshold) return true;
    return _reason != null;
  }

  String _unitLabel() {
    switch (widget.data.metric) {
      case EdenVarianceMetric.gallons:
        return 'gal';
      case EdenVarianceMetric.hours:
        return 'hr';
      case EdenVarianceMetric.minutes:
        return 'min';
      case EdenVarianceMetric.fee:
        return '\$';
      case EdenVarianceMetric.custom:
        return widget.data.unitLabel ?? '?';
    }
  }

  String _formatValue(double v) {
    if (widget.data.metric == EdenVarianceMetric.fee) {
      return '\$${v.toStringAsFixed(2)}';
    }
    return '${v.toStringAsFixed(widget.data.metric == EdenVarianceMetric.gallons ? 1 : 2)} ${_unitLabel()}';
  }

  static String _reasonLabel(EdenDeliveryVarianceReason r) {
    switch (r) {
      case EdenDeliveryVarianceReason.tankCapEarly:
        return 'Tank capacity reached early';
      case EdenDeliveryVarianceReason.customerCanceled:
        return 'Customer canceled';
      case EdenDeliveryVarianceReason.telemetryStale:
        return 'Telemetry stale / inaccurate';
      case EdenDeliveryVarianceReason.meterReadError:
        return 'Meter read error';
      case EdenDeliveryVarianceReason.accessBlocked:
        return 'Site access blocked';
      case EdenDeliveryVarianceReason.weatherDelay:
        return 'Weather delay';
      case EdenDeliveryVarianceReason.customerDispute:
        return 'Customer dispute';
      case EdenDeliveryVarianceReason.other:
        return 'Other';
    }
  }

  static String _dispositionLabel(EdenDeliveryVarianceDisposition d) {
    switch (d) {
      case EdenDeliveryVarianceDisposition.unreviewed:
        return 'Unreviewed';
      case EdenDeliveryVarianceDisposition.driverFlagged:
        return 'Driver flagged';
      case EdenDeliveryVarianceDisposition.officeReviewed:
        return 'Office reviewed';
      case EdenDeliveryVarianceDisposition.accepted:
        return 'Accepted';
      case EdenDeliveryVarianceDisposition.disputed:
        return 'Disputed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    final variancePct =
        computeVariancePct(widget.data.scheduled, widget.data.actual);
    final severity = classifyVariance(variancePct, widget.data.thresholdPct);
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section 1 — variance summary
            _buildSummary(context, variancePct, severity, palette),
            const SizedBox(height: EdenSpacing.space4),
            // Section 2 — reason + notes + photos (hidden when readOnly)
            if (!widget.readOnly) ...[
              _buildReasonSection(context),
              const SizedBox(height: EdenSpacing.space4),
              if (widget.onPickPhoto != null) ...[
                _buildPhotoSection(context),
                const SizedBox(height: EdenSpacing.space4),
              ],
            ],
            // Section 3 — disposition + submit (or pill when readOnly)
            _buildDispositionSection(context, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, double variancePct,
      EdenVarianceSeverity severity, EdenStatusPalette? palette) {
    final color = _severityColor(severity, palette);
    final signedPct = '${variancePct >= 0 ? '+' : ''}${(variancePct * 100).toStringAsFixed(1)}%';
    return LayoutBuilder(builder: (ctx, c) {
      final stack = c.maxWidth < 500;
      final scheduledCard = EdenStatCard(
        label: 'Scheduled',
        value: _formatValue(widget.data.scheduled),
      );
      final actualCard = EdenStatCard(
        label: 'Actual',
        value: _formatValue(widget.data.actual),
        variant: color,
      );
      final header = stack
          ? Column(
              children: [
                scheduledCard,
                const SizedBox(height: 8),
                actualCard,
              ],
            )
          : Row(
              children: [
                Expanded(child: scheduledCard),
                const SizedBox(width: 16),
                Expanded(child: actualCard),
              ],
            );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: EdenSpacing.space3),
          Container(
            key: const Key('variance-band-color'),
            padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3, vertical: EdenSpacing.space2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(_severityIcon(severity), color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Variance: $signedPct',
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '±${(widget.data.thresholdPct * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _ThresholdBand(
            variancePct: variancePct,
            thresholdPct: widget.data.thresholdPct,
            palette: palette,
          ),
        ],
      );
    });
  }

  Widget _buildReasonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Reason', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        EdenSelect<EdenDeliveryVarianceReason?>(
          value: _reason,
          options: [
            const EdenSelectOption<EdenDeliveryVarianceReason?>(
                value: null, label: 'Select reason...'),
            for (final r in EdenDeliveryVarianceReason.values)
              EdenSelectOption(value: r, label: _reasonLabel(r)),
          ],
          onChanged: (v) => setState(() => _reason = v),
        ),
        if (_reason != null) ...[
          const SizedBox(height: 8),
          EdenInput(
            controller: _noteCtrl,
            label: 'Reason note (optional)',
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        if (_photoUrls.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _photoUrls
                .map((u) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: EdenColors.neutral[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.photo, size: 28),
                    ))
                .toList(),
          ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('variance-add-photo'),
            onPressed: () async {
              final url = await widget.onPickPhoto!(context);
              setState(() => _photoUrls.add(url));
            },
            icon: const Icon(Icons.add_a_photo, size: 16),
            label: const Text('Add Photo'),
          ),
        ),
      ],
    );
  }

  Widget _buildDispositionSection(
      BuildContext context, EdenStatusPalette? palette) {
    if (widget.readOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (palette?.infoBg ??
              EdenColors.info.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Disposition: ${_dispositionLabel(_disposition)}',
          style: TextStyle(color: palette?.infoFg ?? EdenColors.info),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Disposition', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        EdenSelect<EdenDeliveryVarianceDisposition>(
          value: _disposition,
          options: [
            for (final d in EdenDeliveryVarianceDisposition.values)
              EdenSelectOption(value: d, label: _dispositionLabel(d)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _disposition = v);
          },
        ),
        const SizedBox(height: EdenSpacing.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onCancel != null) ...[
              OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
            ],
            ElevatedButton(
              key: const Key('variance-submit'),
              onPressed: _canSubmit() ? () => widget.onSubmit(_buildDraft()) : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }

  static Color _severityColor(
      EdenVarianceSeverity s, EdenStatusPalette? palette) {
    switch (s) {
      case EdenVarianceSeverity.withinThreshold:
        return palette?.successFg ?? EdenColors.success;
      case EdenVarianceSeverity.borderline:
        return palette?.warningFg ?? EdenColors.warning;
      case EdenVarianceSeverity.exceedsThreshold:
        return palette?.dangerFg ?? EdenColors.error;
    }
  }

  static IconData _severityIcon(EdenVarianceSeverity s) {
    switch (s) {
      case EdenVarianceSeverity.withinThreshold:
        return Icons.check_circle_outline;
      case EdenVarianceSeverity.borderline:
        return Icons.warning_amber;
      case EdenVarianceSeverity.exceedsThreshold:
        return Icons.error_outline;
    }
  }
}

class _ThresholdBand extends StatelessWidget {
  const _ThresholdBand({
    required this.variancePct,
    required this.thresholdPct,
    required this.palette,
  });

  final double variancePct;
  final double thresholdPct;
  final EdenStatusPalette? palette;

  @override
  Widget build(BuildContext context) {
    final greenColor = (palette?.successBg ??
            EdenColors.success.withValues(alpha: 0.18));
    final amberColor = (palette?.warningBg ??
            EdenColors.warning.withValues(alpha: 0.18));
    final redColor =
        (palette?.dangerBg ?? EdenColors.error.withValues(alpha: 0.18));
    return SizedBox(
      height: 12,
      child: LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        // Scale axis: ±50% maps to full width.
        const axisLimit = 0.50;
        final greenWidth = (thresholdPct / axisLimit) * w;
        final amberWidth = (thresholdPct / axisLimit) * w;
        final markerOffset =
            ((variancePct.clamp(-axisLimit, axisLimit) + axisLimit) /
                    (2 * axisLimit)) *
                w;
        return Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(child: Container(color: redColor)),
                ],
              ),
            ),
            Positioned(
              left: (w / 2) - amberWidth,
              right: (w / 2) - amberWidth,
              top: 0,
              bottom: 0,
              child: Container(color: amberColor),
            ),
            Positioned(
              left: (w / 2) - greenWidth / 2,
              top: 0,
              bottom: 0,
              child: Container(width: greenWidth, color: greenColor),
            ),
            Positioned(
              left: markerOffset - 1,
              top: -2,
              bottom: -2,
              child: Container(width: 2, color: EdenColors.neutral[800]),
            ),
          ],
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_badge.dart';

/// FHIR-shape medication status (library-owned).
enum EdenMedicationStatus { active, paused, discontinued, completed }

/// FHIR-shape medication route (library-owned).
enum EdenMedicationRoute {
  oral,
  injection,
  topical,
  inhaled,
  nasal,
  ophthalmic,
  otic,
  rectal,
  vaginal,
  sublingual,
  transdermal,
  other,
}

/// FHIR-shape medication value class (library-owned — NOT FHIR-bound).
///
/// Maps to FHIR `MedicationStatement` resource shape, but library-owned:
/// no `fhir_dart` dep. Consumer maps backend models (Epic / Cerner /
/// athenahealth FHIR R4) → [EdenMedicationStatement] at the integration
/// boundary.
@immutable
class EdenMedicationStatement {
  const EdenMedicationStatement({
    required this.id,
    required this.patientId,
    required this.drugName,
    required this.doseLabel,
    required this.route,
    required this.frequency,
    this.prescriber,
    this.startDate,
    this.endDate,
    this.status = EdenMedicationStatus.active,
    this.interactionWarning,
    this.needsRefill = false,
    this.refillsRemaining,
    this.notes,
  });

  /// Stable id (typically backend medication-record id).
  final String id;

  /// HIPAA isolation key. Opaque to the library.
  final String patientId;

  /// Display drug name (e.g. 'Metformin').
  final String drugName;

  /// Free-form dose label ('500mg', '5 units', '2 puffs').
  final String doseLabel;

  /// Administration route.
  final EdenMedicationRoute route;

  /// Free-form frequency description ('Twice daily', 'q8h', 'PRN').
  final String frequency;

  /// Prescribing clinician (display name).
  final String? prescriber;

  /// Start date for the medication.
  final DateTime? startDate;

  /// End date (when present — typically only on discontinued/completed).
  final DateTime? endDate;

  /// Lifecycle status.
  final EdenMedicationStatus status;

  /// Free-form interaction warning. Non-null triggers an inline IXN badge.
  final String? interactionWarning;

  /// True → render 'Refill needed' / 'No refills left' badge.
  final bool needsRefill;

  /// When non-null and == 0, badge label switches to 'No refills left'.
  final int? refillsRemaining;

  /// Free-form clinician notes (not rendered by default).
  final String? notes;
}

/// FHIR-shape medication list display widget for medical Patient Chart
/// left rail.
///
/// HIPAA isolation: asserts at construction time that all medications
/// share the same patientId; mismatches throw `AssertionError` in debug.
class EdenMedicationList extends StatelessWidget {
  EdenMedicationList({
    super.key,
    required this.medications,
    this.patientId,
    this.showInactive = false,
    this.onMedicationTap,
    this.onDiscontinueTap,
    this.onRefillTap,
    this.padding,
  }) : assert(
          medications.isEmpty ||
              medications.every(
                (m) =>
                    m.patientId == (patientId ?? medications.first.patientId),
              ),
          'EdenMedicationList: medications must share same patientId; '
          'received mixed PHI. Library widgets enforce HIPAA isolation.',
        );

  final List<EdenMedicationStatement> medications;
  final String? patientId;
  final bool showInactive;
  final void Function(EdenMedicationStatement)? onMedicationTap;
  final void Function(EdenMedicationStatement)? onDiscontinueTap;
  final void Function(EdenMedicationStatement)? onRefillTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final filtered = showInactive
        ? medications
        : medications
            .where((m) =>
                m.status == EdenMedicationStatus.active ||
                m.status == EdenMedicationStatus.paused)
            .toList(growable: false);

    if (filtered.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: padding ?? const EdgeInsets.all(EdenSpacing.space2),
        child: Text(
          'No active medications',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Theme.of(context).dividerColor),
      itemBuilder: (context, i) {
        return _MedicationRow(
          medication: filtered[i],
          onTap: onMedicationTap,
          onRefillTap: onRefillTap,
          onDiscontinueTap: onDiscontinueTap,
        );
      },
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({
    required this.medication,
    this.onTap,
    this.onRefillTap,
    this.onDiscontinueTap,
  });

  final EdenMedicationStatement medication;
  final void Function(EdenMedicationStatement)? onTap;
  final void Function(EdenMedicationStatement)? onRefillTap;
  final void Function(EdenMedicationStatement)? onDiscontinueTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDiscontinued = medication.status == EdenMedicationStatus.discontinued;
    final isPaused = medication.status == EdenMedicationStatus.paused;
    final isCompleted = medication.status == EdenMedicationStatus.completed;

    final lineOne = '${medication.drugName} ${medication.doseLabel} '
        '${_routeAbbrev(medication.route)}';

    final lineOneStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
      fontWeight: FontWeight.w600,
      decoration: isDiscontinued ? TextDecoration.lineThrough : null,
      decorationColor: isDiscontinued ? theme.disabledColor : null,
      color: isDiscontinued
          ? theme.disabledColor
          : (isCompleted ? theme.colorScheme.onSurfaceVariant : null),
      fontStyle: (isPaused || isCompleted) ? FontStyle.italic : null,
    );

    final lineTwoParts = <String>[
      medication.frequency,
      if (medication.prescriber != null) medication.prescriber!,
      if (medication.startDate != null)
        'Since ${_formatDate(medication.startDate!)}',
    ];
    final lineTwo = lineTwoParts.join(' · ');

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(lineOne, style: lineOneStyle)),
              if (medication.interactionWarning != null) ...[
                const SizedBox(width: EdenSpacing.space2),
                Tooltip(
                  message: medication.interactionWarning!,
                  child: const EdenBadge(
                    label: 'IXN',
                    variant: EdenBadgeVariant.danger,
                    size: EdenBadgeSize.sm,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            lineTwo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (medication.needsRefill) ...[
            const SizedBox(height: EdenSpacing.space2),
            GestureDetector(
              onTap: onRefillTap == null ? null : () => onRefillTap!(medication),
              child: EdenBadge(
                label: (medication.refillsRemaining == 0)
                    ? 'No refills left'
                    : 'Refill needed',
                variant: EdenBadgeVariant.warning,
                size: EdenBadgeSize.sm,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null && onDiscontinueTap == null) return row;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(medication),
      child: row,
    );
  }
}

String _routeAbbrev(EdenMedicationRoute r) {
  switch (r) {
    case EdenMedicationRoute.oral:
      return 'PO';
    case EdenMedicationRoute.injection:
      return 'IV';
    case EdenMedicationRoute.topical:
      return 'TOP';
    case EdenMedicationRoute.inhaled:
      return 'INH';
    case EdenMedicationRoute.nasal:
      return 'NAS';
    case EdenMedicationRoute.ophthalmic:
      return 'OPH';
    case EdenMedicationRoute.otic:
      return 'OTI';
    case EdenMedicationRoute.rectal:
      return 'PR';
    case EdenMedicationRoute.vaginal:
      return 'PV';
    case EdenMedicationRoute.sublingual:
      return 'SL';
    case EdenMedicationRoute.transdermal:
      return 'TD';
    case EdenMedicationRoute.other:
      return 'OTH';
  }
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

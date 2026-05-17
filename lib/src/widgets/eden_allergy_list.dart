import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// FHIR-shape allergen type (library-owned).
enum EdenAllergenType { medication, food, environmental, biologic, other }

/// FHIR-shape allergy severity (library-owned).
enum EdenAllergySeverity { mild, moderate, severe, lifeThreatening }

/// FHIR-shape allergy criticality (library-owned).
enum EdenAllergyCriticality { low, high, unable }

/// FHIR-shape allergy clinical status (library-owned).
enum EdenAllergyClinicalStatus { active, inactive, resolved }

/// FHIR-shape allergy verification status (library-owned).
enum EdenAllergyVerificationStatus {
  unconfirmed,
  confirmed,
  refuted,
  enteredInError,
}

/// FHIR-shape AllergyIntolerance value class (library-owned — NOT
/// FHIR-bound). Consumer maps FHIR R4 `AllergyIntolerance` resources
/// at the integration boundary.
@immutable
class EdenAllergyIntolerance {
  const EdenAllergyIntolerance({
    required this.id,
    required this.patientId,
    required this.allergen,
    required this.type,
    required this.reaction,
    required this.severity,
    this.criticality = EdenAllergyCriticality.low,
    this.clinicalStatus = EdenAllergyClinicalStatus.active,
    this.verificationStatus = EdenAllergyVerificationStatus.confirmed,
    this.verifiedBy,
    this.onsetDate,
    this.notes,
  });

  final String id;
  final String patientId;
  final String allergen;
  final EdenAllergenType type;
  final String reaction;
  final EdenAllergySeverity severity;
  final EdenAllergyCriticality criticality;
  final EdenAllergyClinicalStatus clinicalStatus;
  final EdenAllergyVerificationStatus verificationStatus;
  final String? verifiedBy;
  final DateTime? onsetDate;
  final String? notes;
}

/// FHIR-shape allergy/intolerance display widget for medical Patient
/// Chart left-rail.
///
/// HIPAA isolation: asserts at construction time that all allergies
/// share the same patientId. Renders a non-dismissible
/// HIGH-CRITICALITY banner at top whenever any allergy in the active
/// set has `criticality == high`.
class EdenAllergyList extends StatelessWidget {
  EdenAllergyList({
    super.key,
    required this.allergies,
    this.patientId,
    this.showInactive = false,
    this.onAllergyTap,
    this.padding,
  }) : assert(
          allergies.isEmpty ||
              allergies.every(
                (a) =>
                    a.patientId == (patientId ?? allergies.first.patientId),
              ),
          'EdenAllergyList: allergies must share same patientId; received '
          'mixed PHI. Library widgets enforce HIPAA isolation.',
        );

  final List<EdenAllergyIntolerance> allergies;
  final String? patientId;
  final bool showInactive;
  final void Function(EdenAllergyIntolerance)? onAllergyTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final filtered = showInactive
        ? allergies
        : allergies
            .where((a) => a.clinicalStatus == EdenAllergyClinicalStatus.active)
            .toList(growable: false);

    if (filtered.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: padding ?? const EdgeInsets.all(EdenSpacing.space2),
        child: Text(
          'No known drug allergies (NKDA)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final palette = theme.extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();

    final highCritList = filtered
        .where((a) => a.criticality == EdenAllergyCriticality.high)
        .toList(growable: false);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highCritList.isNotEmpty)
            _CriticalityBanner(
              allergies: highCritList,
              palette: palette,
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, i) {
              return _AllergyRow(
                allergy: filtered[i],
                palette: palette,
                onTap: onAllergyTap,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CriticalityBanner extends StatelessWidget {
  const _CriticalityBanner({required this.allergies, required this.palette});

  final List<EdenAllergyIntolerance> allergies;
  final EdenStatusPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show first 3 + overflow indicator.
    final display = allergies.length <= 3 ? allergies : allergies.take(3).toList();
    final extra = allergies.length - display.length;
    final summary = display
        .map((a) => '${a.allergen} (${a.reaction})')
        .join(', ');

    final summaryWithOverflow =
        extra > 0 ? '$summary (+$extra more)' : summary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: EdenSpacing.space2),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: palette.dangerBg,
        borderRadius: BorderRadius.circular(EdenRadii.sm),
        border: Border.all(color: palette.dangerBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.dangerFg, size: 20),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIGH-CRITICALITY ALLERGIES — DO NOT GIVE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.dangerFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summaryWithOverflow,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.dangerFg,
                  ),
                ),
              ],
            ),
          ),
          // NO close icon — non-dismissible by design.
        ],
      ),
    );
  }
}

class _AllergyRow extends StatelessWidget {
  const _AllergyRow({
    required this.allergy,
    required this.palette,
    this.onTap,
  });

  final EdenAllergyIntolerance allergy;
  final EdenStatusPalette palette;
  final void Function(EdenAllergyIntolerance)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isRefuted =
        allergy.verificationStatus == EdenAllergyVerificationStatus.refuted ||
            allergy.verificationStatus ==
                EdenAllergyVerificationStatus.enteredInError;
    final isInactive = allergy.clinicalStatus != EdenAllergyClinicalStatus.active;

    final allergenStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      decoration: (isRefuted || isInactive) ? TextDecoration.lineThrough : null,
      color: isInactive ? theme.disabledColor : null,
    );

    final (severityLabel, severityFg, severityBg, severityBorder) =
        _severityTokens(allergy.severity, palette);

    final lineTwoParts = <String>[
      severityLabel,
      _verificationLabel(allergy.verificationStatus),
      if (allergy.verifiedBy != null) allergy.verifiedBy!,
    ];

    final verificationItalic = allergy.verificationStatus ==
        EdenAllergyVerificationStatus.unconfirmed;

    final lineTwoStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontStyle: verificationItalic ? FontStyle.italic : null,
      decoration: isRefuted ? TextDecoration.lineThrough : null,
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_typeIcon(allergy.type),
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(allergy.allergen, style: allergenStyle)),
                    const SizedBox(width: EdenSpacing.space2),
                    _SeverityPill(
                      label: severityLabel,
                      fg: severityFg,
                      bg: severityBg,
                      border: severityBorder,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(lineTwoParts.join(' · '), style: lineTwoStyle),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: () => onTap!(allergy), child: row);
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
  });

  final String label;
  final Color fg;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

(String, Color, Color, Color) _severityTokens(
  EdenAllergySeverity s,
  EdenStatusPalette p,
) {
  switch (s) {
    case EdenAllergySeverity.lifeThreatening:
      return ('Life-threatening', p.dangerFg, p.dangerBg, p.dangerBorder);
    case EdenAllergySeverity.severe:
      return ('Severe', p.dangerFg, p.dangerBg, p.dangerBorder);
    case EdenAllergySeverity.moderate:
      return ('Moderate', p.warningFg, p.warningBg, p.warningBorder);
    case EdenAllergySeverity.mild:
      return ('Mild', p.neutralFg, p.neutralBg, p.neutralBorder);
  }
}

String _verificationLabel(EdenAllergyVerificationStatus v) {
  switch (v) {
    case EdenAllergyVerificationStatus.confirmed:
      return 'Confirmed';
    case EdenAllergyVerificationStatus.unconfirmed:
      return 'Unconfirmed';
    case EdenAllergyVerificationStatus.refuted:
      return 'Refuted';
    case EdenAllergyVerificationStatus.enteredInError:
      return 'In error';
  }
}

IconData _typeIcon(EdenAllergenType t) {
  switch (t) {
    case EdenAllergenType.medication:
      return Icons.medication_outlined;
    case EdenAllergenType.food:
      return Icons.restaurant_outlined;
    case EdenAllergenType.environmental:
      return Icons.eco_outlined;
    case EdenAllergenType.biologic:
      return Icons.coronavirus_outlined;
    case EdenAllergenType.other:
      return Icons.warning_amber_outlined;
  }
}

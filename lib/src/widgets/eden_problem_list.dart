import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// FHIR-shape Condition clinical status (library-owned).
enum EdenConditionStatus { active, resolved, inactive, recurrence }

/// FHIR-shape Condition verification status (library-owned).
enum EdenConditionVerification {
  provisional,
  differential,
  confirmed,
  refuted,
  enteredInError,
}

/// FHIR-shape Condition value class (library-owned — NOT FHIR-bound).
///
/// Maps to FHIR `Condition` resource shape with ICD-10-CM as default
/// code system; SNOMED supported via `codeSystem` string.
@immutable
class EdenCondition {
  const EdenCondition({
    required this.id,
    required this.patientId,
    required this.code,
    required this.codeSystem,
    required this.description,
    required this.status,
    this.verification = EdenConditionVerification.confirmed,
    this.onsetDate,
    this.resolvedDate,
    this.diagnosedBy,
    this.severity,
    this.notes,
  });

  final String id;
  final String patientId;
  final String code;
  final String codeSystem;
  final String description;
  final EdenConditionStatus status;
  final EdenConditionVerification verification;
  final DateTime? onsetDate;
  final DateTime? resolvedDate;
  final String? diagnosedBy;
  final String? severity;
  final String? notes;
}

/// FHIR-shape problem list display for medical Patient Chart Problems tab.
///
/// HIPAA isolation: asserts at construction time that all conditions
/// share the same patientId.
class EdenProblemList extends StatelessWidget {
  EdenProblemList({
    super.key,
    required this.conditions,
    this.patientId,
    this.showResolved = false,
    this.sortAscending = false,
    this.onProblemTap,
    this.onResolveTap,
    this.onRecurrenceTap,
    this.padding,
  }) : assert(
          conditions.isEmpty ||
              conditions.every(
                (c) =>
                    c.patientId == (patientId ?? conditions.first.patientId),
              ),
          'EdenProblemList: conditions must share same patientId; received '
          'mixed PHI. Library widgets enforce HIPAA isolation.',
        );

  final List<EdenCondition> conditions;
  final String? patientId;
  final bool showResolved;
  final bool sortAscending;
  final void Function(EdenCondition)? onProblemTap;
  final void Function(EdenCondition)? onResolveTap;
  final void Function(EdenCondition)? onRecurrenceTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final filtered = showResolved
        ? conditions
        : conditions
            .where((c) =>
                c.status == EdenConditionStatus.active ||
                c.status == EdenConditionStatus.recurrence)
            .toList(growable: false);

    if (filtered.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: padding ?? const EdgeInsets.all(EdenSpacing.space2),
        child: Text(
          'No active problems',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final sorted = [...filtered];
    sorted.sort((a, b) {
      final ao = a.onsetDate;
      final bo = b.onsetDate;
      if (ao == null && bo == null) return 0;
      if (ao == null) return 1;
      if (bo == null) return -1;
      return sortAscending ? ao.compareTo(bo) : bo.compareTo(ao);
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.zero,
      itemCount: sorted.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Theme.of(context).dividerColor),
      itemBuilder: (context, i) {
        return _ProblemRow(
          condition: sorted[i],
          onTap: onProblemTap,
          onResolveTap: onResolveTap,
        );
      },
    );
  }
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({
    required this.condition,
    this.onTap,
    this.onResolveTap,
  });

  final EdenCondition condition;
  final void Function(EdenCondition)? onTap;
  final void Function(EdenCondition)? onResolveTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();

    final isRefuted = condition.verification == EdenConditionVerification.refuted ||
        condition.verification == EdenConditionVerification.enteredInError;

    final descriptionStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
      fontWeight: FontWeight.w600,
      decoration: isRefuted ? TextDecoration.lineThrough : null,
      color: condition.verification == EdenConditionVerification.enteredInError
          ? theme.disabledColor
          : null,
    );

    final lineOneSuffix = _verificationSuffix(condition.verification);

    final lineTwoParts = <String>[
      condition.onsetDate != null
          ? 'Onset ${_formatDate(condition.onsetDate!)}'
          : 'Onset unknown',
      if (condition.diagnosedBy != null) condition.diagnosedBy!,
      if (condition.resolvedDate != null)
        'Resolved ${_formatDate(condition.resolvedDate!)}',
    ];

    final inner = Padding(
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
              Text(
                condition.code,
                style: EdenTypography.monoFont.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  children: [
                    Text('— ${condition.description}', style: descriptionStyle),
                    if (lineOneSuffix != null)
                      Text(
                        ' $lineOneSuffix',
                        style: descriptionStyle.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: EdenSpacing.space2),
              _StatusPill(status: condition.status, palette: palette),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            lineTwoParts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (onTap == null && onResolveTap == null) return inner;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(condition),
      child: inner,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.palette});
  final EdenConditionStatus status;
  final EdenStatusPalette palette;

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;
    Color border;
    switch (status) {
      case EdenConditionStatus.active:
        label = 'Active';
        bg = palette.warningBg;
        fg = palette.warningFg;
        border = palette.warningBorder;
        break;
      case EdenConditionStatus.recurrence:
        label = 'Recurrence';
        bg = palette.dangerBg;
        fg = palette.dangerFg;
        border = palette.dangerBorder;
        break;
      case EdenConditionStatus.resolved:
        label = 'Resolved';
        bg = palette.successBg;
        fg = palette.successFg;
        border = palette.successBorder;
        break;
      case EdenConditionStatus.inactive:
        label = 'Inactive';
        bg = palette.neutralBg;
        fg = palette.neutralFg;
        border = palette.neutralBorder;
        break;
    }
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

String? _verificationSuffix(EdenConditionVerification v) {
  switch (v) {
    case EdenConditionVerification.provisional:
      return '(provisional)';
    case EdenConditionVerification.differential:
      return '(differential dx)';
    case EdenConditionVerification.confirmed:
    case EdenConditionVerification.refuted:
    case EdenConditionVerification.enteredInError:
      return null;
  }
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

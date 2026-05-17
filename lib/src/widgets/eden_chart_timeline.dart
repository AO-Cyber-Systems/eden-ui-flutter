import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Clinical event category (library-owned).
enum EdenChartEventCategory {
  encounter,
  lab,
  medication,
  note,
  order,
  vitalsCapture,
  allergy,
  problem,
  other,
}

/// Clinical event severity for [EdenChartTimeline] row tinting.
enum EdenChartEventSeverity { routine, caution, critical, resolved }

/// Clinical timeline event value class (library-owned — FHIR-shape-inspired
/// but not FHIR-bound).
@immutable
class EdenChartTimelineEvent {
  const EdenChartTimelineEvent({
    required this.id,
    required this.patientId,
    required this.category,
    required this.title,
    required this.occurredAt,
    this.subtitle,
    this.severity = EdenChartEventSeverity.routine,
    this.provider,
    this.relatedId,
    this.notes,
  });

  final String id;
  final String patientId;
  final EdenChartEventCategory category;
  final String title;
  final String? subtitle;
  final DateTime occurredAt;
  final EdenChartEventSeverity severity;
  final String? provider;
  final String? relatedId;
  final String? notes;
}

/// Vertical scrolling timeline of clinical events for medical Patient
/// Chart History / Overview tabs.
///
/// Composes severity tinting, category filter chips, date grouping with
/// multi-year quarterly compression, and an `aiInsightSlot` for downstream
/// summarization plug-in (per locked decision F).
class EdenChartTimeline extends StatefulWidget {
  EdenChartTimeline({
    super.key,
    required this.events,
    this.patientId,
    this.initialCategoryFilter,
    this.aiInsightSlot,
    this.onEventTap,
    this.padding,
  }) : assert(
          events.isEmpty ||
              events.every(
                (e) => e.patientId == (patientId ?? events.first.patientId),
              ),
          'EdenChartTimeline: events must share same patientId; received '
          'mixed PHI. Library widgets enforce HIPAA isolation.',
        );

  final List<EdenChartTimelineEvent> events;
  final String? patientId;
  final Set<EdenChartEventCategory>? initialCategoryFilter;
  final Widget? aiInsightSlot;
  final void Function(EdenChartTimelineEvent)? onEventTap;
  final EdgeInsetsGeometry? padding;

  @override
  State<EdenChartTimeline> createState() => _EdenChartTimelineState();
}

/// Filter-chip categories shown in the UI (collapses problem/allergy/
/// vitalsCapture/other into "Other" for chip clarity).
const _filterChipCategories = <EdenChartEventCategory>[
  EdenChartEventCategory.encounter,
  EdenChartEventCategory.lab,
  EdenChartEventCategory.medication,
  EdenChartEventCategory.note,
  EdenChartEventCategory.order,
];

String _chipLabel(EdenChartEventCategory c) {
  switch (c) {
    case EdenChartEventCategory.encounter:
      return 'Encounters';
    case EdenChartEventCategory.lab:
      return 'Labs';
    case EdenChartEventCategory.medication:
      return 'Meds';
    case EdenChartEventCategory.note:
      return 'Notes';
    case EdenChartEventCategory.order:
      return 'Orders';
    case EdenChartEventCategory.vitalsCapture:
      return 'Vitals';
    case EdenChartEventCategory.allergy:
      return 'Allergies';
    case EdenChartEventCategory.problem:
      return 'Problems';
    case EdenChartEventCategory.other:
      return 'Other';
  }
}

class _EdenChartTimelineState extends State<EdenChartTimeline> {
  late Set<EdenChartEventCategory> _activeFilters;

  @override
  void initState() {
    super.initState();
    _activeFilters = widget.initialCategoryFilter == null
        ? <EdenChartEventCategory>{...EdenChartEventCategory.values}
        : <EdenChartEventCategory>{...widget.initialCategoryFilter!};
  }

  bool get _allActive =>
      _activeFilters.length == EdenChartEventCategory.values.length;

  void _toggleAll() {
    setState(() {
      if (_allActive) {
        _activeFilters = <EdenChartEventCategory>{};
      } else {
        _activeFilters = <EdenChartEventCategory>{...EdenChartEventCategory.values};
      }
    });
  }

  void _toggleCategory(EdenChartEventCategory c) {
    setState(() {
      if (_activeFilters.contains(c)) {
        _activeFilters.remove(c);
      } else {
        _activeFilters.add(c);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();

    final filtered = widget.events
        .where((e) => _activeFilters.contains(e.category))
        .toList(growable: false)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final groups = _groupByDate(filtered, now: DateTime.now());

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filterChips(theme),
          if (widget.aiInsightSlot != null) ...[
            const SizedBox(height: EdenSpacing.space3),
            widget.aiInsightSlot!,
          ],
          const SizedBox(height: EdenSpacing.space3),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              child: Text(
                'No events to display',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in groups.entries) ...[
                  _dateHeader(theme, entry.key),
                  for (final ev in entry.value)
                    _eventRow(theme, palette, ev),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _filterChips(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _allActive,
          onSelected: (_) => _toggleAll(),
        ),
        for (final c in _filterChipCategories)
          FilterChip(
            label: Text(_chipLabel(c)),
            selected: _activeFilters.contains(c),
            onSelected: (_) => _toggleCategory(c),
          ),
      ],
    );
  }

  Widget _dateHeader(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _eventRow(
    ThemeData theme,
    EdenStatusPalette palette,
    EdenChartTimelineEvent ev,
  ) {
    final tintBg = _severityBg(ev.severity, palette);
    final tintBorder = _severityBorder(ev.severity, palette);

    final inner = Container(
      margin: const EdgeInsets.only(bottom: EdenSpacing.space2),
      padding: const EdgeInsets.all(EdenSpacing.space2),
      decoration: BoxDecoration(
        color: tintBg,
        borderRadius: BorderRadius.circular(EdenRadii.sm),
        border: tintBorder == null
            ? null
            : Border.all(color: tintBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_categoryIcon(ev.category),
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ev.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (ev.provider != null)
                      Text(
                        ev.provider!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (ev.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    ev.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.onEventTap == null) return inner;
    return InkWell(onTap: () => widget.onEventTap!(ev), child: inner);
  }
}

// ────────────────────────── helpers ──────────────────────────

Color? _severityBg(EdenChartEventSeverity s, EdenStatusPalette p) {
  switch (s) {
    case EdenChartEventSeverity.routine:
      return null;
    case EdenChartEventSeverity.caution:
      return p.warningBg;
    case EdenChartEventSeverity.critical:
      return p.dangerBg;
    case EdenChartEventSeverity.resolved:
      return p.successBg;
  }
}

Color? _severityBorder(EdenChartEventSeverity s, EdenStatusPalette p) {
  switch (s) {
    case EdenChartEventSeverity.routine:
      return null;
    case EdenChartEventSeverity.caution:
      return p.warningBorder;
    case EdenChartEventSeverity.critical:
      return p.dangerBorder;
    case EdenChartEventSeverity.resolved:
      return p.successBorder;
  }
}

IconData _categoryIcon(EdenChartEventCategory c) {
  switch (c) {
    case EdenChartEventCategory.encounter:
      return Icons.medical_services_outlined;
    case EdenChartEventCategory.lab:
      return Icons.science_outlined;
    case EdenChartEventCategory.medication:
      return Icons.medication_outlined;
    case EdenChartEventCategory.note:
      return Icons.description_outlined;
    case EdenChartEventCategory.order:
      return Icons.assignment_outlined;
    case EdenChartEventCategory.vitalsCapture:
      return Icons.monitor_heart_outlined;
    case EdenChartEventCategory.allergy:
      return Icons.warning_amber_outlined;
    case EdenChartEventCategory.problem:
      return Icons.report_problem_outlined;
    case EdenChartEventCategory.other:
      return Icons.circle_outlined;
  }
}

/// Public for unit testing — groups events into rendered headers, with
/// quarterly compression for events older than 12 months.
Map<String, List<EdenChartTimelineEvent>> _groupByDate(
  List<EdenChartTimelineEvent> events, {
  required DateTime now,
}) {
  final twelveMo = now.subtract(const Duration(days: 365));
  final out = <String, List<EdenChartTimelineEvent>>{};

  for (final ev in events) {
    final key = _headerLabel(ev.occurredAt, now: now, twelveMonthsAgo: twelveMo);
    out.putIfAbsent(key, () => []).add(ev);
  }

  return out;
}

String _headerLabel(
  DateTime when, {
  required DateTime now,
  required DateTime twelveMonthsAgo,
}) {
  if (when.isBefore(twelveMonthsAgo)) {
    final q = ((when.month - 1) ~/ 3) + 1;
    return '${when.year} Q$q';
  }
  final today = DateTime(now.year, now.month, now.day);
  final whenDay = DateTime(when.year, when.month, when.day);
  final daysAgo = today.difference(whenDay).inDays;
  if (daysAgo == 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 30) {
    return '$daysAgo days ago (${_fmt(whenDay)})';
  }
  return _fmt(whenDay);
}

String _fmt(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_allergy_list.dart';
import 'eden_audit_log_viewer.dart';
import 'eden_blocking_alerts.dart';
import 'eden_chart_timeline.dart';
import 'eden_lab_result_table.dart';
import 'eden_medication_list.dart';
import 'eden_problem_list.dart';
import 'eden_section_header.dart';
import 'eden_soap_note.dart';
import 'eden_tabs.dart';
import 'eden_vitals_row.dart';

/// Patient demographics value class for the chart header.
@immutable
class EdenPatientDemographics {
  const EdenPatientDemographics({
    required this.patientId,
    required this.name,
    required this.mrn,
    required this.dob,
    required this.sex,
    this.payer,
    this.pcp,
    this.preferredLanguage,
    this.phone,
  });

  final String patientId;
  final String name;
  final String mrn;
  final DateTime dob;
  final String sex;
  final String? payer;
  final String? pcp;
  final String? preferredLanguage;
  final String? phone;
}

/// Composite patient-chart data carrier — all sub-collections must carry
/// the same patientId; the scaffold asserts isolation in its constructor.
@immutable
class EdenPatientChartData {
  const EdenPatientChartData({
    required this.patientId,
    required this.demographics,
    required this.vitals,
    required this.medications,
    required this.problems,
    required this.allergies,
    required this.labs,
    required this.notes,
    required this.timelineEvents,
    this.blockingAlerts = const [],
    this.auditEvents = const [],
  });

  final String patientId;
  final EdenPatientDemographics demographics;
  final List<EdenVitalSign> vitals;
  final List<EdenMedicationStatement> medications;
  final List<EdenCondition> problems;
  final List<EdenAllergyIntolerance> allergies;
  final List<EdenLabResult> labs;
  final List<EdenSoapNoteData> notes;
  final List<EdenChartTimelineEvent> timelineEvents;
  final List<EdenBlockingAlertData> blockingAlerts;
  final List<EdenAuditLogEntry> auditEvents;
}

/// Three-pane Patient Chart shell composing all of obj 013 Wave 1 + 2
/// widgets + obj 011 EdenAuditLogViewer.
///
/// HIPAA bleed isolation: scaffold-level + per-collection assertions
/// enforce single-patient PHI boundary across all sub-widgets.
class EdenPatientChartScaffold extends StatefulWidget {
  EdenPatientChartScaffold({
    super.key,
    required this.data,
    required this.patientId,
    this.initialTabIndex = 0,
    this.aiInsightSlot,
    this.onPatientHeaderTap,
    this.onTabChange,
    this.onEventDrillDown,
    this.onAuditAccess,
    this.padding,
  })  : assert(
          data.patientId == patientId,
          'EdenPatientChartScaffold: data.patientId must match patientId param. '
          'HIPAA isolation enforced.',
        ),
        assert(
          data.demographics.patientId == patientId,
          'EdenPatientChartScaffold: demographics.patientId mismatch (PHI bleed).',
        ),
        assert(
          data.vitals.every((v) => v.patientId == patientId),
          'EdenPatientChartScaffold: vitals contain mismatched patientId (PHI bleed).',
        ),
        assert(
          data.medications.every((m) => m.patientId == patientId),
          'EdenPatientChartScaffold: medications contain mismatched patientId (PHI bleed).',
        ),
        assert(
          data.problems.every((p) => p.patientId == patientId),
          'EdenPatientChartScaffold: problems contain mismatched patientId (PHI bleed).',
        ),
        assert(
          data.allergies.every((a) => a.patientId == patientId),
          'EdenPatientChartScaffold: allergies contain mismatched patientId (PHI bleed).',
        ),
        assert(
          data.labs.every((l) => l.patientId == patientId),
          'EdenPatientChartScaffold: labs contain mismatched patientId (PHI bleed).',
        ),
        assert(
          data.notes.every((n) => n.patientId == patientId),
          'EdenPatientChartScaffold: notes contain mismatched patientId (PHI bleed).',
        ),
        assert(
          data.timelineEvents.every((e) => e.patientId == patientId),
          'EdenPatientChartScaffold: timelineEvents contain mismatched patientId (PHI bleed).',
        );

  final EdenPatientChartData data;
  final String patientId;
  final int initialTabIndex;
  final Widget? aiInsightSlot;
  final VoidCallback? onPatientHeaderTap;
  final void Function(int)? onTabChange;
  final void Function(EdenChartTimelineEvent)? onEventDrillDown;
  final VoidCallback? onAuditAccess;
  final EdgeInsetsGeometry? padding;

  @override
  State<EdenPatientChartScaffold> createState() =>
      _EdenPatientChartScaffoldState();
}

class _EdenPatientChartScaffoldState extends State<EdenPatientChartScaffold> {
  late int _currentTab;

  static const _tabLabels = <String>[
    'Overview',
    'Vitals',
    'Notes',
    'Labs',
    'Meds',
    'History',
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTabIndex;
  }

  void _onTab(int i) {
    setState(() => _currentTab = i);
    widget.onTabChange?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      if (w >= 840) {
        return _buildExpanded(context);
      }
      if (w >= 600) {
        return _buildMedium(context);
      }
      return _buildCompact(context);
    });
  }

  Widget _buildExpanded(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          _tabBar(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    key: const Key('left-rail'),
                    padding: const EdgeInsets.all(EdenSpacing.space2),
                    child: _leftRailContent(context),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('center-pane'),
                    padding: const EdgeInsets.all(EdenSpacing.space3),
                    child: _tabContent(context),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    key: const Key('right-rail'),
                    padding: const EdgeInsets.all(EdenSpacing.space2),
                    child: _rightRailContent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedium(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          _tabBar(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('center-pane'),
                    padding: const EdgeInsets.all(EdenSpacing.space3),
                    child: _tabContent(context),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    key: const Key('right-rail'),
                    padding: const EdgeInsets.all(EdenSpacing.space2),
                    child: _rightRailContent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    // Compact tier: left + right rail content move into a leading "Summary"
    // tab so all sub-content remains reachable. We expose 7 tabs in
    // Compact (Summary + the 6 standard tabs).
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          _compactTabBar(context),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('compact-pane'),
              padding: const EdgeInsets.all(EdenSpacing.space2),
              child: _compactTabContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final demo = widget.data.demographics;
    final ageYears = _ageInYears(demo.dob, DateTime.now());
    final subtitleParts = <String>[
      'MRN ${demo.mrn}',
      '${ageYears}y ${demo.sex}',
      'DOB ${_formatDate(demo.dob)}',
      if (demo.payer != null) 'Payer: ${demo.payer}',
      if (demo.pcp != null) 'PCP: ${demo.pcp}',
    ];

    final inner = Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            demo.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitleParts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (widget.onPatientHeaderTap == null) return inner;
    return InkWell(onTap: widget.onPatientHeaderTap, child: inner);
  }

  Widget _tabBar(BuildContext context) {
    final tabs = _tabLabels
        .map((label) => EdenTabItem(label: label))
        .toList(growable: false);
    return EdenTabs(
      tabs: tabs,
      selectedIndex: _currentTab,
      onChanged: _onTab,
    );
  }

  Widget _compactTabBar(BuildContext context) {
    final tabs = <EdenTabItem>[
      const EdenTabItem(label: 'Summary'),
      ..._tabLabels.map((l) => EdenTabItem(label: l)),
    ];
    return EdenTabs(
      tabs: tabs,
      selectedIndex: _currentTab,
      onChanged: _onTab,
    );
  }

  Widget _tabContent(BuildContext context) {
    switch (_currentTab) {
      case 0:
        return _overviewTab(context);
      case 1:
        return _vitalsTab(context);
      case 2:
        return _notesTab(context);
      case 3:
        return _labsTab(context);
      case 4:
        return _medsTab(context);
      case 5:
        return _historyTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _compactTabContent(BuildContext context) {
    if (_currentTab == 0) {
      return _compactSummaryTab(context);
    }
    final centerIndex = _currentTab - 1;
    switch (centerIndex) {
      case 0:
        return _overviewTab(context);
      case 1:
        return _vitalsTab(context);
      case 2:
        return _notesTab(context);
      case 3:
        return _labsTab(context);
      case 4:
        return _medsTab(context);
      case 5:
        return _historyTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _compactSummaryTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leftRailContent(context),
        const SizedBox(height: EdenSpacing.space4),
        _rightRailContent(context),
      ],
    );
  }

  Widget _leftRailContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EdenSectionHeader(title: 'Problem List'),
        EdenProblemList(
          conditions: widget.data.problems,
          patientId: widget.patientId,
        ),
        const SizedBox(height: EdenSpacing.space3),
        const EdenSectionHeader(title: 'Medications'),
        EdenMedicationList(
          medications: widget.data.medications,
          patientId: widget.patientId,
        ),
        const SizedBox(height: EdenSpacing.space3),
        const EdenSectionHeader(title: 'Allergies'),
        EdenAllergyList(
          allergies: widget.data.allergies,
          patientId: widget.patientId,
        ),
      ],
    );
  }

  Widget _rightRailContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EdenSectionHeader(title: 'Active Alerts'),
        EdenBlockingAlerts(alerts: widget.data.blockingAlerts),
        const SizedBox(height: EdenSpacing.space3),
        const EdenSectionHeader(title: 'Audit Trail'),
        EdenAuditLogViewer(
          entries: widget.data.auditEvents,
          showFilters: false,
        ),
        if (widget.aiInsightSlot != null) ...[
          const SizedBox(height: EdenSpacing.space3),
          const EdenSectionHeader(title: 'AI Insights'),
          widget.aiInsightSlot!,
        ],
      ],
    );
  }

  Widget _overviewTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EdenVitalsRow(
          vitals: widget.data.vitals,
          patientId: widget.patientId,
        ),
        const SizedBox(height: EdenSpacing.space4),
        EdenChartTimeline(
          events: widget.data.timelineEvents,
          patientId: widget.patientId,
          onEventTap: widget.onEventDrillDown,
        ),
      ],
    );
  }

  Widget _vitalsTab(BuildContext context) {
    return EdenVitalsRow(
      vitals: widget.data.vitals,
      patientId: widget.patientId,
      showTimestamps: true,
    );
  }

  Widget _notesTab(BuildContext context) {
    if (widget.data.notes.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(EdenSpacing.space2),
        child: Text(
          'No notes recorded',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final note in widget.data.notes) ...[
          EdenSOAPNote(
            data: note,
            patientId: widget.patientId,
            mode: EdenSoapMode.view,
          ),
          const SizedBox(height: EdenSpacing.space4),
        ],
      ],
    );
  }

  Widget _labsTab(BuildContext context) {
    return EdenLabResultTable(
      results: widget.data.labs,
      patientId: widget.patientId,
      groupByPanel: true,
    );
  }

  Widget _medsTab(BuildContext context) {
    return EdenMedicationList(
      medications: widget.data.medications,
      patientId: widget.patientId,
    );
  }

  Widget _historyTab(BuildContext context) {
    return EdenChartTimeline(
      events: widget.data.timelineEvents,
      patientId: widget.patientId,
      onEventTap: widget.onEventDrillDown,
    );
  }
}

int _ageInYears(DateTime dob, DateTime now) {
  var age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age -= 1;
  }
  return age;
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

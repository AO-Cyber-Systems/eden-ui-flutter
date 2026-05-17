import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_detail_header.dart';
import 'eden_medication_list.dart';
import 'eden_problem_list.dart';
import 'eden_soap_note.dart';

/// Layout variants for the After Visit Summary surface.
///
/// Use [compact] for mobile-first patient portals and [printFriendly] for
/// paper / PDF rendering at wider widths.
enum EdenAvsLayout {
  /// Single-column vertical scroll — mobile-first patient-portal default.
  compact,

  /// Two-column at >=600pt for paper preview (collapses to single-column
  /// below the breakpoint). Used by print + email-as-PDF channels.
  printFriendly,
}

/// Output format emitted on action callbacks.
enum EdenAvsExportFormat {
  /// Print channel — consumer wires the OS print pipeline.
  print,

  /// Email channel — consumer wires SMTP / SendGrid.
  email,

  /// Patient portal channel — consumer wires the portal-share pipeline.
  portal,
}

/// Patient-facing After Visit Summary document.
///
/// Composes the four obj-013 clinical primitives (SOAPNote, MedicationList,
/// ProblemList, DetailHeader) into a single patient-readable document.
/// Library is transport-agnostic: consumer assembles this value class from
/// its own backend models and renders via [EdenAVSGenerator].
@immutable
class EdenAvsDocument {
  const EdenAvsDocument({
    required this.patientId,
    required this.patientDisplayName,
    required this.encounterDate,
    required this.providerName,
    this.providerCredentials,
    this.facilityName,
    required this.visitReason,
    required this.soapData,
    this.medications = const [],
    this.problems = const [],
    this.followUpInstructions,
    this.nextAppointmentAt,
  });

  /// HIPAA isolation key. All composed children (soapData, medications,
  /// problems) MUST share this id; the widget asserts the invariant.
  final String patientId;

  /// Display name (e.g., 'Alex Alpha'). Renders in the header row.
  final String patientDisplayName;

  /// Encounter timestamp; formatted in the header.
  final DateTime encounterDate;

  /// Provider display name (e.g., 'Dr. Jane Smith').
  final String providerName;

  /// Optional credentials suffix (e.g., 'PsyD', 'MD', 'NP').
  final String? providerCredentials;

  /// Optional facility name (e.g., 'Eden Behavioral Health Center').
  final String? facilityName;

  /// Patient-readable visit reason (NOT clinical jargon).
  final String visitReason;

  /// SOAP data from obj 013-06. Rendered read-only in patient-friendly form.
  final EdenSoapNoteData soapData;

  /// Medications shown in "What to do next". Active-status filtered.
  final List<EdenMedicationStatement> medications;

  /// Problems shown in "What we found". Active-status filtered.
  final List<EdenCondition> problems;

  /// Free-form patient-readable instructions block.
  final String? followUpInstructions;

  /// Optional follow-up appointment time. Renders as a pill when present.
  final DateTime? nextAppointmentAt;
}

/// Structured export emitted on the Print / Email / Save-to-Portal callbacks.
///
/// Library renders the widget + emits this value; consumer wires the actual
/// print / email / portal pipeline.
@immutable
class EdenAvsExport {
  const EdenAvsExport({
    required this.format,
    required this.plainTextBody,
    required this.document,
  });

  /// Which channel the consumer requested.
  final EdenAvsExportFormat format;

  /// Assembled plain-text fallback for downstream PDF / email rendering.
  final String plainTextBody;

  /// Original document — pass-through for consumer downstream rendering.
  final EdenAvsDocument document;
}

/// Patient-facing After Visit Summary composite (obj 017-01).
///
/// Composes obj 013-06 [EdenSOAPNote] view mode, obj 013-02
/// [EdenMedicationList], obj 013-04 [EdenProblemList], and obj 001-02
/// [EdenDetailHeader] into a single patient-readable surface. Patient-friendly
/// section headers replace SOAP medical jargon ("Why you came in" instead of
/// "Chief complaint", etc.).
///
/// **HIPAA isolation** — constructor asserts that [EdenAvsDocument.soapData],
/// every [EdenAvsDocument.medications] entry, and every
/// [EdenAvsDocument.problems] entry share the same `patientId`. Mismatches
/// throw [AssertionError] in debug.
///
/// **No backend bind** — Print / Email / Portal channels emit
/// [EdenAvsExport] via callbacks. Consumer wires Printing / SMTP / portal
/// integrations.
class EdenAVSGenerator extends StatelessWidget {
  EdenAVSGenerator({
    super.key,
    required this.document,
    this.onPrintRequested,
    this.onEmailRequested,
    this.onPortalShareRequested,
    this.layout = EdenAvsLayout.compact,
  })  : assert(
          document.soapData.patientId == document.patientId,
          'EdenAVSGenerator: soapData.patientId (${document.soapData.patientId}) '
          'must equal document.patientId (${document.patientId}). '
          'HIPAA isolation invariant.',
        ),
        assert(
          document.medications.every((m) => m.patientId == document.patientId),
          'EdenAVSGenerator: all medications must share document.patientId '
          '(${document.patientId}). HIPAA isolation invariant.',
        ),
        assert(
          document.problems.every((p) => p.patientId == document.patientId),
          'EdenAVSGenerator: all problems must share document.patientId '
          '(${document.patientId}). HIPAA isolation invariant.',
        );

  /// The AVS document to render.
  final EdenAvsDocument document;

  /// Fires when the patient taps "Print". Library is print-agnostic.
  final VoidCallback? onPrintRequested;

  /// Fires when the patient taps "Email". Emits an [EdenAvsExport] with
  /// plain-text body for downstream PDF / email rendering.
  final ValueChanged<EdenAvsExport>? onEmailRequested;

  /// Fires when the patient taps "Save to Portal". Emits an [EdenAvsExport]
  /// for downstream portal-share rendering.
  final ValueChanged<EdenAvsExport>? onPortalShareRequested;

  /// Layout variant. Defaults to [EdenAvsLayout.compact] (mobile-first).
  final EdenAvsLayout layout;

  static const double _printFriendlyBreakpoint = 600;
  static const double _bodyFontSize = 14;
  static const double _sectionHeaderFontSize = 18;

  // Patient-readable section header text — explicitly NOT SOAP jargon.
  static const String _whyYouCameIn = 'Why you came in';
  static const String _whatWeMeasured = 'What we measured';
  static const String _whatWeFound = 'What we found';
  static const String _whatToDoNext = 'What to do next';
  static const String _followUpHeading = 'Follow-up instructions';
  static const String _yourMedicationsHeading = 'Your medications';
  static const String _yourActiveConditionsHeading = 'Your active conditions';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumn = layout == EdenAvsLayout.printFriendly &&
            constraints.maxWidth >= _printFriendlyBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: EdenSpacing.space4),
            if (document.nextAppointmentAt != null) ...[
              _buildNextAppointmentPill(context),
              const SizedBox(height: EdenSpacing.space3),
            ],
            if (useTwoColumn)
              _buildTwoColumnBody(context)
            else
              _buildSingleColumnBody(context),
            if (document.followUpInstructions != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              _buildFollowUpBlock(context),
            ],
            const SizedBox(height: EdenSpacing.space4),
            _buildActionButtons(context),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final providerLabel = document.providerCredentials == null
        ? document.providerName
        : '${document.providerName}, ${document.providerCredentials}';
    final encounterLabel = _formatDate(document.encounterDate);
    final metadataParts = <String>[
      providerLabel,
      if (document.facilityName != null) document.facilityName!,
      encounterLabel,
    ];
    return EdenDetailHeader(
      title: document.patientDisplayName,
      subtitle: '${document.visitReason} • ${metadataParts.join(' • ')}',
    );
  }

  Widget _buildNextAppointmentPill(BuildContext context) {
    // Use a flexible pill instead of EdenBadge so long timestamps wrap
    // gracefully at iPhone-narrow (>=390pt) widths instead of overflowing.
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('eden-avs-next-appointment-pill'),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Text(
        'Next appointment: ${_formatDate(document.nextAppointmentAt!)}',
        style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontSize: _bodyFontSize,
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSingleColumnBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          heading: _whyYouCameIn,
          body: _resolveSubjectiveBody(),
        ),
        const SizedBox(height: EdenSpacing.space4),
        if (document.soapData.objective.trim().isNotEmpty) ...[
          _buildSection(
            context,
            heading: _whatWeMeasured,
            body: document.soapData.objective,
          ),
          const SizedBox(height: EdenSpacing.space4),
        ],
        _buildSection(
          context,
          heading: _whatWeFound,
          body: _resolveAssessmentBody(),
        ),
        const SizedBox(height: EdenSpacing.space3),
        _buildActiveProblemsBlock(context),
        const SizedBox(height: EdenSpacing.space4),
        _buildSection(
          context,
          heading: _whatToDoNext,
          body: _resolvePlanBody(),
        ),
        const SizedBox(height: EdenSpacing.space3),
        _buildActiveMedicationsBlock(context),
      ],
    );
  }

  Widget _buildTwoColumnBody(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                heading: _whyYouCameIn,
                body: _resolveSubjectiveBody(),
              ),
              const SizedBox(height: EdenSpacing.space4),
              if (document.soapData.objective.trim().isNotEmpty) ...[
                _buildSection(
                  context,
                  heading: _whatWeMeasured,
                  body: document.soapData.objective,
                ),
                const SizedBox(height: EdenSpacing.space4),
              ],
              _buildSection(
                context,
                heading: _whatToDoNext,
                body: _resolvePlanBody(),
              ),
              const SizedBox(height: EdenSpacing.space3),
              _buildActiveMedicationsBlock(context),
            ],
          ),
        ),
        const SizedBox(width: EdenSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                heading: _whatWeFound,
                body: _resolveAssessmentBody(),
              ),
              const SizedBox(height: EdenSpacing.space3),
              _buildActiveProblemsBlock(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String heading,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
            fontSize: _sectionHeaderFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          body,
          style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontSize: _bodyFontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpBlock(BuildContext context) {
    return _buildSection(
      context,
      heading: _followUpHeading,
      body: document.followUpInstructions!,
    );
  }

  Widget _buildActiveMedicationsBlock(BuildContext context) {
    final theme = Theme.of(context);
    final active = document.medications
        .where((m) => m.status == EdenMedicationStatus.active)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _yourMedicationsHeading,
          style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontSize: _sectionHeaderFontSize - 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        if (active.isEmpty)
          Text(
            'No active medications',
            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontSize: _bodyFontSize,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          EdenMedicationList(
            medications: active,
            patientId: document.patientId,
          ),
      ],
    );
  }

  Widget _buildActiveProblemsBlock(BuildContext context) {
    final theme = Theme.of(context);
    final active = document.problems
        .where((p) => p.status == EdenConditionStatus.active)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _yourActiveConditionsHeading,
          style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontSize: _sectionHeaderFontSize - 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        if (active.isEmpty)
          Text(
            'No active problems',
            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontSize: _bodyFontSize,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          EdenProblemList(
            conditions: active,
            patientId: document.patientId,
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];
    if (onPrintRequested != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const ValueKey('eden-avs-print-button'),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print'),
          onPressed: onPrintRequested,
        ),
      );
    }
    if (onEmailRequested != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const ValueKey('eden-avs-email-button'),
          icon: const Icon(Icons.email_outlined),
          label: const Text('Email'),
          onPressed: () => onEmailRequested!(_buildExport(
            EdenAvsExportFormat.email,
          )),
        ),
      );
    }
    if (onPortalShareRequested != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const ValueKey('eden-avs-portal-button'),
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Save to Portal'),
          onPressed: () => onPortalShareRequested!(_buildExport(
            EdenAvsExportFormat.portal,
          )),
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space2,
      children: buttons,
    );
  }

  EdenAvsExport _buildExport(EdenAvsExportFormat format) {
    final buffer = StringBuffer()
      ..writeln('After Visit Summary')
      ..writeln('Patient: ${document.patientDisplayName}')
      ..writeln('Provider: ${document.providerName}'
          '${document.providerCredentials != null ? ', ${document.providerCredentials}' : ''}')
      ..writeln('Encounter date: ${_formatDate(document.encounterDate)}')
      ..writeln()
      ..writeln('$_whyYouCameIn:')
      ..writeln(_resolveSubjectiveBody())
      ..writeln();
    if (document.soapData.objective.trim().isNotEmpty) {
      buffer
        ..writeln('$_whatWeMeasured:')
        ..writeln(document.soapData.objective)
        ..writeln();
    }
    buffer
      ..writeln('$_whatWeFound:')
      ..writeln(_resolveAssessmentBody())
      ..writeln()
      ..writeln('$_whatToDoNext:')
      ..writeln(_resolvePlanBody());
    if (document.followUpInstructions != null) {
      buffer
        ..writeln()
        ..writeln('$_followUpHeading:')
        ..writeln(document.followUpInstructions);
    }
    return EdenAvsExport(
      format: format,
      plainTextBody: buffer.toString(),
      document: document,
    );
  }

  String _resolveSubjectiveBody() {
    final subjective = document.soapData.subjective.trim();
    if (subjective.isEmpty) return document.visitReason;
    return '${document.visitReason}\n\n$subjective';
  }

  String _resolveAssessmentBody() {
    final assessment = document.soapData.assessment.trim();
    if (assessment.isEmpty) {
      return 'See your active conditions list below.';
    }
    return assessment;
  }

  String _resolvePlanBody() {
    final plan = document.soapData.plan.trim();
    if (plan.isEmpty) {
      return 'See your medications list below.';
    }
    return plan;
  }

  static String _formatDate(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
  }
}

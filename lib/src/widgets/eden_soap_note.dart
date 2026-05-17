import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Edit vs read-only mode for [EdenSOAPNote].
enum EdenSoapMode { compose, view }

/// SOAP note data carrier — patient-isolated.
@immutable
class EdenSoapNoteData {
  const EdenSoapNoteData({
    required this.patientId,
    this.subjective = '',
    this.objective = '',
    this.assessment = '',
    this.plan = '',
    this.signedBy,
    this.signedAt,
    this.encounterId,
    this.providerId,
  });

  final String patientId;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final String? signedBy;
  final DateTime? signedAt;
  final String? encounterId;
  final String? providerId;

  EdenSoapNoteData copyWith({
    String? patientId,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? signedBy,
    DateTime? signedAt,
    String? encounterId,
    String? providerId,
  }) {
    return EdenSoapNoteData(
      patientId: patientId ?? this.patientId,
      subjective: subjective ?? this.subjective,
      objective: objective ?? this.objective,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      signedBy: signedBy ?? this.signedBy,
      signedAt: signedAt ?? this.signedAt,
      encounterId: encounterId ?? this.encounterId,
      providerId: providerId ?? this.providerId,
    );
  }
}

/// SOAP-note 4-section composer + viewer for medical Visit/Encounter
/// screens.
///
/// Library-owned, transport-agnostic, template-slot driven. Per locked
/// decision F: AI surface is callback-driven (consumer plugs in widgets
/// via `aiSuggestionSlot` / `voiceInputSlotBuilder` / `signaturePadSlot`).
class EdenSOAPNote extends StatefulWidget {
  EdenSOAPNote({
    super.key,
    required this.data,
    required this.patientId,
    this.mode = EdenSoapMode.compose,
    this.onChanged,
    this.onSign,
    this.sectionToolbarSlotBuilder,
    this.voiceInputSlotBuilder,
    this.aiSuggestionSlot,
    this.signaturePadSlot,
    this.padding,
  }) : assert(
          data.patientId == patientId,
          'EdenSOAPNote: data.patientId must match patientId param '
          '(HIPAA isolation). Got data.patientId="${data.patientId}", '
          'patientId="$patientId".',
        );

  final EdenSoapNoteData data;
  final String patientId;
  final EdenSoapMode mode;
  final void Function(EdenSoapNoteData)? onChanged;
  final void Function(EdenSoapNoteData)? onSign;
  final Widget? Function(String sectionName)? sectionToolbarSlotBuilder;
  final Widget? Function(String sectionName)? voiceInputSlotBuilder;
  final Widget? aiSuggestionSlot;
  final Widget? signaturePadSlot;
  final EdgeInsetsGeometry? padding;

  @override
  State<EdenSOAPNote> createState() => _EdenSOAPNoteState();
}

class _EdenSOAPNoteState extends State<EdenSOAPNote> {
  late TextEditingController _sCtrl;
  late TextEditingController _oCtrl;
  late TextEditingController _aCtrl;
  late TextEditingController _pCtrl;

  @override
  void initState() {
    super.initState();
    _sCtrl = TextEditingController(text: widget.data.subjective);
    _oCtrl = TextEditingController(text: widget.data.objective);
    _aCtrl = TextEditingController(text: widget.data.assessment);
    _pCtrl = TextEditingController(text: widget.data.plan);
  }

  @override
  void didUpdateWidget(covariant EdenSOAPNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.subjective != _sCtrl.text) _sCtrl.text = widget.data.subjective;
    if (widget.data.objective != _oCtrl.text) _oCtrl.text = widget.data.objective;
    if (widget.data.assessment != _aCtrl.text) _aCtrl.text = widget.data.assessment;
    if (widget.data.plan != _pCtrl.text) _pCtrl.text = widget.data.plan;
  }

  @override
  void dispose() {
    _sCtrl.dispose();
    _oCtrl.dispose();
    _aCtrl.dispose();
    _pCtrl.dispose();
    super.dispose();
  }

  void _emit({
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
  }) {
    widget.onChanged?.call(widget.data.copyWith(
      subjective: subjective,
      objective: objective,
      assessment: assessment,
      plan: plan,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isExpanded = constraints.maxWidth >= 840;
      final mainColumn = _buildMainColumn(context);
      Widget body;
      if (widget.aiSuggestionSlot == null) {
        body = mainColumn;
      } else if (isExpanded) {
        body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: mainColumn),
            const SizedBox(width: EdenSpacing.space4),
            Expanded(flex: 1, child: widget.aiSuggestionSlot!),
          ],
        );
      } else {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            mainColumn,
            const SizedBox(height: EdenSpacing.space4),
            widget.aiSuggestionSlot!,
          ],
        );
      }
      return Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: body,
      );
    });
  }

  Widget _buildMainColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(context, 'subjective', 'Subjective', widget.data.subjective,
            _sCtrl, (v) => _emit(subjective: v)),
        const SizedBox(height: EdenSpacing.space3),
        _section(context, 'objective', 'Objective', widget.data.objective,
            _oCtrl, (v) => _emit(objective: v)),
        const SizedBox(height: EdenSpacing.space3),
        _section(context, 'assessment', 'Assessment', widget.data.assessment,
            _aCtrl, (v) => _emit(assessment: v)),
        const SizedBox(height: EdenSpacing.space3),
        _section(context, 'plan', 'Plan', widget.data.plan, _pCtrl,
            (v) => _emit(plan: v)),
        const SizedBox(height: EdenSpacing.space3),
        _signOffSlot(context),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String sectionKey,
    String label,
    String value,
    TextEditingController controller,
    void Function(String) onChanged,
  ) {
    final theme = Theme.of(context);
    final isView = widget.mode == EdenSoapMode.view;
    final toolbar = widget.sectionToolbarSlotBuilder?.call(sectionKey);
    final voice = widget.voiceInputSlotBuilder?.call(sectionKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (toolbar != null && !isView) toolbar,
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        if (isView)
          Container(
            padding: const EdgeInsets.all(EdenSpacing.space2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(EdenRadii.sm),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: SelectableText(
              value.isEmpty ? '—' : value,
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EdenRadii.sm),
              ),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        if (voice != null && !isView) ...[
          const SizedBox(height: 4),
          voice,
        ],
      ],
    );
  }

  Widget _signOffSlot(BuildContext context) {
    final theme = Theme.of(context);
    final isView = widget.mode == EdenSoapMode.view;

    if (isView) {
      if (widget.data.signedBy != null) {
        final at = widget.data.signedAt;
        final atStr = at == null ? '' : ' on ${_formatDate(at)}';
        return Padding(
          padding: const EdgeInsets.only(top: EdenSpacing.space2),
          child: Text(
            'Signed by ${widget.data.signedBy}$atStr',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: EdenSpacing.space2),
        child: Text(
          'Unsigned draft',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (widget.signaturePadSlot == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space2),
      child: widget.signaturePadSlot!,
    );
  }
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}

// EdenInspectionFormPage — multi-section, multi-field inspection form.
//
// The library's flagship "form-with-photos-and-signature" page.
// Donor: AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/
// inspection_form_page.dart (807 LOC — largest single-file widget in the
// donor set). Port strips:
//   - flutter_riverpod → callbacks + constructor props.
//   - `package:trades/.../inspection_form_model.dart` → inlined value types.
//   - `_PhotoFieldPlaceholder` / `_SignatureFieldPlaceholder` simulating
//     capture → callback boundaries to consumer-supplied capture flows.
//
// **Companion-mode optimized:** designed to render inside an
// EdenCompanionShell content slot OR stand alone full-screen on phones.
//
// **vs EdenIntakeForm (Wave A TRD 001-10):** EdenIntakeForm is a step-wise
// branching questionnaire (one question per step + conditional visibility +
// save/resume + review). EdenInspectionFormPage is a flat multi-section
// form (all fields visible on one page, progress shown as percentage,
// scrollable). Different use cases — keep both.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/spacing.dart';
import 'eden_photo_capture_page.dart' show EdenCapturedPhoto;
import 'eden_signature_capture_page.dart' show EdenSignatureCaptureResult;

/// The 8 typed field kinds supported by [EdenInspectionFormPage].
enum EdenInspectionFieldType {
  text,
  longText,
  number,
  boolean,
  singleSelect,
  multiSelect,
  photo,
  signature,
}

/// Form lifecycle status. The page renders [submitted] forms as
/// read-only (no Submit button, fields disabled).
enum EdenInspectionFormStatus { draft, inProgress, submitted }

/// A single field in an inspection form section.
///
/// [value]'s type depends on [type]:
///   - `text` / `longText` → String?
///   - `number` → double or String (when non-numeric input fails to parse)
///   - `boolean` → bool?
///   - `singleSelect` → String? (one of [options])
///   - `multiSelect` → `List<String>` (any subset of [options])
///   - `photo` → String? (file path or stable id)
///   - `signature` → String? (stable id or 'captured' marker)
class EdenInspectionField {
  const EdenInspectionField({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.value,
    this.options = const [],
    this.helpText,
  });

  final String id;
  final String label;
  final EdenInspectionFieldType type;
  final bool isRequired;
  final Object? value;
  final List<String> options;
  final String? helpText;

  EdenInspectionField copyWith({Object? value, bool clearValue = false}) {
    return EdenInspectionField(
      id: id,
      label: label,
      type: type,
      isRequired: isRequired,
      value: clearValue ? null : (value ?? this.value),
      options: options,
      helpText: helpText,
    );
  }

  /// True when the field's value is considered "filled" for progress
  /// counting + submit gating.
  bool get isCompleted {
    if (value == null) return false;
    if (value is String && (value as String).isEmpty) return false;
    if (value is List && (value as List).isEmpty) return false;
    return true;
  }
}

/// A named group of related fields. Sections render in order; field order
/// within a section is preserved as authored.
class EdenInspectionSection {
  const EdenInspectionSection({
    required this.id,
    required this.title,
    required this.fields,
  });

  final String id;
  final String title;
  final List<EdenInspectionField> fields;

  EdenInspectionSection copyWithFields(List<EdenInspectionField> fields) {
    return EdenInspectionSection(id: id, title: title, fields: fields);
  }
}

/// Top-level form value type. Immutable; field changes flow through
/// [copyWith] + [copyWithSections] + [EdenInspectionField.copyWith].
class EdenInspectionForm {
  const EdenInspectionForm({
    required this.id,
    required this.name,
    required this.status,
    required this.sections,
    required this.createdAt,
    this.templateId,
    this.appointmentId,
    this.completedAt,
    this.submittedAt,
  });

  final String id;
  final String name;
  final EdenInspectionFormStatus status;
  final List<EdenInspectionSection> sections;
  final DateTime createdAt;
  final String? templateId;
  final String? appointmentId;
  final DateTime? completedAt;
  final DateTime? submittedAt;

  /// Total number of fields across all sections.
  int get totalFields =>
      sections.fold(0, (s, sec) => s + sec.fields.length);

  /// Number of fields with a non-empty value.
  int get completedFields => sections.fold(
      0, (s, sec) => s + sec.fields.where((f) => f.isCompleted).length);

  /// 0..1 ratio. 0 when [totalFields] is 0 (avoid NaN).
  double get completionPercent =>
      totalFields == 0 ? 0.0 : completedFields / totalFields;

  /// True when every `isRequired` field has a non-empty value.
  bool get isReadyToSubmit {
    for (final sec in sections) {
      for (final f in sec.fields) {
        if (f.isRequired && !f.isCompleted) return false;
      }
    }
    return true;
  }

  EdenInspectionForm copyWith({
    EdenInspectionFormStatus? status,
    List<EdenInspectionSection>? sections,
    DateTime? completedAt,
    DateTime? submittedAt,
  }) {
    return EdenInspectionForm(
      id: id,
      name: name,
      status: status ?? this.status,
      sections: sections ?? this.sections,
      createdAt: createdAt,
      templateId: templateId,
      appointmentId: appointmentId,
      completedAt: completedAt ?? this.completedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  EdenInspectionForm copyWithFieldUpdate(
      String sectionId, String fieldId, EdenInspectionField updated) {
    return copyWith(sections: [
      for (final s in sections)
        if (s.id == sectionId)
          s.copyWithFields([
            for (final f in s.fields) if (f.id == fieldId) updated else f,
          ])
        else
          s,
    ]);
  }
}

/// Full-page inspection form composition.
///
/// **Photo + signature capture:** when the user taps a `photo` or
/// `signature` field, the page invokes [onCapturePhoto] or
/// [onCaptureSignature] with the field. The consumer typically pushes
/// [EdenPhotoCapturePage] / [EdenSignatureCapturePage] (objective 007
/// TRDs 007-04 / 007-02) inside the callback and returns the result.
/// When the callback is null, a SnackBar surfaces
/// "Photo capture not configured" / "Signature capture not configured".
///
/// **Submit gating:** the Submit FilledButton is enabled only when
/// [EdenInspectionForm.isReadyToSubmit] is true (every required field
/// has a non-empty value). When disabled, the label reads "Complete
/// required fields to submit".
class EdenInspectionFormPage extends StatefulWidget {
  const EdenInspectionFormPage({
    super.key,
    required this.form,
    this.onSaveDraft,
    this.onSubmit,
    this.onCapturePhoto,
    this.onCaptureSignature,
  });

  final EdenInspectionForm form;
  final Future<EdenInspectionForm> Function(EdenInspectionForm form)?
      onSaveDraft;
  final Future<EdenInspectionForm> Function(EdenInspectionForm form)?
      onSubmit;
  final Future<EdenCapturedPhoto?> Function(EdenInspectionField field)?
      onCapturePhoto;
  final Future<EdenSignatureCaptureResult?> Function(EdenInspectionField field)?
      onCaptureSignature;

  @override
  State<EdenInspectionFormPage> createState() => _EdenInspectionFormPageState();
}

class _EdenInspectionFormPageState extends State<EdenInspectionFormPage> {
  late EdenInspectionForm _localForm;
  bool _isSubmitting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _localForm = widget.form;
  }

  @override
  void didUpdateWidget(covariant EdenInspectionFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.form != widget.form) {
      setState(() => _localForm = widget.form);
    }
  }

  bool get _isSubmitted =>
      _localForm.status == EdenInspectionFormStatus.submitted;

  void _updateField(String sectionId, EdenInspectionField updated) {
    setState(() {
      _localForm =
          _localForm.copyWithFieldUpdate(sectionId, updated.id, updated);
    });
  }

  Future<void> _saveDraft() async {
    if (widget.onSaveDraft == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final persisted = await widget.onSaveDraft!.call(_localForm);
      if (!mounted) return;
      setState(() => _localForm = persisted);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Draft saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Save failed: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_localForm.isReadyToSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete all required fields to submit'),
      ));
      return;
    }
    if (widget.onSubmit == null) return;
    setState(() => _isSubmitting = true);
    try {
      final persisted = await widget.onSubmit!.call(_localForm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Form submitted successfully'),
        backgroundColor: Color(0xFF22C55E),
      ));
      Navigator.of(context).pop(persisted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Submit failed: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _capturePhoto(
      String sectionId, EdenInspectionField field) async {
    if (widget.onCapturePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Photo capture not configured'),
      ));
      return;
    }
    final photo = await widget.onCapturePhoto!.call(field);
    if (!mounted || photo == null) return;
    _updateField(sectionId, field.copyWith(value: photo.filePath));
  }

  Future<void> _captureSignature(
      String sectionId, EdenInspectionField field) async {
    if (widget.onCaptureSignature == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Signature capture not configured'),
      ));
      return;
    }
    final result = await widget.onCaptureSignature!.call(field);
    if (!mounted || result == null) return;
    _updateField(sectionId,
        field.copyWith(value: '${result.strokes.length} stroke(s)'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_localForm.completionPercent * 100).round();
    final progressColor =
        percent >= 100 ? const Color(0xFF22C55E) : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_localForm.name),
        actions: [
          if (!_isSubmitted &&
              !_isSaving &&
              widget.onSaveDraft != null)
            TextButton(
              onPressed: _saveDraft,
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4, vertical: EdenSpacing.space3),
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_localForm.completedFields} of ${_localForm.totalFields} fields',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$percent% complete',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _localForm.completionPercent,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _isSubmitted ? _submittedBody() : _activeBody()),
        ],
      ),
      bottomNavigationBar: _isSubmitted
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(EdenSpacing.space4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (_localForm.isReadyToSubmit &&
                            !_isSubmitting &&
                            widget.onSubmit != null)
                        ? _submit
                        : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting...'
                          : (_localForm.isReadyToSubmit
                              ? 'Submit Form'
                              : 'Complete required fields to submit'),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _submittedBody() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 64),
          const SizedBox(height: 12),
          Text('Form Submitted', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'This form has been submitted and is read-only.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeBody() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      itemCount: _localForm.sections.length,
      itemBuilder: (ctx, i) {
        final section = _localForm.sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: EdenSpacing.space3, bottom: EdenSpacing.space2),
              child: Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              height: 1,
            ),
            for (final field in section.fields)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
                child: _FieldWidget(
                  field: field,
                  enabled: !_isSubmitted,
                  onValueChanged: (v) =>
                      _updateField(section.id, field.copyWith(value: v)),
                  onTapPhoto: () => _capturePhoto(section.id, field),
                  onTapSignature: () => _captureSignature(section.id, field),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FieldWidget extends StatefulWidget {
  const _FieldWidget({
    required this.field,
    required this.enabled,
    required this.onValueChanged,
    required this.onTapPhoto,
    required this.onTapSignature,
  });

  final EdenInspectionField field;
  final bool enabled;
  final ValueChanged<Object?> onValueChanged;
  final VoidCallback onTapPhoto;
  final VoidCallback onTapSignature;

  @override
  State<_FieldWidget> createState() => _FieldWidgetState();
}

class _FieldWidgetState extends State<_FieldWidget> {
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    if (widget.field.type == EdenInspectionFieldType.text ||
        widget.field.type == EdenInspectionFieldType.longText ||
        widget.field.type == EdenInspectionFieldType.number) {
      _textController =
          TextEditingController(text: widget.field.value?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  Widget _buildLabel(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.field.label,
                style: theme.textTheme.labelLarge),
          ),
          if (widget.field.isRequired)
            const Text(' *',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = widget.field;
    switch (field.type) {
      case EdenInspectionFieldType.text:
      case EdenInspectionFieldType.longText:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context),
            TextFormField(
              controller: _textController,
              enabled: widget.enabled,
              maxLines: field.type == EdenInspectionFieldType.longText
                  ? null
                  : 3,
              minLines:
                  field.type == EdenInspectionFieldType.longText ? 3 : null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (v) => widget.onValueChanged(v),
            ),
          ],
        );
      case EdenInspectionFieldType.number:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context),
            TextFormField(
              controller: _textController,
              enabled: widget.enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                widget.onValueChanged(parsed ?? (v.isEmpty ? null : v));
              },
            ),
          ],
        );
      case EdenInspectionFieldType.boolean:
        final value = field.value == true;
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: SwitchListTile(
            title: Row(
              children: [
                Expanded(child: Text(field.label)),
                if (field.isRequired)
                  const Text(' *',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700)),
              ],
            ),
            value: value,
            onChanged: widget.enabled
                ? (v) => widget.onValueChanged(v)
                : null,
          ),
        );
      case EdenInspectionFieldType.singleSelect:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context),
            DropdownButtonFormField<String>(
              initialValue: field.value as String?,
              hint: const Text('Select an option'),
              items: [
                for (final opt in field.options)
                  DropdownMenuItem(value: opt, child: Text(opt)),
              ],
              onChanged: widget.enabled ? widget.onValueChanged : null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        );
      case EdenInspectionFieldType.multiSelect:
        final current =
            (field.value as List?)?.cast<String>() ?? const <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final opt in field.options)
                  FilterChip(
                    label: Text(opt),
                    selected: current.contains(opt),
                    onSelected: widget.enabled
                        ? (sel) {
                            final next = List<String>.of(current);
                            if (sel) {
                              if (!next.contains(opt)) next.add(opt);
                            } else {
                              next.remove(opt);
                            }
                            widget.onValueChanged(next);
                          }
                        : null,
                  ),
              ],
            ),
          ],
        );
      case EdenInspectionFieldType.photo:
        final captured = field.value != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context),
            InkWell(
              key: ValueKey('eden_insp_photo_${field.id}'),
              onTap: widget.enabled ? widget.onTapPhoto : null,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        captured
                            ? Icons.check_circle
                            : Icons.camera_alt_outlined,
                        color: captured
                            ? const Color(0xFF22C55E)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(captured
                          ? 'Photo captured — tap to retake'
                          : 'Tap to capture photo'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case EdenInspectionFieldType.signature:
        final captured = field.value != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context),
            InkWell(
              key: ValueKey('eden_insp_sig_${field.id}'),
              onTap: widget.enabled ? widget.onTapSignature : null,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        captured ? Icons.check_circle : Icons.draw,
                        color: captured
                            ? const Color(0xFF22C55E)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(captured
                          ? 'Signature captured'
                          : 'Tap to sign'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

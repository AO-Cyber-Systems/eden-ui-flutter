import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_date_picker.dart';

/// Supported question types in [EdenIntakeForm].
enum EdenIntakeQuestionType { text, longText, singleChoice, multipleChoice, number, date, yesNo }

/// A single question in an [EdenIntakeForm] schema.
///
/// Questions are declarative: the caller provides a list of these and the
/// widget renders them one-per-step with conditional visibility, validation,
/// and a final review step.
@immutable
class EdenIntakeQuestion {
  /// Creates an intake question.
  const EdenIntakeQuestion({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.visibleWhen,
    this.validate,
    this.placeholder,
  });

  /// Stable identifier (used as the key in the answers map).
  final String id;

  /// Display label / question text.
  final String label;

  /// Question type — drives the rendered input control.
  final EdenIntakeQuestionType type;

  /// When true, the question must have a non-empty answer before the form
  /// can advance past it.
  final bool required;

  /// Choice options for [EdenIntakeQuestionType.singleChoice] and
  /// [EdenIntakeQuestionType.multipleChoice].
  final List<String>? options;

  /// Conditional-visibility predicate. The question is rendered only when
  /// this returns true (or when null).
  ///
  /// Note: predicates use the LIVE answers map. If the user goes back and
  /// changes a previous answer, downstream questions may become visible /
  /// hidden on the next step advance.
  final bool Function(Map<String, dynamic> answers)? visibleWhen;

  /// Optional custom validator. Returns an error message string, or null
  /// when the answer passes.
  final String? Function(dynamic answer)? validate;

  /// Placeholder / hint shown inside the input for text-style questions.
  final String? placeholder;
}

/// A declarative branching intake questionnaire.
///
/// Renders one question per step. Caller provides a [questions] schema; the
/// widget handles validation, branching (`visibleWhen`), save+resume via
/// [onPartialSave], and a final review-and-submit step.
///
/// Used by medical intake, legal client intake, government case intake,
/// salon onboarding, retail loyalty signup.
///
/// Transport-agnostic: emits a `Map<String, dynamic>` (questionId → answer)
/// via [onComplete]. The library does NOT persist.
class EdenIntakeForm extends StatefulWidget {
  /// Creates an intake form widget.
  const EdenIntakeForm({
    super.key,
    required this.questions,
    this.initialAnswers = const <String, dynamic>{},
    this.onPartialSave,
    required this.onComplete,
    this.onCancel,
  });

  /// The declarative question schema, in display order.
  final List<EdenIntakeQuestion> questions;

  /// Initial answer values (used for resume scenarios).
  final Map<String, dynamic> initialAnswers;

  /// Invoked on each step advance with the current answers map.
  /// Caller persists for save+resume.
  final ValueChanged<Map<String, dynamic>>? onPartialSave;

  /// Invoked when the user submits on the review step.
  final ValueChanged<Map<String, dynamic>> onComplete;

  /// Invoked when the user cancels.
  final VoidCallback? onCancel;

  @override
  State<EdenIntakeForm> createState() => _EdenIntakeFormState();
}

class _EdenIntakeFormState extends State<EdenIntakeForm> {
  late Map<String, dynamic> _answers;

  /// Per-question text controllers (lazy-created in didChangeDependencies).
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  /// Index into the *visible-questions* list. The visible list is
  /// recomputed every build from [widget.questions] using each question's
  /// `visibleWhen` predicate.
  int _visibleIndex = 0;

  /// `true` when we've passed the last visible question and the review
  /// step should be displayed.
  bool _onReview = false;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, dynamic>.from(widget.initialAnswers);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The visible-questions list, recomputed each call to reflect the
  /// current `_answers` snapshot.
  List<EdenIntakeQuestion> get _visibleQuestions {
    return widget.questions
        .where((q) => q.visibleWhen?.call(_answers) ?? true)
        .toList();
  }

  TextEditingController _controllerFor(EdenIntakeQuestion q) {
    final c = _controllers.putIfAbsent(
      q.id,
      () => TextEditingController(text: _initialControllerText(q)),
    );
    // If the answer changed externally (resume / back-edit), sync.
    final desired = _initialControllerText(q);
    if (c.text != desired && desired.isNotEmpty && c.text.isEmpty) {
      c.text = desired;
    }
    return c;
  }

  String _initialControllerText(EdenIntakeQuestion q) {
    final v = _answers[q.id];
    if (v == null) return '';
    if (v is String) return v;
    if (v is num) return v.toString();
    return v.toString();
  }

  bool _hasAnswerFor(EdenIntakeQuestion q) {
    final v = _answers[q.id];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true; // bool, num, DateTime: presence == answered
  }

  bool _canAdvance() {
    if (_onReview) return true;
    final visible = _visibleQuestions;
    if (_visibleIndex >= visible.length) return true;
    final q = visible[_visibleIndex];
    if (q.required && !_hasAnswerFor(q)) return false;
    if (q.validate != null) {
      final err = q.validate!(_answers[q.id]);
      if (err != null) return false;
    }
    return true;
  }

  void _goNext() {
    if (!_canAdvance()) return;
    widget.onPartialSave?.call(Map<String, dynamic>.from(_answers));
    final visible = _visibleQuestions;
    if (_visibleIndex >= visible.length - 1) {
      // Last visible question — advance to review.
      setState(() {
        _onReview = true;
        _visibleIndex = visible.length;
      });
    } else {
      setState(() => _visibleIndex++);
    }
  }

  void _goBack() {
    if (_onReview) {
      setState(() {
        _onReview = false;
        _visibleIndex = _visibleQuestions.length - 1;
      });
      return;
    }
    if (_visibleIndex > 0) {
      setState(() => _visibleIndex--);
    }
  }

  void _submit() {
    // Strip answers for questions that are not currently visible (so
    // skipped-branch answers don't leak into the final result).
    final visibleIds = _visibleQuestions.map((q) => q.id).toSet();
    final clean = <String, dynamic>{};
    _answers.forEach((k, v) {
      if (visibleIds.contains(k)) clean[k] = v;
    });
    widget.onComplete(clean);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: _onReview ? _buildReview(context) : _buildQuestion(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: _buildActions(context),
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final visible = _visibleQuestions;
    if (visible.isEmpty) {
      return const Text('No questions to display.');
    }
    final q = visible[_visibleIndex.clamp(0, visible.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          q.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EdenSpacing.space3),
        _buildInputFor(q),
      ],
    );
  }

  Widget _buildInputFor(EdenIntakeQuestion q) {
    switch (q.type) {
      case EdenIntakeQuestionType.text:
        return TextField(
          key: ValueKey<String>('input_${q.id}'),
          controller: _controllerFor(q),
          decoration: InputDecoration(hintText: q.placeholder),
          onChanged: (v) => setState(() => _answers[q.id] = v),
        );
      case EdenIntakeQuestionType.longText:
        return TextField(
          key: ValueKey<String>('input_${q.id}'),
          controller: _controllerFor(q),
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(hintText: q.placeholder),
          onChanged: (v) => setState(() => _answers[q.id] = v),
        );
      case EdenIntakeQuestionType.singleChoice:
        return Column(
          children: <Widget>[
            for (final opt in q.options ?? const <String>[])
              RadioListTile<String>(
                key: ValueKey<String>('opt_${q.id}_$opt'),
                title: Text(opt),
                value: opt,
                groupValue: _answers[q.id] as String?,
                onChanged: (v) => setState(() => _answers[q.id] = v),
              ),
          ],
        );
      case EdenIntakeQuestionType.multipleChoice:
        final List<String> selected =
            (_answers[q.id] as List<String>? ?? <String>[]);
        return Column(
          children: <Widget>[
            for (final opt in q.options ?? const <String>[])
              CheckboxListTile(
                key: ValueKey<String>('opt_${q.id}_$opt'),
                title: Text(opt),
                value: selected.contains(opt),
                onChanged: (v) => setState(() {
                  final next = List<String>.from(selected);
                  if (v == true) {
                    if (!next.contains(opt)) next.add(opt);
                  } else {
                    next.remove(opt);
                  }
                  _answers[q.id] = next;
                }),
              ),
          ],
        );
      case EdenIntakeQuestionType.number:
        return TextField(
          key: ValueKey<String>('input_${q.id}'),
          controller: _controllerFor(q),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: q.placeholder),
          onChanged: (v) {
            final parsed = num.tryParse(v);
            setState(() => _answers[q.id] = parsed);
          },
        );
      case EdenIntakeQuestionType.date:
        return EdenDatePicker(
          key: ValueKey<String>('input_${q.id}'),
          value: _answers[q.id] as DateTime?,
          onChanged: (d) => setState(() => _answers[q.id] = d),
        );
      case EdenIntakeQuestionType.yesNo:
        final bool? current = _answers[q.id] as bool?;
        return Row(
          children: <Widget>[
            EdenButton(
              label: 'Yes',
              variant: current == true
                  ? EdenButtonVariant.primary
                  : EdenButtonVariant.secondary,
              onPressed: () => setState(() => _answers[q.id] = true),
            ),
            const SizedBox(width: EdenSpacing.space2),
            EdenButton(
              label: 'No',
              variant: current == false
                  ? EdenButtonVariant.primary
                  : EdenButtonVariant.secondary,
              onPressed: () => setState(() => _answers[q.id] = false),
            ),
          ],
        );
    }
  }

  Widget _buildReview(BuildContext context) {
    final visible = _visibleQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Review',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: EdenSpacing.space3),
        for (final q in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(q.label,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: EdenSpacing.space1),
                Text(_formatAnswer(_answers[q.id])),
              ],
            ),
          ),
      ],
    );
  }

  String _formatAnswer(dynamic v) {
    if (v == null) return '(no answer)';
    if (v is List) return v.join(', ');
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is DateTime) {
      final y = v.year.toString().padLeft(4, '0');
      final m = v.month.toString().padLeft(2, '0');
      final d = v.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return v.toString();
  }

  Widget _buildActions(BuildContext context) {
    final bool isFirst = !_onReview && _visibleIndex == 0;
    return Row(
      children: <Widget>[
        if (widget.onCancel != null)
          EdenButton(
            label: 'Cancel',
            variant: EdenButtonVariant.ghost,
            onPressed: widget.onCancel,
          ),
        const Spacer(),
        if (!isFirst)
          EdenButton(
            label: 'Back',
            variant: EdenButtonVariant.secondary,
            onPressed: _goBack,
          ),
        const SizedBox(width: EdenSpacing.space2),
        if (_onReview)
          EdenButton(
            label: 'Submit',
            variant: EdenButtonVariant.primary,
            onPressed: _submit,
          )
        else
          EdenButton(
            label: 'Next',
            variant: EdenButtonVariant.primary,
            onPressed: _canAdvance() ? _goNext : null,
          ),
      ],
    );
  }
}

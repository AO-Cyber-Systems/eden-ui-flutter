import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    // RED-phase stub.
    return const Placeholder();
  }
}

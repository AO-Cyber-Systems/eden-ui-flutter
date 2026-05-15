import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_signature_pad.dart';

/// A single clause in an [EdenConsentFlow] consent ladder.
///
/// Each clause renders a Checkbox + clause body. When [requireAffirmation] is
/// true, an additional "I understand" affirmation checkbox is shown beneath
/// the clause and must also be checked before the user can advance.
@immutable
class EdenConsentClause {
  /// Creates a consent clause.
  const EdenConsentClause({
    required this.id,
    required this.title,
    required this.body,
    this.requireAffirmation = false,
  });

  /// Stable identifier (returned in [EdenConsentRecord.acceptedClauses]).
  final String id;

  /// Short heading shown above the clause body (e.g. "Privacy Policy").
  final String title;

  /// The full clause text the user must read and accept.
  final String body;

  /// When true, the clause also requires an explicit "I understand"
  /// affirmation checkbox above and beyond the main accept checkbox.
  final bool requireAffirmation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EdenConsentClause &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.requireAffirmation == requireAffirmation;
  }

  @override
  int get hashCode => Object.hash(id, title, body, requireAffirmation);
}

/// The output of a completed [EdenConsentFlow].
///
/// Transport-agnostic — the library does NOT persist this; the caller decides
/// where to send it (HTTP, local store, audit log, etc.).
@immutable
class EdenConsentRecord {
  /// Creates a consent record.
  const EdenConsentRecord({
    required this.acceptedClauses,
    required this.primarySignature,
    required this.capturedAt,
    this.witnessName,
    this.witnessSignature,
    this.metadata = const <String, String>{},
  });

  /// Map of clause `id` → true (every clause that gated the flow).
  final Map<String, bool> acceptedClauses;

  /// The signer's signature strokes (captured by the embedded
  /// [EdenSignaturePad]). Callers can rasterise these to PNG/SVG.
  ///
  /// We retain strokes rather than pre-rasterised bytes so consumers can
  /// archive at any resolution and so the data round-trips losslessly.
  final List<EdenSignatureStroke> primarySignature;

  /// Wall-clock time consent was finalised.
  final DateTime capturedAt;

  /// Witness's name (only set when the flow was constructed with
  /// `requireWitness: true`).
  final String? witnessName;

  /// Witness's signature strokes (only set when `requireWitness: true`).
  final List<EdenSignatureStroke>? witnessSignature;

  /// Caller-supplied audit metadata (IP address, user-agent, tenant id, etc.).
  ///
  /// The library does NOT compute these — the caller passes them in via
  /// [EdenConsentFlow.metadata] and they round-trip into the record.
  final Map<String, String> metadata;
}

/// A guided consent capture flow.
///
/// Composes an explicit clause-acceptance ladder above the existing
/// [EdenSignaturePad] primitive. Used by medical (informed consent for
/// procedures), legal (engagement agreements), government (Privacy Act
/// notices, attestation forms), fuel (hazmat acknowledgment), and retail
/// (return / refund agreements).
///
/// Flow:
/// 1. Clauses step — Checkbox per clause + optional "I understand"
///    affirmation. Cannot advance until all are checked.
/// 2. Signature step — primary signer uses an [EdenSignaturePad].
/// 3. (Optional) Witness step — witness name + second signature pad.
/// 4. Review step — displays accepted clauses + signature preview + a
///    "Submit consent" button that emits an [EdenConsentRecord] via
///    [onComplete].
///
/// The widget is transport-agnostic. It captures data and emits a record;
/// caller persists.
class EdenConsentFlow extends StatefulWidget {
  /// Creates a consent flow widget.
  const EdenConsentFlow({
    super.key,
    required this.clauses,
    this.requireWitness = false,
    this.metadata = const <String, String>{},
    required this.onComplete,
    this.onCancel,
  }) : assert(
          // ignore: prefer_is_empty
          clauses.length > 0,
          'EdenConsentFlow requires at least one clause',
        );

  /// The list of clauses the signer must accept, in display order.
  final List<EdenConsentClause> clauses;

  /// When true, a witness step is inserted after the primary signature.
  final bool requireWitness;

  /// Caller-supplied audit metadata; round-tripped into [EdenConsentRecord].
  final Map<String, String> metadata;

  /// Invoked when the signer submits on the review step.
  final ValueChanged<EdenConsentRecord> onComplete;

  /// Invoked when the signer taps Cancel.
  final VoidCallback? onCancel;

  @override
  State<EdenConsentFlow> createState() => _EdenConsentFlowState();
}

enum _ConsentStep { clauses, signature, witness, review }

class _EdenConsentFlowState extends State<EdenConsentFlow> {
  late final List<_ConsentStep> _steps;
  int _currentStepIndex = 0;

  /// Tracks acceptance state per clause id, including affirmation states.
  final Map<String, bool> _accepted = <String, bool>{};
  final Map<String, bool> _affirmed = <String, bool>{};

  List<EdenSignatureStroke> _primarySignature = <EdenSignatureStroke>[];
  List<EdenSignatureStroke> _witnessSignature = <EdenSignatureStroke>[];
  final TextEditingController _witnessNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _steps = <_ConsentStep>[
      _ConsentStep.clauses,
      _ConsentStep.signature,
      if (widget.requireWitness) _ConsentStep.witness,
      _ConsentStep.review,
    ];
    for (final clause in widget.clauses) {
      _accepted[clause.id] = false;
      if (clause.requireAffirmation) {
        _affirmed[clause.id] = false;
      }
    }
  }

  @override
  void dispose() {
    _witnessNameController.dispose();
    super.dispose();
  }

  bool get _clausesComplete {
    for (final clause in widget.clauses) {
      if (_accepted[clause.id] != true) return false;
      if (clause.requireAffirmation && _affirmed[clause.id] != true) {
        return false;
      }
    }
    return true;
  }

  bool get _signatureComplete => _primarySignature.isNotEmpty;

  bool get _witnessComplete =>
      _witnessNameController.text.trim().isNotEmpty &&
      _witnessSignature.isNotEmpty;

  bool get _canAdvance {
    switch (_steps[_currentStepIndex]) {
      case _ConsentStep.clauses:
        return _clausesComplete;
      case _ConsentStep.signature:
        return _signatureComplete;
      case _ConsentStep.witness:
        return _witnessComplete;
      case _ConsentStep.review:
        return true;
    }
  }

  void _goNext() {
    if (!_canAdvance) return;
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
    }
  }

  void _goBack() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  void _submit() {
    final record = EdenConsentRecord(
      acceptedClauses: Map<String, bool>.unmodifiable(
        <String, bool>{
          for (final clause in widget.clauses) clause.id: true,
        },
      ),
      primarySignature: List<EdenSignatureStroke>.unmodifiable(
        _primarySignature,
      ),
      capturedAt: DateTime.now(),
      witnessName: widget.requireWitness
          ? _witnessNameController.text.trim()
          : null,
      witnessSignature: widget.requireWitness
          ? List<EdenSignatureStroke>.unmodifiable(_witnessSignature)
          : null,
      metadata: Map<String, String>.unmodifiable(widget.metadata),
    );
    widget.onComplete(record);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: switch (step) {
              _ConsentStep.clauses => _buildClausesStep(context),
              _ConsentStep.signature => _buildSignatureStep(context),
              _ConsentStep.witness => _buildWitnessStep(context),
              _ConsentStep.review => _buildReviewStep(context),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: _buildActions(context, step),
        ),
      ],
    );
  }

  Widget _buildClausesStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final clause in widget.clauses)
          Padding(
            padding: const EdgeInsets.only(bottom: EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  clause.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: EdenSpacing.space1),
                Text(clause.body),
                CheckboxListTile(
                  key: ValueKey<String>('accept_${clause.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('I accept the ${clause.title}'),
                  value: _accepted[clause.id] ?? false,
                  onChanged: (bool? v) =>
                      setState(() => _accepted[clause.id] = v ?? false),
                ),
                if (clause.requireAffirmation)
                  CheckboxListTile(
                    key: ValueKey<String>('affirm_${clause.id}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I understand'),
                    value: _affirmed[clause.id] ?? false,
                    onChanged: (bool? v) =>
                        setState(() => _affirmed[clause.id] = v ?? false),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSignatureStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Sign below',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenSignaturePad(
          key: const ValueKey<String>('primary_signature_pad'),
          initialStrokes: _primarySignature,
          onSignatureChanged: (List<EdenSignatureStroke> strokes) {
            setState(() => _primarySignature = strokes);
          },
        ),
      ],
    );
  }

  Widget _buildWitnessStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Witness',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextField(
          key: const ValueKey<String>('witness_name_field'),
          controller: _witnessNameController,
          decoration: const InputDecoration(
            labelText: 'Witness full name',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: EdenSpacing.space3),
        EdenSignaturePad(
          key: const ValueKey<String>('witness_signature_pad'),
          initialStrokes: _witnessSignature,
          onSignatureChanged: (List<EdenSignatureStroke> strokes) {
            setState(() => _witnessSignature = strokes);
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Review',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: EdenSpacing.space3),
        Text(
          'Accepted clauses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final clause in widget.clauses)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
            child: Row(
              children: <Widget>[
                const Icon(Icons.check, size: 16),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(child: Text(clause.title)),
              ],
            ),
          ),
        const SizedBox(height: EdenSpacing.space3),
        Text(
          'Signature',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenSignaturePad(
          key: const ValueKey<String>('primary_signature_preview'),
          initialStrokes: _primarySignature,
          readOnly: true,
          showControls: false,
          height: 120,
        ),
        if (widget.requireWitness) ...<Widget>[
          const SizedBox(height: EdenSpacing.space3),
          Text(
            'Witness: ${_witnessNameController.text.trim()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EdenSpacing.space2),
          EdenSignaturePad(
            key: const ValueKey<String>('witness_signature_preview'),
            initialStrokes: _witnessSignature,
            readOnly: true,
            showControls: false,
            height: 120,
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, _ConsentStep step) {
    final bool isFirst = _currentStepIndex == 0;
    final bool isLast = step == _ConsentStep.review;
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
        if (isLast)
          EdenButton(
            label: 'Submit consent',
            variant: EdenButtonVariant.primary,
            onPressed: _submit,
          )
        else
          EdenButton(
            label: 'Next',
            variant: EdenButtonVariant.primary,
            onPressed: _canAdvance ? _goNext : null,
          ),
      ],
    );
  }
}

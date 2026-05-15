import 'package:flutter/material.dart';

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
  /// signature pad). Callers can rasterise these to PNG/SVG.
  ///
  /// We retain strokes rather than pre-rasterised bytes so consumers can
  /// archive at any resolution and so the data round-trips losslessly.
  ///
  /// Typed as `List<Object>` here to avoid leaking the signature-pad's
  /// internal `EdenSignatureStroke` type into the record's import surface;
  /// downstream callers can cast back to `List<EdenSignatureStroke>`.
  final List<Object> primarySignature;

  /// Wall-clock time consent was finalised.
  final DateTime capturedAt;

  /// Witness's name (only set when the flow was constructed with
  /// `requireWitness: true`).
  final String? witnessName;

  /// Witness's signature strokes (only set when `requireWitness: true`).
  final List<Object>? witnessSignature;

  /// Caller-supplied audit metadata (IP address, user-agent, tenant id, etc.).
  ///
  /// The library does NOT compute these — the caller passes them in via
  /// [EdenConsentFlow.metadata] and they round-trip into the record.
  final Map<String, String> metadata;
}

/// A guided consent capture flow.
///
/// TODO(001-09): implement the staged clauses → signature → witness → review
/// flow per TRD 001-09. This is a deliberate stub; widget tests are RED until
/// the implementation lands in the GREEN commit.
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

class _EdenConsentFlowState extends State<EdenConsentFlow> {
  @override
  Widget build(BuildContext context) {
    // Stub renders a placeholder so the widget tree mounts and tests fail
    // on assertion of the real behavior rather than failing at build-time.
    return const Placeholder();
  }
}

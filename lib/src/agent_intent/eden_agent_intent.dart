import 'package:flutter/foundation.dart';

/// One entry of an intent's `actions[]`, exactly as the wire carries it.
///
/// THE WIRE PERMITS NONSENSE, AND THIS TYPE SAYS SO. eden-biz sends every
/// action through one Go struct:
///
/// ```go
/// type Action struct {
///   ID         string `json:"id"`
///   ToolID     string `json:"tool_id,omitempty"`
///   ProposalID string `json:"proposal_id,omitempty"`
///   Decision   string `json:"decision,omitempty"`
/// }
/// ```
///
/// Every binding field is `omitempty`, so `{"id": "approve"}` — bound to
/// nothing a caller could invoke — decodes cleanly, and so does an action
/// carrying both a tool and a proposal. All three are nullable here because
/// pretending otherwise would mean inventing a binding at parse time, which
/// is the one place that must not happen: a fabricated `tool_id` is
/// something the dispatcher would hand back to be CALLED.
///
/// Deciding what is bindable belongs to the decoder and the components,
/// which already refuse an empty `decision` and a `proposal_id` that names a
/// different proposal.
@immutable
class EdenRawAction {
  const EdenRawAction({
    required this.id,
    this.toolId,
    this.proposalId,
    this.decision,
  });

  /// Wire key: `id`. The only field the Go struct does not mark omitempty.
  final String id;

  /// Wire key: `tool_id`. Null when absent — never `''`, so "no binding" and
  /// "a binding to the empty string" stay distinguishable.
  final String? toolId;

  /// Wire key: `proposal_id`.
  final String? proposalId;

  /// Wire key: `decision`.
  final String? decision;

  /// True when this action names a tool to invoke.
  bool get bindsTool => toolId != null && toolId!.isNotEmpty;

  /// True when this action decides a proposal.
  bool get bindsProposal =>
      proposalId != null &&
      proposalId!.isNotEmpty &&
      decision != null &&
      decision!.isNotEmpty;

  /// `null` -> `null`; `''` -> `null`.
  ///
  /// Go's `omitempty` cannot distinguish an absent string from an empty one
  /// on the way out, so both arrive meaning the same thing and are collapsed
  /// to the same thing here.
  static String? _str(Object? v) {
    if (v is! String || v.isEmpty) return null;
    return v;
  }

  static EdenRawAction fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('agent intent: an action has no "id"');
    }
    return EdenRawAction(
      id: id,
      toolId: _str(json['tool_id']),
      proposalId: _str(json['proposal_id']),
      decision: _str(json['decision']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EdenRawAction &&
      other.id == id &&
      other.toolId == toolId &&
      other.proposalId == proposalId &&
      other.decision == decision;

  @override
  int get hashCode => Object.hash(id, toolId, proposalId, decision);

  @override
  String toString() => 'EdenRawAction($id'
      '${toolId != null ? ' tool=$toolId' : ''}'
      '${proposalId != null ? ' proposal=$proposalId/$decision' : ''})';
}

/// An agent's intent envelope: `{component_id, data, actions}`.
///
/// `data` STAYS RAW HERE, deliberately. Turning it into one of the typed
/// data classes is the decoder's job, and keeping the two apart means a
/// malformed `data` cannot stop the envelope from being read well enough to
/// NAME the component that failed. An envelope that refused to parse at all
/// would leave the refusal unable to say what it was refusing.
@immutable
class EdenAgentIntent {
  const EdenAgentIntent({
    required this.componentId,
    required this.data,
    required this.actions,
  });

  /// Wire key: `component_id`. A free string — nothing on the wire
  /// constrains it to an id this package can draw.
  final String componentId;

  /// Wire key: `data`, undecoded.
  final Object? data;

  /// Wire key: `actions`. EMPTY, never null, when the key is absent:
  /// "the payload granted nothing" is read-only, which is a real and correct
  /// state rather than missing information.
  final List<EdenRawAction> actions;

  /// Throws [FormatException] naming the field when the envelope itself is
  /// unreadable.
  ///
  /// THROWING IS CORRECT HERE and does not break the layer's "never crash"
  /// rule: that rule binds the PUBLIC entry point, which catches this and
  /// returns a refusal naming the field. A private helper signalling with an
  /// exception is not a crash reaching a caller.
  static EdenAgentIntent fromJson(Map<String, dynamic> json) {
    final Object? id = json['component_id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException(
        'agent intent: "component_id" is missing or not a non-empty string',
      );
    }

    final Object? rawActions = json['actions'];
    final List<EdenRawAction> actions = <EdenRawAction>[];
    if (rawActions != null) {
      if (rawActions is! List) {
        throw FormatException(
          'agent intent: "actions" is ${rawActions.runtimeType}, want a list',
        );
      }
      for (final Object? a in rawActions) {
        if (a is! Map<String, dynamic>) {
          throw FormatException(
            'agent intent: an entry of "actions" is ${a.runtimeType}, '
            'want an object',
          );
        }
        actions.add(EdenRawAction.fromJson(a));
      }
    }

    return EdenAgentIntent(
      componentId: id,
      data: json['data'],
      actions: List<EdenRawAction>.unmodifiable(actions),
    );
  }
}

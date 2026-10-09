import 'package:flutter/foundation.dart';

/// An action the user fired, on its way back to whoever owns transport.
///
/// SEALED AND SPLIT BY KIND, because the two are not interchangeable: one
/// asks for a tool to be CALLED, the other records a DECISION on a pending
/// mutation. A single bag with nullable fields would let a caller invoke a
/// decision or decide a tool, and nothing would catch it.
///
/// THIS LAYER INVOKES NOTHING. It hands back what the payload granted; the
/// caller owns the transport. In particular nothing here is, or becomes, a
/// route — binding an action to navigation would send the user somewhere the
/// grant never covered, which is why `eden_intent_dispatcher_test` scans
/// this directory's source for `Navigator` and friends rather than trusting
/// a comment.
@immutable
sealed class EdenFiredAction {
  const EdenFiredAction({required this.actionId});

  /// The `intent.actions[].id` the user fired.
  final String actionId;
}

/// A tool the payload granted, with the row it was fired on.
@immutable
final class EdenFiredToolAction extends EdenFiredAction {
  const EdenFiredToolAction({
    required super.actionId,
    required this.toolId,
    this.target,
  });

  /// `intent.actions[].tool_id`. Handed back, never interpreted here.
  final String toolId;

  /// The row pressed, for a list component — `intent.actions` is
  /// COMPONENT-level with no per-row binding, so row identity comes from the
  /// press and is the other half of the invocation. Null for a component
  /// with no rows.
  final Object? target;

  @override
  String toString() => 'EdenFiredToolAction($actionId -> $toolId)';
}

/// A decision on a pending proposal.
@immutable
final class EdenFiredProposalDecision extends EdenFiredAction {
  const EdenFiredProposalDecision({
    required super.actionId,
    required this.proposalId,
    required this.decision,
  });

  /// `intent.actions[].proposal_id`, already checked against
  /// `intent.data.action_id` by [EdenProposalCard] before any control for it
  /// was drawn.
  final String proposalId;

  /// `intent.actions[].decision`.
  final String decision;

  @override
  String toString() =>
      'EdenFiredProposalDecision($actionId -> $proposalId/$decision)';
}

/// Where fired actions go. Null means the surface is read-only: a granted
/// action with nowhere to send it would be an affordance that does nothing.
typedef EdenIntentActionSink = void Function(EdenFiredAction fired);

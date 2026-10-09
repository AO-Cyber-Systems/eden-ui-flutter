import 'package:flutter/widgets.dart';

import '../widgets/eden_data_display/eden_data_display_exports.dart';
import 'eden_agent_intent.dart';
import 'eden_intent_decoder.dart';
import 'eden_intent_egress.dart';
import 'eden_intent_host_context.dart';

/// Everything a builder needs to draw one decoded intent.
@immutable
class EdenIntentRenderRequest {
  const EdenIntentRenderRequest({
    required this.decoded,
    required this.context,
    this.onAction,
  });

  final EdenIntentDecoded decoded;
  final EdenIntentHostContext context;
  final EdenIntentActionSink? onAction;
}

/// Draws one decoded intent, or a refusal when it cannot.
typedef EdenIntentBuilder = Widget Function(EdenIntentRenderRequest request);

/// The refusal widget, built here so every refusal in this layer looks the
/// same to a user and carries a reason.
Widget _refuse(String reason) => EdenRefusal(
      data: EdenRefusalData(reason: reason),
    );

/// The tool actions of a payload, narrowed.
///
/// An action binding to NOTHING is dropped rather than rendered: the Go
/// struct's `omitempty` makes `{"id": "open"}` legal, and a control the
/// caller could not invoke is an affordance that does nothing.
List<EdenIntentAction> _toolActions(List<EdenRawAction> raw) =>
    <EdenIntentAction>[
      for (final EdenRawAction a in raw)
        if (a.bindsTool) EdenIntentAction(id: a.id, toolId: a.toolId!),
    ];

/// The proposal actions of a payload, narrowed the same way.
List<EdenProposalAction> _proposalActions(List<EdenRawAction> raw) =>
    <EdenProposalAction>[
      for (final EdenRawAction a in raw)
        if (a.bindsProposal)
          EdenProposalAction(
            id: a.id,
            proposalId: a.proposalId!,
            decision: a.decision!,
          ),
    ];

/// Find the raw action an id came from, so egress can report the tool id.
EdenRawAction? _rawById(List<EdenRawAction> raw, String id) {
  for (final EdenRawAction a in raw) {
    if (a.id == id) return a;
  }
  return null;
}

Widget _buildAppointments(EdenIntentRenderRequest r) {
  final List<EdenRawAction> raw = r.decoded.actions;
  return EdenAppointmentList(
    data: r.decoded.data as EdenAppointmentListData,
    actions: _toolActions(raw),
    onAction: r.onAction == null
        ? null
        : (EdenIntentAction action, EdenAppointmentSummary row) =>
            r.onAction!(EdenFiredToolAction(
              actionId: action.id,
              toolId: action.toolId,
              target: row,
            )),
  );
}

Widget _buildRefusal(EdenIntentRenderRequest r) =>
    EdenRefusal(data: r.decoded.data as EdenRefusalData);

Widget _buildCustomers(EdenIntentRenderRequest r) {
  return EdenCustomerList(
    data: r.decoded.data as EdenCustomerListData,
    actions: _toolActions(r.decoded.actions),
    onAction: r.onAction == null
        ? null
        : (EdenIntentAction action, EdenCustomerSummary row) =>
            r.onAction!(EdenFiredToolAction(
              actionId: action.id,
              toolId: action.toolId,
              target: row,
            )),
  );
}

Widget _buildServices(EdenIntentRenderRequest r) {
  // THE REFUSAL THAT MATTERS. `price_cents` arrives with no currency
  // (eden-biz#860), so the host must say. It cannot be defaulted: `$50.00`
  // is correct for a USD tenant and a silent ~1.4x error for a CAD one,
  // with nothing on screen separating them.
  final String? code = r.context.currencyCode;
  if (code == null || code.isEmpty) {
    return _refuse(
      'list/services needs a currency and the payload carries none '
      '(eden-biz#860). Supply EdenIntentHostContext.currencyCode. It is not '
      'defaulted on purpose: a price in the wrong currency renders exactly '
      'as convincingly as one in the right currency.',
    );
  }

  return EdenServiceList(
    data: r.decoded.data as EdenServiceListData,
    currencyCode: code,
    actions: _toolActions(r.decoded.actions),
    onAction: r.onAction == null
        ? null
        : (EdenIntentAction action, EdenServiceSummary row) =>
            r.onAction!(EdenFiredToolAction(
              actionId: action.id,
              toolId: action.toolId,
              target: row,
            )),
  );
}

Widget _buildProposal(EdenIntentRenderRequest r) {
  // THE OTHER REFUSAL, and the higher-stakes one. The payload names no
  // mutation (eden-biz#863), so without a subject this card would ask for
  // consent to something unnamed.
  final String? subject = r.context.proposalSubject;
  if (subject == null || subject.isEmpty) {
    return _refuse(
      'card/proposal needs a subject and the payload carries none '
      '(eden-biz#863). Supply EdenIntentHostContext.proposalSubject. Without '
      'it the card would read "Pending approval. [Approve] [Reject]" and '
      'render identically whether the proposal creates a lead or deletes a '
      'customer.',
    );
  }

  final List<EdenRawAction> raw = r.decoded.actions;
  return EdenProposalCard(
    data: r.decoded.data as EdenProposalData,
    subject: subject,
    actions: _proposalActions(raw),
    onDecision: r.onAction == null
        ? null
        : (EdenProposalAction action) {
            final EdenRawAction? src = _rawById(raw, action.id);
            r.onAction!(EdenFiredProposalDecision(
              actionId: action.id,
              proposalId: src?.proposalId ?? action.proposalId,
              decision: action.decision,
            ));
          },
  );
}

/// `component_id` -> the widget that draws it.
///
/// THIS IS THE MAP `kDataDisplayComponents` CANNOT BE. That list pairs an id
/// with a Dart `Type`, and a `Type` is not constructible without reflection,
/// which AOT Flutter has none of — so it can DETECT an unknown id and can
/// never RENDER a known one. It stays exactly as it is, as the verification
/// artifact with its closed-partition test; this map renders.
///
/// The two describe the same set from two sides, so
/// `eden_intent_dispatcher_test` asserts their key sets are EQUAL in both
/// directions. A component added to one and not the other is the drift that
/// would otherwise leave the partition test green while nothing could draw
/// the thing.
///
/// Keyed off each widget's own `componentId` static, never a re-typed
/// literal.
final Map<String, EdenIntentBuilder> kIntentBuilders =
    <String, EdenIntentBuilder>{
  EdenAppointmentList.componentId: _buildAppointments,
  EdenRefusal.componentId: _buildRefusal,
  EdenCustomerList.componentId: _buildCustomers,
  EdenServiceList.componentId: _buildServices,
  EdenProposalCard.componentId: _buildProposal,
};

/// THE ENTRY POINT. A raw agent-intent payload in, a widget out.
///
/// NEVER THROWS AND NEVER GUESSES. An unreadable envelope, an id with no
/// renderer, a malformed field, or a host context missing something a
/// component requires each come back as an [EdenRefusal] carrying a reason
/// that names the cause.
///
/// The renderer never fetches: everything drawn comes from [json] and
/// [context].
Widget buildAgentIntent(
  Map<String, dynamic> json, {
  EdenIntentHostContext context = EdenIntentHostContext.empty,
  EdenIntentActionSink? onAction,
}) {
  final EdenIntentDecodeResult result = decodeAgentIntent(json);

  switch (result) {
    case EdenIntentRefused(:final String reason):
      // THE DECODER'S OWN REASON, not a generic one. The field name is the
      // only thing that makes a malformed payload diagnosable.
      return _refuse(reason);

    case EdenIntentDecoded():
      final EdenIntentBuilder? builder =
          kIntentBuilders[result.componentId];
      if (builder == null) {
        // Unreachable while the two maps agree, and asserted to be so. Kept
        // because "unreachable" plus a crash is worse than "unreachable"
        // plus a refusal.
        return _refuse(
          'no renderer for component_id "${result.componentId}" '
          '(it decoded, so this is a builder missing from kIntentBuilders)',
        );
      }
      return builder(EdenIntentRenderRequest(
        decoded: result,
        context: context,
        onAction: onAction,
      ));
  }
}

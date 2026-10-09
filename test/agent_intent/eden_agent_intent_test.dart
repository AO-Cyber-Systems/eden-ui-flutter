// The envelope: `{component_id, data, actions}` as it arrives on the wire.
//
// THE RECORDINGS ARE THE SOURCE. Every payload here is a vendored eden-biz
// recording or a STATED mutation of one — see
// `test/fixtures/agent_intent_fixtures.dart`.
//
// WHY `data` STAYS RAW AT THIS LAYER. Decoding it is the decoder's job, and
// keeping the two apart means a malformed `data` cannot stop the envelope
// from being read well enough to NAME the component that failed. An
// envelope that refused to parse at all would leave the refusal unable to
// say what it was refusing.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/agent_intent_fixtures.dart';

void main() {
  test('case 1: fixture 01 parses to its component id and both actions', () {
    final EdenAgentIntent intent = EdenAgentIntent.fromJson(
      agentIntentOf('01-list_upcoming_appointments-populated.json'),
    );

    expect(intent.componentId, 'list/appointments');
    expect(intent.actions.map((EdenRawAction a) => a.id).toList(),
        <String>['open', 'cancel']);
    expect(intent.actions.map((EdenRawAction a) => a.toolId).toList(),
        <String>['get_appointment', 'cancel_appointment']);
  });

  test('case 2: both action shapes survive, neither normalised away', () {
    // `agentintent.Action` is ONE Go struct with tool_id, proposal_id and
    // decision all `omitempty`. A tool-bound action and a proposal-bound one
    // are the same type on the wire, and the envelope must carry each as it
    // came — deciding which is BINDABLE belongs further in.
    final EdenRawAction tool = EdenAgentIntent.fromJson(
      agentIntentOf('01-list_upcoming_appointments-populated.json'),
    ).actions.first;
    expect(tool.toolId, 'get_appointment');
    expect(tool.proposalId, isNull);
    expect(tool.decision, isNull);

    final EdenRawAction proposal =
        EdenAgentIntent.fromJson(agentIntentOf('05-create_lead-proposal.json'))
            .actions
            .first;
    expect(proposal.proposalId, '00000000-0000-4000-8000-000000000001');
    expect(proposal.decision, 'approve');
    expect(proposal.toolId, isNull,
        reason: 'a proposal action carries no tool id, and inventing one '
            'here would hand the dispatcher something to invoke');
  });

  test('case 3: a missing component_id is a parse failure naming the field',
      () {
    // MUTATION of fixture 01: `component_id` deleted.
    final Map<String, dynamic> broken = mutatedIntent(
      '01-list_upcoming_appointments-populated.json',
      (Map<String, dynamic> i) => i.remove('component_id'),
    );

    expect(
      () => EdenAgentIntent.fromJson(broken),
      throwsA(isA<FormatException>().having(
        (FormatException e) => e.message, 'message',
        contains('component_id'),
      )),
      reason: 'the envelope throws here and the DECODER converts it to a '
          'refusal — contract 5 binds the public entry point, and a private '
          'helper that signals with an exception is not a crash reaching a '
          'caller. The decoder test pins that conversion.',
    );
  });

  test('case 4: absent actions decode to an EMPTY list, never null', () {
    // MUTATION of fixture 01: the whole `actions` key removed. `omitempty`
    // on the Go side means an intent granting nothing may omit the array.
    final Map<String, dynamic> noActions = mutatedIntent(
      '01-list_upcoming_appointments-populated.json',
      (Map<String, dynamic> i) => i.remove('actions'),
    );

    final EdenAgentIntent intent = EdenAgentIntent.fromJson(noActions);
    expect(intent.actions, isEmpty,
        reason: '"the payload granted nothing" is READ-ONLY, which is a real '
            'and correct state (contract 2). A null would force every '
            'consumer to decide what absence means, and one of them would '
            'decide wrong.');
  });

  test('case 5: fixture 03 — a refusal carries zero actions on the wire', () {
    final EdenAgentIntent intent = EdenAgentIntent.fromJson(
      agentIntentOf('03-get_appointment-wrong-tenant-refusal.json'),
    );
    expect(intent.componentId, 'error/refusal');
    expect(intent.actions, isEmpty,
        reason: 'refusal is one-sided (contract 4), and the RECORDING '
            'already shows it — this is not a rule the renderer imposes.');
  });

  test('case 6: every vendored recording yields a readable envelope', () {
    for (final String name in agentIntentFixtureNames()) {
      final EdenAgentIntent intent =
          EdenAgentIntent.fromJson(agentIntentOf(name));
      expect(intent.componentId.isNotEmpty, isTrue, reason: name);
      expect(intent.actions, isNotNull, reason: name);
    }
    expect(agentIntentFixtureNames(), hasLength(14),
        reason: 'the loop must have covered the whole set, not an empty one');
  });
}

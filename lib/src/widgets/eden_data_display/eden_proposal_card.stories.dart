// Co-located stories for [EdenProposalCard] — `component_id: card/proposal`.
//
// FIXTURE 05 IS THE SOURCE. From eden-biz `origin/main` at
// `go/internal/agentintent/testdata/05-create_lead-proposal.json`:
//
//   pending    -> 05, verbatim, both decisions granted
//   read-only  -> 05, with `intent.actions` emptied
//   applied    -> SYNTHETIC; `applied: true`, the committed state
//   narrow     -> 05 at 390, where the two controls have to share the width
//
// THE SUBJECT IS NOT IN THE FIXTURE, and that is the component's defining
// problem rather than an oversight in these stories. `intent.data` carries
// `action_id`, `applied`, `status` and `expires_at` and nothing that names
// the mutation. The recording's `source.tool` is `create_lead` and its
// `source.arguments` name Jordan Lee — but `source` is the recorder's own
// metadata and is absent from a production envelope. The subject used here
// is therefore composed from that metadata and stated as such; it is what a
// caller WOULD know, because the agent called the tool.
//
// WHY `applied` IS A STORY AND NOT A KNOB. It is the state in which the
// controls must be GONE. A knob would make the two states one baseline;
// separate stories make the pixel difference between "you may approve this"
// and "this is already committed" a thing CI compares.
//
// WHY `narrow` EXISTS. The decisions render in a Row, and a Row of two
// buttons is the classic overflow. At the default 1280 they occupy a
// fraction of the width and an overflow defect would be invisible — the
// same gap `list-services/catalogue` had before `list-services/narrow`
// was added to close it.
library;

import 'package:flutter/material.dart';

import '../../../dev_app/registry/eden_story.dart';
import 'agent_intent_data.dart';
import 'eden_proposal_card.dart';

/// FIXTURE 05's `intent.data`, verbatim.
final EdenProposalData kFixtureProposalPending = EdenProposalData(
  actionId: '00000000-0000-4000-8000-000000000001',
  applied: false,
  status: 'pending_approval',
  expiresAt: DateTime.utc(2030, 1, 7, 0, 30),
);

/// SYNTHETIC: the same proposal after it was committed.
///
/// `status` STAYS `pending_approval` ON PURPOSE. `pending_approval` is the
/// only value any recording has produced, and inventing an `applied` status
/// here would be asserting a value eden-biz has not been observed to emit.
/// So this is deliberately a payload that disagrees with itself — `applied`
/// says committed, `status` still says pending — and the card resolves it
/// the safe way: `applied` wins and the controls go. A payload CAN arrive
/// self-contradictory, and the state worth pinning is the one where the
/// resolution errs away from offering a second commit.
final EdenProposalData kFixtureProposalApplied = EdenProposalData(
  actionId: '00000000-0000-4000-8000-000000000001',
  applied: true,
  status: 'pending_approval',
  expiresAt: DateTime.utc(2030, 1, 7, 0, 30),
);

/// FIXTURE 05's `intent.actions`, verbatim.
const List<EdenProposalAction> kFixtureProposalActions =
    <EdenProposalAction>[
  EdenProposalAction(
    id: 'approve',
    proposalId: '00000000-0000-4000-8000-000000000001',
    decision: 'approve',
  ),
  EdenProposalAction(
    id: 'reject',
    proposalId: '00000000-0000-4000-8000-000000000001',
    decision: 'reject',
  ),
];

/// Composed from the recording's `source.tool` and `source.arguments`, which
/// the production envelope does not carry. See the header.
const String kFixtureProposalSubject = 'Create a lead for Jordan Lee';

final List<EdenStory> edenProposalCardStories = <EdenStory>[
  /// FIXTURE 05. The open proposal: both decisions granted.
  EdenStory(
    id: 'card-proposal/pending',
    component: 'card-proposal',
    name: 'Pending',
    icon: Icons.pending_actions_outlined,
    knobs: const [],
    build: (BuildContext context, _) => EdenProposalCard(
      data: kFixtureProposalPending,
      subject: kFixtureProposalSubject,
      actions: kFixtureProposalActions,
      onDecision: _noop,
    ),
  ),

  /// FIXTURE 05 WITH `intent.actions` EMPTIED — the withheld case.
  ///
  /// The record of the proposal without the power to decide it. Someone who
  /// may SEE a pending approval is not necessarily someone who may grant it.
  EdenStory(
    id: 'card-proposal/read-only',
    component: 'card-proposal',
    name: 'Read only',
    icon: Icons.lock_outline,
    knobs: const [],
    build: (BuildContext context, _) => EdenProposalCard(
      data: kFixtureProposalPending,
      subject: kFixtureProposalSubject,
      // actions omitted deliberately.
    ),
  ),

  /// SYNTHETIC. `applied: true` — committed, controls gone.
  ///
  /// The actions ARE passed. The card drops them because the payload says
  /// the proposal is already applied, which is the visual record that
  /// payload state, not the caller, decides.
  EdenStory(
    id: 'card-proposal/applied',
    component: 'card-proposal',
    name: 'Applied',
    icon: Icons.task_alt_outlined,
    knobs: const [],
    build: (BuildContext context, _) => EdenProposalCard(
      data: kFixtureProposalApplied,
      subject: kFixtureProposalSubject,
      actions: kFixtureProposalActions,
      onDecision: _noop,
    ),
  ),

  /// FIXTURE 05 at 390 — the two controls sharing a phone's width.
  EdenStory(
    id: 'card-proposal/narrow',
    component: 'card-proposal',
    name: 'Narrow',
    icon: Icons.smartphone_outlined,
    knobs: const [],
    viewportWidth: 390,
    build: (BuildContext context, _) => EdenProposalCard(
      data: kFixtureProposalPending,
      subject: kFixtureProposalSubject,
      actions: kFixtureProposalActions,
      onDecision: _noop,
    ),
  ),
];

/// A story is a render, not an interaction harness.
void _noop(EdenProposalAction action) {}

// Co-located stories for [EdenRefusal] — `component_id: error/refusal`.
//
// BOTH FIXTURES ARE TRANSCRIPTIONS. From eden-biz `origin/main` at
// `go/internal/agentintent/testdata/`:
//
//   refusal             -> 03-get_appointment-wrong-tenant-refusal.json
//   refusal-tool-named  -> 14-get_customer_history-wrong-tenant-refusal.json
//
// Both are WRONG-TENANT probes: a principal scoped to company A asking for a
// row belonging to company B. The tool answers `is_error: true` with a reason
// and `actions: []`.
//
// WHY THERE ARE TWO. They are the same class of refusal phrased two ways: one
// bare (`appointment not found`), one prefixed by the tool that refused
// (`get_customer_history: customer not found`). The pair pins that the
// component passes the reason through VERBATIM — a component that tidied the
// prefix away would render these two identically, and the golden-uniqueness
// gate would then be the thing that caught it.
//
// WHY THERE IS NO `narrow` STORY. The card is a heading, one sentence and a
// footnote inside a 560px measure. At 390 it reflows; nothing about the layout
// CHANGES. A narrow story here would pin a text wrap, which the populated
// appointment-list story already pins on a surface where the layout genuinely
// switches — and it would cost two more baselines for no new fact.
//
// INPUT MODALITY. Declared `touch` like its sibling, and it is not a
// formality: `expectUiSane`'s touch floor asserts a 48dp/44pt minimum on every
// IDENTIFIED control, and this surface has none at all. That is the point —
// see the story doc below.
//
// Goldens are generated and compared by the CI `stories` job on Linux only
// (eden-ui-flutter#32); locally they skip. `expectUiSane` runs everywhere.

import 'package:flutter/material.dart';

import '../../../dev_app/registry/eden_story.dart';
import 'agent_intent_data.dart';
import 'eden_refusal.dart';

/// Fixture 03's payload, verbatim.
const EdenRefusalData kFixtureRefusalBare =
    EdenRefusalData(reason: 'appointment not found');

/// Fixture 14's payload, verbatim — the reason carries the refusing tool's
/// name as a prefix and is NOT stripped.
const EdenRefusalData kFixtureRefusalToolNamed =
    EdenRefusalData(reason: 'get_customer_history: customer not found');

/// The `error/refusal` state fixtures. Registered by tool/gen_stories.dart —
/// never hand-edit lib/dev_app/registry/register_stories.g.dart.
final List<EdenStory> edenRefusalStories = <EdenStory>[
  /// FIXTURE 03. The refusal state itself.
  ///
  /// WHAT THIS GOLDEN PINS IS AN ABSENCE. `intent.actions` is `[]`, and a
  /// refusal is one-sided: there is nothing the user could press that would
  /// change the answer. So the card carries no button, and the day somebody
  /// adds a "Try again" this golden goes red — which is the only automated
  /// guard that exists for it, because `expectUiSane` is perfectly happy with
  /// a surface that has no controls (correctly: it has nothing to check).
  /// [EdenRefusal] takes no action callback at all, so the absence is also a
  /// compile error to undo; the golden catches the case where somebody adds
  /// the parameter back.
  EdenStory(
    id: 'error-refusal/refusal',
    component: 'error-refusal',
    name: 'Refusal',
    icon: Icons.block_outlined,
    knobs: const [],
    build: (BuildContext context, _) =>
        const EdenRefusal(data: kFixtureRefusalBare),
  ),

  /// FIXTURE 14. The same refusal, reason prefixed with the tool that refused.
  ///
  /// Pins the pass-through. If the component ever starts stripping the prefix
  /// or substituting friendlier copy, this golden becomes identical to
  /// `error-refusal/refusal` and `golden_uniqueness_test.dart` fails on the
  /// collision before a human notices the reason went missing.
  EdenStory(
    id: 'error-refusal/tool-named',
    component: 'error-refusal',
    name: 'Tool named',
    icon: Icons.label_off_outlined,
    knobs: const [],
    build: (BuildContext context, _) =>
        const EdenRefusal(data: kFixtureRefusalToolNamed),
  ),
];

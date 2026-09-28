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
// component passes the reason through VERBATIM.
//
// WHAT WOULD ACTUALLY CATCH A COMPONENT THAT STRIPPED THE PREFIX — corrected
// in the eden-ui-flutter#53 review, because the first version of this comment
// credited a gate with a property it does not have, which is the exact defect
// class the rest of this file is about.
//
// It is NOT golden_uniqueness_test. Strip `get_customer_history: ` and this
// story renders "customer not found" against the other's "appointment not
// found" — still two different strings, still two different images, still two
// unique baselines. The uniqueness gate would pass, and would be right to.
//
// The guards that DO close it are:
//   * `eden_data_display_test.dart`, which asserts the exact full string
//     `get_customer_history: customer not found` is on screen. This one runs
//     on every platform and is the real guard.
//   * the golden COMPARISON at tolerance 0, which goes red because the pixels
//     moved — on Linux CI only (eden-ui-flutter#32), so not on a workstation.
//
// The second story still earns its place: it is the only state in the
// catalogue carrying a tool-prefixed reason, so without it the prefix shape is
// pinned by no golden at all.
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
  /// Pins the pass-through. Strip the prefix and this golden MOVES — the
  /// tolerance-0 comparison on Linux goes red — but it does not COLLIDE with
  /// `error-refusal/refusal`, which would still read "appointment not found".
  /// See the header: the exact-string assertion in
  /// `test/widgets/eden_data_display/eden_data_display_test.dart` is the guard
  /// that runs everywhere, and this story is what pins the shape in pixels.
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

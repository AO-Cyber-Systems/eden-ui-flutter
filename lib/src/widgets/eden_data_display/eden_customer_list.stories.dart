// Co-located stories for [EdenCustomerList] — `component_id: list/customers`.
//
// FIXTURE 11 IS THE SOURCE, with one stated exception. From eden-biz
// `origin/main` at `go/internal/agentintent/testdata/`:
//
//   populated  -> 11-find_customer-populated.json
//   read-only  -> 11, with `intent.actions` emptied (see below)
//   empty      -> SYNTHETIC; eden-biz records no customers-empty case
//
// Both populated rows are called Priya. That is not a contrived collision —
// it is the recorded result of `find_customer(query: "Priya")`, and it is the
// reason the tool returns an `email_hint` at all. A fixture with two
// distinguishable names would quietly remove the ambiguity the field exists
// to resolve.
//
// WHY `read-only` IS ITS OWN STORY, AND NOT A KNOB. The contract's
// load-bearing claim is that affordances are granted by the PAYLOAD: the
// agent's `intent.actions` decides whether this caller may open a customer.
// The two stories differ only in that list, so the pair is the visual record
// of the difference — chevrons and tap targets in one, none in the other. A
// renderer that offered `open` regardless would have invented an
// authorization the observation never granted, and the pixels are where that
// becomes visible rather than merely asserted.
//
// `eden_customer_list_test.dart` cases 3-5 hold the same property
// behaviourally (no InkWell, no chevron, a tap that does nothing). The
// stories hold it VISUALLY, which is the half a behavioural test cannot see:
// a chevron rendered in a colour nobody can make out is a control the test
// finds and the user does not.
//
// THE EXCEPTION, disclosed rather than buried: `empty` is synthetic.
// eden-biz records an empty case for appointments (fixture 02) and not for
// customers, so `customers: []` here is constructed. It is the one state
// where a renderer's failure mode and its success mode look identical — a
// card that draws nothing is indistinguishable from a card that failed to
// draw — so it needs a baseline even though no recording produces it.
//
// INPUT MODALITY IS LEFT AT THE DEFAULT, deliberately, and the default is
// the strict one. `EdenStory.inputModality` defaults to
// `EdenInputModality.touch`, so `expectUiSane` holds every row here to 48dp
// rather than Material's 44 — which is why the row is BUILT to 48. This
// surface ships to the biz portal (pointer) AND to the companion app
// (touch), and the right floor for something that ships to both is the one a
// fingertip can reach. Declaring `pointer` to make a 44dp row pass would be
// weakening the gate to fit the widget.
library;

import 'package:flutter/material.dart';

import '../../../dev_app/registry/eden_story.dart';
import 'agent_intent_data.dart';
import 'eden_customer_list.dart';

/// FIXTURE 11, verbatim: two rows, three keys each, both hints identical.
const EdenCustomerListData kFixtureCustomersPopulated = EdenCustomerListData(
  customers: <EdenCustomerSummary>[
    EdenCustomerSummary(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Priya Raman',
      emailHint: 'p***@example.test',
    ),
    EdenCustomerSummary(
      id: '00000000-0000-4000-8000-000000000002',
      name: 'Priya Shah',
      emailHint: 'p***@example.test',
    ),
  ],
);

/// SYNTHETIC — see the header. No recording produces this.
const EdenCustomerListData kFixtureCustomersEmpty =
    EdenCustomerListData(customers: <EdenCustomerSummary>[]);

/// FIXTURE 11's `intent.actions`, verbatim.
const List<EdenIntentAction> kFixtureCustomerActions = <EdenIntentAction>[
  EdenIntentAction(id: 'open', toolId: 'get_customer_history'),
];

final List<EdenStory> edenCustomerListStories = <EdenStory>[
  /// FIXTURE 11. The ordinary answer: two matches, `open` granted.
  ///
  /// Pins the disambiguation case — same first name, same masked hint, so
  /// the only thing separating the rows visually is the surname. If the hint
  /// ever stopped rendering, this golden moves and the row becomes a name
  /// with no way to tell the two people apart.
  EdenStory(
    id: 'list-customers/populated',
    component: 'list-customers',
    name: 'Populated',
    icon: Icons.people_outline,
    knobs: const [],
    build: (BuildContext context, _) => const EdenCustomerList(
      data: kFixtureCustomersPopulated,
      actions: kFixtureCustomerActions,
      // A callback IS supplied: `open` plus no callback would render an
      // affordance that does nothing, and this story is the granted case.
      onAction: _noop,
    ),
  ),

  /// FIXTURE 11 WITH `intent.actions` EMPTIED — the withheld case.
  ///
  /// Same data, same rows, no chevrons and no tap targets. The diff against
  /// `populated` is the entire visual record of "the payload decides".
  EdenStory(
    id: 'list-customers/read-only',
    component: 'list-customers',
    name: 'Read only',
    icon: Icons.lock_outline,
    knobs: const [],
    build: (BuildContext context, _) => const EdenCustomerList(
      data: kFixtureCustomersPopulated,
      // actions omitted deliberately — this is the point of the story.
    ),
  ),

  /// SYNTHETIC. `customers: []` — nobody matched.
  ///
  /// The state where a blank card and a broken card look the same, which is
  /// why it carries a sentence and gets a baseline despite no recording
  /// producing it.
  EdenStory(
    id: 'list-customers/empty',
    component: 'list-customers',
    name: 'Empty',
    icon: Icons.person_search_outlined,
    knobs: const [],
    build: (BuildContext context, _) => const EdenCustomerList(
      data: kFixtureCustomersEmpty,
      actions: kFixtureCustomerActions,
      onAction: _noop,
    ),
  ),
];

/// A story is a render, not an interaction harness; the callback exists so
/// the granted state renders its affordances.
void _noop(EdenIntentAction action, EdenCustomerSummary customer) {}

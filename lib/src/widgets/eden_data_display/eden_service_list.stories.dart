// Co-located stories for [EdenServiceList] — `component_id: list/services`.
//
// FIXTURE 08 IS THE SOURCE, with two stated exceptions. From eden-biz
// `origin/main` at `go/internal/agentintent/testdata/`:
//
//   populated  -> 08-list_services-populated.json
//   read-only  -> 08, with `intent.actions` emptied
//   empty      -> SYNTHETIC; eden-biz records no services-empty case
//   catalogue  -> SYNTHETIC; see below, and it is the one that earns its keep
//
// EXCEPTION 1, `empty`. eden-biz records an empty case for appointments
// (fixture 02) and not for services, so `services: []` is constructed. It is
// the state where a renderer's failure mode and its success mode look
// identical — a card that draws nothing is indistinguishable from a card
// that failed to draw — so it needs a baseline even though no recording
// produces it.
//
// EXCEPTION 2, `catalogue`, AND WHY A FIXTURE-ONLY SET WOULD BE A GAP.
// Fixture 08 records exactly ONE service. A single-row render cannot show
// anything about the treatment BETWEEN rows: whether prices align on the
// decimal, whether a long name pushes the price off the row, whether two
// rows of different name lengths keep the same baseline. Those are the
// defects this component is most likely to have, and a one-row baseline is
// green for all of them. So this story is synthetic and says so, and the
// rows are built to stress exactly those three things — a long name, a
// price an order of magnitude larger, and a duration that crosses the hour
// boundary the formatter branches on.
//
// INPUT MODALITY IS LEFT AT THE DEFAULT, deliberately, and the default is
// the strict one: `EdenStory.inputModality` defaults to
// `EdenInputModality.touch`, so `expectUiSane` holds every row here to 48dp
// rather than Material's 44 — which is why the row is BUILT to 48.
//
// EVERY STORY STATES A CURRENCY, because the widget has no default and
// cannot have one (eden-biz#860). `USD` here is the fixture principal's
// seed company, not a guess the component made.
library;

import 'package:flutter/material.dart';

import '../../../dev_app/registry/eden_story.dart';
import 'agent_intent_data.dart';
import 'eden_service_list.dart';

/// FIXTURE 08, verbatim: one service, four keys.
const EdenServiceListData kFixtureServicesPopulated = EdenServiceListData(
  services: <EdenServiceSummary>[
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Fixture Consultation',
      durationMinutes: 30,
      priceCents: 5000,
    ),
  ],
);

/// SYNTHETIC — see the header. No recording produces this.
const EdenServiceListData kFixtureServicesEmpty = EdenServiceListData(
  services: <EdenServiceSummary>[],
);

/// SYNTHETIC — see the header. Three rows chosen to expose what one row
/// cannot: decimal alignment across differing magnitudes, a name long
/// enough to compete with the price for width, and an over-the-hour
/// duration.
const EdenServiceListData kFixtureServicesCatalogue = EdenServiceListData(
  services: <EdenServiceSummary>[
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Fixture Consultation',
      durationMinutes: 30,
      priceCents: 5000,
    ),
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000002',
      name: 'Extended diagnostic and system commissioning visit',
      durationMinutes: 90,
      priceCents: 124500,
    ),
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000003',
      name: 'Follow-up',
      durationMinutes: 60,
      priceCents: 0,
    ),
  ],
);

/// FIXTURE 08's `intent.actions`, verbatim.
const List<EdenIntentAction> kFixtureServiceActions = <EdenIntentAction>[
  EdenIntentAction(id: 'check_availability', toolId: 'find_availability'),
];

final List<EdenStory> edenServiceListStories = <EdenStory>[
  /// FIXTURE 08. The ordinary answer: one service, `check_availability`
  /// granted.
  EdenStory(
    id: 'list-services/populated',
    component: 'list-services',
    name: 'Populated',
    icon: Icons.design_services_outlined,
    knobs: const [],
    build: (BuildContext context, _) => const EdenServiceList(
      data: kFixtureServicesPopulated,
      currencyCode: 'USD',
      actions: kFixtureServiceActions,
      // A callback IS supplied: a granted action with no callback would
      // render an affordance that does nothing.
      onAction: _noop,
    ),
  ),

  /// FIXTURE 08 WITH `intent.actions` EMPTIED — the withheld case.
  ///
  /// Same data, no chevron and no tap target. The diff against `populated`
  /// is the entire visual record of "the payload decides".
  EdenStory(
    id: 'list-services/read-only',
    component: 'list-services',
    name: 'Read only',
    icon: Icons.lock_outline,
    knobs: const [],
    build: (BuildContext context, _) => const EdenServiceList(
      data: kFixtureServicesPopulated,
      currencyCode: 'USD',
      // actions omitted deliberately — this is the point of the story.
    ),
  ),

  /// SYNTHETIC. `services: []` — an empty catalogue, stated.
  EdenStory(
    id: 'list-services/empty',
    component: 'list-services',
    name: 'Empty',
    icon: Icons.inventory_2_outlined,
    knobs: const [],
    build: (BuildContext context, _) => const EdenServiceList(
      data: kFixtureServicesEmpty,
      currencyCode: 'USD',
      actions: kFixtureServiceActions,
      onAction: _noop,
    ),
  ),

  /// SYNTHETIC, and the only story that can fail on inter-row treatment.
  /// Three rows: decimal alignment across 50.00 / 1245.00 / 0.00, a name
  /// long enough to be truncated rather than to shove the price, and a
  /// 90-minute duration rendering as `1 hr 30 min`.
  EdenStory(
    id: 'list-services/catalogue',
    component: 'list-services',
    name: 'Catalogue',
    icon: Icons.list_alt_outlined,
    knobs: const [],
    build: (BuildContext context, _) => const EdenServiceList(
      data: kFixtureServicesCatalogue,
      currencyCode: 'USD',
      actions: kFixtureServiceActions,
      onAction: _noop,
    ),
  ),
];

/// A story is a render, not an interaction harness; the callback exists so
/// the granted state renders its affordances.
void _noop(EdenIntentAction action, EdenServiceSummary service) {}

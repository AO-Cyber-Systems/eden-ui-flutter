// `list/services` — the behaviour the payload decides, plus the one thing
// the payload cannot tell us.
//
// THE FIXTURE IS THE SOURCE. The populated row is transcribed from eden-biz
// `go/internal/agentintent/testdata/08-list_services-populated.json`,
// recorded from `list_services` with `arguments: {}`.
//
// WHERE THIS DIFFERS FROM `list/customers`. Same affordance contract, plus a
// currency the observation does not carry (eden-biz#860). Cases 6-8 are
// about that gap, and case 6 is the load-bearing one: a `currencyCode`
// parameter that the widget quietly ignored would render EXACTLY like one it
// honoured, so the test asserts that two different codes produce two
// different strings rather than asserting one code produces one string.
//
// SYNTHETIC INPUT IS LABELLED. The multi-row data and the formatter
// boundaries below are test INPUT, not claims about recorded data: the
// recording has one row and one duration, while `duration_minutes` and
// `price_cents` are unbounded integers in the tool's `OutputSchema`, so the
// branches exist whether or not a recording reaches them.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture 08's single row, verbatim.
const EdenServiceListData _kPopulated = EdenServiceListData(
  services: <EdenServiceSummary>[
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Fixture Consultation',
      durationMinutes: 30,
      priceCents: 5000,
    ),
  ],
);

/// SYNTHETIC. Three rows, so a press can land on one that is not the first.
const EdenServiceListData _kThreeRows = EdenServiceListData(
  services: <EdenServiceSummary>[
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Fixture Consultation',
      durationMinutes: 30,
      priceCents: 5000,
    ),
    EdenServiceSummary(
      id: '00000000-0000-4000-8000-000000000002',
      name: 'Extended diagnostic',
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

/// Fixture 08's action, verbatim.
const List<EdenIntentAction> _kCheckGranted = <EdenIntentAction>[
  EdenIntentAction(id: 'check_availability', toolId: 'find_availability'),
];

Future<void> _pump(
  WidgetTester tester, {
  required EdenServiceListData data,
  String currencyCode = 'USD',
  List<EdenIntentAction> actions = const <EdenIntentAction>[],
  EdenServiceActionCallback? onAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: EdenTheme.light(),
      home: Scaffold(
        body: EdenServiceList(
          data: data,
          currencyCode: currencyCode,
          actions: actions,
          onAction: onAction,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('case 1: renders the transcribed row, its duration and price', (
    WidgetTester tester,
  ) async {
    await _pump(tester, data: _kPopulated);

    expect(find.text('Fixture Consultation'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('USD 50.00'), findsOneWidget);
  });

  testWidgets('case 2: an empty catalogue is STATED, never a blank region', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      data: const EdenServiceListData(services: <EdenServiceSummary>[]),
    );

    // On PAINTED TEXT, not on the absence of rows: a card that renders
    // nothing is indistinguishable from a card that failed to render.
    expect(
      find.byKey(const ValueKey<String>('eden-services-empty')),
      findsOneWidget,
    );

    // "LISTED", not "matched". `list_services` takes no arguments, so an
    // empty array means the catalogue is empty, not that a search missed.
    expect(find.text('No services are listed.'), findsOneWidget);
    expect(find.text('Fixture Consultation'), findsNothing);
  });

  testWidgets('case 3: NO actions means no tap targets at all', (
    WidgetTester tester,
  ) async {
    bool fired = false;
    await _pump(
      tester,
      data: _kPopulated,
      // actions deliberately omitted — the payload granted nothing.
      onAction: (_, __) => fired = true,
    );

    expect(
      find.byType(InkWell),
      findsNothing,
      reason:
          'an empty intent.actions must render a READ-ONLY catalogue. '
          'A renderer that offers `check_availability` anyway has invented '
          'an authorization the observation did not grant.',
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.tap(find.text('Fixture Consultation'));
    await tester.pump();
    expect(
      fired,
      isFalse,
      reason:
          'tapping a row in a read-only catalogue must do nothing even '
          'when a callback was supplied — the PAYLOAD withheld the '
          'affordance, not the caller.',
    );
  });

  testWidgets(
    'case 4: a granted action fires with the action AND the row pressed',
    (WidgetTester tester) async {
      EdenIntentAction? gotAction;
      EdenServiceSummary? gotService;

      await _pump(
        tester,
        data: _kThreeRows,
        actions: _kCheckGranted,
        onAction: (EdenIntentAction a, EdenServiceSummary s) {
          gotAction = a;
          gotService = s;
        },
      );

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));

      // THE SECOND ROW, deliberately. `intent.actions` is component-level with
      // no per-row binding, so row identity comes from the press — tapping the
      // first row would pass by accident if the widget always reported
      // `services.first`.
      await tester.tap(find.text('Extended diagnostic'));
      await tester.pump();

      expect(gotAction?.id, 'check_availability');
      expect(
        gotAction?.toolId,
        'find_availability',
        reason:
            'the tool id is handed BACK, not interpreted here. Actions '
            'bind to tool ids, never routes.',
      );
      expect(
        gotService?.id,
        '00000000-0000-4000-8000-000000000002',
        reason: 'the callback must carry the row the user pressed',
      );
    },
  );

  testWidgets('case 5: an action id the component does not know is ignored', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      data: _kPopulated,
      // A real id from a DIFFERENT component's payload (customers carry
      // `open`). Action ids are free strings on the wire, so one this
      // component has no meaning for must be inert.
      actions: const <EdenIntentAction>[
        EdenIntentAction(id: 'open', toolId: 'get_customer_history'),
      ],
      onAction: (_, __) {},
    );

    expect(find.byType(InkWell), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('case 6: the currency code is LOAD-BEARING, not decoration', (
    WidgetTester tester,
  ) async {
    // THE POINT OF THIS CASE. A `currencyCode` the widget accepted and then
    // ignored would render identically to one it honoured — the failure mode
    // and the success mode would be the same pixels. So the assertion is
    // that two codes over the SAME data produce two DIFFERENT strings.
    await _pump(tester, data: _kPopulated, currencyCode: 'USD');
    expect(find.text('USD 50.00'), findsOneWidget);
    expect(find.text('CAD 50.00'), findsNothing);

    await _pump(tester, data: _kPopulated, currencyCode: 'CAD');
    expect(find.text('CAD 50.00'), findsOneWidget);
    expect(
      find.text('USD 50.00'),
      findsNothing,
      reason:
          'a hardcoded symbol or a defaulted USD would leave this '
          'assertion passing on the first pump and failing here — which '
          'is the only way to tell an honoured parameter from an ignored '
          'one, since both render a plausible price.',
    );
  });

  testWidgets('case 7: the code is rendered verbatim, not normalised', (
    WidgetTester tester,
  ) async {
    // eden-biz stores `'USD'` on ten tables and `'usd'` on `payment_intents`.
    // Upper-casing here would HIDE that split behind a renderer that always
    // looks right, so the lowercase code is displayed as given.
    await _pump(tester, data: _kPopulated, currencyCode: 'usd');
    expect(find.text('usd 50.00'), findsOneWidget);
    expect(find.text('USD 50.00'), findsNothing);
  });

  testWidgets('case 8: a zero price renders as a number, never as "Free"', (
    WidgetTester tester,
  ) async {
    await _pump(tester, data: _kThreeRows, currencyCode: 'USD');

    // `appointment_types` has `price` AND `price_cents`, both DEFAULT 0, and
    // nothing states which is authoritative. So a service nobody priced is
    // byte-identical to one that is genuinely free, and labelling 0 as
    // "Free" would be the renderer inventing a claim the data does not make.
    expect(find.text('USD 0.00'), findsOneWidget);
    expect(find.text('Free'), findsNothing);
  });

  group(
    'case 9: formatters, over branches the one-row recording cannot hit',
    () {
      test('minor units use integer arithmetic', () {
        expect(edenFormatMinorUnits(5000), '50.00');
        expect(edenFormatMinorUnits(0), '0.00');
        expect(edenFormatMinorUnits(5), '0.05');
        expect(edenFormatMinorUnits(99), '0.99');
        expect(edenFormatMinorUnits(124500), '1245.00');
        expect(edenFormatMinorUnits(-5000), '-50.00');

        // ABOVE 2^53, where `minorUnits / 100` as a double has already lost
        // the cents. Integer division and a padded remainder have no such
        // range, and this is the assertion that would catch a refactor back
        // to floating point.
        expect(edenFormatMinorUnits(9007199254740993), '90071992547409.93');
      });

      test('durations cross the hour boundary', () {
        expect(edenFormatDurationMinutes(30), '30 min'); // the recorded one
        expect(edenFormatDurationMinutes(0), '0 min');
        expect(edenFormatDurationMinutes(59), '59 min');
        expect(edenFormatDurationMinutes(60), '1 hr');
        expect(edenFormatDurationMinutes(90), '1 hr 30 min');
        expect(edenFormatDurationMinutes(120), '2 hr');
        expect(edenFormatDurationMinutes(125), '2 hr 5 min');
      });
    },
  );
}

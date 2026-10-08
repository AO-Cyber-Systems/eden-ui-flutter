// `list/customers` — the behaviour the payload decides.
//
// THE FIXTURE IS THE SOURCE. Every row below is transcribed from eden-biz
// `go/internal/agentintent/testdata/11-find_customer-populated.json`, recorded
// from `find_customer(query: "Priya")`. Two rows called Priya is not a
// contrived collision — it is why the tool returns an `email_hint` at all,
// and it is why the disambiguation case is the recorded case rather than one
// someone invented.
//
// WHAT THESE CASES ARE ABOUT. Not layout. The contract's load-bearing claim is
// that AFFORDANCES ARE GRANTED BY THE PAYLOAD: the agent's `intent.actions` is
// what decides whether this caller may open a customer, so a renderer that
// offers the control regardless is inventing an authorization the observation
// never granted. Cases 3-5 are that property from three directions.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture 11's two rows, verbatim.
const EdenCustomerListData _kPopulated = EdenCustomerListData(
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

/// Fixture 11's action, verbatim: `open` bound to `get_customer_history`.
const List<EdenIntentAction> _kOpenGranted = <EdenIntentAction>[
  EdenIntentAction(id: 'open', toolId: 'get_customer_history'),
];

Future<void> _pump(
  WidgetTester tester, {
  required EdenCustomerListData data,
  List<EdenIntentAction> actions = const <EdenIntentAction>[],
  EdenCustomerActionCallback? onAction,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: Scaffold(
      body: EdenCustomerList(
        data: data,
        actions: actions,
        onAction: onAction,
      ),
    ),
  ));
}

void main() {
  testWidgets('case 1: renders both transcribed rows with their hints',
      (WidgetTester tester) async {
    await _pump(tester, data: _kPopulated);

    expect(find.text('Priya Raman'), findsOneWidget);
    expect(find.text('Priya Shah'), findsOneWidget);

    // BOTH hints, not one. Two rows carrying the SAME hint string is the
    // recorded case, so a finder that collapsed them would hide exactly the
    // ambiguity the field exists to expose.
    expect(find.text('p***@example.test'), findsNWidgets(2));
  });

  testWidgets('case 2: an empty result is STATED, never a blank region',
      (WidgetTester tester) async {
    await _pump(tester,
        data: const EdenCustomerListData(customers: <EdenCustomerSummary>[]));

    // The one outcome both sides of this contract agreed must never happen is
    // a card that renders nothing, because it is indistinguishable from a
    // card that failed to render. So the assertion is on PAINTED TEXT, not
    // on the absence of rows.
    expect(find.byKey(const ValueKey<String>('eden-customers-empty')),
        findsOneWidget);
    expect(find.text('No customers matched.'), findsOneWidget);

    // And no row survived.
    expect(find.text('Priya Raman'), findsNothing);
  });

  testWidgets('case 3: NO actions means no tap targets at all',
      (WidgetTester tester) async {
    bool fired = false;
    await _pump(
      tester,
      data: _kPopulated,
      // actions deliberately omitted — the payload granted nothing.
      onAction: (_, __) => fired = true,
    );

    expect(find.byType(InkWell), findsNothing,
        reason: 'an empty intent.actions must render a READ-ONLY list. A '
            'renderer that offers `open` anyway has invented an '
            'authorization the observation did not grant.');
    expect(find.byIcon(Icons.chevron_right), findsNothing,
        reason: 'the chevron is the affordance cue; it must not appear when '
            'there is nothing to open.');

    await tester.tap(find.text('Priya Raman'));
    await tester.pump();
    expect(fired, isFalse,
        reason: 'tapping a row in a read-only list must do nothing even when '
            'a callback was supplied — the PAYLOAD is what withheld the '
            'affordance, not the caller.');
  });

  testWidgets(
      'case 4: a granted `open` fires with the action AND the row pressed',
      (WidgetTester tester) async {
    EdenIntentAction? gotAction;
    EdenCustomerSummary? gotCustomer;

    await _pump(
      tester,
      data: _kPopulated,
      actions: _kOpenGranted,
      onAction: (EdenIntentAction a, EdenCustomerSummary c) {
        gotAction = a;
        gotCustomer = c;
      },
    );

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

    // THE SECOND ROW, deliberately. `intent.actions` is component-level with
    // no per-row binding, so the row identity comes from the press. Tapping
    // the first row could pass by accident if the widget always reported
    // `customers.first`.
    await tester.tap(find.text('Priya Shah'));
    await tester.pump();

    expect(gotAction?.id, 'open');
    expect(gotAction?.toolId, 'get_customer_history',
        reason: 'the tool id is handed BACK, not interpreted here — the '
            'caller invokes it. Actions bind to tool ids, never routes.');
    expect(gotCustomer?.id, '00000000-0000-4000-8000-000000000002',
        reason: 'the callback must carry the row the user pressed, not the '
            'first row: that id is the other half of the invocation.');
  });

  testWidgets('case 5: an action id the component does not know is ignored',
      (WidgetTester tester) async {
    await _pump(
      tester,
      data: _kPopulated,
      // A real id from a DIFFERENT component's payload (appointments carry
      // `cancel`). `component_id` is a free string on the wire and so are
      // action ids, so an id this component has no meaning for must be inert
      // rather than rendered as some generic control.
      actions: const <EdenIntentAction>[
        EdenIntentAction(id: 'cancel', toolId: 'cancel_appointment'),
      ],
      onAction: (_, __) {},
    );

    expect(find.byType(InkWell), findsNothing,
        reason: 'an unrecognised action must not grant tapping');
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('case 6: the masked hint is displayed exactly as received',
      (WidgetTester tester) async {
    await _pump(tester, data: _kPopulated);

    final Text hint = tester.widget<Text>(
      find.byKey(const ValueKey<String>('eden-customer-email-hint')).first,
    );

    // CHARACTER-FOR-CHARACTER. The tool decided what a caller with these
    // scopes may see; the renderer's only job is to show that. An
    // "improvement" here — unmasking, linkifying, or validating it as an
    // email and styling it as malformed — would either leak or lie.
    expect(hint.data, 'p***@example.test');
  });
}

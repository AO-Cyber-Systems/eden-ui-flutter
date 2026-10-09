// `card/proposal` — the one component whose controls mutate.
//
// THE FIXTURE IS THE SOURCE. Transcribed from eden-biz
// `go/internal/agentintent/testdata/05-create_lead-proposal.json`, recorded
// by routing `create_lead` through the real `actionsink.NewMCPProposer`.
//
// WHAT THESE CASES ARE ABOUT. Not layout. Every case below is a rule about
// when a control that COMMITS something may be drawn. The others in this
// directory hand back a tool id so the caller can read more; this one
// authorizes a mutation, so the question "may this button exist?" is the
// whole component. Cases 5-9 are the five ways the answer is no.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture 05's `intent.data`, verbatim.
final EdenProposalData _kPending = EdenProposalData(
  actionId: '00000000-0000-4000-8000-000000000001',
  applied: false,
  status: 'pending_approval',
  expiresAt: DateTime.utc(2030, 1, 7, 0, 30),
);

/// Fixture 05's `intent.actions`, verbatim — both bound to `action_id`.
const List<EdenProposalAction> _kBothDecisions = <EdenProposalAction>[
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

/// What the envelope cannot say, supplied by the caller.
const String _kSubject = 'Create a lead for Jordan Lee';

Future<void> _pump(
  WidgetTester tester, {
  required EdenProposalData data,
  String subject = _kSubject,
  List<EdenProposalAction> actions = const <EdenProposalAction>[],
  EdenProposalDecisionCallback? onDecision,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: Scaffold(
      body: EdenProposalCard(
        data: data,
        subject: subject,
        actions: actions,
        onDecision: onDecision,
      ),
    ),
  ));
}

Finder _approve() =>
    find.byKey(const ValueKey<String>('eden-proposal-action-approve'));
Finder _reject() =>
    find.byKey(const ValueKey<String>('eden-proposal-action-reject'));

void main() {
  testWidgets('case 1: the subject leads, and it is rendered verbatim',
      (WidgetTester tester) async {
    await _pump(tester,
        data: _kPending, actions: _kBothDecisions, onDecision: (_) {});

    // THE POINT OF THE PARAMETER. The payload cannot say what is being
    // approved, so the caller must, and the card must show exactly what it
    // was given — not a generic "Approve this action?".
    expect(find.text(_kSubject), findsOneWidget);
  });

  testWidgets('case 2: the status line carries the status AND the expiry',
      (WidgetTester tester) async {
    await _pump(tester, data: _kPending);

    final Text line = tester.widget<Text>(
      find.byKey(const ValueKey<String>('eden-proposal-status')),
    );
    expect(line.data, 'pending_approval · expires 07/01/2030 00:30');
  });

  testWidgets('case 3: a granted approve fires with the bound action',
      (WidgetTester tester) async {
    EdenProposalAction? got;
    await _pump(
      tester,
      data: _kPending,
      actions: _kBothDecisions,
      onDecision: (EdenProposalAction a) => got = a,
    );

    expect(_approve(), findsOneWidget);
    expect(_reject(), findsOneWidget);

    await tester.tap(_approve());
    await tester.pump();

    expect(got?.decision, 'approve');
    expect(got?.proposalId, '00000000-0000-4000-8000-000000000001',
        reason: 'the caller sends proposal_id and decision back; neither is '
            'interpreted here.');
  });

  testWidgets('case 4: reject fires with reject, not with the first action',
      (WidgetTester tester) async {
    EdenProposalAction? got;
    await _pump(
      tester,
      data: _kPending,
      actions: _kBothDecisions,
      onDecision: (EdenProposalAction a) => got = a,
    );

    // THE SECOND CONTROL, deliberately: a card that always reported
    // `actions.first` would pass a tap on approve and silently approve
    // everything the user rejected.
    await tester.tap(_reject());
    await tester.pump();
    expect(got?.decision, 'reject');
  });

  testWidgets('case 5: `applied: true` renders NO decision controls',
      (WidgetTester tester) async {
    await _pump(
      tester,
      data: EdenProposalData(
        actionId: _kPending.actionId,
        applied: true,
        status: 'pending_approval',
        expiresAt: _kPending.expiresAt,
      ),
      actions: _kBothDecisions,
      onDecision: (_) {},
    );

    // Already committed. Re-offering the decision invites a double-apply,
    // and `applied` is payload-carried state, so suppressing on it needs no
    // judgement the renderer is not entitled to make.
    expect(_approve(), findsNothing);
    expect(_reject(), findsNothing);
    expect(find.text(_kSubject), findsOneWidget,
        reason: 'the card still states what WAS proposed; it is the controls '
            'that go, not the record.');
  });

  testWidgets('case 6: a status other than pending renders NO controls',
      (WidgetTester tester) async {
    await _pump(
      tester,
      data: EdenProposalData(
        actionId: _kPending.actionId,
        applied: false,
        status: 'rejected',
        expiresAt: _kPending.expiresAt,
      ),
      actions: _kBothDecisions,
      onDecision: (_) {},
    );

    expect(_approve(), findsNothing);
    expect(_reject(), findsNothing);
  });

  testWidgets('case 7: no actions, or no callback, renders NO controls',
      (WidgetTester tester) async {
    await _pump(tester, data: _kPending, onDecision: (_) {});
    expect(_approve(), findsNothing);

    // And a granted action with nowhere to send it is an affordance that
    // does nothing, which is worse than no affordance.
    await _pump(tester, data: _kPending, actions: _kBothDecisions);
    expect(_approve(), findsNothing);
  });

  testWidgets('case 8: an action with an EMPTY decision binds to nothing',
      (WidgetTester tester) async {
    await _pump(
      tester,
      data: _kPending,
      // `agentintent.Action` makes every binding field omitempty, so
      // `{"id": "approve"}` is legal on the wire and decodes to exactly
      // this. The caller would have nothing to send back.
      actions: const <EdenProposalAction>[
        EdenProposalAction(
          id: 'approve',
          proposalId: '00000000-0000-4000-8000-000000000001',
          decision: '',
        ),
      ],
      onDecision: (_) {},
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets(
      'case 9: an action for a DIFFERENT proposal is inert — the card '
      'would otherwise decide something the user is not looking at',
      (WidgetTester tester) async {
    bool fired = false;
    await _pump(
      tester,
      data: _kPending,
      actions: const <EdenProposalAction>[
        EdenProposalAction(
          id: 'approve',
          // NOT data.actionId. eden-biz's own integrity test asserts these
          // match for every card/proposal fixture; this is the renderer
          // re-checking rather than trusting, because a mismatch renders
          // EXACTLY like a match — same button, same label, same card — and
          // commits a decision against a proposal that is not on screen.
          proposalId: '00000000-0000-4000-8000-00000000beef',
          decision: 'approve',
        ),
      ],
      onDecision: (_) => fired = true,
    );

    expect(_approve(), findsNothing,
        reason: 'binding to another proposal is not a grant for this one');
    expect(fired, isFalse);
  });

  testWidgets('case 10: an UNKNOWN decision still renders a usable control',
      (WidgetTester tester) async {
    EdenProposalAction? got;
    await _pump(
      tester,
      data: _kPending,
      // `decision` is a free string. A value this component has never seen
      // must not vanish — the payload granted it — and must not fall
      // through to the affirmative styling, which would dress an unknown
      // decision as "approve".
      actions: const <EdenProposalAction>[
        EdenProposalAction(
          id: 'defer',
          proposalId: '00000000-0000-4000-8000-000000000001',
          decision: 'defer',
        ),
      ],
      onDecision: (EdenProposalAction a) => got = a,
    );

    final Finder defer =
        find.byKey(const ValueKey<String>('eden-proposal-action-defer'));
    expect(defer, findsOneWidget);
    expect(find.byType(FilledButton), findsNothing,
        reason: 'only `approve` gets the affirmative treatment');
    expect(find.byType(OutlinedButton), findsOneWidget);

    await tester.tap(defer);
    await tester.pump();
    expect(got?.decision, 'defer');
  });

  testWidgets(
      'case 11: an EXPIRED proposal keeps its controls — the renderer has '
      'no clock authority', (WidgetTester tester) async {
    await _pump(
      tester,
      data: EdenProposalData(
        actionId: _kPending.actionId,
        applied: false,
        status: 'pending_approval',
        // Long past, by any clock.
        expiresAt: DateTime.utc(2001, 1, 1, 0, 30),
      ),
      actions: _kBothDecisions,
      onDecision: (_) {},
    );

    // DELIBERATE, and the opposite of cases 5-9. Those suppress on state the
    // PAYLOAD carries. This would suppress on a comparison against device
    // time — skewed, unset, or in another zone, and this package never calls
    // toLocal(). Hiding a live control because a wrong local clock said so is
    // worse than showing one the server rejects with a reason. The expiry is
    // rendered so the user can see it; the server stays the authority.
    expect(_approve(), findsOneWidget);
    final Text line = tester.widget<Text>(
      find.byKey(const ValueKey<String>('eden-proposal-status')),
    );
    expect(line.data, contains('01/01/2001'));
  });
}

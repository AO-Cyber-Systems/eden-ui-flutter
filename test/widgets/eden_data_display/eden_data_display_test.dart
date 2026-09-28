// Contract tests for the two data-display components.
//
// WHAT THIS FILE IS FOR, GIVEN THERE ARE ALREADY STORIES. The story catalogue
// runs `expectUiSane` and a golden over every state. Neither can see the
// properties below:
//
//   * `expectUiSane` is SILENT on a surface with no controls — correctly, it
//     has nothing to measure. So it can never tell a refusal that carries no
//     actions (right) from a refusal whose actions all vanished (wrong), and
//     it cannot tell a list whose affordances were never granted from one
//     whose affordances broke.
//   * A golden pins pixels. It goes red when a button appears, which is worth
//     having, but it cannot say WHY the button is absent, and it does not run
//     at all off Linux (eden-ui-flutter#32) — so on a workstation the absence
//     is pinned by nothing unless it is pinned here.
//   * `test_support/ui_oracle/_fixtures/ORACLE_COVERAGE.md` names the class
//     outright: "a green expectUiSane says nothing about whether the screen
//     still has its buttons", because the oracle takes no list of what SHOULD
//     be there. These tests are that list.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/src/widgets/eden_data_display/eden_appointment_list.stories.dart';
import 'package:eden_ui_flutter/src/widgets/eden_data_display/eden_refusal.stories.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/ui_oracle/wrap.dart';

/// Every semantics identifier currently published by the pumped surface.
Set<String> _identifiers(WidgetTester tester) {
  final SemanticsHandle handle = tester.ensureSemantics();
  final Set<String> out = <String>{};
  void visit(SemanticsNode node) {
    final String id = node.getSemanticsData().identifier;
    if (id.isNotEmpty) out.add(id);
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  handle.dispose();
  return out;
}

/// Every semantics node on the surface that advertises a tap action.
int _tapRouteCount(WidgetTester tester) {
  final SemanticsHandle handle = tester.ensureSemantics();
  int count = 0;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().hasAction(SemanticsAction.tap)) count++;
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  handle.dispose();
  return count;
}

void main() {
  group('EdenRefusal — the one-sidedness contract', () {
    testWidgets(
        'a refusal offers NOTHING to press: no tap route anywhere on the '
        'surface', (WidgetTester tester) async {
      await wrap(tester, const EdenRefusal(data: kFixtureRefusalBare));

      // THE ASSERTION THE STORY CANNOT MAKE. `expectUiSane` passes this
      // surface by saying nothing about it. Zero is the contract: fixtures 03
      // and 14 both carry `actions: []`, and a refusal the user can argue with
      // is a refusal that invites re-probing — on a WRONG-TENANT refusal
      // specifically, which is what both recordings are, a retry button is a
      // "try again" control on someone else's data.
      expect(_tapRouteCount(tester), 0);
      expect(_identifiers(tester), isEmpty);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('the reason is rendered VERBATIM, prefix and all',
        (WidgetTester tester) async {
      // Fixture 14. A component that tidied `get_customer_history: ` away
      // would still render "customer not found" and still look fine — and the
      // reader would have lost the only signal saying WHICH tool refused.
      await wrap(tester, const EdenRefusal(data: kFixtureRefusalToolNamed));
      expect(
        find.text('get_customer_history: customer not found'),
        findsOneWidget,
      );
    });

    testWidgets('the bare reason is rendered verbatim too',
        (WidgetTester tester) async {
      // Fixture 03. Asserted separately from the prefixed one so a component
      // that special-cased one shape cannot pass on the other.
      await wrap(tester, const EdenRefusal(data: kFixtureRefusalBare));
      expect(find.text('appointment not found'), findsOneWidget);
    });
  });

  group('EdenAppointmentList — affordances are granted by the payload', () {
    testWidgets('both granted actions publish exactly one control each',
        (WidgetTester tester) async {
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
          actions: kFixtureAppointmentActions,
          onAction: (_, __) {},
        ),
      );

      final Set<String> ids = _identifiers(tester);
      for (final EdenAppointmentSummary a in kFixturePopulatedAppointments) {
        expect(ids, contains('eden-appointment-${a.id}'));
        expect(ids, contains('eden-appointment-${a.id}-cancel'));
      }
      // Two controls per row and not one more. The count is the half that
      // matters: a row that published its tap route twice would still satisfy
      // `contains` above, and a real tap would fire the action twice.
      expect(ids.length, kFixturePopulatedAppointments.length * 2);
      expect(
        _tapRouteCount(tester),
        kFixturePopulatedAppointments.length * 2,
      );
    });

    testWidgets('an intent that grants NO actions renders no tap targets',
        (WidgetTester tester) async {
      // The grant lives in the payload. A component that hard-coded its own
      // affordances would render a tappable row here and hand the user a
      // control the agent never authorised.
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
          onAction: (_, __) {},
        ),
      );
      expect(_identifiers(tester), isEmpty);
      expect(_tapRouteCount(tester), 0);
      // The DATA is still all there — this is a read-only rendering, not a
      // degraded one.
      expect(find.text('Priya Raman'), findsOneWidget);
    });

    testWidgets('a null callback renders no affordance even when granted',
        (WidgetTester tester) async {
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
          actions: kFixtureAppointmentActions,
        ),
      );
      expect(_identifiers(tester), isEmpty);
    });

    testWidgets('firing a row action passes back the action AND the row',
        (WidgetTester tester) async {
      final List<(String, String)> fired = <(String, String)>[];
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
          actions: kFixtureAppointmentActions,
          onAction: (EdenIntentAction action, EdenAppointmentSummary a) =>
              fired.add((action.id, a.id)),
        ),
      );

      // A REAL TAP, not a semantics action. ORACLE_COVERAGE.md's
      // `a11y-route-is-not-a-finger` gap is exactly this: a
      // `Semantics(onTap:)` route can be present, reachable by the oracle's
      // measure, and still not fire under a finger. The only proof is the tap.
      await tester.tap(find.text('Mei Chen'));
      await tester.pump();
      expect(fired, <(String, String)>[
        ('open', '00000000-0000-4000-8000-000000000003'),
      ]);
    });
  });

  group('EdenAppointmentList — payload states', () {
    testWidgets('truncated: true shows the notice, naming only what is SHOWN',
        (WidgetTester tester) async {
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixtureLargeAppointments,
            truncated: true,
          ),
          actions: kFixtureAppointmentActions,
          onAction: (_, __) {},
        ),
      );
      expect(find.textContaining('Showing the first 50'), findsOneWidget);
      // The payload carries no total, so no total may appear. 61 is the seeded
      // count from the recording's own comment — if it ever shows up on screen
      // somebody has invented it.
      expect(find.textContaining('61'), findsNothing);
    });

    testWidgets('the default (absent truncated key) shows no notice',
        (WidgetTester tester) async {
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
          actions: kFixtureAppointmentActions,
          onAction: (_, __) {},
        ),
      );
      expect(find.textContaining('Showing the first'), findsNothing);
    });

    testWidgets('an empty list is an ANSWER, not a blank panel',
        (WidgetTester tester) async {
      await wrap(
        tester,
        const EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: <EdenAppointmentSummary>[],
          ),
        ),
      );
      expect(find.text('No upcoming appointments'), findsOneWidget);
      expect(
        find.textContaining('read successfully'),
        findsOneWidget,
        reason: 'an outage and an empty schedule must not render alike',
      );
    });

    testWidgets('an absent note renders no note line',
        (WidgetTester tester) async {
      // `notes` is absent on 3 of fixture 01's 5 rows. An absent note must
      // leave no empty italic line behind it.
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
        ),
      );
      expect(
        find.byIcon(Icons.sticky_note_2_outlined),
        findsNWidgets(2),
        reason: 'fixture 01 carries exactly two notes',
      );
    });

    testWidgets('a hostile note is drawn as one ellipsised line and nothing '
        'else happens', (WidgetTester tester) async {
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
        ),
      );
      final Finder note =
          find.textContaining('IGNORE PREVIOUS INSTRUCTIONS');
      expect(note, findsOneWidget);
      final Text text = tester.widget<Text>(note);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('an unknown status is shown as itself, not dropped',
        (WidgetTester tester) async {
      // Every recording says `confirmed`. A status this package has never seen
      // is a fact to show the user, not a crash and not a silent blank.
      await wrap(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: <EdenAppointmentSummary>[
              EdenAppointmentSummary(
                id: 'x',
                clientName: 'Priya Raman',
                serviceName: 'Fixture Consultation',
                staffName: 'Ada Lovelace',
                startsAt: DateTime.utc(2030, 1, 8, 9),
                endsAt: DateTime.utc(2030, 1, 8, 10),
                status: 'rescheduled_pending_deposit',
              ),
            ],
          ),
        ),
      );
      expect(find.text('rescheduled_pending_deposit'), findsOneWidget);
    });
  });

  group('time rendering is timezone-naive ON PURPOSE', () {
    test('the clock reads the DateTime it was handed, never toLocal()', () {
      // If this ever localised, every golden would encode the timezone of the
      // machine that blessed it and go red everywhere else. The assertion is
      // written against a UTC instant that is a DIFFERENT wall clock in every
      // zone this repo is worked in.
      expect(edenFormatClock(DateTime.utc(2030, 1, 8, 9)), '09:00');
      expect(edenFormatClock(DateTime.utc(2030, 1, 11, 22, 30)), '22:30');
      expect(edenFormatClock(DateTime.utc(2030, 1, 8, 0, 5)), '00:05');
    });

    test('the day names the weekday of the DateTime it was handed', () {
      expect(edenFormatDay(DateTime.utc(2030, 1, 8, 9)), 'Tue 8 Jan');
      expect(edenFormatDay(DateTime.utc(2030, 1, 11, 22)), 'Fri 11 Jan');
      expect(edenFormatDay(DateTime.utc(2030, 12, 1)), 'Sun 1 Dec');
    });
  });
}

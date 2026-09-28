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
// `rootSemanticsNodeOf` is not on the `testing.dart` show list, and the only
// other handle on the root node is `tester.binding.pipelineOwner`, which is
// deprecated. That accessor already lives behind one scoped ignore with the
// reason, in semantics_geometry.dart; reaching it here keeps this file at
// zero new analyzer findings rather than adding a second copy of the ignore.
import 'package:eden_ui_flutter/testing/semantics_geometry.dart'
    show rootSemanticsNodeOf;
import 'package:eden_ui_flutter/src/widgets/eden_data_display/eden_appointment_list.stories.dart';
import 'package:eden_ui_flutter/src/widgets/eden_data_display/eden_refusal.stories.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/ui_oracle/wrap.dart';

/// Pumps [child] with an UNBOUNDED height, the way a conversational
/// transcript does.
///
/// WHY THIS HELPER EXISTS. `wrap()` — which every story test and every test
/// above uses — lays its child out inside a `Scaffold` body and always hands
/// it a finite height. So the entire catalogue exercised one of the two height
/// modes these components ship into, and the OTHER one is the agent-UI surface
/// they were built for: a transcript is itself a scrollable, and a scrollable
/// gives its children `maxHeight: infinity`. `Expanded` and
/// `SingleChildScrollView` both THROW there. Nothing in the repo could have
/// caught it (eden-ui-flutter#53 review).
Future<void> pumpUnbounded(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: EdenTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[child],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

  visit(rootSemanticsNodeOf(tester));
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

  visit(rootSemanticsNodeOf(tester));
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

  // -------------------------------------------------------------------------
  // The height mode the whole catalogue could not reach
  // -------------------------------------------------------------------------
  group('unbounded height — the conversational surface', () {
    testWidgets('the list renders inside a transcript instead of throwing',
        (WidgetTester tester) async {
      // Pre-fix this threw "RenderFlex children have non-zero flex but
      // incoming height constraints are unbounded", from the top-level
      // Expanded. `wrap()` always bounds height, so all 12 story runs and
      // every test above passed over it.
      await pumpUnbounded(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixturePopulatedAppointments,
          ),
          actions: kFixtureAppointmentActions,
          onAction: (_, __) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Priya Raman'), findsOneWidget);
      // SHRINK-WRAPPED, not windowed. Every row is laid out, because the
      // transcript scrolls for it — a lazy viewport here would show a few
      // rows and silently swallow the rest into a scroll nobody can reach.
      expect(find.text('Alice Anderson'), findsOneWidget);
    });

    testWidgets('the empty state renders unbounded', (WidgetTester tester) async {
      // `Center` under an infinite height is the same crash one widget down.
      await pumpUnbounded(
        tester,
        const EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: <EdenAppointmentSummary>[],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No upcoming appointments'), findsOneWidget);
    });

    testWidgets('a truncated list renders unbounded, notice and all',
        (WidgetTester tester) async {
      await pumpUnbounded(
        tester,
        EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: kFixtureLargeAppointments,
            truncated: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Showing the first 50'), findsOneWidget);
    });

    testWidgets('the refusal renders unbounded', (WidgetTester tester) async {
      // The SingleChildScrollView added for the long-reason case would throw
      // here if it were unconditional.
      await pumpUnbounded(
        tester,
        const EdenRefusal(data: kFixtureRefusalBare),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('appointment not found'), findsOneWidget);
    });
  });

  group('a long refusal reason is reachable, not clipped', () {
    testWidgets('a reason taller than the card does not overflow',
        (WidgetTester tester) async {
      // The reason is untrusted text from a tool error; its length is not
      // ours to assume. Pre-fix this overflowed the non-scrolling Column,
      // which is a debug band and SILENT CLIPPING in release -- the exact
      // "reason the reader cannot see" that refusing to ellipsise it was
      // meant to prevent.
      final String long = List<String>.filled(
        400,
        'customer not found in this tenant',
      ).join(' ');
      await wrap(tester, EdenRefusal(data: EdenRefusalData(reason: long)));

      expect(
        tester.takeException(),
        isNull,
        reason: 'a RenderFlex overflow is reported through FlutterError during '
            'layout, not thrown at the call site, so this is the only place it '
            'surfaces in a plain widget test',
      );
      // Still present and still whole -- scrolled, never truncated.
      expect(find.textContaining('customer not found in this tenant'),
          findsOneWidget);
      final Text text = tester.widget<Text>(
        find.textContaining('customer not found in this tenant'),
      );
      expect(text.maxLines, isNull, reason: 'no ellipsis on a refusal reason');
      expect(find.byType(Scrollable), findsWidgets);
    });
  });

  group('is_error is READ, not merely transcribed', () {
    testWidgets('true and false render differently',
        (WidgetTester tester) async {
      // The field carried a comment saying a dropped field "cannot later be
      // noticed changing" -- while nothing read it, so `is_error: false`
      // rendered pixel-identically and could have changed for ever unnoticed
      // (eden-ui-flutter#53 review). It now selects the tone; this is what
      // makes that claim true.
      Color borderOf(WidgetTester t) {
        final Container box = t.widget<Container>(
          find
              .descendant(
                of: find.byType(EdenRefusal),
                matching: find.byType(Container),
              )
              .first,
        );
        return ((box.decoration! as BoxDecoration).border! as Border).top.color;
      }

      await wrap(tester, const EdenRefusal(data: kFixtureRefusalBare));
      final Color errorEdge = borderOf(tester);

      await wrap(
        tester,
        const EdenRefusal(
          data: EdenRefusalData(reason: 'appointment not found', isError: false),
        ),
      );
      final Color plainEdge = borderOf(tester);

      expect(errorEdge, isNot(equals(plainEdge)));

      // AND THE CONTRACT IS UNCHANGED ON BOTH BRANCHES. The tone moves; the
      // one-sidedness does not. A non-error refusal is still a refusal.
      expect(_tapRouteCount(tester), 0);
      expect(find.text('appointment not found'), findsOneWidget);
    });
  });

  group('truncated: true with an empty list', () {
    testWidgets('renders the empty state and NO "Showing the first 0"',
        (WidgetTester tester) async {
      // Reachable only with `limit: 0`; no recording pairs the two. It used to
      // render "No upcoming appointments" directly above "Showing the first
      // 0", which is not a sentence anyone can act on.
      await wrap(
        tester,
        const EdenAppointmentList(
          data: EdenAppointmentListData(
            appointments: <EdenAppointmentSummary>[],
            truncated: true,
          ),
        ),
      );
      expect(find.text('No upcoming appointments'), findsOneWidget);
      expect(find.textContaining('Showing the first'), findsNothing);
    });
  });
}

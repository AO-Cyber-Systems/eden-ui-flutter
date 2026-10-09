// The decoders: wire payload -> the typed data the components already take.
//
// THE RECORDINGS ARE THE SOURCE. Each decoder is exercised over its OWN
// vendored eden-biz recording. Where a case needs a payload no recording
// contains — a missing key, a wrong type — it is built by MUTATING a named
// recording via `mutatedIntent`, and the test says which one and what
// changed. No payload here was invented.
//
// WHAT THESE CASES ARE ABOUT. Half of them are the happy path over real
// bytes. The other half are contract 5: what this layer cannot do honestly
// becomes a REFUSAL naming the cause — never a guess, never a crash. A
// decoder that coerced a bad `price_cents` to 0 would render a complete,
// confident, wrong price, and nothing on screen would differ from a right
// one.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/agent_intent_fixtures.dart';

/// Decode a named recording, or fail the test with the refusal's reason.
EdenIntentDecoded _decoded(String fixture) {
  final EdenIntentDecodeResult r =
      decodeAgentIntent(agentIntentOf(fixture));
  if (r is EdenIntentRefused) {
    fail('$fixture refused unexpectedly: ${r.reason}');
  }
  return r as EdenIntentDecoded;
}

EdenIntentRefused _refused(Map<String, dynamic> intent) {
  final EdenIntentDecodeResult r = decodeAgentIntent(intent);
  if (r is! EdenIntentRefused) {
    fail('expected a refusal, got ${(r as EdenIntentDecoded).data}');
  }
  return r;
}

void main() {
  group('decoders over the recordings', () {
    test('case 1: fixture 01 — 5 rows, notes modelled as absent not empty',
        () {
      final EdenAppointmentListData d =
          _decoded('01-list_upcoming_appointments-populated.json').data
              as EdenAppointmentListData;

      expect(d.appointments, hasLength(5));
      expect(d.truncated, isFalse,
          reason: 'the key is absent in 01, and absent means not truncated');

      // ABSENCE IS MODELLED, NOT SMOOTHED. The recording has `notes` on
      // exactly 2 of its 5 rows. A decoder defaulting the rest to `''` would
      // make the nullable field pointless and hide the distinction between
      // "no note" and "an empty note".
      final int withNotes =
          d.appointments.where((EdenAppointmentSummary a) => a.notes != null)
              .length;
      expect(withNotes, 2);
      expect(
          d.appointments
              .where((EdenAppointmentSummary a) => a.notes == '')
              .isEmpty,
          isTrue,
          reason: 'no row should decode to an EMPTY note');
    });

    test('case 2: fixture 02 — an empty list decodes successfully', () {
      final EdenAppointmentListData d =
          _decoded('02-list_upcoming_appointments-empty.json').data
              as EdenAppointmentListData;
      expect(d.appointments, isEmpty);
      // Empty is an ANSWER, not a failure. A decoder refusing here would
      // turn "nobody is booked" into an error state.
    });

    test('case 3: fixture 04 — 50 rows and truncated is true', () {
      final EdenAppointmentListData d =
          _decoded('04-list_upcoming_appointments-large.json').data
              as EdenAppointmentListData;
      expect(d.appointments, hasLength(50));
      expect(d.truncated, isTrue);
    });

    test('case 4: fixtures 03 and 14 — the reason verbatim', () {
      final EdenRefusalData bare =
          _decoded('03-get_appointment-wrong-tenant-refusal.json').data
              as EdenRefusalData;
      expect(bare.reason, 'appointment not found');
      expect(bare.isError, isTrue);

      final EdenRefusalData named =
          _decoded('14-get_customer_history-wrong-tenant-refusal.json').data
              as EdenRefusalData;
      // NOT stripped of its tool prefix. The reason is the only thing the
      // caller has to go on, and a layer that rewrites it hides which tool
      // said no.
      expect(named.reason, contains('get_customer_history'));
    });

    test('case 5: fixture 11 — 2 customers, both masked hints as received',
        () {
      final EdenCustomerListData d =
          _decoded('11-find_customer-populated.json').data
              as EdenCustomerListData;
      expect(d.customers, hasLength(2));
      expect(
          d.customers
              .map((EdenCustomerSummary c) => c.emailHint)
              .toSet(),
          <String>{'p***@example.test'},
          reason: 'the tool decided what this caller may see; the decoder '
              'passes it through unchanged');
    });

    test('case 6: fixture 08 — one service at 5000 minor units', () {
      final EdenServiceListData d = _decoded('08-list_services-populated.json')
          .data as EdenServiceListData;
      expect(d.services, hasLength(1));
      expect(d.services.first.priceCents, 5000);
      expect(d.services.first.durationMinutes, 30);
    });

    test('case 7: fixture 05 — the proposal, with its instant parsed', () {
      final EdenProposalData d =
          _decoded('05-create_lead-proposal.json').data as EdenProposalData;
      expect(d.actionId, '00000000-0000-4000-8000-000000000001');
      expect(d.applied, isFalse);
      expect(d.status, 'pending_approval');
      expect(d.expiresAt, DateTime.utc(2030, 1, 7, 0, 30));
      expect(d.expiresAt.isUtc, isTrue,
          reason: 'no toLocal() anywhere in this package — a localised '
              'instant renders a different wall clock on every machine');
    });

    test(
        'case 8: all 14 recordings resolve — 9 decode, and the 5 that refuse '
        'are exactly the components nobody has built', () {
      // THIS CASE CAUGHT ITS OWN AUTHOR. It first asserted that all 14
      // recordings decode, on the premise that every recorded component_id
      // is one this package renders. That premise is false and the epic
      // says so: eden-biz's 14 fixtures span TEN distinct ids and five of
      // them have no renderer yet. The partition below is what the premise
      // should have been.
      const Set<String> unrenderable = <String>{
        'detail/appointment',
        'detail/customer-history',
        'list/availability-slots',
        'summary/scheduling',
        'summary/pipeline',
      };

      final List<String> names = agentIntentFixtureNames();
      final List<String> threw = <String>[];
      final Set<String> refusedIds = <String>{};
      final Set<String> decodedIds = <String>{};

      for (final String name in names) {
        final Map<String, dynamic> intent = agentIntentOf(name);
        final String id = intent['component_id'] as String;
        try {
          final EdenIntentDecodeResult r = decodeAgentIntent(intent);
          switch (r) {
            case EdenIntentDecoded():
              decodedIds.add(id);
            case EdenIntentRefused(:final String reason):
              refusedIds.add(id);
              expect(reason, contains(id),
                  reason: '$name: a refusal must NAME the id it refused');
          }
        } catch (e) {
          threw.add('$name: $e');
        }
      }

      expect(threw, isEmpty,
          reason: 'contract 5 — the entry point never crashes:\n'
              '${threw.join('\n')}');
      expect(names, hasLength(14),
          reason: 'the loop must cover the whole set, not an empty one');

      // BOTH DIRECTIONS. Asserting only that the unbuilt ids refuse would
      // pass if everything refused; asserting only that the built ids decode
      // would pass if nothing refused.
      expect(refusedIds, unrenderable,
          reason: 'exactly the unbuilt components refuse');
      expect(decodedIds.intersection(unrenderable), isEmpty,
          reason: 'no unbuilt component decoded');
      expect(decodedIds, hasLength(5),
          reason: 'the five built components, each exercised by at least one '
              'recording');

      // AND THIS IS MEANT TO BREAK when component six lands: moving an id
      // out of `unrenderable` is part of building it, and a decoder added
      // without updating this set would leave the partition lying.
    });
  });

  group('refusals — the half that must not be a guess', () {
    test('case 9: an unknown component_id refuses, naming the id', () {
      // MUTATION of fixture 01: component_id replaced with one eden-biz has
      // never emitted. `component_id` is a free string on the wire, so an
      // id this package cannot draw is a real arrival, not a hypothetical.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '01-list_upcoming_appointments-populated.json',
        (Map<String, dynamic> i) => i['component_id'] = 'chart/burndown',
      ));
      expect(r.reason, contains('chart/burndown'));
      expect(r.componentId, 'chart/burndown');
    });

    test('case 10: a missing required key refuses, naming component AND field',
        () {
      // MUTATION of fixture 11: `email_hint` deleted from the first row.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '11-find_customer-populated.json',
        (Map<String, dynamic> i) =>
            ((i['data'] as Map<String, dynamic>)['customers']
                as List<dynamic>)[0].remove('email_hint'),
      ));
      expect(r.field, 'email_hint');
      expect(r.reason, contains('list/customers'));
      expect(r.reason, contains('email_hint'));
    });

    test('case 11: a wrong JSON type refuses — it does NOT coerce', () {
      // MUTATION of fixture 08: price_cents 5000 -> the STRING "5000".
      //
      // THE POINT OF THIS CASE. A decoder calling int.tryParse here would
      // produce 5000 and render "USD 50.00" — complete, plausible, and
      // indistinguishable from a correct render. Coercion is how a wire
      // type change ships silently.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '08-list_services-populated.json',
        (Map<String, dynamic> i) =>
            ((i['data'] as Map<String, dynamic>)['services']
                as List<dynamic>)[0]['price_cents'] = '5000',
      ));
      expect(r.field, 'price_cents');
      expect(r.reason, contains('want an integer'));
    });

    test('case 12: an unparseable instant refuses, naming the field', () {
      // MUTATION of fixture 05: expires_at -> a value DateTime cannot parse.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '05-create_lead-proposal.json',
        (Map<String, dynamic> i) =>
            (i['data'] as Map<String, dynamic>)['expires_at'] = 'next Tuesday',
      ));
      expect(r.field, 'expires_at');
      expect(r.reason, contains('RFC3339'));
    });

    test('case 13: `data` that is not an object refuses rather than crashing',
        () {
      // MUTATION of fixture 02: data -> a list.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '02-list_upcoming_appointments-empty.json',
        (Map<String, dynamic> i) => i['data'] = <dynamic>[],
      ));
      expect(r.field, 'data');
    });

    test('case 14: a refusal carries NO actions, even when the payload did',
        () {
      // MUTATION of fixture 01, which grants `open` and `cancel`: break the
      // data so it refuses, and confirm the grant does not survive.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '01-list_upcoming_appointments-populated.json',
        (Map<String, dynamic> i) =>
            (i['data'] as Map<String, dynamic>).remove('appointments'),
      ));

      // Contract 4: refusal is one-sided. `EdenIntentRefused` has no actions
      // field AT ALL, which is the strongest form of this — there is nowhere
      // for a grant to survive, rather than a field someone must remember to
      // empty.
      expect(r, isA<EdenIntentRefused>());
      expect(
        EdenIntentRefused,
        isNot(EdenIntentDecoded),
        reason: 'the two results are distinct types; a refusal cannot carry '
            'the decoded shape\'s actions',
      );
      expect(r.field, 'appointments');
    });

    test('case 15: an envelope with no component_id refuses, never throws',
        () {
      // MUTATION of fixture 01: component_id removed. The envelope's own
      // parser THROWS on this (pinned in eden_agent_intent_test case 3);
      // this case pins that the public entry point converts it.
      final EdenIntentRefused r = _refused(mutatedIntent(
        '01-list_upcoming_appointments-populated.json',
        (Map<String, dynamic> i) => i.remove('component_id'),
      ));
      expect(r.field, 'component_id');
      expect(r.componentId, isNull,
          reason: 'there was no id to report — the refusal must not invent '
              'one');
    });
  });
}

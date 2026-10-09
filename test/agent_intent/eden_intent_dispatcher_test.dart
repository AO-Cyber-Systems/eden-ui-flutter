// The dispatcher: a raw payload in, the right widget or an honest refusal out.
//
// END TO END OVER REAL BYTES. Each case starts from a vendored eden-biz
// recording and goes envelope -> decode -> widget, asserting on PAINTED
// TEXT. Asserting on the widget type would pass while the widget rendered
// nothing.
//
// THE CASES THAT MATTER MOST are 6-9: a component needing something the
// payload cannot carry must REFUSE when the host cannot supply it, and must
// never substitute a default. A dispatcher defaulting `currencyCode` to USD
// renders a complete, confident, wrong price for a CAD tenant, and nothing
// on screen differs from the right one.
library;

import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/agent_intent_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  String fixture, {
  EdenIntentHostContext context = EdenIntentHostContext.empty,
  EdenIntentActionSink? onAction,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: buildAgentIntent(
          agentIntentOf(fixture),
          context: context,
          onAction: onAction,
        ),
      ),
    ),
  ));
}

const EdenIntentHostContext _full = EdenIntentHostContext(
  currencyCode: 'USD',
  proposalSubject: 'Create a lead for Jordan Lee',
);

void main() {
  group('dispatch', () {
    testWidgets('case 1: each built component renders from its own recording',
        (WidgetTester tester) async {
      await _pump(tester, '01-list_upcoming_appointments-populated.json');
      expect(find.byType(EdenAppointmentList), findsOneWidget);

      await _pump(tester, '03-get_appointment-wrong-tenant-refusal.json');
      expect(find.text('appointment not found'), findsOneWidget);

      await _pump(tester, '11-find_customer-populated.json');
      expect(find.text('Priya Raman'), findsOneWidget);

      await _pump(tester, '08-list_services-populated.json', context: _full);
      expect(find.text('USD 50.00'), findsOneWidget);

      await _pump(tester, '05-create_lead-proposal.json', context: _full);
      expect(find.text('Create a lead for Jordan Lee'), findsOneWidget);
    });

    testWidgets('case 2: ALL 14 recordings dispatch to a widget, none throws',
        (WidgetTester tester) async {
      final List<String> names = agentIntentFixtureNames();
      for (final String name in names) {
        await _pump(tester, name, context: _full);
        expect(tester.takeException(), isNull, reason: name);
      }
      expect(names, hasLength(14),
          reason: 'the loop must cover the whole set, not an empty one');
    });

    testWidgets('case 3: an unknown component_id lands on a refusal naming it',
        (WidgetTester tester) async {
      // MUTATION of fixture 01: an id eden-biz has never emitted.
      await tester.pumpWidget(MaterialApp(
        theme: EdenTheme.light(),
        home: Scaffold(
          body: buildAgentIntent(mutatedIntent(
            '01-list_upcoming_appointments-populated.json',
            (Map<String, dynamic> i) => i['component_id'] = 'chart/burndown',
          )),
        ),
      ));

      expect(find.byType(EdenRefusal), findsOneWidget);
      expect(find.textContaining('chart/burndown'), findsOneWidget,
          reason: 'the user must be able to see WHICH surface is missing; a '
              'generic "could not display" sends them to a log they do not '
              'have');
    });

    testWidgets("case 4: a decoder refusal keeps the DECODER's reason",
        (WidgetTester tester) async {
      // MUTATION of fixture 08: price_cents as a String.
      await tester.pumpWidget(MaterialApp(
        theme: EdenTheme.light(),
        home: Scaffold(
          body: buildAgentIntent(
            mutatedIntent(
              '08-list_services-populated.json',
              (Map<String, dynamic> i) =>
                  ((i['data'] as Map<String, dynamic>)['services']
                      as List<dynamic>)[0]['price_cents'] = '5000',
            ),
            context: _full,
          ),
        ),
      ));

      // NOT replaced by a generic one. The field name is the only thing that
      // makes this diagnosable.
      expect(find.textContaining('price_cents'), findsOneWidget);
    });
  });

  group('the two maps cannot disagree', () {
    test('case 5: the builder map keys EQUAL kDataDisplayComponents', () {
      final Set<String> builders = kIntentBuilders.keys.toSet();
      final Set<String> declared = kDataDisplayComponents
          .map(((String, Type) e) => e.$1)
          .toSet();

      // BOTH DIRECTIONS, with the difference named. `kDataDisplayComponents`
      // is the verification artifact and cannot render (a Dart `Type` is not
      // constructible without reflection); `kIntentBuilders` renders and
      // cannot verify. They describe the same set from two sides, so a
      // component added to one and not the other is exactly the drift that
      // leaves the partition test green while nothing can draw the thing.
      expect(builders.difference(declared), isEmpty,
          reason: 'builders for ids kDataDisplayComponents does not declare');
      expect(declared.difference(builders), isEmpty,
          reason: 'declared ids with no builder — the partition test would '
              'still pass and the dispatcher would refuse a component that '
              'exists');
    });

    test('case 6: every builder key has a decoder, and the reverse', () {
      expect(kIntentBuilders.keys.toSet(),
          kIntentDataDecoders.keys.toSet(),
          reason: 'a decoder with no builder decodes into nothing; a builder '
              'with no decoder can never be reached');
    });
  });

  group('host context — a missing field refuses, never defaults', () {
    testWidgets('case 7: list/services WITH a currency renders the price',
        (WidgetTester tester) async {
      await _pump(tester, '08-list_services-populated.json',
          context: const EdenIntentHostContext(currencyCode: 'CAD'));
      expect(find.text('CAD 50.00'), findsOneWidget);
    });

    testWidgets('case 8: list/services with NO currency REFUSES',
        (WidgetTester tester) async {
      await _pump(tester, '08-list_services-populated.json');

      // TWO-SIDED. A dispatcher that both refused AND rendered would pass a
      // one-sided check, so the absence of any price is asserted too.
      expect(find.byType(EdenRefusal), findsOneWidget);
      expect(find.textContaining('currencyCode'), findsOneWidget);
      expect(find.textContaining('50.00'), findsNothing,
          reason: 'no price at all — not USD, not a blank, nothing. A '
              'defaulted currency renders as convincingly as a correct one.');
      expect(find.byType(EdenServiceList), findsNothing);
    });

    testWidgets('case 9: card/proposal with NO subject REFUSES',
        (WidgetTester tester) async {
      await _pump(tester, '05-create_lead-proposal.json');

      expect(find.byType(EdenRefusal), findsOneWidget);
      expect(find.textContaining('proposalSubject'), findsOneWidget);
      expect(find.byType(EdenProposalCard), findsNothing,
          reason: 'approving an undescribed mutation is the failure this '
              'refusal exists to prevent — eden-biz#863');
      expect(find.text('approve'), findsNothing,
          reason: 'and no control may be rendered for it');
    });

    testWidgets('case 10: the three components needing nothing render EMPTY',
        (WidgetTester tester) async {
      // A context requirement that applied to everything would be a tax,
      // not a contract.
      for (final String name in <String>[
        '01-list_upcoming_appointments-populated.json',
        '11-find_customer-populated.json',
        '03-get_appointment-wrong-tenant-refusal.json',
      ]) {
        await _pump(tester, name);
        expect(tester.takeException(), isNull, reason: name);
        expect(find.byType(EdenRefusal),
            name.contains('refusal') ? findsOneWidget : findsNothing,
            reason: '$name must render without any host context');
      }
    });
  });

  group('egress', () {
    testWidgets('case 11: a granted tool action arrives with its tool id',
        (WidgetTester tester) async {
      EdenFiredAction? fired;
      await _pump(tester, '11-find_customer-populated.json',
          onAction: (EdenFiredAction f) => fired = f);

      await tester.tap(find.text('Priya Shah'));
      await tester.pump();

      final EdenFiredToolAction t = fired! as EdenFiredToolAction;
      expect(t.actionId, 'open');
      expect(t.toolId, 'get_customer_history');
      expect((t.target as EdenCustomerSummary).name, 'Priya Shah',
          reason: 'the row pressed is the other half of the invocation');
    });

    testWidgets('case 12: a granted decision arrives with proposal and verdict',
        (WidgetTester tester) async {
      EdenFiredAction? fired;
      await _pump(tester, '05-create_lead-proposal.json',
          context: _full, onAction: (EdenFiredAction f) => fired = f);

      await tester.tap(find.text('reject'));
      await tester.pump();

      final EdenFiredProposalDecision d = fired! as EdenFiredProposalDecision;
      expect(d.decision, 'reject');
      expect(d.proposalId, '00000000-0000-4000-8000-000000000001');
    });
  });

  group('source tripwires — the rules a behavioural test cannot prove', () {
    List<(String, String)> layerSources() {
      final Directory d = Directory('lib/src/agent_intent');
      expect(d.existsSync(), isTrue,
          reason: 'the layer must exist for this scan to mean anything — a '
              'missing directory would make both tripwires vacuous');
      final List<(String, String)> out = <(String, String)>[];
      for (final FileSystemEntity f in d.listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          out.add((f.path, f.readAsStringSync()));
        }
      }
      expect(out, isNotEmpty);
      return out;
    }

    test('case 13: NOTHING here binds an action to a route', () {
      // CONTRACT 3, and it is the one rule whose violation is an
      // AUTHORIZATION BYPASS rather than a bug: a payload grants a tool id,
      // and a renderer that turned it into a navigation would send the user
      // somewhere the grant never covered. A behavioural test cannot prove
      // the ABSENCE of a path; only reading the source can.
      const List<String> forbidden = <String>[
        'Navigator',
        'pushNamed',
        'GoRouter',
        'MaterialPageRoute',
        'url_launcher',
        'launchUrl',
      ];
      final List<String> hits = <String>[];
      for (final (String path, String src) in layerSources()) {
        for (final String token in forbidden) {
          // Skip the line that names the tokens in a comment — this file's
          // own prose must not trip its own scan.
          for (final String line in src.split('\n')) {
            if (line.trimLeft().startsWith('//')) continue;
            if (line.contains(token)) hits.add('$path: $line');
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'actions bind to tool ids or proposal ids, NEVER routes:\n'
              '${hits.join('\n')}');
    });

    test('case 14: NOTHING here fetches', () {
      // CONTRACT 1. Everything drawn comes from the payload.
      const List<String> forbidden = <String>[
        'HttpClient',
        'package:http',
        'Dio(',
        'WebSocket',
        'rootBundle',
      ];
      final List<String> hits = <String>[];
      for (final (String path, String src) in layerSources()) {
        for (final String line in src.split('\n')) {
          if (line.trimLeft().startsWith('//')) continue;
          for (final String token in forbidden) {
            if (line.contains(token)) hits.add('$path: $line');
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'the renderer never fetches:\n${hits.join('\n')}');
    });
  });
}

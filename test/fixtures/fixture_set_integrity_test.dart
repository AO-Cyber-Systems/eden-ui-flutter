// The drift gate on the vendored eden-biz agent-intent recordings.
//
// WHY A GATE AND NOT JUST A COPY. Every decoder test in this objective is
// worth exactly as much as the claim that these 14 files are the payloads
// eden-biz actually emits. They are a COPY of
// `go/internal/agentintent/testdata/` on eden-biz `origin/main`, and a copy
// drifts silently: eden-biz re-records, these stay, and a decoder keeps
// passing against a wire format that no longer exists. The copy therefore
// arrives with its own detector.
//
// THE RECIPE IS NOT OURS. `manifest.json` states how the set hash is
// computed, and that computation is performed by Go code in another repo:
//
//   *.json in this directory except manifest.json, file names sorted
//   bytewise (LC_ALL=C), one line per file
//   "<sha256 hex of the file bytes><two spaces><filename>\n",
//   set hash = sha256 hex of the concatenated lines
//
// So the hash function is SPECIFIED, not chosen. `golden_uniqueness_test`
// deliberately compares base64 bytes rather than declare `crypto`, and that
// was right there — it compares two local files to each other, where any
// injective function works. Here the value has to match a number another
// repo produced, so it must be sha256.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'agent_intent_fixtures.dart';

void main() {
  test('case 1: the set is exactly the 14 recordings plus the manifest', () {
    final List<String> names = agentIntentFixtureNames();
    expect(names.length, 14,
        reason: 'eden-biz records 14 fixtures. The COUNT is named here on '
            'purpose: a vendoring that dropped one would otherwise leave '
            'every per-file check passing over a smaller set.');
    expect(names.contains('manifest.json'), isFalse,
        reason: 'the manifest is not one of the hashed files');
  });

  test('case 2: every file digest matches its manifest entry', () {
    final Map<String, dynamic> manifest = loadAgentIntentManifest();
    final List<dynamic> entries = manifest['fixtures'] as List<dynamic>;
    final List<String> wrong = <String>[];

    for (final dynamic raw in entries) {
      final Map<String, dynamic> e = raw as Map<String, dynamic>;
      final String file = e['file'] as String;
      final String want = e['sha256'] as String;
      final String got =
          sha256.convert(readAgentIntentFixtureBytes(file)).toString();
      if (got != want) wrong.add('$file: want $want got $got');
    }

    expect(wrong, isEmpty,
        reason: 'a single edited or corrupted recording, named:\n'
            '${wrong.join('\n')}');
  });

  test('case 3: the recomputed set hash matches the vendored manifest', () {
    expect(computeAgentIntentSetHash(),
        loadAgentIntentManifest()['set_sha256'] as String,
        reason: 'the manifest is stale against the files sitting beside it');
  });

  test('case 4: the vendored manifest matches the hash pinned to eden-biz',
      () {
    // TWO ASSERTIONS, NOT ONE, and neither detects the other's failure.
    //
    // Case 3 alone passes if someone re-vendors a DIFFERENT set together
    // with its matching manifest — internally consistent, silently newer.
    // Case 4 alone passes if the manifest is stale against its own files.
    // Only both together say "these are the payloads eden-biz emits".
    expect(
      loadAgentIntentManifest()['set_sha256'],
      kAgentIntentFixtureSetSha256,
      reason: 'The vendored recordings are no longer eden-biz origin/main\'s '
          'set. If eden-biz re-recorded deliberately, re-vendor:\n'
          '  cd <an eden-biz checkout> && git fetch origin main\n'
          '  for f in \$(git ls-tree --name-only origin/main '
          'go/internal/agentintent/testdata/ | grep "\\.json\$"); do \\\n'
          '    git show "origin/main:\$f" > '
          '<eden-ui>/test/fixtures/agentintent/\$(basename \$f); done\n'
          'then update kAgentIntentFixtureSetSha256 and re-run the decoder '
          'suite — the wire format may have changed under it.',
    );
  });

  test('case 5: manifest entries and files are exhaustive BOTH ways', () {
    final Set<String> onDisk = agentIntentFixtureNames().toSet();
    final Set<String> inManifest = (loadAgentIntentManifest()['fixtures']
            as List<dynamic>)
        .map((dynamic e) => (e as Map<String, dynamic>)['file'] as String)
        .toSet();

    // A ONE-SIDED CHECK PASSES WHILE THE OTHER SIDE DRIFTS: a file with no
    // entry is unhashed, and an entry with no file is a recording that
    // silently vanished.
    expect(onDisk.difference(inManifest), isEmpty,
        reason: 'vendored files absent from the manifest');
    expect(inManifest.difference(onDisk), isEmpty,
        reason: 'manifest names recordings that are not here');
  });

  test('case 6: every recording parses and carries the envelope keys', () {
    for (final String name in agentIntentFixtureNames()) {
      final Map<String, dynamic> fx = loadAgentIntentFixture(name);
      expect(fx['format'], isA<String>(), reason: '$name: format');
      expect(fx['case'], isA<String>(), reason: '$name: case');
      expect(fx['source'], isA<Map<String, dynamic>>(),
          reason: '$name: source');
      expect(fx['intent'], isA<Map<String, dynamic>>(),
          reason: '$name: intent');
    }
  });

  test('case 7: every intent.component_id is non-empty', () {
    for (final String name in agentIntentFixtureNames()) {
      final Map<String, dynamic> intent =
          loadAgentIntentFixture(name)['intent'] as Map<String, dynamic>;
      final Object? id = intent['component_id'];
      expect(id, isA<String>(), reason: '$name');
      expect((id as String).isNotEmpty, isTrue, reason: '$name');
    }
  });

  test('case 8: every card/proposal action binds to data.action_id', () {
    // eden-biz asserts this itself (fixtures_integrity_test.go:172). It is
    // re-asserted here because `EdenProposalCard` REFUSES to render a control
    // for an action whose proposal_id differs — so if a vendored recording
    // ever violated it, the card would correctly render nothing and the
    // decoder test would look like a renderer bug.
    int checked = 0;
    for (final String name in agentIntentFixtureNames()) {
      final Map<String, dynamic> intent =
          loadAgentIntentFixture(name)['intent'] as Map<String, dynamic>;
      if (intent['component_id'] != 'card/proposal') continue;
      final Map<String, dynamic> data =
          intent['data'] as Map<String, dynamic>;
      final Object? actionId = data['action_id'];
      expect(actionId, isA<String>(), reason: '$name: data.action_id');
      for (final dynamic raw in intent['actions'] as List<dynamic>) {
        expect((raw as Map<String, dynamic>)['proposal_id'], actionId,
            reason: '$name: action ${raw['id']} decides another proposal');
      }
      checked++;
    }
    expect(checked, greaterThan(0),
        reason: 'no card/proposal recording was examined, so this case '
            'asserted nothing — the loop silently covering zero fixtures is '
            'exactly the shape of a check that cannot fail.');
  });

  test('case 9: the loader returns a parsed recording by name', () {
    final Map<String, dynamic> fx =
        loadAgentIntentFixture('05-create_lead-proposal.json');
    expect(
        (fx['intent'] as Map<String, dynamic>)['component_id'], 'card/proposal');
  });

  test('case 10: an unknown fixture name FAILS LOUDLY', () {
    // Returning null would let a decoder test assert nothing at all against
    // a typo'd filename and still report green.
    expect(
      () => loadAgentIntentFixture('99-does-not-exist.json'),
      throwsA(isA<ArgumentError>().having(
        (ArgumentError e) => e.toString(),
        'message',
        allOf(contains('99-does-not-exist.json'),
            contains('05-create_lead-proposal.json')),
      )),
      reason: 'the error must name the miss AND list what is available',
    );
  });

  test('case 11: the JSON codec round-trips the loader output', () {
    final Map<String, dynamic> fx =
        loadAgentIntentFixture('03-get_appointment-wrong-tenant-refusal.json');
    expect(jsonDecode(jsonEncode(fx)), equals(fx));
  });
}

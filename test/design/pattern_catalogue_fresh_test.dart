// test/design/pattern_catalogue_fresh_test.dart
//
// The freshness gate for `design/patterns.json`, the machine catalogue DevFlow
// reads as `df-tools ui spec validate <spec> --patterns design/patterns.json`
// (Surface Spec §4.5 invariant I5).
//
// It regenerates the catalogue IN MEMORY from the front matter of
// `design/patterns/*.md` and compares it against the committed JSON — it never
// writes. Both directions fail here:
//
//   * a pattern doc edited without regenerating  -> the JSON is stale
//   * the JSON edited by hand                    -> it no longer matches the docs
//
// and, one level down, the front matter itself is locked to the prose: a rule
// added to a doc body and left unclassified fails, and a front-matter term with
// no prose behind it fails. A generated file that can go stale silently is the
// defect this whole programme is about.
//
// See tool/gen_pattern_catalogue.dart for the generator this mirrors.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_pattern_catalogue.dart';

/// Resolves the package root from the CURRENT working directory rather than a
/// hardcoded absolute path (`edenbiz-website-tests-gated-on-absolute-paths`),
/// asserting the resolution up front with a clear message.
String _repoRoot() {
  final root = Directory.current.path;
  if (!File('$root/pubspec.yaml').existsSync()) {
    fail('pattern_catalogue_fresh_test: expected to run from the '
        'eden_ui_flutter package root (pubspec.yaml not found under '
        'Directory.current="$root"). Run `flutter test` from the package root.');
  }
  return root;
}

// ── Fixture builders ────────────────────────────────────────────────────────
// Hand-built factories, not hand-typed sample documents: each case below states
// only the one thing it varies, so a reader can see what makes it red.

/// A minimal, VALID pattern doc: the seven headings, one unconditional
/// interaction rule, one scoped one, and front matter that classifies both.
String buildPatternDoc({
  String id = 'sample-pattern',
  String? kind = 'toggle',
  List<String> mustNot = const <String>['fire twice per activation'],
  List<String> mustNotScoped = const <String>['change route'],
  List<String> interactionRuleTerms = const <String>[
    'fire twice per activation',
    'change route',
  ],
  List<String> accessibilityTerms = const <String>[],
}) {
  final fm = StringBuffer()
    ..writeln('---')
    ..writeln('id: $id');
  if (kind != null) fm.writeln('kind: $kind');
  if (mustNot.isNotEmpty || kind != null) {
    fm.writeln('must_not: ${jsonEncode(mustNot)}');
    fm.writeln('must_not_scoped: ${jsonEncode(mustNotScoped)}');
  }
  fm.writeln('---');

  String rules(List<String> terms) => terms.isEmpty
      ? 'No rules.\n'
      : terms.map((t) => '- `must_not: $t` — a rule.\n').join();

  return '$fm'
      '# Sample pattern\n\n'
      '## Intent\nA fixture.\n\n'
      '## Widgets\nNone.\n\n'
      '## States\nOne.\n\n'
      '## Interaction rules\n${rules(interactionRuleTerms)}\n'
      '## Breakpoints\nNone.\n\n'
      '## Content\nNone.\n\n'
      '## Accessibility\n${rules(accessibilityTerms)}';
}

/// The closed vocabulary, for the unit cases that do not touch disk.
Set<String> _sampleVocabulary() => <String>{
      'fire twice per activation',
      'change route',
      'cover sibling hit rects',
      'render below the tap target floor',
    };

void main() {
  // ── Case 1: the catalogue exists and is non-vacuous ──────────────────────
  test('case 1: every pattern doc carries parseable front matter', () {
    final root = _repoRoot();
    final entries = readPatterns(root);
    expect(
      entries,
      isNotEmpty,
      reason: 'design/patterns/ produced no catalogue entries, so every other '
          'check in this file would pass over an empty list.',
    );
    expect(
      entries.length,
      patternFiles(root).length,
      reason: 'one catalogue entry per pattern doc, no more and no fewer.',
    );
  });

  // ── Case 2: the both-directions staleness lock ───────────────────────────
  test(
      'case 2: design/patterns.json matches design/patterns/ '
      '(stale from either direction fails)', () {
    final root = _repoRoot();
    final file = File('$root/$kCataloguePath');
    expect(
      file.existsSync(),
      isTrue,
      reason: '$kCataloguePath is missing — it is the file DevFlow reads with '
          '`--patterns`, and without it §4.5 I5 reports PAT000/UNCHECKED on '
          'every spec. Generate it with: $kRegenerateCommand',
    );

    final expected = generateCatalogue(root);
    final existing = file.readAsStringSync();
    if (expected != existing) {
      final e = expected.split('\n');
      final a = existing.split('\n');
      var i = 0;
      while (i < e.length && i < a.length && e[i] == a[i]) {
        i++;
      }
      fail('$kCataloguePath is stale against design/patterns/.\n'
          '  first difference: line ${i + 1}\n'
          '  expected: ${i < e.length ? e[i] : '<EOF>'}\n'
          '  found:    ${i < a.length ? a[i] : '<EOF>'}\n'
          'Regenerate with: $kRegenerateCommand');
    }
  });

  // ── Case 3: the shape DevFlow actually reads ─────────────────────────────
  test('case 3: the committed catalogue is in the shape ui-spec-validate reads',
      () {
    final root = _repoRoot();
    final decoded =
        jsonDecode(File('$root/$kCataloguePath').readAsStringSync());
    expect(decoded, isA<Map<String, Object?>>(),
        reason: 'DevFlow accepts a JSON array or an object with a `patterns` '
            'array; this package ships the object form.');
    final patterns = (decoded as Map)['patterns'];
    expect(patterns, isA<List<Object?>>());

    final ids = <String>{};
    for (final entry in (patterns as List).cast<Map<String, Object?>>()) {
      final id = entry['id'];
      expect(id, isA<String>(), reason: 'every entry resolves by `id`.');
      expect(ids.add(id! as String), isTrue, reason: 'ids are unique.');
      expect(
        entry.keys.toSet().difference(<String>{'id', 'kind', 'must_not'}),
        isEmpty,
        reason: 'ui-spec-validate.cjs reads {id, kind?, must_not?} and nothing '
            'else; an extra key is data no consumer will ever see.',
      );
      if (entry.containsKey('kind')) {
        expect(entry['must_not'], isA<List<Object?>>(),
            reason: 'PAT002 groups `must_not` by `kind`: a kind with no '
                'must_not inherits nothing and should not carry a kind.');
      }
    }
  });

  // ── Case 4: every emitted kind is one the Surface Spec schema admits ─────
  test('case 4: every emitted kind is a Surface Spec control kind', () {
    final root = _repoRoot();
    for (final entry in readPatterns(root)) {
      if (entry.kind == null) continue;
      expect(
        kControlKinds,
        contains(entry.kind),
        reason: '${entry.fileName} emits kind "${entry.kind}", which '
            'devflow/schemas/surface-spec.schema.json does not admit. A spec '
            'could never declare a control of that kind, so the entry would be '
            'unreachable.',
      );
    }
  });

  // ── Case 5: every emitted must_not term is in the closed vocabulary ──────
  test('case 5: every emitted must_not term is in must_not_vocabulary.json',
      () {
    final root = _repoRoot();
    final vocabulary = readVocabulary(root);
    for (final entry in readPatterns(root)) {
      for (final term in entry.mustNot) {
        expect(
          vocabulary,
          contains(term),
          reason: '${entry.fileName} inherits "$term", which is not in '
              '$kVocabularyPath. DevFlow validates control `must_not` terms '
              '(CTRL007) against exactly that file, so no conforming spec '
              'could ever declare it.',
        );
      }
    }
  });

  // ── Case 6: the lock refuses an INVENTED term (front matter -> prose) ────
  test('case 6: a front-matter term the body never states is refused', () {
    expect(
      () => parsePattern(
        buildPatternDoc(
          mustNot: const <String>['fire twice per activation'],
          mustNotScoped: const <String>['change route', 'cover sibling hit rects'],
          interactionRuleTerms: const <String>[
            'fire twice per activation',
            'change route',
          ],
        ),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('which the doc body never states'),
      )),
      reason: 'the prose is the source of truth; front matter classifies it, '
          'it does not add to it.',
    );
  });

  // ── Case 7: the lock refuses an UNCLASSIFIED term (prose -> front matter) ─
  test('case 7: a body rule the front matter does not classify is refused', () {
    expect(
      () => parsePattern(
        buildPatternDoc(
          mustNot: const <String>['fire twice per activation'],
          mustNotScoped: const <String>[],
          interactionRuleTerms: const <String>[
            'fire twice per activation',
            'change route',
          ],
        ),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('classifies neither as an inherited default'),
      )),
      reason: 'a rule added to a doc and never classified would leave the '
          'catalogue silently stale against the doc.',
    );
  });

  // ── Case 8: only the behavioural contract is inherited ──────────────────
  test('case 8: an accessibility-only rule cannot be an inherited default', () {
    expect(
      () => parsePattern(
        buildPatternDoc(
          mustNot: const <String>[
            'fire twice per activation',
            'render below the tap target floor',
          ],
          mustNotScoped: const <String>['change route'],
          interactionRuleTerms: const <String>[
            'fire twice per activation',
            'change route',
          ],
          accessibilityTerms: const <String>[
            'render below the tap target floor',
          ],
        ),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('is not stated under `## Interaction rules`'),
      )),
    );
  });

  // ── Case 9: an unknown kind is refused ──────────────────────────────────
  test('case 9: a kind outside the Surface Spec schema is refused', () {
    expect(
      () => parsePattern(
        buildPatternDoc(kind: 'rail-header'),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('is not a Surface Spec control kind'),
      )),
    );
  });

  // ── Case 10: the id is locked to the file name ──────────────────────────
  test('case 10: an id that does not flatten to the file stem is refused', () {
    expect(
      () => parsePattern(
        buildPatternDoc(id: 'navigation/shell'),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('does not match the file name'),
      )),
      reason: 'a catalogue id that drifts from its doc leaves a referenced '
          'pattern pointing at prose nobody can find.',
    );
  });

  // ── Case 11: a doc with no front matter is refused, by name ─────────────
  test('case 11: a pattern doc with no front matter is refused', () {
    expect(
      () => parsePattern(
        '# Sample pattern\n\n## Intent\nNo front matter here.\n',
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('no YAML front matter'),
      )),
    );
  });
  // ── Case 12: THE SOURCE-TO-ARTIFACT LOCK ────────────────────────────────
  // Cases 2 and 6-8 lock the catalogue to the GENERATOR and the generator to
  // the FRONT MATTER. Neither reads the prose, so a rule stated only in a doc
  // body — which is how nine of the ten docs state every rule they have — can
  // be absent from `design/patterns.json` with every test green. That is the
  // defect class this branch exists to remove, so this case compares the
  // COMMITTED JSON against the DOC BODIES and nothing in between: no front
  // matter, no generator, no regeneration.
  test(
      'case 12: the committed catalogue carries every `must_not:` rule the '
      'doc bodies state', () {
    final root = _repoRoot();
    final decoded =
        jsonDecode(File('$root/$kCataloguePath').readAsStringSync()) as Map;
    final entries =
        (decoded['patterns']! as List).cast<Map<String, Object?>>();

    final complaints = <String>[];
    var stated = 0;
    var carried = 0;

    for (final file in patternFiles(root)) {
      final fileName = file.uri.pathSegments.last;
      final stem = fileName.substring(0, fileName.length - 3);
      final source = file.readAsStringSync();
      final split = splitFrontMatter(source);
      final body = split == null ? source : split.$2;

      // The id is locked to the file stem (`id.replaceAll('/', '-') == stem`),
      // so the entry can be found without reading the front matter at all.
      final matches = entries
          .where((e) => (e['id']! as String).replaceAll('/', '-') == stem)
          .toList();
      if (matches.length != 1) {
        complaints.add('$fileName: ${matches.length} catalogue entries whose '
            'id flattens to "$stem" — expected exactly one.');
        continue;
      }
      final entry = matches.single;

      final bodyTerms = mustNotTermsIn(body).toSet();
      final inCatalogue = <String>{
        for (final key in const <String>['must_not', 'must_not_scoped'])
          ...((entry[key] as List?) ?? const <Object?>[]).cast<String>(),
      };
      stated += bodyTerms.length;
      carried += inCatalogue.intersection(bodyTerms).length;

      final dropped = bodyTerms.difference(inCatalogue);
      if (dropped.isNotEmpty) {
        complaints.add('$fileName states ${dropped.length} rule(s) the '
            'catalogue drops: ${(dropped.toList()..sort()).map(jsonEncode).join(", ")}');
      }
      final phantom = inCatalogue.difference(bodyTerms);
      if (phantom.isNotEmpty) {
        complaints.add('$fileName: the catalogue carries '
            '${(phantom.toList()..sort()).map(jsonEncode).join(", ")}, which the '
            'doc body never states as `must_not: <term>`');
      }
    }

    if (complaints.isNotEmpty) {
      fail('$kCataloguePath is LOSSY against design/patterns/: it carries '
          '$carried of the $stated `must_not:` rules the doc bodies state.\n'
          '  ${complaints.join("\n  ")}\n'
          'The prose is the single source of truth. Regenerate with: '
          '$kRegenerateCommand');
    }
  });

  // ── Case 13: a rule the docs state is a rule some pattern INHERITS ───────
  // Case 12 alone is satisfiable by a catalogue that files every rule as
  // scoped. The partition has to keep meaning something, so at least one
  // pattern must still carry an unconditional `must_not`.
  test('case 13: the partition is not collapsed — some pattern still inherits',
      () {
    final root = _repoRoot();
    final decoded =
        jsonDecode(File('$root/$kCataloguePath').readAsStringSync()) as Map;
    final entries =
        (decoded['patterns']! as List).cast<Map<String, Object?>>();
    expect(
      entries.any((e) => ((e['must_not'] as List?) ?? const []).isNotEmpty),
      isTrue,
      reason: 'every rule in the catalogue is filed as condition-scoped, so '
          'no control inherits anything and PAT002 can never fire.',
    );
  });
}

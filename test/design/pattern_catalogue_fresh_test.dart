// test/design/pattern_catalogue_fresh_test.dart
//
// The freshness gate for `design/patterns.json`, the machine catalogue DevFlow
// reads as `df-tools ui spec validate <spec> --patterns design/patterns.json`
// (Surface Spec §4.5 invariant I5).
//
// THE ASSERTION THAT MATTERS IS CASE 12: the committed JSON is compared
// against the DOC BODIES, with no front matter and no generator in between. An
// earlier version of this file regenerated from YAML front matter and compared
// bytes, which locked the OUTPUT to the GENERATOR instead of the CATALOGUE to
// its SOURCE — and let a catalogue carrying 2 of the 78 rules the docs state
// report success. A generated file that can go stale silently is the defect
// this whole programme is about; a freshness gate that cannot see its own
// source is that defect one level up.
//
// The rest of the file holds the surrounding locks:
//
//   * case 2   a doc edited without regenerating, or the JSON edited by hand
//   * case 3   the entry shape `ui-spec-validate.cjs` reads
//   * case 5   every term is in the closed vocabulary (CTRL007)
//   * cases 6-11, 14-16  the generator's own refusals, as unit cases
//
// See tool/gen_pattern_catalogue.dart for the generator this mirrors, and for
// why the partition is signalled by an in-prose `*(inherited)*` marker rather
// than by which section a rule sits in.

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

/// A minimal, VALID pattern doc: the seven headings, one interaction rule
/// elected as an inherited default, one that is not, and front matter carrying
/// only `id` and `kind`.
///
/// Rules are given as `(term, inherited)` pairs so a case states only the one
/// thing it varies — the marker is the whole classification signal, so it is
/// the only knob a case needs.
String buildPatternDoc({
  String id = 'sample-pattern',
  String? kind = 'toggle',
  List<(String, bool)> interactionRules = const <(String, bool)>[
    ('fire twice per activation', true),
    ('change route', false),
  ],
  List<(String, bool)> accessibilityRules = const <(String, bool)>[],
  String? rawInteractionBody,
}) {
  final fm = StringBuffer()
    ..writeln('---')
    ..writeln('id: $id');
  if (kind != null) fm.writeln('kind: $kind');
  fm.writeln('---');

  String rules(List<(String, bool)> rs) => rs.isEmpty
      ? 'No rules.\n'
      : rs
          .map((r) =>
              '- `must_not: ${r.$1}`${r.$2 ? ' $kInheritedMarker' : ''} — a rule.\n')
          .join();

  return '$fm'
      '# Sample pattern\n\n'
      '## Intent\nA fixture.\n\n'
      '## Widgets\nNone.\n\n'
      '## States\nOne.\n\n'
      '## Interaction rules\n${rawInteractionBody ?? rules(interactionRules)}\n'
      '## Breakpoints\nNone.\n\n'
      '## Content\nNone.\n\n'
      '## Accessibility\n${rules(accessibilityRules)}';
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
        entry.keys
            .toSet()
            .difference(<String>{'id', 'kind', 'must_not', 'must_not_scoped'}),
        isEmpty,
        reason: 'ui-spec-validate.cjs reads {id, kind?, must_not?}; '
            '`must_not_scoped` is this catalogue\'s completeness record, so '
            'that every rule the docs state is carried and case 12 can prove '
            'it. Any FIFTH key is data no consumer and no gate would ever '
            'see.',
      );
      expect(
        entry['must_not_scoped'],
        isA<List<Object?>>(),
        reason: 'every entry carries the rules it does not inherit, even when '
            'that list is empty — an absent key would be indistinguishable '
            'from a pattern whose rules were dropped.',
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

  // ── Case 6: the DUPLICATE SOURCE is refused outright ────────────────────
  test('case 6: front matter that still declares `must_not:` is refused', () {
    final doc = buildPatternDoc().replaceFirst(
      'kind: toggle\n',
      'kind: toggle\nmust_not: ["fire twice per activation"]\n',
    );
    expect(
      () => parsePattern(
        doc,
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        allOf(contains('front matter declares `must_not:`'),
            contains(kInheritedMarker)),
      )),
      reason: 'front-matter rule lists were a second source for a fact the '
          'prose already states, and they drifted: nine of ten docs never '
          'carried them. The remedy names the in-prose marker.',
    );
  });

  // ── Case 7: every rule the body states reaches the catalogue ────────────
  // The unit-level twin of case 12: a rule added anywhere in the body — under
  // any heading, marked or not — is carried. Nothing is dropped on the floor.
  test('case 7: a rule stated in any section is carried by the entry', () {
    final entry = parsePattern(
      buildPatternDoc(
        interactionRules: const <(String, bool)>[
          ('fire twice per activation', true),
          ('change route', false),
        ],
        accessibilityRules: const <(String, bool)>[
          ('render below the tap target floor', false),
        ],
      ),
      fileName: 'sample-pattern.md',
      vocabulary: _sampleVocabulary(),
    );
    expect(
      entry.statedTerms.toSet(),
      equals(<String>{
        'fire twice per activation',
        'change route',
        'render below the tap target floor',
      }),
      reason: 'the catalogue is a complete record of the doc, not a fraction '
          'of it — this is the property whose absence shipped a 2-of-78 '
          'catalogue with a green gate.',
    );
    expect(entry.mustNot, equals(const <String>['fire twice per activation']));
    expect(
      entry.mustNotScoped,
      equals(const <String>['change route', 'render below the tap target floor']),
    );
  });

  // ── Case 8: only the behavioural contract may be elected ────────────────
  test('case 8: an accessibility rule cannot be marked inherited', () {
    expect(
      () => parsePattern(
        buildPatternDoc(
          accessibilityRules: const <(String, bool)>[
            ('render below the tap target floor', true),
          ],
        ),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('under `## Accessibility`'),
      )),
      reason: "`## Accessibility` and `## Breakpoints` rules are carried by a "
          "spec's `a11y` and `hit_rect` fields, not by a control-level "
          '`must_not`.',
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

  // ── Case 14: a marker with nothing to inherit it is refused ─────────────
  test('case 14: `*(inherited)*` in a pattern with no kind is refused', () {
    expect(
      () => parsePattern(
        buildPatternDoc(kind: null),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('declares no `kind:`'),
      )),
      reason: 'with no kind nothing can inherit the rule, so the marker would '
          'be dead data dressed as a contract.',
    );
  });

  // ── Case 15: a kind that inherits nothing is refused ────────────────────
  test('case 15: a kind with no elected rule is refused', () {
    expect(
      () => parsePattern(
        buildPatternDoc(
          interactionRules: const <(String, bool)>[
            ('fire twice per activation', false),
            ('change route', false),
          ],
        ),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        contains('no rule is marked'),
      )),
      reason: 'a kind whose must_not is empty makes PAT002 unable to fire, '
          'which is the 2-of-78 failure in miniature.',
    );
  });

  // ── Case 16: a rule the catalogue cannot read is refused, not dropped ───
  test('case 16: a `must_not:` token outside a backticked rule line is refused',
      () {
    expect(
      () => parsePattern(
        buildPatternDoc(
          rawInteractionBody:
              '- `must_not: fire twice per activation` $kInheritedMarker — a rule.\n'
              '- must_not: change route — a rule written without backticks.\n',
        ),
        fileName: 'sample-pattern.md',
        vocabulary: _sampleVocabulary(),
      ),
      throwsA(isA<PatternFrontMatterError>().having(
        (e) => e.message,
        'message',
        allOf(contains('"change route"'), contains('not as a rule line')),
      )),
      reason: 'a rule the parser cannot see is a rule stated to humans and '
          'silently dropped from the catalogue — the exact shape of this '
          "branch's defect. It must fail loudly, naming the term.",
    );
  });

  // ── Case 17: a term the TOKEN REGEX cannot match is refused, not invisible ──
  test('case 17: a must_not term in a non-conforming shape is refused', () {
    // THE HOLE UNDER CASE 16. Case 16 compares the token scan against the rule
    // scan — but BOTH used the same `[a-z][a-z0-9]*` shape, so a term that
    // matched neither (capitalised, or digit-initial) was invisible to both.
    // The generator dropped it and case 12 still reported 78 of 78: the
    // source-to-artifact lock was detecting dropped rules with the very regex
    // that dropped them.
    //
    // Latent rather than live — all 78 terms conform today — which is exactly
    // why it needed closing before the next doc is written.
    for (final term in const <String>[
      'Fire twice per activation',
      '2 taps to open',
    ]) {
      expect(
        () => parsePattern(
          buildPatternDoc(
            rawInteractionBody:
                '- `must_not: fire twice per activation` $kInheritedMarker — a rule.\n'
                '- `must_not: $term` — a rule in a shape the catalogue cannot carry.\n',
          ),
          fileName: 'sample-pattern.md',
          vocabulary: _sampleVocabulary(),
        ),
        throwsA(isA<PatternFrontMatterError>().having(
          (e) => e.message,
          'message',
          allOf(contains(term), contains('lowercase')),
        )),
        reason: 'the term must be NAMED and the doc REFUSED — a generator '
            'that cannot read a rule must not pretend the rule is not there.',
      );
    }
  });

  // ── Case 18: the plain term scan sees a non-conforming term ─────────────
  test('case 18: the term scan is case-insensitive, so nothing hides from it',
      () {
    // `mustNotTermsIn` is what case 12's lock reads the doc bodies with. If it
    // cannot see a term, the lock cannot see it dropped.
    expect(
      mustNotTermsIn('- `must_not: Fire twice per activation` — a rule.\n'),
      equals(const <String>['Fire twice per activation']),
    );
    expect(
      mustNotTermsIn('- `must_not: 2 taps to open` — a rule.\n'),
      equals(const <String>['2 taps to open']),
    );
  });
}

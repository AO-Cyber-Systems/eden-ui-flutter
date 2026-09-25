// tool/gen_pattern_catalogue.dart
//
// Generates `design/patterns.json` — the MACHINE catalogue of the ten
// interaction patterns in `design/patterns/` — from the PROSE of those docs.
//
// WHY THIS EXISTS (the cross-repo gap it closes)
// ----------------------------------------------
// DevFlow's `df-tools ui spec validate <spec> --patterns <file>` enforces
// Surface Spec §4.5 invariant I5: every pattern a spec references must exist
// in the pinned eden-ui-flutter release, and a control of a pattern's `kind`
// inherits that pattern's `must_not` defaults. It reads the catalogue as a
// JSON array, or an object with a `patterns` array, of entries shaped
// `{id, kind?, must_not?}`. This package shipped no such file, so `--patterns`
// had nothing to point at and I5 reported PAT000/UNCHECKED on every run.
//
// WHY THIS FILE WAS REWRITTEN (the defect it removes)
// ---------------------------------------------------
// The first version read the rules out of YAML front matter, with `must_not:`
// and `must_not_scoped:` lists restating what the doc body already said. That
// is two sources for one fact, and it drifted immediately: one of the ten docs
// carried the lists, nine did not, so the catalogue carried 2 of the 78 rules
// the docs state and the freshness gate reported success — because it
// regenerated from the front matter and never read the prose. It locked the
// OUTPUT to the GENERATOR rather than the CATALOGUE to its SOURCE.
//
// THE SINGLE SOURCE IS THE BODY
// -----------------------------
// Every rule is a line in the doc body of the form
//
//     - `must_not: <term>` — <prose>
//
// and every one of them reaches the catalogue. Front matter now carries only
// what prose genuinely cannot state unambiguously — the catalogue `id` and the
// Surface Spec control `kind`:
//
//   ---
//   id: navigation/disclosure-group
//   kind: disclosure-header
//   ---
//
//   * `id`   — the catalogue id. Slash-namespaced where the FILE NAME already
//              carries a group prefix (`navigation-*`); otherwise the file
//              stem. Locked to the file name by
//              `id.replaceAll('/', '-') == <stem>`.
//   * `kind` — OPTIONAL, and present only where the pattern governs ONE
//              control of exactly one Surface Spec control kind. A kind is a
//              blast radius: PAT002 makes EVERY control of that kind in EVERY
//              spec inherit this pattern's `must_not`. Patterns that govern a
//              composition (a shell, a list-detail, a studio, a bar, a dialog)
//              or a non-interactive element (a caption) get NO kind and
//              therefore inherit nothing onto anybody.
//
// A `must_not:` / `must_not_scoped:` key in front matter is now REFUSED: it is
// the duplicate source this rewrite removes.
//
// HOW THE PARTITION IS SIGNALLED — `*(inherited)*`, IN THE PROSE
// --------------------------------------------------------------
// The catalogue still partitions a pattern's rules into the ones a control
// INHERITS at control level (§4.5 I5, the schema's "applies to EVERY behaviour
// of this control") and the ones it does not. The previous pass keyed that off
// the `## Interaction rules` section. THAT HEURISTIC DOES NOT HOLD: the one
// doc that carried a hand-written partition classified two of its four
// interaction rules as scoped, because `## Interaction rules` mixes rules
// stated as flat properties of the control with rules whose prose names the
// gesture or state they bite under ("collapsing a group…", "when a group
// collapses over the selected child…"). The section cannot tell them apart, so
// the section is not the signal.
//
// The signal is an explicit marker on the rule line itself:
//
//     - `must_not: fire twice per activation` *(inherited)* — the header row …
//
// It is stated ONCE, in the prose, immediately beside the rule it classifies —
// one source, not a duplicate. The DEFAULT IS NOT INHERITED, because
// inheritance is a blast radius and a blast radius should be opted into by the
// author who understands the control, never acquired by a rule's position in
// the file. A marker is legal only under `## Interaction rules` (an
// accessibility or breakpoint rule is carried by a spec's `a11y` / `hit_rect`
// fields, not by a control-level `must_not`) and only in a doc that declares a
// `kind` (with no kind nothing can inherit, so the marker would be dead).
//
// WHAT THE CATALOGUE CARRIES
// --------------------------
//   * `must_not`        — the inherited defaults. Emitted ONLY alongside a
//                         `kind`, because that is the pair PAT002 reads; a
//                         `must_not` without a `kind` inherits onto nobody.
//   * `must_not_scoped` — every other rule the doc states. DevFlow reads only
//                         `id`, `kind` and `must_not`; this key exists so the
//                         catalogue is a COMPLETE record of the docs and so
//                         `test/design/pattern_catalogue_fresh_test.dart` can
//                         prove it, by comparing the committed JSON against
//                         the doc bodies. A catalogue that silently carries a
//                         fraction of what the design system states is the
//                         defect this file exists to remove.
//
// Together the two lists are exactly the set of `must_not: <term>` tokens in
// the body — no more (a term with no prose behind it is impossible, since the
// prose is what is parsed) and no fewer (a rule the body states and the JSON
// drops reddens case 12).
//
// HOW TO RUN — via the flutter test runner, NOT plain `dart` (same reason as
// tool/gen_design_md.dart):
//
//   flutter test tool/gen_pattern_catalogue.dart
//
// 0-new-deps: dart:io + dart:convert, plus the already-present flutter_test.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Where the generated catalogue lives, relative to the package root.
///
/// `design/` — NOT `design/patterns/` — because `design/` is already this
/// package's published machine-interface directory: DevFlow mirrors
/// `design/must_not_vocabulary.json` from it at
/// `devflow/schemas/must_not_vocabulary.json`. A JSON file inside
/// `design/patterns/` would read as an eleventh pattern; `design/patterns.json`
/// names itself as the machine twin of the `design/patterns/` directory.
const String kCataloguePath = 'design/patterns.json';

/// The human docs this catalogue is generated from.
const String kPatternsDirPath = 'design/patterns';

/// The closed `must_not` vocabulary every term must come from (CTRL007).
const String kVocabularyPath = 'design/must_not_vocabulary.json';

/// Printed in every failure message, so a red test says how to go green.
const String kRegenerateCommand =
    'flutter test tool/gen_pattern_catalogue.dart';

/// The control kinds a Surface Spec admits.
///
/// MIRRORED, deliberately, from W1b's `devflow/schemas/surface-spec.schema.json`
/// (`$defs.control.properties.kind.enum`, engine 2.9.0). Same standing as
/// `design/must_not_vocabulary.json`, which W1b mirrors in the other
/// direction: changing this list is a cross-repo change and must be called out
/// in the objective SUMMARY. Emitting a `kind` outside it would produce a
/// catalogue no spec could ever satisfy.
const List<String> kControlKinds = <String>[
  'button',
  'toggle',
  'link',
  'menu',
  'disclosure-header',
  'input',
];

/// The one heading under which a rule may be elected as an inherited default.
const String kInteractionRulesHeading = '## Interaction rules';

/// The in-prose marker that elects a rule as a control-level inherited default.
const String kInheritedMarker = '*(inherited)*';

/// The `$note` written into the generated file, so a reader who opens
/// `design/patterns.json` first learns it is generated before they edit it.
const String kCatalogueNote =
    'GENERATED FILE — do not edit by hand. The machine twin of design/patterns/, '
    'built from the `must_not:` rule lines in the BODY of those docs by '
    'tool/gen_pattern_catalogue.dart and locked against those bodies by '
    'test/design/pattern_catalogue_fresh_test.dart. '
    'Consumed by DevFlow as `df-tools ui spec validate <spec> --patterns design/patterns.json` '
    '(Surface Spec §4.5 invariant I5), which reads {id, kind?, must_not?}. `kind` is present only '
    'where the pattern governs one control of exactly that kind; `must_not` is the negation set a '
    'control of that kind INHERITS and may not silently drop, elected rule by rule in the prose '
    'with the marker $kInheritedMarker; `must_not_scoped` is every other rule the doc states, '
    'carried so this catalogue is a complete record of design/patterns/ rather than a fraction of '
    'it. Regenerate with: $kRegenerateCommand';

/// `must_not: <term>` — terms are lowercase words separated by single spaces.
///
/// The same shape `test/design/patterns_test.dart` case 3 already gates. This
/// is the CONFORMING shape, used to validate; it is NOT what the doc bodies
/// are scanned with — see [kMustNotTokenAnyShape].
final RegExp kMustNotToken =
    RegExp(r'must_not:\s*([a-z][a-z0-9]*(?: [a-z0-9]+)*)');

/// The whole conforming term, anchored — `kMustNotToken`'s body as a
/// full-string test.
final RegExp kMustNotTermShape =
    RegExp(r'^[a-z][a-z0-9]*(?: [a-z0-9]+)*$');

/// `must_not: <anything>` — whatever the author actually wrote, up to the
/// closing backtick, the em dash that opens the prose, or the end of the line.
///
/// WHY A SECOND, PERMISSIVE SCAN. The source-to-artifact lock
/// (`pattern_catalogue_fresh_test.dart` case 12) detects dropped rules by
/// scanning the doc bodies for `must_not:` tokens and checking the catalogue
/// carries each one. It used [kMustNotToken] to do it — the generator's OWN
/// regex — so a term that regex could not match (capitalised, digit-initial)
/// was invisible to the token scan AND to the rule scan: the generator
/// dropped it and the lock still reported 78 of 78. A lock that detects loss
/// with the instrument that causes it is not a lock.
///
/// Scanning permissively and then REFUSING anything that does not conform
/// (see `parsePattern`) is what closes it: nothing can be written that the
/// catalogue silently declines to carry.
final RegExp kMustNotTokenAnyShape =
    RegExp(r'must_not:[ \t]*([^\n`—]*)');

/// A whole rule line: the backticked token, plus the optional election marker.
///
/// The marker must follow the closing backtick immediately (one space), before
/// the em dash that opens the prose, so it reads as a classification of the
/// rule rather than as a word in the sentence.
final RegExp kMustNotRule = RegExp(
    r'`must_not:\s*([a-z][a-z0-9]*(?: [a-z0-9]+)*)`(?:[ \t]*(\*\(inherited\)\*))?');

/// A catalogue id: lowercase segments joined by `-` or `/`.
final RegExp _idShape = RegExp(r'^[a-z0-9]+(?:[-/][a-z0-9]+)*$');

/// Raised for any pattern doc this tool refuses to guess at. Every message
/// names the file and the remedy: a generator that silently drops a pattern is
/// the defect this whole file exists to remove.
class PatternFrontMatterError implements Exception {
  final String message;
  const PatternFrontMatterError(this.message);
  @override
  String toString() => 'PatternFrontMatterError: $message';
}

/// One `must_not:` rule line, with where it was stated and how it was
/// classified.
class PatternRule {
  /// The vocabulary term, e.g. `fire twice per activation`.
  final String term;

  /// The `## ` heading the rule sits under, e.g. `## Interaction rules`.
  final String heading;

  /// True when the line carries [kInheritedMarker].
  final bool inherited;

  const PatternRule({
    required this.term,
    required this.heading,
    required this.inherited,
  });
}

/// The machine half of one pattern doc.
class PatternEntry {
  /// Source file name, e.g. `navigation-disclosure-group.md`.
  final String fileName;

  /// Catalogue id, e.g. `navigation/disclosure-group`.
  final String id;

  /// Surface Spec control kind, or null when the pattern binds no single kind.
  final String? kind;

  /// Inherited defaults (§4.5 I5). Empty exactly when [kind] is null.
  final List<String> mustNot;

  /// Every other rule the doc states, in document order.
  final List<String> mustNotScoped;

  const PatternEntry({
    required this.fileName,
    required this.id,
    required this.kind,
    required this.mustNot,
    required this.mustNotScoped,
  });

  /// Every rule the doc states — the completeness claim case 12 checks.
  List<String> get statedTerms => <String>[...mustNot, ...mustNotScoped];

  /// The catalogue entry, in the shape `ui-spec-validate.cjs` reads.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        if (kind != null) 'kind': kind,
        if (kind != null) 'must_not': mustNot,
        'must_not_scoped': mustNotScoped,
      };
}

/// Splits [source] into (frontMatter, body) at the leading `---` fence.
///
/// Returns null when the file carries no front matter at all.
(String, String)? splitFrontMatter(String source) {
  if (!source.startsWith('---\n')) return null;
  final end = source.indexOf('\n---\n', 3);
  if (end < 0) return null;
  return (source.substring(4, end + 1), source.substring(end + 5));
}

/// Reads `key: value` (a bare scalar) out of [frontMatter]; null when absent.
String? _readScalar(String frontMatter, String key) {
  final m =
      RegExp('^$key:[ \\t]*(.*)\$', multiLine: true).firstMatch(frontMatter);
  if (m == null) return null;
  return m.group(1)!.trim();
}

/// Every `must_not: <term>` token in [body], in document order, deduplicated,
/// EXACTLY AS WRITTEN — conforming or not.
///
/// Kept as the plain term scan the freshness test uses to state, independently
/// of every classification rule below, what the doc says. It must be able to
/// see a term the rest of this file would refuse, or it cannot report that
/// one was dropped (see [kMustNotTokenAnyShape]).
List<String> mustNotTermsIn(String body) {
  final seen = <String>{};
  final out = <String>[];
  for (final m in kMustNotTokenAnyShape.allMatches(body)) {
    final term = m.group(1)!.trim();
    if (term.isEmpty) continue;
    if (seen.add(term)) out.add(term);
  }
  return out;
}

/// Every rule line in [body], in document order, each tagged with its heading
/// and whether it carries the inherited-election marker.
List<PatternRule> rulesIn(String body) {
  final out = <PatternRule>[];
  var heading = '<before the first heading>';
  for (final line in body.split('\n')) {
    if (line.startsWith('## ')) {
      heading = line.trim();
      continue;
    }
    for (final m in kMustNotRule.allMatches(line)) {
      out.add(PatternRule(
        term: m.group(1)!,
        heading: heading,
        inherited: m.group(2) != null,
      ));
    }
  }
  return out;
}

/// Parses and FULLY validates one pattern doc.
PatternEntry parsePattern(
  String source, {
  required String fileName,
  required Set<String> vocabulary,
}) {
  final split = splitFrontMatter(source);
  if (split == null) {
    throw PatternFrontMatterError(
        '$fileName: no YAML front matter. Every file in $kPatternsDirPath '
        'must open with a `---` fence carrying at least `id:` — it is the '
        'machine half DevFlow reads through $kCataloguePath. '
        'Remedy: add the front matter, then run $kRegenerateCommand.');
  }
  final (frontMatter, body) = split;

  final stem = fileName.endsWith('.md')
      ? fileName.substring(0, fileName.length - 3)
      : fileName;

  final id = _readScalar(frontMatter, 'id');
  if (id == null || id.isEmpty) {
    throw PatternFrontMatterError(
        '$fileName: front matter has no `id:`. Remedy: add `id: $stem`.');
  }
  if (!_idShape.hasMatch(id)) {
    throw PatternFrontMatterError(
        '$fileName: id "$id" is not lowercase segments joined by `-` or `/`.');
  }
  if (id.replaceAll('/', '-') != stem) {
    throw PatternFrontMatterError(
        '$fileName: id "$id" does not match the file name. An id is the file '
        'stem, optionally with `-` replaced by `/` where the prefix is a real '
        'namespace, so this file must declare an id whose slashes flatten to '
        '"$stem" (got "${id.replaceAll('/', '-')}").');
  }

  // The duplicate source this generator was rewritten to remove.
  for (final dead in const <String>['must_not', 'must_not_scoped']) {
    if (RegExp('^$dead:', multiLine: true).hasMatch(frontMatter)) {
      throw PatternFrontMatterError(
          '$fileName: front matter declares `$dead:`. Rules are read from the '
          'doc BODY now — the front-matter lists were a second source for the '
          'same fact and drifted: nine of the ten docs never carried them, so '
          'the catalogue shipped 2 of 78 rules and the freshness gate passed. '
          'Remedy: delete the `$dead:` line and, if it was electing inherited '
          'defaults, mark those rule lines in the prose with '
          '$kInheritedMarker, then run $kRegenerateCommand.');
    }
  }

  final kind = _readScalar(frontMatter, 'kind');
  if (kind != null && !kControlKinds.contains(kind)) {
    throw PatternFrontMatterError(
        '$fileName: kind "$kind" is not a Surface Spec control kind. The '
        'schema admits exactly ${kControlKinds.join(", ")} '
        '(devflow/schemas/surface-spec.schema.json). Remedy: use one of those, '
        'or drop `kind:` — a pattern that governs a composition rather than a '
        'single control should carry no kind, and then inherits nothing.');
  }

  final rules = rulesIn(body);

  // Every `must_not:` token must be written in the closed term SHAPE before
  // anything else asks what it says. A term the rule regex cannot match is
  // one the generator drops on the floor, and the freshness lock used the
  // same regex to look for dropped rules — so a non-conforming term was
  // invisible to both and the catalogue reported itself complete.
  final malformed = <String>[
    for (final term in mustNotTermsIn(body))
      if (!kMustNotTermShape.hasMatch(term)) term,
  ];
  if (malformed.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: must_not term(s) ${malformed.map(jsonEncode).join(", ")} '
        'are not written in the term shape the catalogue can carry: lowercase '
        'words, starting with a letter, separated by single spaces '
        '(`must_not: fire twice per activation`). A term outside that shape is '
        'stated to humans and dropped from $kCataloguePath without a word. '
        'Remedy: reword it to a term in $kVocabularyPath, then run '
        '$kRegenerateCommand.');
  }

  // Every `must_not:` token must be a real rule line. A token the rule regex
  // cannot see is a rule written in a shape the catalogue will silently drop —
  // exactly the failure this rewrite exists to make impossible.
  final tokenTerms = mustNotTermsIn(body).toSet();
  final ruleTerms = rules.map((r) => r.term).toSet();
  final unreachable = tokenTerms.difference(ruleTerms);
  if (unreachable.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: ${unreachable.map(jsonEncode).join(", ")} appears as '
        '`must_not: <term>` but not as a rule line the catalogue can read. A '
        'rule must be written with the term in backticks — '
        '``- `must_not: <term>` — <prose>`` — or it is stated to humans and '
        'dropped from $kCataloguePath.');
  }

  // Vocabulary — collected, not short-circuited, so one run names every miss.
  final misses = <String>[
    for (final term in ruleTerms.toList()..sort())
      if (!vocabulary.contains(term)) term,
  ];
  if (misses.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: must_not term(s) ${misses.map(jsonEncode).join(", ")} are '
        'not in the closed vocabulary at $kVocabularyPath. DevFlow validates '
        'control `must_not` terms (CTRL007) against exactly that file, so a '
        'term outside it could never be declared by a conforming spec. '
        'Remedy: reword the rule with an existing term, or add the term to '
        'the vocabulary deliberately — it is mirrored by W1b and is a '
        'cross-repo change.');
  }

  // ── The election marker ─────────────────────────────────────────────────
  final elected = <String>[];
  final seenElected = <String>{};
  final notElected = <String>[];
  final seenNotElected = <String>{};
  for (final rule in rules) {
    if (!rule.inherited) continue;
    if (kind == null) {
      throw PatternFrontMatterError(
          '$fileName: rule ${jsonEncode(rule.term)} is marked '
          '$kInheritedMarker, but this pattern declares no `kind:`. With no '
          'kind nothing can inherit it, so the marker would be dead data. '
          'Remedy: declare the `kind:` this pattern governs, or drop the '
          'marker — a pattern governing a composition inherits nothing onto '
          'anybody and that is the correct, deliberate outcome.');
    }
    if (rule.heading != kInteractionRulesHeading) {
      throw PatternFrontMatterError(
          '$fileName: rule ${jsonEncode(rule.term)} is marked '
          '$kInheritedMarker under `${rule.heading}`. Only the control\'s '
          'behavioural contract is inherited at control level; '
          '`## Accessibility` and `## Breakpoints` rules are carried by a '
          'spec\'s `a11y` and `hit_rect` fields. Remedy: drop the marker, or '
          'state the rule under `$kInteractionRulesHeading`.');
    }
    if (seenElected.add(rule.term)) elected.add(rule.term);
  }
  for (final rule in rules) {
    if (seenElected.contains(rule.term)) continue;
    if (seenNotElected.add(rule.term)) notElected.add(rule.term);
  }

  if (kind != null && elected.isEmpty) {
    throw PatternFrontMatterError(
        '$fileName: `kind: $kind` is declared but no rule is marked '
        '$kInheritedMarker, so a control of that kind inherits nothing and the '
        'kind is doing no work. Remedy: mark the rules this pattern states '
        'unconditionally for the control, or drop `kind:`.');
  }

  return PatternEntry(
    fileName: fileName,
    id: id,
    kind: kind,
    mustNot: kind == null ? const <String>[] : elected,
    mustNotScoped: notElected,
  );
}

/// Every pattern doc under `design/patterns/`, sorted by file name.
List<File> patternFiles(String repoRoot) {
  final dir = Directory('$repoRoot/$kPatternsDirPath');
  if (!dir.existsSync()) {
    throw PatternFrontMatterError(
        'gen_pattern_catalogue: $kPatternsDirPath not found under '
        'repoRoot="$repoRoot". Run from the eden_ui_flutter package root.');
  }
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .where((f) => !f.path.endsWith('README.md'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// The closed `must_not` vocabulary, read from `design/`.
Set<String> readVocabulary(String repoRoot) {
  final file = File('$repoRoot/$kVocabularyPath');
  if (!file.existsSync()) {
    throw PatternFrontMatterError(
        'gen_pattern_catalogue: $kVocabularyPath not found under '
        'repoRoot="$repoRoot".');
  }
  return (jsonDecode(file.readAsStringSync()) as List).cast<String>().toSet();
}

/// Parses every pattern doc, sorted by catalogue id.
List<PatternEntry> readPatterns(String repoRoot) {
  final vocabulary = readVocabulary(repoRoot);
  final entries = <PatternEntry>[
    for (final file in patternFiles(repoRoot))
      parsePattern(
        file.readAsStringSync(),
        fileName: file.uri.pathSegments.last,
        vocabulary: vocabulary,
      ),
  ]..sort((a, b) => a.id.compareTo(b.id));

  final seen = <String>{};
  for (final e in entries) {
    if (!seen.add(e.id)) {
      throw PatternFrontMatterError(
          'gen_pattern_catalogue: duplicate catalogue id "${e.id}".');
    }
  }
  return entries;
}

/// Renders `design/patterns.json` IN MEMORY. Never writes.
String generateCatalogue(String repoRoot) {
  final entries = readPatterns(repoRoot);
  final model = <String, Object?>{
    r'$note': kCatalogueNote,
    'patterns': [for (final e in entries) e.toJson()],
  };
  return '${const JsonEncoder.withIndent('  ').convert(model)}\n';
}

void main() {
  // Wrapped in a single test() so `flutter test tool/gen_pattern_catalogue.dart`
  // exits 0 — see tool/gen_design_md.dart for why a bare main() would not.
  test('generate design/patterns.json', () {
    final repoRoot = Directory.current.path;
    if (!File('$repoRoot/pubspec.yaml').existsSync()) {
      fail('gen_pattern_catalogue: expected the eden_ui_flutter package root '
          '(pubspec.yaml not found under Directory.current="$repoRoot").');
    }
    final json = generateCatalogue(repoRoot);
    final out = File('$repoRoot/$kCataloguePath');
    out.writeAsStringSync(json);
    final entries = readPatterns(repoRoot);
    final rules =
        entries.fold<int>(0, (n, e) => n + e.statedTerms.length);
    stdout.writeln('gen_pattern_catalogue: wrote ${out.path} — '
        '${entries.length} patterns, $rules rules '
        '(${entries.fold<int>(0, (n, e) => n + e.mustNot.length)} inherited)');
    expect(json, contains('"patterns"'));
  });
}

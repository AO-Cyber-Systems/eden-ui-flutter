// tool/gen_pattern_catalogue.dart
//
// Generates `design/patterns.json` — the MACHINE catalogue of the ten
// interaction patterns in `design/patterns/` — from front matter carried in
// those same markdown docs.
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
// HOW THE MACHINE DATA IS CARRIED
// -------------------------------
// The markdown docs stay the source of truth for humans. Each one now opens
// with YAML front matter carrying only what prose cannot state unambiguously:
//
//   ---
//   id: navigation/disclosure-group
//   kind: disclosure-header
//   must_not: ["fire twice per activation", "cover sibling hit rects"]
//   must_not_scoped: ["navigate on close", "lose selection"]
//   ---
//
//   * `id`      — the catalogue id. Slash-namespaced where the FILE NAME
//                 already carries a group prefix (`navigation-*`); otherwise
//                 the file stem. Locked to the file name by
//                 `id.replaceAll('/', '-') == <stem>`.
//   * `kind`    — OPTIONAL, and present only where the pattern governs ONE
//                 control of exactly one Surface Spec control kind. A kind is
//                 a blast radius: PAT002 makes EVERY control of that kind in
//                 EVERY spec inherit this pattern's `must_not`. Patterns that
//                 govern a composition (a shell, a list-detail, a studio, a
//                 bar, a dialog) or a non-interactive element (a caption) get
//                 NO kind and therefore inherit nothing onto anybody.
//   * `must_not` / `must_not_scoped` — required together IFF `kind` is
//                 present, forbidden otherwise. They PARTITION every
//                 `must_not: <term>` token in the doc body:
//                   - `must_not`        the terms the pattern states
//                                       UNCONDITIONALLY for the control, under
//                                       `## Interaction rules`. These are the
//                                       inherited defaults §4.5 I5 means, and
//                                       they match the schema's own definition
//                                       of a control-level `must_not`
//                                       ("applies to EVERY behaviour of this
//                                       control").
//                   - `must_not_scoped` everything else the doc states: terms
//                                       stated under a CONDITION ("collapsing a
//                                       group…", "when a group collapses over
//                                       the selected child…"), which a spec
//                                       declares per-behaviour, and terms
//                                       stated under `## Accessibility` /
//                                       `## Breakpoints`, which a spec carries
//                                       in `a11y` and `hit_rect` instead.
//
// The partition is the both-directions lock: a rule added to the prose and not
// classified reddens `test/design/pattern_catalogue_fresh_test.dart`, and a
// front-matter term with no prose behind it reddens it too.
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

/// The heading whose rules are eligible to become inherited defaults.
const String kInteractionRulesHeading = '## Interaction rules';

/// The `$note` written into the generated file, so a reader who opens
/// `design/patterns.json` first learns it is generated before they edit it.
const String kCatalogueNote =
    'GENERATED FILE — do not edit by hand. The machine twin of design/patterns/, '
    'built from the YAML front matter of those docs by tool/gen_pattern_catalogue.dart '
    'and locked against them in both directions by test/design/pattern_catalogue_fresh_test.dart. '
    'Consumed by DevFlow as `df-tools ui spec validate <spec> --patterns design/patterns.json` '
    '(Surface Spec §4.5 invariant I5). Entry shape: {id, kind?, must_not?} — `kind` is present '
    'only where the pattern governs one control of exactly that kind, and `must_not` is the '
    'negation set a control of that kind INHERITS and may not silently drop. '
    'Regenerate with: $kRegenerateCommand';

/// `must_not: <term>` — terms are lowercase words separated by single spaces.
///
/// The same shape `test/design/patterns_test.dart` case 3 already gates. It
/// deliberately does NOT match the front matter, whose value begins with `[`.
final RegExp kMustNotToken =
    RegExp(r'must_not:\s*([a-z][a-z0-9]*(?: [a-z0-9]+)*)');

/// A catalogue id: lowercase segments joined by `-` or `/`.
final RegExp _idShape = RegExp(r'^[a-z0-9]+(?:[-/][a-z0-9]+)*$');

/// Raised for any front matter this tool refuses to guess at. Every message
/// names the file and the remedy: a generator that silently drops a pattern is
/// the defect this whole file exists to remove.
class PatternFrontMatterError implements Exception {
  final String message;
  const PatternFrontMatterError(this.message);
  @override
  String toString() => 'PatternFrontMatterError: $message';
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

  /// Terms the doc states that are NOT inherited at control level.
  final List<String> mustNotScoped;

  const PatternEntry({
    required this.fileName,
    required this.id,
    required this.kind,
    required this.mustNot,
    required this.mustNotScoped,
  });

  /// The catalogue entry, in the shape `ui-spec-validate.cjs` reads.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        if (kind != null) 'kind': kind,
        if (kind != null) 'must_not': mustNot,
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

/// Reads `key: [ ... ]` — a JSON array, possibly spanning lines — out of
/// [frontMatter]. Returns null when the key is absent.
List<String>? _readList(String frontMatter, String key, String fileName) {
  final at = RegExp('^$key:', multiLine: true).firstMatch(frontMatter);
  if (at == null) return null;
  final open = frontMatter.indexOf('[', at.end);
  if (open < 0) {
    throw PatternFrontMatterError(
        '$fileName: front-matter key `$key` must be a JSON array (it is read '
        'with jsonDecode, so `["a", "b"]` — no bare scalars, no trailing '
        'commas). Remedy: rewrite the value and run $kRegenerateCommand.');
  }
  var depth = 0;
  var close = -1;
  for (var i = open; i < frontMatter.length; i++) {
    final c = frontMatter[i];
    if (c == '[') depth++;
    if (c == ']') {
      depth--;
      if (depth == 0) {
        close = i;
        break;
      }
    }
  }
  if (close < 0) {
    throw PatternFrontMatterError(
        '$fileName: front-matter key `$key` opens a `[` that is never closed.');
  }
  final raw = frontMatter.substring(open, close + 1);
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw PatternFrontMatterError(
        '$fileName: front-matter key `$key` is not a JSON array: ${e.message}\n'
        '  found: $raw');
  }
  if (decoded is! List || decoded.any((v) => v is! String)) {
    throw PatternFrontMatterError(
        '$fileName: front-matter key `$key` must be a JSON array of strings.');
  }
  return decoded.cast<String>();
}

/// Reads `key: value` (a bare scalar) out of [frontMatter]; null when absent.
String? _readScalar(String frontMatter, String key) {
  final m = RegExp('^$key:[ \\t]*(.*)\$', multiLine: true)
      .firstMatch(frontMatter);
  if (m == null) return null;
  return m.group(1)!.trim();
}

/// Every `must_not: <term>` token in [body], in document order, deduplicated.
List<String> mustNotTermsIn(String body) {
  final seen = <String>{};
  final out = <String>[];
  for (final m in kMustNotToken.allMatches(body)) {
    final term = m.group(1)!;
    if (seen.add(term)) out.add(term);
  }
  return out;
}

/// Every `must_not: <term>` token stated under `## Interaction rules`.
///
/// This is the ELIGIBLE set: a term may only become an inherited default if
/// the pattern states it as part of the control's behavioural contract.
/// `## Accessibility` and `## Breakpoints` rules are carried by a spec's
/// `a11y` / `hit_rect` fields, not by a control-level `must_not`.
List<String> interactionRuleTermsIn(String body) {
  final start = body.indexOf('\n$kInteractionRulesHeading');
  if (start < 0) return const <String>[];
  final afterHeading = start + kInteractionRulesHeading.length + 1;
  final next = body.indexOf('\n## ', afterHeading);
  final section =
      next < 0 ? body.substring(afterHeading) : body.substring(afterHeading, next);
  return mustNotTermsIn(section);
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

  final kind = _readScalar(frontMatter, 'kind');
  if (kind != null && !kControlKinds.contains(kind)) {
    throw PatternFrontMatterError(
        '$fileName: kind "$kind" is not a Surface Spec control kind. The '
        'schema admits exactly ${kControlKinds.join(", ")} '
        '(devflow/schemas/surface-spec.schema.json). Remedy: use one of those, '
        'or drop `kind:` — a pattern that governs a composition rather than a '
        'single control should carry no kind, and then inherits nothing.');
  }

  final mustNot = _readList(frontMatter, 'must_not', fileName);
  final mustNotScoped = _readList(frontMatter, 'must_not_scoped', fileName);

  if (kind == null) {
    if (mustNot != null || mustNotScoped != null) {
      throw PatternFrontMatterError(
          '$fileName: `must_not` / `must_not_scoped` are declared without a '
          '`kind:`. With no kind nothing can inherit them, so the data would '
          'be dead. Remedy: add the `kind:` this pattern governs, or remove '
          'both lists.');
    }
    return PatternEntry(
      fileName: fileName,
      id: id,
      kind: null,
      mustNot: const <String>[],
      mustNotScoped: const <String>[],
    );
  }

  if (mustNot == null || mustNotScoped == null) {
    throw PatternFrontMatterError(
        '$fileName: `kind: $kind` is declared, so BOTH `must_not:` and '
        '`must_not_scoped:` are required — together they must account for '
        'every `must_not: <term>` in the body. '
        'Missing: ${[if (mustNot == null) 'must_not', if (mustNotScoped == null) 'must_not_scoped'].join(" and ")}.');
  }
  if (mustNot.isEmpty) {
    throw PatternFrontMatterError(
        '$fileName: `kind: $kind` with an empty `must_not:` inherits nothing, '
        'so the kind is doing no work. Remedy: name the unconditional rules, '
        'or drop `kind:`.');
  }

  final overlap = mustNot.toSet().intersection(mustNotScoped.toSet());
  if (overlap.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: ${overlap.map(jsonEncode).join(", ")} appear in BOTH '
        '`must_not` and `must_not_scoped`. A term is either inherited at '
        'control level or it is not.');
  }

  for (final term in <String>[...mustNot, ...mustNotScoped]) {
    if (!vocabulary.contains(term)) {
      throw PatternFrontMatterError(
          '$fileName: must_not term ${jsonEncode(term)} is not in the closed '
          'vocabulary at $kVocabularyPath. DevFlow validates control `must_not` '
          'terms (CTRL007) against exactly that file, so a term outside it '
          'could never be declared by a conforming spec. Remedy: reword the '
          'rule with an existing term, or add the term to the vocabulary '
          'deliberately — it is mirrored by W1b and is a cross-repo change.');
    }
  }

  // ── The both-directions lock ────────────────────────────────────────────
  final bodyTerms = mustNotTermsIn(body).toSet();
  final declared = <String>{...mustNot, ...mustNotScoped};

  final invented = declared.difference(bodyTerms);
  if (invented.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: front matter declares ${invented.map(jsonEncode).join(", ")}, '
        'which the doc body never states as `must_not: <term>`. The prose is '
        'the source of truth; front matter classifies it, it does not add to '
        'it. Remedy: state the rule in the body, or drop it from the front '
        'matter.');
  }

  final unclassified = bodyTerms.difference(declared);
  if (unclassified.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: the body states ${unclassified.map(jsonEncode).join(", ")}, '
        'which the front matter classifies neither as an inherited default '
        '(`must_not`) nor as scoped (`must_not_scoped`). A pattern with a '
        '`kind` must account for every rule it states, or the catalogue goes '
        'silently stale against the doc. Remedy: add each term to exactly one '
        'of the two lists, then run $kRegenerateCommand.');
  }

  final eligible = interactionRuleTermsIn(body).toSet();
  final ineligible = mustNot.toSet().difference(eligible);
  if (ineligible.isNotEmpty) {
    throw PatternFrontMatterError(
        '$fileName: ${ineligible.map(jsonEncode).join(", ")} is listed as an '
        'inherited default but is not stated under `$kInteractionRulesHeading`. '
        'Only the control\'s behavioural contract is inherited at control '
        'level; `## Accessibility` and `## Breakpoints` rules are carried by a '
        'spec\'s `a11y` and `hit_rect` fields. Remedy: move the term to '
        '`must_not_scoped`, or state it under `$kInteractionRulesHeading`.');
  }

  return PatternEntry(
    fileName: fileName,
    id: id,
    kind: kind,
    mustNot: mustNot,
    mustNotScoped: mustNotScoped,
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
    stdout.writeln('gen_pattern_catalogue: wrote ${out.path}');
    expect(json, contains('"patterns"'));
  });
}

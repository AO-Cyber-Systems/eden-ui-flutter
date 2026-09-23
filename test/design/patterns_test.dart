// test/design/patterns_test.dart
//
// The gate that keeps `design/patterns/` honest (TRD 23-09, row 1a-09).
//
// Five checks:
//   1. Seven required headings, in order, in every pattern file.
//   2. Every `story:<id>` token cited in prose resolves against StoryRegistry.
//   3. Every `must_not: <term>` uses a term from the CLOSED vocabulary.
//   4. `design/patterns/README.md` indexes all ten patterns and nothing else.
//   5. `design/must_not_vocabulary.json` is well-formed.
//
// Paths are resolved from [Directory.current] (the package root under
// `flutter test`) and the resolution is asserted up front with a remedy —
// NEVER from a hardcoded absolute path, which would silently skip forever.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/register_all.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';

/// The seven headings every pattern file carries, in this order.
const List<String> kRequiredHeadings = <String>[
  '## Intent',
  '## Widgets',
  '## States',
  '## Interaction rules',
  '## Breakpoints',
  '## Content',
  '## Accessibility',
];

/// The ten patterns the index must link, and no others.
const List<String> kPatternIds = <String>[
  'navigation-disclosure-group',
  'navigation-section-caption',
  'navigation-shell',
  'list-detail',
  'state-empty-error-outage-loading',
  'form-validation',
  'bulk-action-bar',
  'dialog-confirm-destructive',
  'density-breakpoints',
  'studio-three-pane',
];

Directory get _designDir => Directory('${Directory.current.path}/design');
Directory get _patternsDir => Directory('${_designDir.path}/patterns');
File get _vocabularyFile => File('${_designDir.path}/must_not_vocabulary.json');
File get _indexFile => File('${_patternsDir.path}/README.md');

/// Every pattern file (`design/patterns/*.md` except `README.md`), sorted.
List<File> _patternFiles() {
  if (!_patternsDir.existsSync()) {
    fail(
      'design/patterns/ not found at ${_patternsDir.path}.\n'
      'Resolved from Directory.current = ${Directory.current.path}.\n'
      'Remedy: run `flutter test` from the package root, and create the '
      'pattern files described by TRD 23-09.',
    );
  }
  final files = _patternsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .where((f) => !f.path.endsWith('README.md'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String _name(File f) => f.uri.pathSegments.last;

/// `must_not: <term>` — terms are lowercase words separated by single spaces.
final RegExp _mustNotToken = RegExp(r'must_not:\s*([a-z][a-z0-9]*(?: [a-z0-9]+)*)');

/// `story:<id>` — ids are the registry's URL-safe alphabet.
final RegExp _storyToken = RegExp(r'story:([a-z0-9\-/]+)');

void main() {
  setUp(() {
    StoryRegistry.instance.clear();
    registerAllStories();
  });

  tearDown(() {
    StoryRegistry.instance.clear();
  });

  test('the pattern set is non-empty (the suite must not pass vacuously)', () {
    final files = _patternFiles();
    expect(
      files,
      isNotEmpty,
      reason:
          'design/patterns/ contains no *.md pattern files, so every other '
          'check in this file would pass over an empty list. '
          'Remedy: write the pattern files described by TRD 23-09.',
    );
  });

  // --- Case 1 -------------------------------------------------------------
  test('case 1: every pattern file has the seven headings, in order', () {
    final problems = <String>[];
    for (final file in _patternFiles()) {
      final text = file.readAsStringSync();
      var cursor = 0;
      for (final heading in kRequiredHeadings) {
        final at = text.indexOf('\n$heading', cursor);
        if (at < 0) {
          final anywhere = text.contains('\n$heading');
          problems.add(
            '${_name(file)}: ${anywhere ? "heading out of order" : "missing heading"} '
            '"$heading" (expected order: ${kRequiredHeadings.join(" → ")})',
          );
          break;
        }
        cursor = at + heading.length;
      }
    }
    expect(
      problems,
      isEmpty,
      reason:
          'Pattern files must carry all seven headings in the fixed order.\n'
          '${problems.join("\n")}',
    );
  });

  // --- Case 2 -------------------------------------------------------------
  test('case 2: every cited story:<id> resolves against StoryRegistry', () {
    final problems = <String>[];
    for (final file in _patternFiles()) {
      for (final m in _storyToken.allMatches(file.readAsStringSync())) {
        final id = m.group(1)!;
        if (StoryRegistry.instance.byId(id) == null) {
          problems.add(
            '${_name(file)}: dangling story reference "story:$id" — no story '
            'with that id is registered. Remedy: cite a story that '
            'register_all.dart registers, or state that no story exists yet.',
          );
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  // --- Case 3 -------------------------------------------------------------
  test('case 3: every must_not term is in the closed vocabulary', () {
    final vocabulary = (jsonDecode(_vocabularyFile.readAsStringSync()) as List)
        .cast<String>()
        .toSet();
    final problems = <String>[];
    for (final file in _patternFiles()) {
      for (final m in _mustNotToken.allMatches(file.readAsStringSync())) {
        final term = m.group(1)!;
        if (!vocabulary.contains(term)) {
          problems.add(
            '${_name(file)}: must_not term "$term" is not in the closed '
            'vocabulary at design/must_not_vocabulary.json. Remedy: reword the '
            'rule using an existing term, or add the term to that file '
            'deliberately (it is mirrored by W1b and is a cross-repo change).',
          );
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  // --- Case 4 -------------------------------------------------------------
  test('case 4: the index links all ten patterns and no missing file', () {
    expect(
      _indexFile.existsSync(),
      isTrue,
      reason: 'design/patterns/README.md is missing — it is the index that '
          "DevFlow's design-stack-flutter.md points at.",
    );
    final text = _indexFile.readAsStringSync();
    final linked = RegExp(r'\(\./([a-z0-9\-]+)\.md\)')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();

    final missing = kPatternIds.where((id) => !linked.contains(id)).toList();
    expect(
      missing,
      isEmpty,
      reason: 'design/patterns/README.md does not link: ${missing.join(", ")}',
    );

    final dangling = linked
        .where((id) => !File('${_patternsDir.path}/$id.md').existsSync())
        .toList();
    expect(
      dangling,
      isEmpty,
      reason: 'design/patterns/README.md links files that do not exist: '
          '${dangling.join(", ")}',
    );

    final onDisk = _patternFiles().map((f) {
      final n = _name(f);
      return n.substring(0, n.length - 3);
    }).toSet();
    expect(
      onDisk,
      equals(kPatternIds.toSet()),
      reason: 'design/patterns/ holds a different set of patterns than the '
          'ten this gate knows about. On disk: ${onDisk.toList()..sort()}',
    );
  });

  // --- Case 5 -------------------------------------------------------------
  test('case 5: must_not_vocabulary.json is a non-empty array of unique '
      'lowercase phrases', () {
    expect(
      _vocabularyFile.existsSync(),
      isTrue,
      reason: 'design/must_not_vocabulary.json is missing at '
          '${_vocabularyFile.path} (resolved from Directory.current = '
          '${Directory.current.path}).',
    );
    final decoded = jsonDecode(_vocabularyFile.readAsStringSync());
    expect(decoded, isA<List<dynamic>>(),
        reason: 'must_not_vocabulary.json must be a flat JSON array.');
    final terms = (decoded as List).cast<dynamic>();
    expect(terms, isNotEmpty, reason: 'The vocabulary must not be empty.');
    for (final t in terms) {
      expect(t, isA<String>(), reason: 'Every entry must be a string; got $t');
      final s = t as String;
      expect(
        RegExp(r'^[a-z][a-z0-9]*(?: [a-z0-9]+)*$').hasMatch(s),
        isTrue,
        reason: 'Vocabulary term "$s" must be lowercase words separated by '
            'single spaces, so it completes "this control must_not …".',
      );
    }
    expect(
      terms.toSet().length,
      equals(terms.length),
      reason: 'Vocabulary terms must be unique.',
    );
  });
}

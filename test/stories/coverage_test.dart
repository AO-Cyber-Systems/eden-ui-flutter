// test/stories/coverage_test.dart
//
// The story coverage RATCHET (TRD 23-04, requirement W1A-1a-04).
//
// WAVE-1 SCOPE DECISION: this floor is deliberately partial, not a march to
// 100%. This package exports 364 symbols across 517 Dart files; Wave-1 story
// scope is the shell widgets (layout, nav, buttons, inputs, data grid) plus
// anything a later objective touches. A 100% gate over 364 exports would be
// permanently red and would get disabled within a week — the
// `edenbiz-migration-gate-is-dead` failure mode. A floor that HOLDS (may
// rise, may never fall) is worth more than a target that gets switched off.
//
// Deleting a story, or exporting a new widget without one, can only fail this
// build if it takes the live `with_story` count BELOW the committed floor in
// `.story-coverage.json`. Raising the floor is a deliberate human edit to
// that file in its own `chore:` commit — this test only ever READS it. It
// never rewrites `.story-coverage.json`: see the second test below, and the
// differential control recorded in TRD 23-04's SUMMARY (floor+1 -> exit 1
// naming the uncovered exports -> `git checkout -- .story-coverage.json`).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/register_all.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';

import '../../tool/story_coverage.dart';

/// Computes today's live coverage report the same way `tool/story_coverage.dart`
/// does — same pure functions, same barrel, same registry — so coverage and
/// testing can never disagree (TRD 23-04 key_link).
CoverageReport _liveReport() {
  final barrelLines = File(kBarrelPath).readAsLinesSync();
  final exported = exportedWidgets(barrelLines);

  StoryRegistry.instance.clear();
  registerAllStories();
  final covered = widgetsWithStory(StoryRegistry.instance.all());
  StoryRegistry.instance.clear();

  return computeCoverage(exported: exported, covered: covered);
}

void main() {
  test(
      'case 5/6: current story coverage is at or above the committed floor '
      '(never the reverse)', () {
    final committed = jsonDecode(
      File(kStoryCoveragePath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final floor = committed['with_story'] as int;

    final report = _liveReport();

    if (report.withStory < floor) {
      fail(
        'Story coverage fell below the committed floor: '
        '${report.withStory} < $floor.\n'
        'Exports with no story:\n'
        '${report.uncovered.map((name) => '  - $name').join('\n')}\n'
        'The floor is raised in a chore: commit by editing '
        '.story-coverage.json — never by this test.',
      );
    }
  });

  test(
      'case 7: the ratchet never rewrites .story-coverage.json, whether the '
      'live count equals or exceeds the floor', () {
    final before = File(kStoryCoveragePath).readAsBytesSync();

    _liveReport(); // exercise the exact same computation a second time

    final after = File(kStoryCoveragePath).readAsBytesSync();
    expect(
      after,
      equals(before),
      reason: 'the ratchet test must never write .story-coverage.json — '
          'raising the floor is a human edit in a chore: commit, not '
          'something this test does (run `flutter test tool/story_coverage.dart` '
          'and commit the diff to raise it)',
    );
  });
}

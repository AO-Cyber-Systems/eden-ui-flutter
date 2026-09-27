// TRD 23-03, case 8 — the generated-test FRESHNESS gate.
//
// Every story contributed by a co-located `<widget>.stories.dart` file must
// have a committed generated test asserting a light golden, a dark golden and
// expectUiSane. A registered co-located story with no generated test fails
// HERE, naming the story id, with the regeneration command in the message.
//
// Scope, stated plainly: the covered set is the CO-LOCATED stories (see the
// header of tool/gen_story_tests.dart). The 49 hand-written dev-app stories are
// covered by test/dev_app/registry/registry_complete_test.dart instead.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_story_tests.dart';

void main() {
  test('every co-located story has an up-to-date generated test', () {
    final stories = coLocatedStories();
    final expected = generateStoryTestSources(stories);
    final dir = Directory(kGeneratedTestDir);

    expect(dir.existsSync(), isTrue,
        reason: '$kGeneratedTestDir is missing. Run: '
            '$kRegenerateStoryTestsCommand');

    final onDisk = <String, String>{
      for (final f in dir.listSync())
        if (f is File && f.path.endsWith('_stories_test.dart'))
          f.uri.pathSegments.last: f.readAsStringSync(),
    };

    // 1. Missing / stale coverage, reported BY STORY ID.
    final uncovered = <String>[];
    for (final s in stories) {
      final name = storyTestFileName(s.component);
      final source = onDisk[name];
      // The golden test's NAME carries a runtime suffix naming the skip reason
      // (kGoldenSkipSuffix — see story_harness.dart; `testWidgets` takes
      // `bool? skip`, so the reason cannot ride in `skip:`). Match the name
      // PREFIX, and require the expectUiSane test too: a story is only covered
      // when BOTH assertions were generated for it.
      if (source == null ||
          !source.contains("'${s.id} — light — golden") ||
          !source.contains("'${s.id} — light — expectUiSane'")) {
        uncovered.add(s.id);
      }
    }
    expect(
      uncovered,
      isEmpty,
      reason: 'STORY TEST FRESHNESS: no generated test covers ${uncovered.join(", ")}. '
          'Regenerate and commit $kGeneratedTestDir: $kRegenerateStoryTestsCommand',
    );

    // 2. Byte drift in a covered file.
    for (final entry in expected.entries) {
      expect(
        onDisk[entry.key],
        equals(entry.value),
        reason: 'STORY TEST FRESHNESS: $kGeneratedTestDir/${entry.key} differs '
            'from a fresh generation. Regenerate and commit it: '
            '$kRegenerateStoryTestsCommand',
      );
    }

    // 3. Orphans — a generated test for a story that no longer exists.
    final orphans = onDisk.keys.where((k) => !expected.containsKey(k)).toList()
      ..sort();
    expect(
      orphans,
      isEmpty,
      reason: 'STORY TEST FRESHNESS: orphaned generated test(s) '
          '${orphans.join(", ")} — the stories they cover are gone. '
          'Regenerate and commit: $kRegenerateStoryTestsCommand',
    );
  });
}

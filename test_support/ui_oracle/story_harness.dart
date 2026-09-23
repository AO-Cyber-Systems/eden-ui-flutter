// The story harness — what turns an EdenStory from a demo into a contract.
//
// IMPORT CONVENTION: `test_support/` is a top-level directory and is NOT part
// of the package's `lib/`, so there is no `package:eden_ui_flutter/...` URI for
// it. Generated story tests reach this file by RELATIVE import (23-01):
//
//     import '../../../test_support/ui_oracle/story_harness.dart';
//
// GOLDEN POLICY — read before changing anything below.
// Goldens for this repo are generated and compared in CI on LINUX ONLY, by the
// `stories` job in .github/workflows/ci.yml at the pinned Flutter 3.47.4.
// A workstation here runs 3.41.9 and bundles no fonts, so a locally blessed
// baseline is pure churn against CI's rasterisation — that is exactly
// eden-ui-flutter#32 (chat_screen_test's 390pt overflow assertion passes CI and
// fails locally by 8.5px). Never run `flutter test --update-goldens` here.
//
// Consequently the golden expectations SKIP off Linux, with the reason string
// below naming the issue, while [expectStorySane] runs on EVERY platform — a
// skipped golden on macOS must still leave the a11y and geometry assertions
// running, or a local `flutter test` proves nothing about the catalogue.
library;

import 'dart:io' show Platform;

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/register_all.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wrap.dart';

/// Re-exported so a generated test file needs exactly ONE relative import.
export 'package:flutter/material.dart' show ThemeMode;

/// `null` on Linux (goldens run); a reason string everywhere else (goldens
/// skip). Passed verbatim as `skip:` by every generated golden test.
final String? kGoldenSkipReason = Platform.isLinux
    ? null
    : 'goldens are generated and compared in CI (Linux) only — eden-ui-flutter#32';

/// Directory (relative to the generated test file) holding the CI baselines.
/// `ci/` is the Alchemist-style platform tag, expressed as a directory rather
/// than a package dependency — see the TRD's no-new-deps gotcha.
const String kGoldenDir = 'goldens/ci';

/// Registers the full catalogue exactly once for a generated test file.
///
/// Each `flutter test` file runs in its own isolate, so clearing first is safe
/// and keeps the registry's duplicate-id assertion happy on a re-run.
void ensureStoriesRegistered() {
  // [3J[H[2J is @visibleForTesting; this file is test-only support reached by
  // relative import from test/, but it lives outside test/ so the analyzer
  // cannot see that. Scoped ignore with the reason rather than widening the
  // registry's API.
  // ignore: invalid_use_of_visible_for_testing_member
  StoryRegistry.instance.clear();
  registerAllStories();
}

/// Looks up [id], failing with the id in the message when it is absent — a
/// generated test that outlived its story must say WHICH story went away.
EdenStory storyById(String id) {
  final story = StoryRegistry.instance.byId(id);
  if (story == null) {
    fail('No EdenStory registered with id "$id". A generated story test is '
        'stale — regenerate: $kRegenerateStoryTestsCommandRef');
  }
  return story;
}

/// Kept in sync with tool/gen_story_tests.dart's constant of the same value.
const String kRegenerateStoryTestsCommandRef =
    'flutter test tool/gen_story_tests.dart';

/// Golden file path for one (story, theme) pair. Story ids contain '/', which
/// is sanitised for the FILENAME; the raw id stays in the test name.
String goldenPathFor(EdenStory story, ThemeMode themeMode) =>
    '$kGoldenDir/${story.id.replaceAll('/', '_')}.${themeMode.name}.png';

Future<void> _pump(
  WidgetTester tester,
  EdenStory story, {
  required ThemeMode themeMode,
  required double width,
}) async {
  await wrap(
    tester,
    Builder(
      builder: (context) => story.build(context, story.defaultKnobValues),
    ),
    width: width,
    themeMode: themeMode,
  );
}

/// Pumps [story] and runs the Eden UI Oracle over it. Runs on EVERY platform.
///
/// KNOWN LIMITATION (23-02): the contrast rule inside `expectUiSane` cannot run
/// on an `EdenTheme` surface, because `google_fonts` fires a network fetch at
/// theme-construction time and the image capture is the first thing that awaits
/// it. Geometry, overlap, overflow and target-size rules are unaffected.
Future<void> expectStorySane(
  WidgetTester tester,
  EdenStory story, {
  required ThemeMode themeMode,
  double width = 1280,
}) async {
  await _pump(tester, story, themeMode: themeMode, width: width);
  await expectUiSane(tester);
}

/// Pumps [story] and compares it to its CI baseline.
///
/// Callers MUST pass `skip: kGoldenSkipReason` on the enclosing `testWidgets`
/// (the generated tests do). The story id is embedded in the golden path, so a
/// mismatch names the story that moved.
Future<void> expectStoryGolden(
  WidgetTester tester,
  EdenStory story, {
  required ThemeMode themeMode,
  double width = 1280,
}) async {
  await _pump(tester, story, themeMode: themeMode, width: width);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenPathFor(story, themeMode)),
    reason: 'golden mismatch for story "${story.id}" (${themeMode.name})',
  );
}

// Every story is measured at the viewport it DECLARES.
//
// WHY THIS FILE EXISTS — the vacuous-golden defect. `wrap()` lays the story
// out inside `Center(child: SizedBox(width: width, child: child))`, and that
// slot is TIGHT: a story that imposed its own width with an inner
// `SizedBox(width: 720)` had it clamped straight back by
// `BoxConstraints.enforce` against a tight parent. Both shell stories did
// exactly that, and the result was measurable:
//
//   * `desktop-layout_narrow.light.png` and `desktop-layout_default.light.png`
//     were BYTE-IDENTICAL (sha256 a077f9dd…), as were the dark pair;
//   * every one of the 22 baselines was 1280x800, the 390px mobile story
//     included;
//   * so the narrow rail had never been rendered, the mobile bar's "captions
//     and dividers never reach the bar" claim was pinned at desktop width,
//     and the `expectUiSane` half of both stories re-measured the DEFAULT
//     surface while both story files carried comments asserting the opposite.
//
// The fix is [EdenStory.viewportWidth]: the width is driven through
// `tester.view.physicalSize`, so MediaQuery, the golden's own dimensions and
// every geometry rule agree on one number. A golden taken at 720 cannot be
// byte-identical to one taken at 1280 — the vacuity is structurally
// impossible rather than merely noticed.
//
// The one-edit differential: in `test_support/ui_oracle/story_harness.dart`,
// change `width ?? story.viewportWidth ?? kDefaultStoryViewportWidth` to
// `width ?? kDefaultStoryViewportWidth` and cases 1 and 2 go red at 1280.

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/story_harness.dart';

void main() {
  setUp(ensureStoriesRegistered);

  testWidgets('case 1: desktop-layout/narrow renders at its declared 720px',
      (WidgetTester tester) async {
    await expectStorySane(
      tester,
      storyById('desktop-layout/narrow'),
      themeMode: ThemeMode.light,
      inputModality: EdenInputModality.pointer,
    );
    expect(
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
      720,
      reason: 'the narrow story must be measured at a narrow VIEWPORT — a '
          'SizedBox inside a tight slot is clamped and proves nothing',
    );
    expect(tester.getSize(find.byType(EdenDesktopLayout)).width, 720);
  });

  testWidgets('case 2: mobile-layout/default renders at its declared 390px',
      (WidgetTester tester) async {
    await expectStorySane(
      tester,
      storyById('mobile-layout/default'),
      themeMode: ThemeMode.light,
      inputModality: EdenInputModality.touch,
    );
    expect(
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
      390,
    );
    expect(tester.getSize(find.byType(EdenMobileLayout)).width, 390);
  });

  testWidgets(
      'case 3: a story that declares no viewport keeps the 1280 default',
      (WidgetTester tester) async {
    // The differential control. Declaring a viewport on two stories must not
    // move the other twenty baselines.
    await expectStorySane(
      tester,
      storyById('desktop-layout/default'),
      themeMode: ThemeMode.light,
      inputModality: EdenInputModality.pointer,
    );
    expect(
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
      kDefaultStoryViewportWidth,
    );
    expect(tester.getSize(find.byType(EdenDesktopLayout)).width, 1280);
  });

  testWidgets('case 4: every registered story declares a positive viewport '
      'or none at all', (WidgetTester tester) async {
    // A zero or negative viewport would pump a degenerate view and every
    // geometry rule would report nonsense on it.
    for (final EdenStory story in StoryRegistry.instance.all()) {
      final double? declared = story.viewportWidth;
      if (declared != null) {
        expect(declared, greaterThan(0),
            reason: '${story.id} declares viewportWidth $declared');
      }
    }
  });
}

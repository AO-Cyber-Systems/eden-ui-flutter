// test/dev_app/registry/registry_complete_test.dart
//
// Full-registry smoke test for the complete StoryRegistry (38-05).
// Asserts exact count, unique URL-safe ids, deterministic sort, and pumps
// every story once at its defaultKnobValues.
//
// Objective 040 (TRD 40-17) raised the total from 45 to 49 by registering the
// autofill/selection stories.
// Objective 23 (TRD 23-05) raised the total from 49 to 60 by registering the
// co-located nav/layout stories — the FIFTH group, emitted by
// tool/gen_stories.dart into register_stories.g.dart: 8 nav-item states,
// 2 desktop-layout states and 1 mobile-layout state.
// eden-ui-flutter#50 raised it from 60 to 66 with the first DATA-DISPLAY
// components — 4 `list/appointments` states (populated, empty, large/truncated,
// narrow) and 2 `error/refusal` states (bare reason, tool-named reason) — also
// co-located, so the fifth group goes 11 -> 17.
// This count is a real contract: registering a new story is meant to break it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/register_all.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';

void main() {
  setUp(() {
    StoryRegistry.instance.clear();
    registerAllStories();
  });

  tearDown(() {
    StoryRegistry.instance.clear();
  });

  test(
      'registry has exactly 68 stories '
      '(6 interactive + 4 autofill/selection + 6 galleries + 33 static '
      '+ 19 co-located)', () {
    // 66 -> 67: eden-ui-flutter#58's third remediation adds
    // `desktop-layout/collapsed-badged-selection`. That story exists because
    // NOTHING rendered a collapsed rail — `_collapsed` is only ever
    // `widget.initiallyCollapsed`, there is no width breakpoint, and
    // `desktop-layout/narrow` at 720px still renders the EXPANDED rail. A
    // badge painted on the selection pill in the identical token (1.00:1,
    // invisible) therefore shipped with all seven checks green.
    expect(StoryRegistry.instance.all().length, equals(68));
  });

  test('all story ids are unique', () {
    final ids = StoryRegistry.instance.all().map((s) => s.id).toList();
    final unique = ids.toSet();
    expect(ids.length, equals(unique.length), reason: 'Duplicate ids found: ${ids.where((id) => ids.where((x) => x == id).length > 1).toSet()}');
  });

  test('all story ids are URL-safe', () {
    for (final story in StoryRegistry.instance.all()) {
      expect(
        StoryRegistry.isUrlSafeId(story.id),
        isTrue,
        reason: 'Story id "${story.id}" is not URL-safe',
      );
    }
  });

  test('all() is deterministically sorted by component then name', () {
    final all = StoryRegistry.instance.all();
    for (int i = 0; i < all.length - 1; i++) {
      final cmp = all[i].component.compareTo(all[i + 1].component);
      if (cmp > 0) {
        fail('Out of order at index $i: "${all[i].component}" > "${all[i + 1].component}"');
      }
      if (cmp == 0) {
        expect(
          all[i].name.compareTo(all[i + 1].name),
          lessThanOrEqualTo(0),
          reason: 'Out of order by name at index $i: "${all[i].name}" > "${all[i + 1].name}"',
        );
      }
    }
  });

  testWidgets('every story pumps at defaultKnobValues without exception',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    for (final story in StoryRegistry.instance.all()) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  story.build(context, story.defaultKnobValues),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException(); // drain deliberate overflow
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

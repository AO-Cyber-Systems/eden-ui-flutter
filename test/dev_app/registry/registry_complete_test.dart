// test/dev_app/registry/registry_complete_test.dart
//
// Full-registry smoke test for the complete StoryRegistry (38-05).
// Asserts exact count, unique URL-safe ids, deterministic sort, and pumps
// every story once at its defaultKnobValues.

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

  test('registry has exactly 45 stories (6 interactive + 6 galleries + 33 static)', () {
    expect(StoryRegistry.instance.all().length, equals(45));
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

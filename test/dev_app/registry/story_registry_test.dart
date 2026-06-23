// test/dev_app/registry/story_registry_test.dart
//
// TDD RED phase: unit tests for StoryRegistry singleton.
// Written FIRST, before any implementation exists.

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _TestVariant { a, b, c }

/// Helper to build a minimal story with the given component, name, and id.
EdenStory _story({
  required String component,
  required String name,
  String? id,
}) {
  final resolvedId = id ?? '$component/$name';
  return EdenStory(
    id: resolvedId,
    component: component,
    name: name,
    knobs: const [],
    build: (_, __) => const SizedBox(),
  );
}

void main() {
  setUp(() {
    StoryRegistry.instance.clear();
  });

  group('StoryRegistry.register + byId', () {
    test('registered story is retrievable by id', () {
      final story = _story(component: 'buttons', name: 'interactive');
      StoryRegistry.instance.register(story);
      expect(StoryRegistry.instance.byId('buttons/interactive'), equals(story));
    });

    test('unknown id returns null', () {
      expect(StoryRegistry.instance.byId('does-not/exist'), isNull);
    });
  });

  group('StoryRegistry.all() — deterministic sort', () {
    test('all() returns stories sorted by component then name', () {
      // Register out of alphabetical order
      StoryRegistry.instance.register(_story(component: 'inputs', name: 'text'));
      StoryRegistry.instance.register(_story(component: 'buttons', name: 'icon'));
      StoryRegistry.instance.register(_story(component: 'buttons', name: 'filled'));

      final all = StoryRegistry.instance.all();
      expect(all.length, equals(3));
      expect(all[0].id, equals('buttons/filled'));
      expect(all[1].id, equals('buttons/icon'));
      expect(all[2].id, equals('inputs/text'));
    });

    test('all() returns an unmodifiable list', () {
      StoryRegistry.instance.register(_story(component: 'buttons', name: 'filled'));
      final all = StoryRegistry.instance.all();
      expect(() => all.add(_story(component: 'x', name: 'y', id: 'x/y')),
          throwsUnsupportedError);
    });
  });

  group('StoryRegistry.isUrlSafeId', () {
    test("'buttons/interactive' is URL-safe", () {
      expect(StoryRegistry.isUrlSafeId('buttons/interactive'), isTrue);
    });

    test("'Buttons/Foo' is NOT URL-safe (uppercase)", () {
      expect(StoryRegistry.isUrlSafeId('Buttons/Foo'), isFalse);
    });

    test("'a b' is NOT URL-safe (space)", () {
      expect(StoryRegistry.isUrlSafeId('a b'), isFalse);
    });

    test("'a@b' is NOT URL-safe (special char)", () {
      expect(StoryRegistry.isUrlSafeId('a@b'), isFalse);
    });

    test("'my-component/kebab-name' is URL-safe (hyphens)", () {
      expect(StoryRegistry.isUrlSafeId('my-component/kebab-name'), isTrue);
    });
  });

  group('StoryRegistry — ID invariants', () {
    test('every registered story passes isUrlSafeId', () {
      StoryRegistry.instance.register(_story(component: 'buttons', name: 'filled'));
      StoryRegistry.instance.register(_story(component: 'inputs', name: 'text'));
      for (final story in StoryRegistry.instance.all()) {
        expect(StoryRegistry.isUrlSafeId(story.id), isTrue,
            reason: 'story.id "${story.id}" fails URL-safe check');
      }
    });

    test('duplicate-id registration throws an assertion error', () {
      StoryRegistry.instance.register(_story(component: 'buttons', name: 'filled'));
      expect(
        () => StoryRegistry.instance
            .register(_story(component: 'buttons', name: 'filled')),
        throwsA(isA<AssertionError>()),
      );
    });

    test('invalid (non-URL-safe) id throws an assertion error', () {
      expect(
        () => StoryRegistry.instance.register(
          EdenStory(
            id: 'Buttons/Bad Id',
            component: 'Buttons',
            name: 'Bad Id',
            knobs: const [],
            build: (_, __) => const SizedBox(),
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('StoryRegistry.clear()', () {
    test('clear() empties the registry', () {
      StoryRegistry.instance.register(_story(component: 'buttons', name: 'filled'));
      StoryRegistry.instance.clear();
      expect(StoryRegistry.instance.all(), isEmpty);
    });
  });
}

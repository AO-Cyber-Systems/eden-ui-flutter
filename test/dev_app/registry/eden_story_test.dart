// test/dev_app/registry/eden_story_test.dart
//
// TDD RED phase: unit tests for EdenStory data class and sealed KnobSpec hierarchy.
// Written FIRST, before any implementation exists.

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _TestVariant { a, b, c }

void main() {
  group('EdenStory.routeName', () {
    test("id 'buttons/interactive' produces '/story/buttons/interactive'", () {
      final story = EdenStory(
        id: 'buttons/interactive',
        component: 'buttons',
        name: 'interactive',
        knobs: const [],
        build: (_, __) => const SizedBox(),
      );
      expect(story.routeName, equals('/story/buttons/interactive'));
    });
  });

  group('EdenStory.defaultKnobValues', () {
    test('completeness — all knob keys present with correct defaults', () {
      final story = EdenStory(
        id: 'buttons/interactive',
        component: 'buttons',
        name: 'interactive',
        knobs: [
          EnumKnob<_TestVariant>(
            key: 'variant',
            label: 'Variant',
            values: _TestVariant.values,
            defaultValue: _TestVariant.a,
          ),
          const BoolKnob(
            key: 'outline',
            label: 'Outline',
            defaultValue: false,
          ),
        ],
        build: (_, __) => const SizedBox(),
      );

      final defaults = story.defaultKnobValues;
      expect(defaults.get<_TestVariant>('variant'), equals(_TestVariant.a));
      expect(defaults.get<bool>('outline'), isFalse);
    });
  });

  group('KnobSpec sealed switch', () {
    test('sealed switch compiles with no default arm', () {
      // This test validates that the sealed class hierarchy covers all cases.
      // If sealed is broken, the switch will fail to compile or throw at runtime.
      final List<KnobSpec> knobs = [
        EnumKnob<_TestVariant>(
          key: 'variant',
          label: 'Variant',
          values: _TestVariant.values,
          defaultValue: _TestVariant.a,
        ),
        const BoolKnob(
          key: 'outline',
          label: 'Outline',
          defaultValue: false,
        ),
      ];

      final labels = knobs.map((knob) {
        // Exhaustive switch — no default arm needed because KnobSpec is sealed
        return switch (knob) {
          EnumKnob<Enum>() => 'enum:${knob.key}',
          BoolKnob() => 'bool:${knob.key}',
        };
      }).toList();

      expect(labels, equals(['enum:variant', 'bool:outline']));
    });
  });
}

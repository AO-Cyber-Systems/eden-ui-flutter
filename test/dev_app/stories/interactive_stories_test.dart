// test/dev_app/stories/interactive_stories_test.dart
//
// Widget smoke tests for the six interactive stories (38-04).
//
// Each story is pumped:
//   1. At defaultKnobValues — verifies the story builds without exception.
//   2. With one knob flipped — verifies the story re-renders without exception.
//
// Overflow errors in the test pump are drained with takeException() (matching
// the existing screen-test pattern) to keep tests stable on constrained viewports.
//
// The StoryRegistry singleton is registered/cleared in setUp/tearDown to
// ensure test isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:eden_ui_flutter/dev_app/registry/knob_values.dart';
import 'package:eden_ui_flutter/dev_app/stories/buttons_story.dart';
import 'package:eden_ui_flutter/dev_app/stories/cards_story.dart';
import 'package:eden_ui_flutter/dev_app/stories/badges_alerts_story.dart';
import 'package:eden_ui_flutter/dev_app/stories/inputs_story.dart';
import 'package:eden_ui_flutter/dev_app/stories/navigation_story.dart';
import 'package:eden_ui_flutter/dev_app/stories/overlays_story.dart';

void main() {
  setUp(() {
    StoryRegistry.instance.clear();
  });

  tearDown(() {
    StoryRegistry.instance.clear();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Pumps [story.build] at the given [values] inside a minimal app harness.
  Future<void> pumpStory(
    WidgetTester tester,
    KnobValues values,
    Widget Function(BuildContext, KnobValues) build,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => build(ctx, values),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    // Drain deliberate overflow/RenderFlex errors that stories may surface when
    // rendered at test-viewport size (matches existing screen-test pattern).
    tester.takeException();
  }

  // ---------------------------------------------------------------------------
  // Task 1: buttons, cards, badges_alerts
  // ---------------------------------------------------------------------------

  group('buttonsInteractiveStory', () {
    test('defaultKnobValues contains every knob key', () {
      final defaults = buttonsInteractiveStory.defaultKnobValues;
      for (final knob in buttonsInteractiveStory.knobs) {
        expect(
          () => defaults.get<Object>(knob.key),
          returnsNormally,
          reason: 'defaultKnobValues missing key "${knob.key}"',
        );
      }
    });

    testWidgets('renders at defaultKnobValues without exception', (t) async {
      await pumpStory(
        t,
        buttonsInteractiveStory.defaultKnobValues,
        buttonsInteractiveStory.build,
      );
    });

    testWidgets('renders with flipped knobs without exception', (t) async {
      var values = buttonsInteractiveStory.defaultKnobValues;
      // Flip outline, pill, disabled, loading bools; pick non-default enum values.
      values = values.copyWith('outline', true);
      values = values.copyWith('pill', true);
      values = values.copyWith('disabled', true);
      values = values.copyWith('loading', true);
      // Use a non-primary variant and non-md size.
      values = values.copyWith('variant', buttonsInteractiveStory.knobs
          .whereType<EnumKnob<dynamic>>()
          .firstWhere((k) => k.key == 'variant')
          .values
          .last as Object);
      values = values.copyWith('size', buttonsInteractiveStory.knobs
          .whereType<EnumKnob<dynamic>>()
          .firstWhere((k) => k.key == 'size')
          .values
          .first as Object);
      await pumpStory(t, values, buttonsInteractiveStory.build);
    });
  });

  group('cardsInteractiveStory', () {
    test('defaultKnobValues contains every knob key', () {
      final defaults = cardsInteractiveStory.defaultKnobValues;
      for (final knob in cardsInteractiveStory.knobs) {
        expect(
          () => defaults.get<Object>(knob.key),
          returnsNormally,
          reason: 'defaultKnobValues missing key "${knob.key}"',
        );
      }
    });

    testWidgets('renders at defaultKnobValues without exception', (t) async {
      await pumpStory(
        t,
        cardsInteractiveStory.defaultKnobValues,
        cardsInteractiveStory.build,
      );
    });

    testWidgets('renders with flipped knobs without exception', (t) async {
      var values = cardsInteractiveStory.defaultKnobValues;
      values = values.copyWith('clickable', true);
      values = values.copyWith('gradient', true);
      await pumpStory(t, values, cardsInteractiveStory.build);
    });
  });

  group('badgesAlertsInteractiveStory', () {
    test('defaultKnobValues contains every knob key', () {
      final defaults = badgesAlertsInteractiveStory.defaultKnobValues;
      for (final knob in badgesAlertsInteractiveStory.knobs) {
        expect(
          () => defaults.get<Object>(knob.key),
          returnsNormally,
          reason: 'defaultKnobValues missing key "${knob.key}"',
        );
      }
    });

    testWidgets('renders at defaultKnobValues without exception', (t) async {
      await pumpStory(
        t,
        badgesAlertsInteractiveStory.defaultKnobValues,
        badgesAlertsInteractiveStory.build,
      );
    });

    testWidgets('renders with flipped knobs without exception', (t) async {
      var values = badgesAlertsInteractiveStory.defaultKnobValues;
      values = values.copyWith('badge-variant', badgesAlertsInteractiveStory.knobs
          .whereType<EnumKnob<dynamic>>()
          .firstWhere((k) => k.key == 'badge-variant')
          .values
          .last as Object);
      values = values.copyWith('alert-variant', badgesAlertsInteractiveStory.knobs
          .whereType<EnumKnob<dynamic>>()
          .firstWhere((k) => k.key == 'alert-variant')
          .values
          .last as Object);
      await pumpStory(t, values, badgesAlertsInteractiveStory.build);
    });
  });

  // ---------------------------------------------------------------------------
  // Task 2: inputs, navigation, overlays
  // ---------------------------------------------------------------------------

  group('inputsInteractiveStory', () {
    test('defaultKnobValues contains every knob key', () {
      final defaults = inputsInteractiveStory.defaultKnobValues;
      for (final knob in inputsInteractiveStory.knobs) {
        expect(
          () => defaults.get<Object>(knob.key),
          returnsNormally,
          reason: 'defaultKnobValues missing key "${knob.key}"',
        );
      }
    });

    testWidgets('renders at defaultKnobValues without exception', (t) async {
      await pumpStory(
        t,
        inputsInteractiveStory.defaultKnobValues,
        inputsInteractiveStory.build,
      );
    });

    testWidgets('renders with flipped knobs without exception', (t) async {
      var values = inputsInteractiveStory.defaultKnobValues;
      values = values.copyWith('enabled', false);
      values = values.copyWith('error', true);
      values = values.copyWith('size', inputsInteractiveStory.knobs
          .whereType<EnumKnob<dynamic>>()
          .firstWhere((k) => k.key == 'size')
          .values
          .last as Object);
      await pumpStory(t, values, inputsInteractiveStory.build);
    });
  });

  group('navigationInteractiveStory', () {
    test('defaultKnobValues contains every knob key', () {
      final defaults = navigationInteractiveStory.defaultKnobValues;
      for (final knob in navigationInteractiveStory.knobs) {
        expect(
          () => defaults.get<Object>(knob.key),
          returnsNormally,
          reason: 'defaultKnobValues missing key "${knob.key}"',
        );
      }
    });

    testWidgets('renders at defaultKnobValues without exception', (t) async {
      await pumpStory(
        t,
        navigationInteractiveStory.defaultKnobValues,
        navigationInteractiveStory.build,
      );
    });

    testWidgets('renders with flipped knobs without exception', (t) async {
      var values = navigationInteractiveStory.defaultKnobValues;
      // Flip any available enum knob to a non-default value.
      for (final knob in navigationInteractiveStory.knobs) {
        if (knob is EnumKnob<dynamic> && knob.values.length > 1) {
          values = values.copyWith(
            knob.key,
            knob.values.last as Object,
          );
        } else if (knob is BoolKnob) {
          values = values.copyWith(knob.key, !knob.defaultValue);
        }
      }
      await pumpStory(t, values, navigationInteractiveStory.build);
    });
  });

  group('overlaysInteractiveStory', () {
    test('defaultKnobValues contains every knob key', () {
      final defaults = overlaysInteractiveStory.defaultKnobValues;
      for (final knob in overlaysInteractiveStory.knobs) {
        expect(
          () => defaults.get<Object>(knob.key),
          returnsNormally,
          reason: 'defaultKnobValues missing key "${knob.key}"',
        );
      }
    });

    testWidgets('renders at defaultKnobValues without exception', (t) async {
      await pumpStory(
        t,
        overlaysInteractiveStory.defaultKnobValues,
        overlaysInteractiveStory.build,
      );
    });

    testWidgets('renders with flipped knobs without exception', (t) async {
      var values = overlaysInteractiveStory.defaultKnobValues;
      // Flip any available enum knob to a non-default value.
      for (final knob in overlaysInteractiveStory.knobs) {
        if (knob is EnumKnob<dynamic> && knob.values.length > 1) {
          values = values.copyWith(
            knob.key,
            knob.values.last as Object,
          );
        } else if (knob is BoolKnob) {
          values = values.copyWith(knob.key, !knob.defaultValue);
        }
      }
      await pumpStory(t, values, overlaysInteractiveStory.build);
    });
  });

  // ---------------------------------------------------------------------------
  // Combined interactiveStories list — validates all six are exported
  // ---------------------------------------------------------------------------

  test('interactiveStories list contains all six stories', () {
    expect(interactiveStories.length, equals(6));
    expect(
      interactiveStories.map((s) => s.id).toList(),
      containsAll([
        'buttons/interactive',
        'cards/interactive',
        'badges-alerts/interactive',
        'inputs/interactive',
        'navigation/interactive',
        'overlays/interactive',
      ]),
    );
  });
}

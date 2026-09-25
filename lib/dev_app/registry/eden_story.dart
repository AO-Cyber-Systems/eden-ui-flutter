// lib/dev_app/registry/eden_story.dart
//
// EdenStory data class + sealed KnobSpec hierarchy.
//
// Sealed subtypes MUST be in the same library file so the Dart compiler
// can verify exhaustive switches without a default arm.

import 'package:flutter/material.dart';

import '../../src/a11y/eden_input_modality.dart';
import 'knob_values.dart';

/// A single explorable story in the Flutter component explorer.
///
/// An [EdenStory] is a pure-data description of one variant of one component.
/// It carries the ID used for routing, the knob specifications that drive the
/// interactive controls panel, and the [build] callback that renders the
/// component under inspection.
@immutable
class EdenStory {
  const EdenStory({
    required this.id,
    required this.component,
    required this.name,
    required this.knobs,
    required this.build,
    this.icon,
    this.inputModality = EdenInputModality.touch,
    this.viewportWidth,
  });

  /// Unique story identifier — format `<component>/<name>`, e.g.
  /// `buttons/interactive`. Must match `^[a-z0-9\-/]+$`.
  final String id;

  /// Component category, e.g. `buttons`.
  final String component;

  /// Story variant name, e.g. `interactive`.
  final String name;

  /// Ordered list of knob specifications for this story's controls panel.
  final List<KnobSpec> knobs;

  /// Renders the story's preview widget given the current [KnobValues].
  final Widget Function(BuildContext context, KnobValues knobValues) build;

  /// Optional icon shown in the sidebar navigation.
  final IconData? icon;

  /// What this surface is DRIVEN WITH — the input modality the generated
  /// story test holds it to.
  ///
  /// This is a declaration, not a waiver: `expectUiSane` asserts a real
  /// tap-target floor on BOTH paths (WCAG 2.5.8's 24x24 for
  /// [EdenInputModality.pointer]; 48dp/44pt for [EdenInputModality.touch]).
  /// There is deliberately no third value that means "skip the check".
  ///
  /// Defaults to [EdenInputModality.touch], the stricter floor, so a story
  /// author who says nothing gets the stricter rule. A surface that ships to
  /// both is [EdenInputModality.touch] — a fingertip can reach it.
  ///
  /// It lives on the STORY because it is a fact about the surface, and a story
  /// is the surface's declaration point. `tool/gen_story_tests.dart` emits it
  /// verbatim into each generated test, so the standard a story is held to is
  /// readable at the assertion rather than inherited from a default.
  final EdenInputModality inputModality;

  /// The VIEWPORT this surface is a fact about, in logical pixels, or null
  /// for the catalogue's default width.
  ///
  /// WHY IT LIVES HERE, AND WHY IT IS A VIEWPORT. The story harness lays a
  /// story out inside a TIGHT slot, so a story that imposed its own width
  /// with an inner `SizedBox(width: 720)` had it clamped straight back by
  /// `BoxConstraints.enforce`. Both shell stories did exactly that. The
  /// result was two goldens BYTE-IDENTICAL to the default ones
  /// (`desktop-layout_narrow` vs `desktop-layout_default`, sha256
  /// a077f9dd…), a 390px "phone" story pinned at 1280, and `expectUiSane`
  /// re-measuring the default surface under both — while both story files
  /// carried comments asserting the opposite.
  ///
  /// Declaring it here drives `tester.view.physicalSize` instead, so
  /// `MediaQuery`, the golden's own dimensions and every geometry rule agree
  /// on one number, and a breakpoint the surface actually has can fire. A
  /// golden taken at 720 cannot be byte-identical to one taken at 1280: the
  /// vacuity becomes structurally impossible rather than merely noticed.
  ///
  /// Like [inputModality] it is a DECLARATION about the surface, not a
  /// waiver — nothing is skipped at a narrow viewport, and
  /// `tool/gen_story_tests.dart` emits it verbatim into the generated test so
  /// the width a story is measured at is readable at the assertion.
  final double? viewportWidth;

  /// Route name for deep-linking: `/story/<id>`.
  String get routeName => '/story/$id';

  /// A [KnobValues] bag pre-populated with each knob's [KnobSpec.defaultValue].
  KnobValues get defaultKnobValues => KnobValues(
        Map.unmodifiable({
          for (final k in knobs) k.key: k.defaultValue,
        }),
      );
}

// ---------------------------------------------------------------------------
// KnobSpec sealed hierarchy
// ---------------------------------------------------------------------------

/// Base description of a single interactive control ("knob") for a story.
///
/// [KnobSpec] is sealed — use an exhaustive switch to handle all variants:
/// ```dart
/// switch (knob) {
///   EnumKnob<Enum>() => ...,
///   BoolKnob()       => ...,
/// }
/// ```
sealed class KnobSpec {
  const KnobSpec({required this.key, required this.label});

  /// Map key used in [KnobValues].
  final String key;

  /// Human-readable label shown in the controls panel.
  final String label;

  /// Default value for this knob, returned by [EdenStory.defaultKnobValues].
  Object get defaultValue;
}

/// An enum-valued knob rendered as a chip selector.
///
/// The generic parameter [T] must extend [Enum]. Store the full [values] list
/// so the controls panel can enumerate all options without reflection.
final class EnumKnob<T extends Enum> extends KnobSpec {
  const EnumKnob({
    required super.key,
    required super.label,
    required this.values,
    required this.defaultValue,
    this.labelBuilder,
  });

  /// All selectable enum values (typically `MyEnum.values`).
  final List<T> values;

  @override
  final T defaultValue;

  /// Optional display name override — falls back to `value.name`.
  final String Function(T)? labelBuilder;
}

/// A boolean knob rendered as a toggle switch.
final class BoolKnob extends KnobSpec {
  const BoolKnob({
    required super.key,
    required super.label,
    required this.defaultValue,
  });

  @override
  final bool defaultValue;
}

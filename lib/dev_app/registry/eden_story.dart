// lib/dev_app/registry/eden_story.dart
//
// EdenStory data class + sealed KnobSpec hierarchy.
//
// Sealed subtypes MUST be in the same library file so the Dart compiler
// can verify exhaustive switches without a default arm.

import 'package:flutter/material.dart';

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

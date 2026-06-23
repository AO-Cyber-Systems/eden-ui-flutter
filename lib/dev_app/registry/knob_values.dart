// lib/dev_app/registry/knob_values.dart
//
// Immutable typed value bag for story knob state.
// No widget dependencies — pure Dart.

import 'package:flutter/foundation.dart' show immutable;

/// An immutable map of knob key → current value.
///
/// Values are stored as [Object] and retrieved with a reified-generic [get<T>].
/// Use [copyWith] to produce a new bag with one key updated.
@immutable
class KnobValues {
  const KnobValues(this._map);

  final Map<String, Object> _map;

  /// Returns the value for [key] cast to [T].
  ///
  /// Throws a [TypeError] if the stored value is not assignable to [T].
  T get<T>(String key) => _map[key] as T;

  /// Returns a new [KnobValues] with [key] set to [value].
  ///
  /// The original bag is not modified.
  KnobValues copyWith(String key, Object value) =>
      KnobValues(Map.unmodifiable({..._map, key: value}));
}

// lib/dev_app/registry/story_registry.dart
//
// StoryRegistry — the single source of truth for all registered stories.
//
// Stories are registered by their respective screen/story files (TRDs 38-04 and
// 38-05). This registry provides the ordered list consumed by the sidebar
// navigator (38-02) and the manifest emitter (38-06).

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'eden_story.dart';

/// Singleton registry of all [EdenStory] instances.
///
/// ### ID contract
/// Every ID must match `^[a-z0-9\-/]+$` — lowercase, digits, hyphens, and
/// forward-slashes only. Attempting to register a story with an invalid ID or
/// a duplicate ID fires a debug assertion (asserts run in `flutter test`).
///
/// ### Sort order
/// [all] returns stories sorted by `component` then `name`, both ascending and
/// stable. This order is the canonical order used by the manifest emitter and
/// the sidebar navigator; it must not change without a corresponding update to
/// the golden manifest bytes in TRD 38-06.
///
/// ### Usage
/// ```dart
/// StoryRegistry.instance.register(myStory);
/// final stories = StoryRegistry.instance.all();
/// final story = StoryRegistry.instance.byId('buttons/interactive');
/// ```
class StoryRegistry {
  StoryRegistry._();

  /// The application-wide singleton.
  static final StoryRegistry instance = StoryRegistry._();

  final Map<String, EdenStory> _byId = {};

  /// Registers [story] with the registry.
  ///
  /// Asserts that [story.id] passes [isUrlSafeId] and that no story with the
  /// same id has already been registered.
  void register(EdenStory story) {
    assert(
      isUrlSafeId(story.id),
      'EdenStory id "${story.id}" contains characters outside [a-z0-9\\-/]. '
      'IDs must be lowercase kebab-case with "/" as the component separator.',
    );
    assert(
      !_byId.containsKey(story.id),
      'Duplicate EdenStory id detected: "${story.id}"',
    );
    _byId[story.id] = story;
  }

  /// Returns all registered stories, sorted by [EdenStory.component] then
  /// [EdenStory.name] (both ascending, stable sort).
  ///
  /// The returned list is unmodifiable.
  List<EdenStory> all() {
    final sorted = _byId.values.toList()
      ..sort((a, b) {
        final cmp = a.component.compareTo(b.component);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });
    return List.unmodifiable(sorted);
  }

  /// Returns the story with the given [id], or `null` if not found.
  EdenStory? byId(String id) => _byId[id];

  /// Returns `true` when [id] contains only lowercase letters, digits, hyphens,
  /// and forward-slashes — e.g. `buttons/interactive`, `my-comp/kebab-name`.
  static bool isUrlSafeId(String id) =>
      RegExp(r'^[a-z0-9\-/]+$').hasMatch(id);

  /// Removes all registered stories.
  ///
  /// Intended for test isolation only — not for production use.
  @visibleForTesting
  void clear() => _byId.clear();
}

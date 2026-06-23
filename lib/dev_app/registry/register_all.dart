// lib/dev_app/registry/register_all.dart
//
// Central story registration for the Eden Flutter component explorer (38-05).
//
// Registers all 45 stories in three groups:
//   - 6 interactive stories (one knob-driven story per interactive component)
//   - 6 gallery stories    (full-screen overview for each interactive component)
//   - 33 static stories    (zero-knob wrapper for every non-interactive screen)
//
// Call `registerAllStories()` once at app startup — typically in `main()` before
// `runApp()`. The function is idempotent with respect to the registry only when
// the registry has been cleared first (done automatically in tests via setUp).

import 'package:flutter/material.dart';

import '../screens/badges_alerts_screen.dart';
import '../screens/buttons_screen.dart';
import '../screens/cards_screen.dart';
import '../screens/inputs_screen.dart';
import '../screens/navigation_screen.dart';
import '../screens/overlays_screen.dart';
import '../stories/overlays_story.dart';
import '../stories/static_stories.dart';
import 'eden_story.dart';
import 'story_registry.dart';

// ---------------------------------------------------------------------------
// Gallery stories — full-screen overview for each interactive component
// ---------------------------------------------------------------------------

final List<EdenStory> _galleryStories = [
  EdenStory(
    id: 'buttons/all',
    component: 'buttons',
    name: 'All',
    icon: Icons.smart_button,
    knobs: const [],
    build: (context, _) => ButtonsScreen(),
  ),
  EdenStory(
    id: 'cards/all',
    component: 'cards',
    name: 'All',
    icon: Icons.credit_card,
    knobs: const [],
    build: (context, _) => CardsScreen(),
  ),
  EdenStory(
    id: 'badges-alerts/all',
    component: 'badges-alerts',
    name: 'All',
    icon: Icons.label_outline,
    knobs: const [],
    build: (context, _) => BadgesAlertsScreen(),
  ),
  EdenStory(
    id: 'inputs/all',
    component: 'inputs',
    name: 'All',
    icon: Icons.text_snippet_outlined,
    knobs: const [],
    build: (context, _) => InputsScreen(),
  ),
  EdenStory(
    id: 'navigation/all',
    component: 'navigation',
    name: 'All',
    icon: Icons.menu_open,
    knobs: const [],
    build: (context, _) => NavigationScreen(),
  ),
  EdenStory(
    id: 'overlays/all',
    component: 'overlays',
    name: 'All',
    icon: Icons.layers_outlined,
    knobs: const [],
    build: (context, _) => OverlaysScreen(),
  ),
];

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Registers all 45 [EdenStory] instances with [StoryRegistry.instance].
///
/// Call once before `runApp()`. In tests, call after `StoryRegistry.instance.clear()`
/// in `setUp()` to ensure a clean slate.
///
/// Registration order: interactive → galleries → static.
void registerAllStories() {
  final registry = StoryRegistry.instance;

  for (final story in interactiveStories) {
    registry.register(story);
  }
  for (final story in _galleryStories) {
    registry.register(story);
  }
  for (final story in staticStories) {
    registry.register(story);
  }
}

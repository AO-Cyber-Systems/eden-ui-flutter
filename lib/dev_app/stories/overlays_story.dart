// lib/dev_app/stories/overlays_story.dart
//
// Interactive story for EdenBanner (overlay component).
//
// Knob set mirrors overlays_screen.dart's banner usage:
//   - variant    (EnumKnob<EdenBannerVariant>)
//   - dismissible (BoolKnob)
//
// NOTE: Modals, toasts, and drawers open imperatively and cannot be
// auto-opened in a widget pump. This story previews the EdenBanner
// surface (which renders inline) rather than the opened overlay, keeping
// the smoke test stable.
//
// Pure build function — no internal setState.
// Exports `interactiveStories` — the combined list of all six interactive
// stories used by the test and by 38-05 for central registration.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';
import 'badges_alerts_story.dart';
import 'buttons_story.dart';
import 'cards_story.dart';
import 'inputs_story.dart';
import 'navigation_story.dart';

/// Interactive story for [EdenBanner].
///
/// Registered by 38-05's central registry assembly.
final overlaysInteractiveStory = EdenStory(
  id: 'overlays/interactive',
  component: 'overlays',
  name: 'Interactive',
  icon: Icons.layers_outlined,
  knobs: [
    const EnumKnob<EdenBannerVariant>(
      key: 'variant',
      label: 'Variant',
      values: EdenBannerVariant.values,
      defaultValue: EdenBannerVariant.info,
    ),
    const BoolKnob(
      key: 'dismissible',
      label: 'Dismissible',
      defaultValue: false,
    ),
  ],
  build: (BuildContext context, KnobValues k) => EdenBanner(
    message: 'This is a banner preview message.',
    variant: k.get<EdenBannerVariant>('variant'),
    dismissible: k.get<bool>('dismissible'),
  ),
);

/// All six interactive stories.
///
/// Consumed by the widget smoke test and imported by 38-05 for central
/// registration with [StoryRegistry].
final List<EdenStory> interactiveStories = [
  buttonsInteractiveStory,
  cardsInteractiveStory,
  badgesAlertsInteractiveStory,
  inputsInteractiveStory,
  navigationInteractiveStory,
  overlaysInteractiveStory,
];

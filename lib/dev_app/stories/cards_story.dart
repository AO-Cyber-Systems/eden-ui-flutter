// lib/dev_app/stories/cards_story.dart
//
// Interactive story for EdenCard.
//
// Knob set mirrors cards_screen.dart:
//   - clickable (BoolKnob) — drives onTap: null vs. onTap: () {}
//   - gradient  (BoolKnob) — EdenCard supports gradient bool
//   - glass     (BoolKnob) — EdenCard supports glass bool
//
// Pure build function — no internal setState.
// Exported for central registration in 38-05.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';

/// Interactive story for [EdenCard].
///
/// Registered by 38-05's central registry assembly.
final cardsInteractiveStory = EdenStory(
  id: 'cards/interactive',
  component: 'cards',
  name: 'Interactive',
  icon: Icons.crop_square,
  knobs: [
    const BoolKnob(key: 'clickable', label: 'Clickable', defaultValue: false),
    const BoolKnob(key: 'gradient', label: 'Gradient', defaultValue: false),
    const BoolKnob(key: 'glass', label: 'Glass', defaultValue: false),
  ],
  build: (BuildContext context, KnobValues k) => EdenCard(
    title: 'Preview Card',
    subtitle: 'Tap to interact',
    gradient: k.get<bool>('gradient'),
    glass: k.get<bool>('glass'),
    onTap: k.get<bool>('clickable') ? () {} : null,
  ),
);

// lib/dev_app/stories/buttons_story.dart
//
// Interactive story for EdenButton.
//
// Knob set mirrors buttons_screen.dart:
//   - EdenButtonVariant (EnumKnob)
//   - EdenButtonSize    (EnumKnob)
//   - outline           (BoolKnob)
//   - pill              (BoolKnob)
//   - disabled          (BoolKnob)
//   - loading           (BoolKnob)
//
// Pure build function — no internal setState.
// Exported for central registration in 38-05.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';

/// Interactive story for [EdenButton].
///
/// Registered by 38-05's central registry assembly.
final buttonsInteractiveStory = EdenStory(
  id: 'buttons/interactive',
  component: 'buttons',
  name: 'Interactive',
  icon: Icons.smart_button,
  knobs: [
    const EnumKnob<EdenButtonVariant>(
      key: 'variant',
      label: 'Variant',
      values: EdenButtonVariant.values,
      defaultValue: EdenButtonVariant.primary,
    ),
    const EnumKnob<EdenButtonSize>(
      key: 'size',
      label: 'Size',
      values: EdenButtonSize.values,
      defaultValue: EdenButtonSize.md,
    ),
    const BoolKnob(key: 'outline', label: 'Outline', defaultValue: false),
    const BoolKnob(key: 'pill', label: 'Pill', defaultValue: false),
    const BoolKnob(key: 'disabled', label: 'Disabled', defaultValue: false),
    const BoolKnob(key: 'loading', label: 'Loading', defaultValue: false),
  ],
  build: (BuildContext context, KnobValues k) => EdenButton(
    label: 'Button',
    variant: k.get<EdenButtonVariant>('variant'),
    size: k.get<EdenButtonSize>('size'),
    outline: k.get<bool>('outline'),
    pill: k.get<bool>('pill'),
    disabled: k.get<bool>('disabled'),
    loading: k.get<bool>('loading'),
    onPressed: () {},
  ),
);

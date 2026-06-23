// lib/dev_app/stories/inputs_story.dart
//
// Interactive story for EdenInput.
//
// Knob set mirrors inputs_screen.dart:
//   - size    (EnumKnob<EdenInputSize>)
//   - enabled (BoolKnob)
//   - error   (BoolKnob) — drives errorText presence
//
// Pure build function — no internal setState.
// Exported for central registration in 38-05.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';

/// Interactive story for [EdenInput].
///
/// Registered by 38-05's central registry assembly.
final inputsInteractiveStory = EdenStory(
  id: 'inputs/interactive',
  component: 'inputs',
  name: 'Interactive',
  icon: Icons.text_fields,
  knobs: [
    const EnumKnob<EdenInputSize>(
      key: 'size',
      label: 'Size',
      values: EdenInputSize.values,
      defaultValue: EdenInputSize.md,
    ),
    const BoolKnob(key: 'enabled', label: 'Enabled', defaultValue: true),
    const BoolKnob(key: 'error', label: 'Error', defaultValue: false),
  ],
  build: (BuildContext context, KnobValues k) => EdenInput(
    label: 'Demo Input',
    hint: 'Type something...',
    size: k.get<EdenInputSize>('size'),
    enabled: k.get<bool>('enabled'),
    errorText: k.get<bool>('error') ? 'This field has an error.' : null,
  ),
);

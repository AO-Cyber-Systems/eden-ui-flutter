// lib/dev_app/explorer/canvas.dart
//
// ExplorerCanvas — the live preview surface for the Flutter explorer (38-02).
//
// The canvas wraps the active story's build() in the theme system using the
// EdenAdaptiveTheme.light/.dark factory (the EdenAdaptiveTheme *widget* only
// emits light, so brightness is selected here per the TRD's error-recovery
// note), inside a viewport-constrained box, with a KnobPanel below that renders
// the story's KnobSpec list via a sealed switch onto the existing
// EnumSelector / ToggleControl primitives.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

import '../registry/eden_story.dart';
import '../registry/knob_values.dart';
import '../widgets/interactive_controls.dart';

/// Live, theme-wrapped preview of one [EdenStory] plus its knob panel.
class ExplorerCanvas extends StatelessWidget {
  const ExplorerCanvas({
    super.key,
    required this.story,
    required this.values,
    required this.profile,
    required this.brand,
    required this.brightness,
    required this.viewportWidth,
    required this.onKnobChanged,
  });

  final EdenStory story;
  final KnobValues values;
  final EdenThemeProfile profile;
  final EdenBrandPreset? brand;
  final Brightness brightness;

  /// Fixed canvas width (Mobile 390 / Tablet 768 / Desktop 1280) or `null`
  /// for an unconstrained ("Fluid") canvas.
  final double? viewportWidth;

  final void Function(String key, Object value) onKnobChanged;

  @override
  Widget build(BuildContext context) {
    final themeData = brightness == Brightness.dark
        ? EdenAdaptiveTheme.dark(profile, brand: brand)
        : EdenAdaptiveTheme.light(profile, brand: brand);

    final preview = Builder(builder: (ctx) => story.build(ctx, values));
    final viewportBox = viewportWidth == null
        ? preview
        : ClipRect(child: SizedBox(width: viewportWidth, child: preview));

    return EdenThemeProfileScope(
      profile: profile,
      child: Theme(
        data: themeData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: themeData.scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: viewportBox),
                ),
              ),
            ),
            KnobPanel(
              story: story,
              values: values,
              onChanged: onKnobChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the active story's knobs as a row of live controls.
///
/// Switches on the sealed [KnobSpec] hierarchy from 38-01:
/// `EnumKnob` → [EnumSelector], `BoolKnob` → [ToggleControl]. Empty knob lists
/// collapse to nothing (zero-knob stories show no panel).
class KnobPanel extends StatelessWidget {
  const KnobPanel({
    super.key,
    required this.story,
    required this.values,
    required this.onChanged,
  });

  final EdenStory story;
  final KnobValues values;
  final void Function(String key, Object value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (story.knobs.isEmpty) return const SizedBox.shrink();
    return Material(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: story.knobs.map(_buildControl).toList(),
        ),
      ),
    );
  }

  Widget _buildControl(KnobSpec knob) => switch (knob) {
        EnumKnob<Enum>() => EnumSelector<Enum>(
            values: knob.values,
            selected: values.get<Enum>(knob.key),
            onChanged: (v) => onChanged(knob.key, v),
            labelBuilder: knob.labelBuilder,
          ),
        BoolKnob() => ToggleControl(
            label: knob.label,
            value: values.get<bool>(knob.key),
            onChanged: (v) => onChanged(knob.key, v),
          ),
      };
}

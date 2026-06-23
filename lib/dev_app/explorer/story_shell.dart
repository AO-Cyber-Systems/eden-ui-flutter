// lib/dev_app/explorer/story_shell.dart
//
// StoryShell — the top-level three-pane explorer widget for the Flutter
// component explorer (38-02). Owns all explorer state (selected story, live
// knob values, theme profile/brand/brightness, viewport) and composes the
// toolbar + sidebar + canvas. Routing (deep links) arrives in 38-03 via the
// `initialStoryId` parameter; the full story set arrives in 38-04/38-05.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

import '../registry/knob_values.dart';
import '../registry/story_registry.dart';
import 'canvas.dart';
import 'sidebar.dart';
import 'toolbar.dart';

/// The Widgetbook-style shell. Drives [StoryRegistry] and renders the active
/// story in a theme- and viewport-configurable canvas with a live knob panel.
class StoryShell extends StatefulWidget {
  const StoryShell({super.key, this.initialStoryId});

  /// Story id to select on first build (used by 38-03's onGenerateRoute for
  /// deep links). When null, the first registered story is selected.
  final String? initialStoryId;

  @override
  State<StoryShell> createState() => _StoryShellState();
}

class _StoryShellState extends State<StoryShell> {
  static const KnobValues _emptyValues = KnobValues(<String, Object>{});

  String? _selectedStoryId;
  KnobValues _knobValues = _emptyValues;
  EdenThemeProfile _profile = EdenThemeProfile.commercialWarm;
  EdenBrandPreset? _brand;
  Brightness _brightness = Brightness.dark; // matches the dev app's default
  double? _viewportWidth; // null == Fluid

  @override
  void initState() {
    super.initState();
    _selectedStoryId = widget.initialStoryId ?? _firstStoryId();
    _knobValues = _valuesFor(_selectedStoryId);
  }

  String? _firstStoryId() {
    final all = StoryRegistry.instance.all();
    return all.isEmpty ? null : all.first.id;
  }

  KnobValues _valuesFor(String? id) {
    if (id == null) return _emptyValues;
    return StoryRegistry.instance.byId(id)?.defaultKnobValues ?? _emptyValues;
  }

  void _selectStory(String id) => setState(() {
        _selectedStoryId = id;
        _knobValues = _valuesFor(id);
      });

  void _onKnobChanged(String key, Object value) =>
      setState(() => _knobValues = _knobValues.copyWith(key, value));

  @override
  Widget build(BuildContext context) {
    final story = _selectedStoryId == null
        ? null
        : StoryRegistry.instance.byId(_selectedStoryId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExplorerToolbar(
          profile: _profile,
          brand: _brand,
          isDark: _brightness == Brightness.dark,
          viewportWidth: _viewportWidth,
          onProfile: (p) => setState(() => _profile = p),
          onBrand: (b) => setState(() => _brand = b),
          onBrightness: (dark) =>
              setState(() => _brightness = dark ? Brightness.dark : Brightness.light),
          onViewport: (w) => setState(() => _viewportWidth = w),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExplorerSidebar(
                selectedStoryId: _selectedStoryId,
                onSelect: _selectStory,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: story == null
                    ? const Center(child: Text('Select a story'))
                    : ExplorerCanvas(
                        story: story,
                        values: _knobValues,
                        profile: _profile,
                        brand: _brand,
                        brightness: _brightness,
                        viewportWidth: _viewportWidth,
                        onKnobChanged: _onKnobChanged,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// lib/dev_app/stories/navigation_story.dart
//
// Interactive story for EdenTabs (navigation component).
//
// Knob set:
//   - selected-tab (EnumKnob<_TabIndex>) — controls the selectedIndex of EdenTabs.
//
// The navigation screen's InteractivePlayground drives tab selection via
// setState. Here we model the tab index as a small private enum so the
// EnumKnob typed API is satisfied. The story previews a 3-tab EdenTabs
// widget with the selectedIndex driven by the knob.
//
// Pure build function — no internal setState.
// Exported for central registration in 38-05.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';

/// Lightweight enum representing the three preview tab indices.
enum _NavigationTab { first, second, third }

/// Interactive story for [EdenTabs].
///
/// Registered by 38-05's central registry assembly.
final navigationInteractiveStory = EdenStory(
  id: 'navigation/interactive',
  component: 'navigation',
  name: 'Interactive',
  icon: Icons.tab_outlined,
  knobs: [
    EnumKnob<_NavigationTab>(
      key: 'selected-tab',
      label: 'Selected Tab',
      values: _NavigationTab.values,
      defaultValue: _NavigationTab.first,
      labelBuilder: (v) => switch (v) {
        _NavigationTab.first => 'Overview',
        _NavigationTab.second => 'Details',
        _NavigationTab.third => 'Settings',
      },
    ),
  ],
  build: (BuildContext context, KnobValues k) {
    final tab = k.get<_NavigationTab>('selected-tab');
    final selectedIndex = tab.index;
    return EdenTabs(
      tabs: const [
        EdenTabItem(label: 'Overview'),
        EdenTabItem(label: 'Details'),
        EdenTabItem(label: 'Settings'),
      ],
      selectedIndex: selectedIndex,
      onChanged: (_) {},
    );
  },
);

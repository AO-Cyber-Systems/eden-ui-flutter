// Co-located story for the mobile shell.
//
// HAND-WRITTEN, and deliberately fed the SAME [kSharedShellNavItems] dataset as
// eden_desktop_layout.stories.dart. That is the point of the pair: the desktop
// golden shows the caption ('WORKSPACE') and the divider in the rail, and this
// golden must show NEITHER in the bottom bar — captions and dividers are
// decorations of the rail, not routes (nav commit 9e64517; EdenMobileLayout's
// `_flatItems` drops them). TRD 23-06 turns that into an assertion; here it is
// pinned as pixels, which is the form that survives a refactor of the
// assertion.
//
// GOTCHA carried forward for 23-06: EdenMobileLayout still defaults
// `selectableBody: true` today. This golden is taken BEFORE 23-06 flips it — if
// the flip moves a pixel, 23-06 owes an explanation.
//
// INPUT MODALITY. The mobile shell is a TOUCH surface, so it declares
// `EdenInputModality.touch` and is held to the 48dp Material / 44pt iOS HIG
// floors — the strict ones. A bottom bar is reached with a fingertip; there is
// no reading under which the pointer floor is the honest standard for it.

import 'package:flutter/material.dart';

import '../../a11y/eden_input_modality.dart';
import '../../../dev_app/registry/eden_story.dart';
import 'eden_desktop_layout.stories.dart' show kSharedShellNavItems, kShellUser;
import 'eden_mobile_layout.dart';
import 'layout_data.dart';

/// The mobile shell fixture. Registered by tool/gen_stories.dart.
final List<EdenStory> edenMobileLayoutStories = <EdenStory>[
  /// Pins the bottom bar at a phone width: four real destinations, no caption,
  /// no divider, 'Orders' selected. The 390px box is the phone viewport,
  /// imposed by the story because the generated tests share one harness width.
  EdenStory(
    id: 'mobile-layout/default',
    component: 'mobile-layout',
    name: 'Default',
    icon: Icons.phone_iphone,
    knobs: const [],
    inputModality: EdenInputModality.touch,
    build: (context, _) => SizedBox(
      width: 390,
      child: EdenMobileLayout(
        navItems: kSharedShellNavItems,
        selectedId: 'orders',
        onNavChanged: (_) {},
        topBar: const EdenTopBarConfig(title: 'Orders'),
        user: kShellUser,
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Orders placed in the last 30 days appear here.',
          ),
        ),
      ),
    ),
  ),
];

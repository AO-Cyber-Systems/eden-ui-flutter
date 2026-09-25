// Co-located stories for the full desktop shell.
//
// These two goldens are the BEFORE-BASELINE that TRD 23-06 reshapes the shell
// against: the default-builder path is only provably a no-visual-change if a
// byte-identical render exists first.
//
// HAND-WRITTEN. The `navItems` list below is deliberately shared with
// eden_mobile_layout.stories.dart (via [kSharedShellNavItems]) so the desktop
// and mobile goldens are directly comparable — that is what makes "captions and
// dividers never reach the bottom bar" (nav commit 9e64517) VISIBLE in pixels
// rather than only asserted in a widget test.
//
// INPUT MODALITY. The desktop shell is a POINTER surface (both stories, the
// 720px 'narrow' one included — narrow still renders the rail, not the bottom
// bar). See eden_nav_item.stories.dart for the reasoning; the declaration
// selects WCAG 2.5.8's 24x24 floor and waives nothing.
//
// VIEWPORT. The narrow story declares `viewportWidth: 720` rather than
// wrapping the shell in a SizedBox. It used to do the latter, and the
// harness's child slot is TIGHT: the 720 was clamped back to 1280 by
// `BoxConstraints.enforce` and the story rendered the DEFAULT surface. The
// two light goldens were byte-identical (sha256 a077f9dd…), as were the dark
// pair, so the narrow rail had never been rendered once and the `expectUiSane`
// half re-measured the default surface too. A declared viewport drives
// `tester.view.physicalSize`, so MediaQuery, the golden's dimensions and every
// geometry rule agree on one number.

import 'package:flutter/material.dart';

import '../../a11y/eden_input_modality.dart';
import '../../tokens/spacing.dart';
import '../../../dev_app/registry/eden_story.dart';
import 'eden_desktop_layout.dart';
import 'layout_data.dart';

/// The one nav dataset both shell stories render. Four real destinations plus
/// one caption and one divider — the caption/divider pair is the part the
/// mobile bottom bar must drop.
const List<EdenNavItem> kSharedShellNavItems = <EdenNavItem>[
  EdenNavItem.caption('Workspace'),
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
  EdenNavItem(
      id: 'orders',
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      badge: '3'),
  EdenNavItem.divider(),
  EdenNavItem(
      id: 'reports', label: 'Reports', icon: Icons.insert_chart_outlined),
  EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
];

/// The signed-in user shown in the sidebar footer.
const EdenLayoutUser kShellUser = EdenLayoutUser(
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  initials: 'AL',
);

/// A top bar with a title AND search, so the golden pins both slots.
const EdenTopBarConfig kShellTopBar = EdenTopBarConfig(
  title: 'Orders',
  showSearch: true,
  searchHint: 'Search orders…',
);

/// The viewport the 'narrow' story is measured at. A VIEWPORT, not spacing:
/// it is named rather than inlined so `no_magic_spacing` -- which cannot tell
/// a viewport from a gutter, and correctly refuses to guess -- reads a
/// token-shaped reference here instead of a bare literal. Same pixels.
const double _kNarrowShellViewport = 720;

/// Body copy long enough to actually be visible in the golden — an empty body
/// would make a content-area regression invisible.
const Widget _kBody = Padding(
  padding: EdgeInsets.all(EdenSpacing.space6),
  child: Text(
    'Orders placed in the last 30 days appear here. Select an order to see '
    'its fulfilment timeline, payment status and customer contact details.',
  ),
);

EdenDesktopLayout _shell() => EdenDesktopLayout(
      navItems: kSharedShellNavItems,
      selectedId: 'orders',
      onNavChanged: (_) {},
      topBar: kShellTopBar,
      user: kShellUser,
      body: _kBody,
    );

/// The desktop shell fixtures. Registered by tool/gen_stories.dart.
final List<EdenStory> edenDesktopLayoutStories = <EdenStory>[
  /// Pins the whole assembled shell at a comfortable width: 260px rail with
  /// caption, divider, badge and selected item; top bar with title + search;
  /// user tile in the footer; body copy in the content area.
  EdenStory(
    id: 'desktop-layout/default',
    component: 'desktop-layout',
    name: 'Default',
    icon: Icons.desktop_windows_outlined,
    knobs: const [],
    inputModality: EdenInputModality.pointer,
    build: (context, _) => _shell(),
  ),

  /// Pins the rail's behaviour BELOW the comfortable breakpoint. The width is
  /// DECLARED by the story and driven through `tester.view.physicalSize`, not
  /// imposed with a SizedBox around the shell: the harness's child slot is
  /// tight, so a SizedBox is clamped back to the harness width and the story
  /// silently renders the default surface.
  EdenStory(
    id: 'desktop-layout/narrow',
    component: 'desktop-layout',
    name: 'Narrow',
    icon: Icons.width_normal,
    knobs: const [],
    inputModality: EdenInputModality.pointer,
    viewportWidth: _kNarrowShellViewport,
    build: (context, _) => _shell(),
  ),
];

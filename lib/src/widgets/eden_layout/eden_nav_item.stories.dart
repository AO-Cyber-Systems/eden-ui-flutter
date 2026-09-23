// Co-located stories for the nav-item states of the Eden shell rail.
//
// There is NO public `EdenNavItem` WIDGET — `_NavTile`, `_NavSectionLabel`,
// `_ExpandableNavHeader`, `_DisclosedChildren` and `_Badge` are all private to
// eden_desktop_layout.dart. So every item state here is rendered through a real
// [EdenDesktopLayout] with a `navItems` list crafted for exactly that state.
// That is the honest surface, and it is what makes these goldens a valid
// before-baseline for the shell reshaping in TRD 23-06.
//
// HAND-WRITTEN, one story per meaningful state. Not generated from a list of
// state names — each `navItems` list below is the fixture that produces its
// state, and the `///` line above each story says what that story pins.
//
// Goldens for these stories are produced and compared by the CI `stories` job
// on Linux only (eden-ui-flutter#32); locally they skip. `expectUiSane` runs
// everywhere.

import 'package:flutter/material.dart';

import '../../../dev_app/registry/eden_story.dart';
import 'eden_desktop_layout.dart';
import 'layout_data.dart';

/// A label long enough to exceed the 260px rail once the 20px icon, the
/// horizontal padding and the tile inset are taken out of it — roughly 150px of
/// text budget remains, and this string wants far more than that. It exists to
/// pin the ellipsis: if a future layout change lets the label run past the rail
/// (an unbounded Row child, a removed `TextOverflow.ellipsis`) the golden goes
/// red instead of the truncation quietly disappearing.
const String _kLongLabel =
    'Quarterly Reconciliation and Settlement Reporting Workspace';

/// The two children shared by the collapsed and expanded disclosure stories.
/// Same data both times — `initiallyExpanded` is the ONLY difference, which is
/// what makes the pair a real before/after of the disclosure behaviour.
const List<EdenNavItem> _kGroupChildren = <EdenNavItem>[
  EdenNavItem(id: 'reports-daily', label: 'Daily', icon: Icons.today_outlined),
  EdenNavItem(
      id: 'reports-monthly', label: 'Monthly', icon: Icons.date_range_outlined),
];

/// A plain, unselected destination — the baseline every other item state is a
/// deviation from.
const List<EdenNavItem> _kPlainItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
  EdenNavItem(id: 'orders', label: 'Orders', icon: Icons.receipt_long_outlined),
];

EdenDesktopLayout _shell(
  List<EdenNavItem> items, {
  String selectedId = 'home',
}) =>
    EdenDesktopLayout(
      navItems: items,
      selectedId: selectedId,
      onNavChanged: (_) {},
      body: const Center(child: Text('Body')),
    );

/// The nav-item state fixtures. Registered by tool/gen_stories.dart — never
/// hand-edit lib/dev_app/registry/register_stories.g.dart.
final List<EdenStory> edenNavItemStories = <EdenStory>[
  /// Pins the resting treatment of an unselected destination: icon, label,
  /// no fill, no badge.
  EdenStory(
    id: 'nav-item/default',
    component: 'nav-item',
    name: 'Default',
    icon: Icons.radio_button_unchecked,
    knobs: const [],
    build: (context, _) => _shell(_kPlainItems, selectedId: 'nothing-selected'),
  ),

  /// Pins the SELECTED treatment — the same two items, with `selectedId`
  /// naming the first. A regression that drops the selected fill or the active
  /// icon is a golden diff against nav-item/default.
  EdenStory(
    id: 'nav-item/selected',
    component: 'nav-item',
    name: 'Selected',
    icon: Icons.radio_button_checked,
    knobs: const [],
    build: (context, _) => _shell(_kPlainItems),
  ),

  /// Pins that a collapsed disclosure group renders its header ONLY — the two
  /// children must not be in the tree, and `expectUiSane`'s containment rule
  /// must not see them below the fold.
  EdenStory(
    id: 'nav-item/expandable-collapsed',
    component: 'nav-item',
    name: 'Expandable collapsed',
    icon: Icons.chevron_right,
    knobs: const [],
    build: (context, _) => _shell(
      const <EdenNavItem>[
        EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
        EdenNavItem(
          id: 'reports',
          label: 'Reports',
          icon: Icons.insert_chart_outlined,
          expandable: true,
          children: _kGroupChildren,
        ),
      ],
      selectedId: 'home',
    ),
  ),

  /// Pins the CONTAINMENT rule of nav commit b9e82bf: a disclosed group's
  /// children render inside the group, below its header and above the next
  /// sibling. `expectUiSane`'s disjointness assertion is what proves they do
  /// not spill over the sibling item that follows them.
  EdenStory(
    id: 'nav-item/expandable-expanded',
    component: 'nav-item',
    name: 'Expandable expanded',
    icon: Icons.expand_more,
    knobs: const [],
    build: (context, _) => _shell(
      const <EdenNavItem>[
        EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
        EdenNavItem(
          id: 'reports',
          label: 'Reports',
          icon: Icons.insert_chart_outlined,
          expandable: true,
          initiallyExpanded: true,
          children: _kGroupChildren,
        ),
        // The sibling AFTER the group is the whole point: containment is only
        // observable when there is something for the children to spill onto.
        EdenNavItem(
            id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
      ],
      selectedId: 'home',
    ),
  ),

  /// Pins a caption as a PASSIVE label: uppercase section text, no icon, and —
  /// per EdenNavItem.caption's contract — no tap target and no button role, so
  /// `expectUiSane` sees zero tap actions on it, which is correct.
  EdenStory(
    id: 'nav-item/caption',
    component: 'nav-item',
    name: 'Caption',
    icon: Icons.label_outline,
    knobs: const [],
    build: (context, _) => _shell(
      const <EdenNavItem>[
        EdenNavItem.caption('Workspace'),
        EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
      ],
    ),
  ),

  /// Pins the divider: a rule between two groups that is chrome only — it
  /// carries no label, no id a consumer can navigate to, and no tap target.
  EdenStory(
    id: 'nav-item/divider',
    component: 'nav-item',
    name: 'Divider',
    icon: Icons.horizontal_rule,
    knobs: const [],
    build: (context, _) => _shell(
      const <EdenNavItem>[
        EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
        EdenNavItem.divider(),
        EdenNavItem(
            id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
      ],
    ),
  ),

  /// Pins the ELLIPSIS. [_kLongLabel] cannot fit the 260px rail; this golden
  /// goes red the day a layout change lets the label run past the sidebar edge
  /// instead of truncating.
  EdenStory(
    id: 'nav-item/long-label',
    component: 'nav-item',
    name: 'Long label',
    icon: Icons.short_text,
    knobs: const [],
    build: (context, _) => _shell(
      const <EdenNavItem>[
        EdenNavItem(
            id: 'reconciliation',
            label: _kLongLabel,
            icon: Icons.account_balance_outlined),
        EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
      ],
      selectedId: 'home',
    ),
  ),

  /// Pins badge placement relative to its label: the badge sits at the trailing
  /// edge of the tile, and `expectUiSane`'s disjointness rule proves it does not
  /// sit ON the label (on web the semantics node takes the click, so a badge
  /// overlapping its host eats the host's taps).
  EdenStory(
    id: 'nav-item/badge',
    component: 'nav-item',
    name: 'Badge',
    icon: Icons.circle_notifications_outlined,
    knobs: const [],
    build: (context, _) => _shell(
      const <EdenNavItem>[
        EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
        EdenNavItem(
            id: 'inbox',
            label: 'Inbox',
            icon: Icons.inbox_outlined,
            badge: '3'),
      ],
    ),
  ),
];

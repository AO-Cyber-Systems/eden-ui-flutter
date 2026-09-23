import 'package:flutter/material.dart';

/// A single navigation item used by both desktop and mobile layouts.
class EdenNavItem {
  const EdenNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badge,
    this.children = const [],
    this.isDivider = false,
    this.isCaption = false,
    this.expandable = false,
    this.initiallyExpanded = false,
    this.widgetKey,
    this.semanticsIdentifier,
  });

  /// Creates a visual divider separator between nav groups.
  const EdenNavItem.divider()
      : id = '__divider__',
        label = '',
        icon = Icons.horizontal_rule,
        activeIcon = null,
        badge = null,
        children = const [],
        isDivider = true,
        isCaption = false,
        expandable = false,
        initiallyExpanded = false,
        widgetKey = null,
        semanticsIdentifier = null;

  /// A non-interactive section label. Renders as an uppercase caption and
  /// nothing else — no icon, no tap target, no accessibility button role.
  const EdenNavItem.caption(this.label)
      : id = '__caption__',
        icon = Icons.label_outline,
        activeIcon = null,
        badge = null,
        children = const [],
        isDivider = false,
        isCaption = true,
        expandable = false,
        initiallyExpanded = false,
        widgetKey = null,
        semanticsIdentifier = null;

  final String id;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge; // e.g. "3" or "new"
  final List<EdenNavItem> children; // sub-items for grouped nav
  final bool isDivider; // true = renders as a horizontal divider

  /// True = renders as a passive uppercase section label. See
  /// [EdenNavItem.caption].
  final bool isCaption;

  /// Opt-in: render this group's [children] behind a tappable disclosure
  /// control instead of the always-open static band.
  ///
  /// Defaults to `false`, which is today's rendering. Nothing about a group
  /// that does not set this changes.
  final bool expandable;

  /// Seeds the disclosure state for an [expandable] group on first build.
  /// Ignored when [expandable] is `false`.
  final bool initiallyExpanded;

  /// Optional key attached to the rendered widget (e.g. for guided tour targeting).
  final GlobalKey? widgetKey;

  /// Optional stable identifier exposed to the OS accessibility tree for E2E
  /// test tooling (Maestro, etc). When null, layouts fall back to
  /// `eden-nav-<id>`.
  final String? semanticsIdentifier;
}

/// Configuration for the top bar / app bar.
class EdenTopBarConfig {
  const EdenTopBarConfig({
    this.title,
    this.titleWidget,
    this.showSearch = false,
    this.searchHint = 'Search…',
    this.onSearch,
    this.actions = const [],
    this.leading,
    this.trailing,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showSearch;
  final String searchHint;
  final ValueChanged<String>? onSearch;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? trailing; // e.g. user avatar
}

/// User profile shown in sidebar footer or mobile drawer header.
class EdenLayoutUser {
  const EdenLayoutUser({
    required this.name,
    this.email,
    this.avatarUrl,
    this.initials,
    this.onTap,
  });

  final String name;
  final String? email;
  final String? avatarUrl;
  final String? initials;
  final VoidCallback? onTap;
}

// ---------------------------------------------------------------------------
// Composition slots (TRD 23-06 / W1A-1a-06)
// ---------------------------------------------------------------------------

/// The rendering state of a nav row, as the layout knows it.
///
/// Handed to an [EdenNavItemBuilder] so a consumer can render the row itself
/// without having to re-derive selection or disclosure from its own state.
@immutable
class EdenNavItemState {
  const EdenNavItemState({
    this.isSelected = false,
    this.isExpanded = false,
    this.isCollapsedRail = false,
    this.depth = 0,
  });

  /// This row is the current selection.
  final bool isSelected;

  /// Meaningful only for an expandable group header: its children are shown.
  final bool isExpanded;

  /// The desktop sidebar is in its collapsed (icon rail) width.
  final bool isCollapsedRail;

  /// 0 = a top-level row, 1 = a disclosed child of an expandable group.
  final int depth;
}

/// Renders one nav row in place of the built-in renderer.
///
/// Return `null` to fall back to the default rendering for THAT row — which is
/// how a consumer replaces one item without having to re-implement the rest of
/// the rail. (The published interface in IMPLEMENTATION-PLAN row 1a-06 returned
/// a non-nullable `Widget`; that shape cannot satisfy the row's own acceptance
/// criterion — "replace ONE nav item without touching the other items" —
/// because the default renderer is private. The nullable return is the minimal
/// change that makes per-item replacement expressible. See TRD 23-06 SUMMARY.)
///
/// The `eden-nav-<id>` semantics identifier is applied by the layout OUTSIDE
/// this builder's result, so a consumer cannot drop it and the E2E tooling in
/// aodex and eden-biz keeps working whatever is returned here.
typedef EdenNavItemBuilder = Widget? Function(
  BuildContext context,
  EdenNavItem item,
  EdenNavItemState state,
);

/// Renders a non-interactive rail section — an [EdenNavItem] with
/// `isCaption: true` or `isDivider: true` — in place of the built-in
/// treatment. Return `null` to fall back to the default for that section.
typedef EdenNavSectionBuilder = Widget? Function(
  BuildContext context,
  EdenNavItem item,
);

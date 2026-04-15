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
        widgetKey = null,
        semanticsIdentifier = null;

  final String id;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge; // e.g. "3" or "new"
  final List<EdenNavItem> children; // sub-items for grouped nav
  final bool isDivider; // true = renders as a horizontal divider

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

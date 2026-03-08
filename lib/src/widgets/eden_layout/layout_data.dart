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
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge; // e.g. "3" or "new"
  final List<EdenNavItem> children; // sub-items for grouped nav
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

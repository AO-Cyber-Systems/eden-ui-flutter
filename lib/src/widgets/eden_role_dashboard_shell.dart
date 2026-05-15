import 'package:flutter/material.dart';

/// Palette presets for role badges in [EdenRoleDashboardShell].
///
/// Each vertical historically maps its primary brand color into the role
/// badge. The library resolves each enum value to a concrete (background,
/// foreground) pair internally so callers don't need to know about Eden
/// color tokens.
enum EdenRolePalette {
  trades,
  salon,
  medical,
  fuel,
  retail,
  legal,
  gov,
  neutral,
}

/// Display-priority hint for dashboard sections.
enum EdenDashboardSectionPriority { normal, high }

/// One configurable section on an [EdenRoleDashboardShell] grid.
@immutable
class EdenDashboardSection {
  /// Creates a dashboard section.
  const EdenDashboardSection({
    required this.id,
    required this.title,
    required this.body,
    this.priority = EdenDashboardSectionPriority.normal,
    this.icon,
    this.onTap,
    this.badge,
  });

  final String id;
  final String title;
  final Widget body;
  final EdenDashboardSectionPriority priority;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? badge;
}

/// A role-specific home dashboard shell — TODO(001-11) RED stub.
class EdenRoleDashboardShell extends StatelessWidget {
  const EdenRoleDashboardShell({
    super.key,
    required this.greeting,
    required this.roleLabel,
    this.rolePalette = EdenRolePalette.neutral,
    this.avatar,
    this.notificationButton,
    required this.sections,
    this.rightRail,
    this.narrowBreakpoint = 480,
    this.tabletBreakpoint = 768,
  });

  final String greeting;
  final String roleLabel;
  final EdenRolePalette rolePalette;
  final Widget? avatar;
  final Widget? notificationButton;
  final List<EdenDashboardSection> sections;
  final Widget? rightRail;
  final double narrowBreakpoint;
  final double tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

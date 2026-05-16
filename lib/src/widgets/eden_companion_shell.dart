import 'package:flutter/material.dart';

import 'eden_adaptive_layout.dart';
import 'eden_app_mode.dart';
import 'eden_network_status_bar.dart';
import 'eden_role_dashboard_shell.dart';
import 'eden_ux_mode_toggle.dart';

/// One bottom-nav destination. Up to 5 are accepted by
/// [EdenCompanionShell] per Material 3 BottomNavigationBar + lock B.
@immutable
class EdenCompanionNavItem {
  const EdenCompanionNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.activeIcon,
  });

  /// Stable identifier passed back to the consumer's `onNavChanged`.
  final String id;

  /// Short label rendered under the icon.
  final String label;

  /// Default tab icon.
  final IconData icon;

  /// Optional icon shown when this tab is the active destination.
  final IconData? activeIcon;
}

/// Mode-aware companion-app shell. Composes:
///   - `EdenRoleDashboardShell` (Wave A) as the body.
///   - `EdenNetworkStatusBar` (Wave A) pinned at top.
///   - `EdenUxModeToggle.compact` (TRD-03) as the always-on escape
///     hatch in `AppBar.actions`.
///   - `EdenAdaptiveLayout` (TRD-02) wrapping the whole thing with
///     `forceCompact: (mode == fieldCompanion)`.
///
/// **Pre-check note (TRD-05 Task 1).** Wave A's `EdenRoleDashboardShell`
/// does NOT have a top-right action slot — only `notificationButton`
/// (which is semantically dedicated). Per the no-breaking-changes
/// constraint, this shell renders its own `AppBar` and hosts the UX
/// toggle in `AppBar.actions`. Reference: lines 79–90 of
/// `lib/src/widgets/eden_role_dashboard_shell.dart`.
///
/// **CRITICAL — lock E rule 3.** When the surrounding
/// [EdenAppModeScope]'s `currentMode == EdenAppMode.fieldCompanion`,
/// the shell pins to Compact at ALL widths (including 1200pt Expanded
/// surfaces). The mechanism is `EdenAdaptiveLayout(forceCompact:
/// true)`. See the test
/// `'CRITICAL — lock E rule 3: companion pins to Compact at 1200pt'`
/// for the enforcement gate.
///
/// **Out of scope.** Routing (consumer wires `onNavChanged` to
/// `go_router`), auth (greeting + roleLabel are passed in),
/// connectivity polling (consumer pushes `networkStatus` in),
/// pagination of >5 destinations (deferred).
class EdenCompanionShell extends StatelessWidget {
  const EdenCompanionShell({
    super.key,
    required this.greeting,
    required this.roleLabel,
    this.rolePalette,
    this.avatar,
    required this.sections,
    required this.navItems,
    required this.selectedNavId,
    required this.onNavChanged,
    this.networkStatus = EdenNetworkStatus.online,
  }) : assert(
          navItems.length <= 5,
          'EdenCompanionShell supports ≤5 navItems; pagination is deferred.',
        );

  final String greeting;
  final String roleLabel;
  final EdenRolePalette? rolePalette;
  final Widget? avatar;
  final List<EdenDashboardSection> sections;
  final List<EdenCompanionNavItem> navItems;
  final String selectedNavId;
  final ValueChanged<String> onNavChanged;
  final EdenNetworkStatus networkStatus;

  @override
  Widget build(BuildContext context) {
    // Reading via modeOf() also subscribes via
    // dependOnInheritedWidgetOfExactType — this widget rebuilds on
    // controller.setMode.
    final mode = EdenAppModeScope.modeOf(context);
    final forceCompact = mode == EdenAppMode.fieldCompanion;

    return EdenAdaptiveLayout(
      forceCompact: forceCompact,
      compactBuilder: _buildCompactShell,
      expandedBuilder: _buildExpandedShell,
    );
  }

  Widget _buildCompactShell(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roleLabel),
        actions: [
          EdenUxModeToggle.compact(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          EdenNetworkStatusBar(status: networkStatus),
          Expanded(
            child: EdenRoleDashboardShell(
              greeting: greeting,
              roleLabel: roleLabel,
              rolePalette: rolePalette ?? EdenRolePalette.neutral,
              avatar: avatar,
              sections: sections,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentNavIndex(),
          onTap: (index) => onNavChanged(navItems[index].id),
          items: [
            for (final item in navItems)
              BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon:
                    item.activeIcon != null ? Icon(item.activeIcon) : null,
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedShell(BuildContext context) {
    // Admin mode chrome (and any other non-companion mode) — minimal
    // expanded shell. The expectation is that admin chrome lives in
    // `eden-platform-flutter`'s admin shell, NOT here. For the few
    // cases where EdenCompanionShell is rendered in admin mode (e.g.,
    // the dev catalog or a transitional state during mode-flip),
    // render a sensible placeholder that still wires the UX toggle so
    // the user can flip back.
    return Scaffold(
      key: const ValueKey('expanded-companion-shell'),
      appBar: AppBar(
        title: Text(roleLabel),
        actions: [
          EdenUxModeToggle.labeled(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          EdenNetworkStatusBar(status: networkStatus),
          Expanded(
            child: EdenRoleDashboardShell(
              greeting: greeting,
              roleLabel: roleLabel,
              rolePalette: rolePalette ?? EdenRolePalette.neutral,
              avatar: avatar,
              sections: sections,
            ),
          ),
        ],
      ),
    );
  }

  int _currentNavIndex() {
    final i = navItems.indexWhere((n) => n.id == selectedNavId);
    return i < 0 ? 0 : i;
  }
}

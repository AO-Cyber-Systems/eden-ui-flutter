// Do NOT regenerate via LLM — hand-built fixtures for EdenCompanionShell.
//
// Trades-flavored sample data wiring through the TRD-05 composition
// shell. The shell + nav SHAPE is identical across verticals (lock B);
// only this data varies. Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenCompanionShellFixtures {
  EdenCompanionShellFixtures._();

  /// Five-tab bottom-nav (the maximum per Material 3 + lock B).
  static List<EdenCompanionNavItem> tradesNavItems() => const [
        EdenCompanionNavItem(id: 'home', label: 'Home', icon: Icons.home),
        EdenCompanionNavItem(id: 'jobs', label: 'Jobs', icon: Icons.work),
        EdenCompanionNavItem(
            id: 'schedule', label: 'Schedule', icon: Icons.calendar_today),
        EdenCompanionNavItem(
            id: 'inventory', label: 'Inventory', icon: Icons.inventory_2),
        EdenCompanionNavItem(
            id: 'profile', label: 'Profile', icon: Icons.person),
      ];

  /// Three dashboard sections — placeholders for test stability.
  static List<EdenDashboardSection> tradesSections() => const [
        EdenDashboardSection(
          id: 'today',
          title: "Today's appointments",
          body: Padding(
            padding: EdgeInsets.all(8),
            child: Text('3 stops queued'),
          ),
        ),
        EdenDashboardSection(
          id: 'insights',
          title: 'AI insights',
          body: Padding(
            padding: EdgeInsets.all(8),
            child: Text('Look-ahead routing saved 22 min today'),
          ),
        ),
        EdenDashboardSection(
          id: 'quick',
          title: 'Quick actions',
          body: Padding(
            padding: EdgeInsets.all(8),
            child: Text('Check in / Out · Sign / Photo'),
          ),
        ),
      ];
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenMobileQuickAccessGrid.
// Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenMobileQuickAccessGridFixtures {
  EdenMobileQuickAccessGridFixtures._();

  /// Six-item trades-flavored launcher set (donor parity).
  static List<EdenMobileQuickAccessItem> tradesSix() => const [
        EdenMobileQuickAccessItem(
            id: 'find_parts', icon: Icons.search, label: 'Find Parts'),
        EdenMobileQuickAccessItem(
            id: 'request_parts',
            icon: Icons.inventory_2_outlined,
            label: 'Request Parts'),
        EdenMobileQuickAccessItem(
          id: 'quick_bid',
          icon: Icons.attach_money,
          label: 'Quick Bid',
          accent: Color(0xFFD4A853),
        ),
        EdenMobileQuickAccessItem(
            id: 'contacts',
            icon: Icons.phone_outlined,
            label: 'Contacts'),
        EdenMobileQuickAccessItem(
            id: 'po_status',
            icon: Icons.assignment_outlined,
            label: 'PO Status'),
        EdenMobileQuickAccessItem(
          id: 'escalate',
          icon: Icons.warning_amber_outlined,
          label: 'Escalate',
          accent: Color(0xFFEF4444),
        ),
      ];

  /// Two-item smoke fixture (smaller for tap-event tests).
  static List<EdenMobileQuickAccessItem> twoItems() => const [
        EdenMobileQuickAccessItem(
            id: 'a', icon: Icons.search, label: 'Alpha'),
        EdenMobileQuickAccessItem(
            id: 'b', icon: Icons.phone_outlined, label: 'Bravo'),
      ];

  /// Eight-item set (for crossAxisCount: 4 grid layout tests).
  static List<EdenMobileQuickAccessItem> eightItems() => const [
        EdenMobileQuickAccessItem(
            id: 'i1', icon: Icons.search, label: 'One'),
        EdenMobileQuickAccessItem(
            id: 'i2', icon: Icons.phone_outlined, label: 'Two'),
        EdenMobileQuickAccessItem(
            id: 'i3', icon: Icons.assignment_outlined, label: 'Three'),
        EdenMobileQuickAccessItem(
            id: 'i4', icon: Icons.warning_amber_outlined, label: 'Four'),
        EdenMobileQuickAccessItem(
            id: 'i5', icon: Icons.attach_money, label: 'Five'),
        EdenMobileQuickAccessItem(
            id: 'i6', icon: Icons.inventory_2_outlined, label: 'Six'),
        EdenMobileQuickAccessItem(
            id: 'i7', icon: Icons.event_outlined, label: 'Seven'),
        EdenMobileQuickAccessItem(
            id: 'i8', icon: Icons.work_outlined, label: 'Eight'),
      ];

  /// Single-item set with no accent (for default-styling assertions).
  static List<EdenMobileQuickAccessItem> singlePlain() => const [
        EdenMobileQuickAccessItem(
            id: 'plain', icon: Icons.search, label: 'Plain'),
      ];

  /// Single-item set with gold accent (for accent-styling assertions).
  static List<EdenMobileQuickAccessItem> singleGold() => const [
        EdenMobileQuickAccessItem(
          id: 'gold',
          icon: Icons.attach_money,
          label: 'Gold',
          accent: Color(0xFFD4A853),
        ),
      ];

  /// Single-item set with red accent.
  static List<EdenMobileQuickAccessItem> singleRed() => const [
        EdenMobileQuickAccessItem(
          id: 'red',
          icon: Icons.warning_amber_outlined,
          label: 'Red',
          accent: Color(0xFFEF4444),
        ),
      ];
}

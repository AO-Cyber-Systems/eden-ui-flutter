// Do NOT regenerate via LLM — hand-built fixtures for EdenQuickActionBar.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenQuickActionBarFixtures {
  EdenQuickActionBarFixtures._();

  /// 5 actions for a customer-detail bar.
  static List<EdenQuickAction> customerDetailActions({
    VoidCallback? onPin,
    VoidCallback? onChat,
    VoidCallback? onCall,
    VoidCallback? onEmail,
    VoidCallback? onArchive,
  }) =>
      <EdenQuickAction>[
        EdenQuickAction(
            icon: Icons.push_pin, tooltip: 'Pin', onPressed: onPin),
        EdenQuickAction(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chat',
            onPressed: onChat),
        EdenQuickAction(
            icon: Icons.phone, tooltip: 'Call', onPressed: onCall),
        EdenQuickAction(
            icon: Icons.email_outlined,
            tooltip: 'Email',
            onPressed: onEmail),
        EdenQuickAction(
            icon: Icons.archive_outlined,
            tooltip: 'Archive',
            onPressed: onArchive),
      ];

  /// 8 actions for a work-order-detail bar.
  static List<EdenQuickAction> workOrderDetailActions() => <EdenQuickAction>[
        EdenQuickAction(
            icon: Icons.print, tooltip: 'Print', onPressed: () {}),
        EdenQuickAction(
            icon: Icons.push_pin, tooltip: 'Pin', onPressed: () {}),
        EdenQuickAction(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chat',
            onPressed: () {}),
        EdenQuickAction(
            icon: Icons.phone, tooltip: 'Call', onPressed: () {}),
        EdenQuickAction(
            icon: Icons.camera_alt_outlined,
            tooltip: 'Photo',
            onPressed: () {}),
        EdenQuickAction(
            icon: Icons.share, tooltip: 'Share', onPressed: () {}),
        EdenQuickAction(
            icon: Icons.archive_outlined,
            tooltip: 'Archive',
            onPressed: () {}),
        EdenQuickAction(
            icon: Icons.delete_outline,
            tooltip: 'Delete',
            onPressed: () {}),
      ];

  /// 3 actions, all with badge counts.
  static List<EdenQuickAction> withBadges() => <EdenQuickAction>[
        EdenQuickAction(
            icon: Icons.notifications_outlined,
            tooltip: 'Alerts',
            badgeCount: 3,
            onPressed: () {}),
        EdenQuickAction(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Messages',
            badgeCount: 12,
            onPressed: () {}),
        EdenQuickAction(
            icon: Icons.task_alt,
            tooltip: 'Tasks',
            badgeCount: 150,
            onPressed: () {}),
      ];

  /// 4 actions, 2 disabled (onPressed=null).
  static List<EdenQuickAction> withDisabled() => const <EdenQuickAction>[
        EdenQuickAction(
            icon: Icons.push_pin, tooltip: 'Pin'),
        EdenQuickAction(
            icon: Icons.chat_bubble_outline, tooltip: 'Chat'),
        EdenQuickAction(
            icon: Icons.phone, tooltip: 'Call'),
        EdenQuickAction(
            icon: Icons.share, tooltip: 'Share'),
      ];
}

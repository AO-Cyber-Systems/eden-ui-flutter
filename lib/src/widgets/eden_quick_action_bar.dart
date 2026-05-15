import 'package:flutter/material.dart';

/// A single action entry in an [EdenQuickActionBar].
@immutable
class EdenQuickAction {
  const EdenQuickAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.badgeCount,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int? badgeCount;
}

/// RED-phase stub for EdenQuickActionBar.
class EdenQuickActionBar extends StatelessWidget {
  const EdenQuickActionBar({
    super.key,
    required this.actions,
    this.maxInlineActions,
    this.height = 56.0,
    this.elevation = 4.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final List<EdenQuickAction> actions;
  final int? maxInlineActions;
  final double height;
  final double elevation;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

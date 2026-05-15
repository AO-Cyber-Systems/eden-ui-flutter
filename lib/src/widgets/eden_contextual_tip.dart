import 'package:flutter/material.dart';

/// Placement for a contextual tip relative to its target.
enum EdenTipPlacement { above, below, left, right }

/// RED-phase stub for EdenContextualTip.
class EdenContextualTip extends StatelessWidget {
  const EdenContextualTip({
    super.key,
    required this.target,
    required this.message,
    this.visible = true,
    this.onDismiss,
    this.placement = EdenTipPlacement.below,
    this.icon,
  });

  final GlobalKey target;
  final String message;
  final bool visible;
  final VoidCallback? onDismiss;
  final EdenTipPlacement placement;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

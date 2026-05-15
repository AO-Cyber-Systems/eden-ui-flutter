import 'package:flutter/material.dart';

/// Placement for a contextual tip relative to its target.
enum EdenTipPlacement { above, below, left, right }

/// A small dismissible info bubble used to annotate complex UI features.
///
/// The library version renders inline (next to the target) rather than as a
/// floating Overlay — this keeps the widget self-contained, testable, and
/// avoids requiring an Overlay ancestor. Downstream apps that want a
/// floating bubble can wrap this in an [OverlayPortal] themselves.
///
/// Donor pattern: trades-flutter `contextual_tip.dart`.
///
/// ```dart
/// EdenContextualTip(
///   target: aGlobalKey,                       // currently informational only
///   message: 'Drag phases from the palette',
///   visible: !state.dismissed,
///   onDismiss: () => state.dismiss(),
///   placement: EdenTipPlacement.below,
/// )
/// ```
class EdenContextualTip extends StatelessWidget {
  /// Creates a contextual tip.
  const EdenContextualTip({
    super.key,
    required this.target,
    required this.message,
    this.visible = true,
    this.onDismiss,
    this.placement = EdenTipPlacement.below,
    this.icon,
  });

  /// A [GlobalKey] on the target widget. Currently informational — the
  /// library renders inline; downstream wrappers can use this key with
  /// `RenderBox.localToGlobal` for floating-overlay implementations.
  final GlobalKey target;

  /// Message text shown inside the bubble.
  final String message;

  /// When false, the bubble does not render.
  final bool visible;

  /// Invoked when the user taps the close icon.
  final VoidCallback? onDismiss;

  /// Position of the bubble relative to its (caller-anchored) target.
  final EdenTipPlacement placement;

  /// Optional leading icon (defaults to Icons.info_outline).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey<String>('contextual_tip_bubble'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon ?? Icons.info_outline,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
          if (onDismiss != null) ...<Widget>[
            const SizedBox(width: 8),
            InkWell(
              key: const ValueKey<String>('contextual_tip_dismiss'),
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

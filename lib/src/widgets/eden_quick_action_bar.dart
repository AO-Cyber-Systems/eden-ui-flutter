import 'package:flutter/material.dart';

/// A single action entry in an [EdenQuickActionBar].
@immutable
class EdenQuickAction {
  /// Creates a quick-action descriptor.
  const EdenQuickAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.badgeCount,
  });

  /// Icon glyph shown in the action button.
  final IconData icon;

  /// Long-press tooltip / accessibility label.
  final String tooltip;

  /// Tap handler. When null, the action renders as greyed-out and ignores taps.
  final VoidCallback? onPressed;

  /// Optional badge count displayed as a red dot + number on the action icon.
  final int? badgeCount;
}

/// A bottom contextual action strip for detail views.
///
/// Renders a horizontal row of icon-action buttons. At narrow widths,
/// overflow actions collapse into a "more" [PopupMenuButton].
///
/// Distinct from [EdenBottomNav] (route-level navigation) — quick action
/// bars are contextual to the current detail content (customer detail,
/// work order detail, patient chart, matter card, etc.) and surface
/// quick verbs like Pin / Chat / Call / Print / Share / Archive.
///
/// Pattern donor: trades-react `QuickActionBar.tsx`.
class EdenQuickActionBar extends StatelessWidget {
  /// Creates a quick-action bar.
  const EdenQuickActionBar({
    super.key,
    required this.actions,
    this.maxInlineActions,
    this.height = 56.0,
    this.elevation = 4.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  /// Actions to display in display order.
  final List<EdenQuickAction> actions;

  /// Optional explicit cap on inline actions. Anything past this collapses
  /// into a "more" menu. When null, the bar computes the cap from
  /// available width (`maxWidth / 56 - 1`).
  final int? maxInlineActions;

  /// Bar height in logical pixels.
  final double height;

  /// Material elevation.
  final double elevation;

  /// Inner padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        // How many 56pt slots fit in the available width.
        final int slotCap = constraints.maxWidth.isFinite
            ? (constraints.maxWidth / 56).floor().clamp(1, actions.length)
            : actions.length;
        // If every action already fits, no overflow menu is needed.
        // Otherwise, leave one slot for the menu trigger.
        final int autoCap = slotCap >= actions.length
            ? actions.length
            : (slotCap > 1 ? slotCap - 1 : slotCap);
        final int cap = (maxInlineActions ?? autoCap)
            .clamp(0, actions.length);
        final List<EdenQuickAction> inline = actions.take(cap).toList();
        final List<EdenQuickAction> overflow = actions.skip(cap).toList();
        return Material(
          elevation: elevation,
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: padding,
              child: Row(
                children: <Widget>[
                  for (final a in inline)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _ActionButton(action: a),
                    ),
                  if (overflow.isNotEmpty)
                    PopupMenuButton<EdenQuickAction>(
                      key: const ValueKey<String>(
                          'quick_action_overflow_menu'),
                      icon: const Icon(Icons.more_horiz),
                      itemBuilder: (_) => <PopupMenuEntry<EdenQuickAction>>[
                        for (final a in overflow)
                          PopupMenuItem<EdenQuickAction>(
                            value: a,
                            enabled: a.onPressed != null,
                            child: Row(
                              children: <Widget>[
                                Icon(a.icon, size: 18),
                                const SizedBox(width: 8),
                                Text(a.tooltip),
                                if (a.badgeCount != null &&
                                    a.badgeCount! > 0) ...<Widget>[
                                  const SizedBox(width: 8),
                                  _Badge(count: a.badgeCount!),
                                ],
                              ],
                            ),
                          ),
                      ],
                      onSelected: (a) => a.onPressed?.call(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final EdenQuickAction action;

  @override
  Widget build(BuildContext context) {
    final bool enabled = action.onPressed != null;
    final hasBadge =
        action.badgeCount != null && action.badgeCount! > 0;
    final iconButton = IconButton(
      key: ValueKey<String>('quick_action_${action.tooltip}'),
      tooltip: action.tooltip,
      icon: Icon(action.icon),
      onPressed: enabled ? action.onPressed : null,
    );
    if (!hasBadge) return iconButton;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        iconButton,
        Positioned(
          right: 4,
          top: 4,
          child: _Badge(count: action.badgeCount!),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : count.toString();
    return Container(
      key: ValueKey<String>('quick_action_badge_$count'),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        display,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

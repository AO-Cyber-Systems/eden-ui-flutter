import 'package:flutter/material.dart';

/// Animated count badge that overlays a child widget.
///
/// Shows a colored circle with a count when [count] > 0. The badge
/// animates in/out with a scale transition. Commonly used for notification
/// counts on icons or nav items.
///
/// ```dart
/// EdenCountBadge(
///   count: 5,
///   child: Icon(Icons.notifications),
/// )
/// EdenCountBadge(
///   count: 150,
///   maxCount: 99,
///   child: Icon(Icons.mail),
/// )
/// ```
class EdenCountBadge extends StatelessWidget {
  const EdenCountBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.maxCount = 99,
    this.offset = const Offset(-6, -6),
  });

  /// Number of items. Badge is hidden when 0.
  final int count;

  /// The widget to badge (typically an icon).
  final Widget child;

  /// Badge background color. Defaults to theme error color.
  final Color? badgeColor;

  /// Maximum count to display before showing "{maxCount}+".
  final int maxCount;

  /// Position offset from top-right corner of child.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBadgeColor = badgeColor ?? theme.colorScheme.error;

    if (count <= 0) return child;

    final label = count > maxCount ? '$maxCount+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: offset.dx,
          top: offset.dy,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Container(
              key: ValueKey(label),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: effectiveBadgeColor,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

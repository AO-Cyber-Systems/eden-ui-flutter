import 'package:flutter/material.dart';

/// Contextual popup anchored to a child widget.
///
/// Shows a floating card with content when the child is tapped.
/// Tapping outside dismisses the popover.
///
/// ```dart
/// EdenPopover(
///   content: UserProfileCard(user: user),
///   child: EdenAvatar(initials: 'JD'),
/// )
/// ```
class EdenPopover extends StatelessWidget {
  const EdenPopover({
    super.key,
    required this.child,
    required this.content,
    this.width = 280,
    this.padding = const EdgeInsets.all(16),
    this.offset = const Offset(0, 8),
  });

  final Widget child;
  final Widget content;
  final double width;
  final EdgeInsets padding;
  final Offset offset;

  void _show(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            // Dismiss area
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            // Popover card
            Positioned(
              left: position.dx,
              top: position.dy + size.height + offset.dy,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: width,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: content,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: child,
    );
  }
}

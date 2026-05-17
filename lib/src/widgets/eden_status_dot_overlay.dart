import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// The kinds of status indicators an [EdenStatusDotOverlay] can render.
enum EdenStatusDotKind { online, offline, away, busy, sync, unread }

/// Composable overlay that places a status dot or unread-count badge over any
/// child widget.
///
/// SIBLING (not replacement) of `EdenAvatar.status` — that built-in avatar
/// status indicator stays as-is. [EdenStatusDotOverlay] is the cross-vertical
/// primitive for non-avatar widgets and count badges.
///
/// Composable on ANY widget: avatar, button, card, icon, custom widget.
///
/// Reads `EdenStatusPalette` ThemeExtension from obj 009 when present;
/// gracefully falls back to `EdenColors.success/warning/error/info`.
///
/// Usage:
/// ```dart
/// // Crew tile with availability
/// EdenStatusDotOverlay(
///   kind: EdenStatusDotKind.busy,
///   child: CrewTile(name: 'Devon'),
/// )
///
/// // Notification bell with unread count
/// EdenStatusDotOverlay(
///   kind: EdenStatusDotKind.unread,
///   count: state.unreadCount,
///   alignment: Alignment.topRight,
///   child: IconButton(icon: Icon(Icons.notifications), onPressed: _open),
/// )
/// ```
class EdenStatusDotOverlay extends StatelessWidget {
  const EdenStatusDotOverlay({
    super.key,
    required this.child,
    this.kind = EdenStatusDotKind.online,
    this.count,
    this.color,
    this.alignment = Alignment.bottomRight,
    this.size,
  });

  final Widget child;
  final EdenStatusDotKind kind;
  final int? count;
  final Color? color;
  final AlignmentGeometry alignment;
  final double? size;

  bool get _showCount =>
      kind == EdenStatusDotKind.unread && count != null && count! > 0;

  String _badgeText() => count! > 99 ? '99+' : count.toString();

  Color _resolveColor(BuildContext context) {
    if (color != null) return color!;
    // TODO: read obj-009 EdenStatusPalette ThemeExtension when shipped.
    switch (kind) {
      case EdenStatusDotKind.online:
        return EdenColors.success;
      case EdenStatusDotKind.offline:
        return EdenColors.neutral[400]!;
      case EdenStatusDotKind.away:
        return EdenColors.warning;
      case EdenStatusDotKind.busy:
        return EdenColors.error;
      case EdenStatusDotKind.sync:
        return EdenColors.info;
      case EdenStatusDotKind.unread:
        return Theme.of(context).colorScheme.primary;
    }
  }

  double _resolveSize() {
    if (size != null) return size!;
    if (_showCount) {
      return count! > 9 ? 18.0 : 16.0;
    }
    return 12.0;
  }

  ({double? top, double? right, double? bottom, double? left}) _resolvePosition() {
    if (alignment == Alignment.bottomRight) {
      return (top: null, right: -2.0, bottom: -2.0, left: null);
    }
    if (alignment == Alignment.bottomLeft) {
      return (top: null, right: null, bottom: -2.0, left: -2.0);
    }
    if (alignment == Alignment.topRight) {
      return (top: -2.0, right: -2.0, bottom: null, left: null);
    }
    if (alignment == Alignment.topLeft) {
      return (top: -2.0, right: null, bottom: null, left: -2.0);
    }
    return (top: null, right: -2.0, bottom: -2.0, left: null);
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = _resolveSize();
    final dotColor = _resolveColor(context);
    final pos = _resolvePosition();
    final surface = Theme.of(context).colorScheme.surface;

    final overlay = _showCount
        ? Container(
            constraints: BoxConstraints(minWidth: dotSize, minHeight: dotSize),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(dotSize / 2),
              border: Border.all(color: surface, width: 1.5),
            ),
            child: Center(
              child: Text(
                _badgeText(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        : Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: surface, width: 1.5),
            ),
          );

    final semanticsLabel = _showCount ? '${_badgeText()} unread' : kind.name;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: pos.top,
          right: pos.right,
          bottom: pos.bottom,
          left: pos.left,
          child: IgnorePointer(
            child: Semantics(label: semanticsLabel, child: overlay),
          ),
        ),
      ],
    );
  }
}

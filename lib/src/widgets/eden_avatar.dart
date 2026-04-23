import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Avatar size presets.
enum EdenAvatarSize { xs, sm, md, lg, xl }

/// Status indicator for [EdenAvatar].
enum EdenAvatarStatus { online, offline, busy, away }

/// Mirrors the eden_avatar Rails component.
///
/// Supports image, initials fallback, and status indicator.
class EdenAvatar extends StatelessWidget {
  const EdenAvatar({
    super.key,
    this.image,
    this.initials,
    this.size = EdenAvatarSize.md,
    this.status,
    this.backgroundColor,
  });

  final ImageProvider? image;
  final String? initials;
  final EdenAvatarSize size;
  final EdenAvatarStatus? status;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizing = _resolveSizing();

    Widget avatar;
    if (image != null) {
      avatar = CircleAvatar(
        radius: sizing.radius,
        backgroundImage: image,
      );
    } else {
      avatar = CircleAvatar(
        radius: sizing.radius,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          (initials ?? '?').substring(0, initials != null && initials!.length >= 2 ? 2 : (initials?.length ?? 1)),
          style: TextStyle(
            fontSize: sizing.fontSize,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (status == null) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: sizing.statusSize,
            height: sizing.statusSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(),
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor() {
    switch (status!) {
      case EdenAvatarStatus.online:
        return EdenColors.success;
      case EdenAvatarStatus.offline:
        return EdenColors.neutral[400]!;
      case EdenAvatarStatus.busy:
        return EdenColors.error;
      case EdenAvatarStatus.away:
        return EdenColors.warning;
    }
  }

  _AvatarSizing _resolveSizing() {
    switch (size) {
      case EdenAvatarSize.xs:
        return const _AvatarSizing(12, 10, 8);
      case EdenAvatarSize.sm:
        return const _AvatarSizing(16, 11, 10);
      case EdenAvatarSize.md:
        return const _AvatarSizing(20, 13, 12);
      case EdenAvatarSize.lg:
        return const _AvatarSizing(24, 15, 14);
      case EdenAvatarSize.xl:
        return const _AvatarSizing(32, 18, 16);
    }
  }
}

class _AvatarSizing {
  const _AvatarSizing(this.radius, this.fontSize, this.statusSize);
  final double radius;
  final double fontSize;
  final double statusSize;
}

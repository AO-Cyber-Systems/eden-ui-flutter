import 'package:flutter/material.dart';

/// A circular avatar with a camera icon overlay for photo upload.
///
/// The consumer handles file picking via [onTap]; this widget only
/// provides the visual UI.
class EdenAvatarUpload extends StatelessWidget {
  const EdenAvatarUpload({
    super.key,
    this.currentImage,
    this.currentUrl,
    this.initials,
    this.onTap,
    this.radius = 48,
    this.badgeSize = 28,
    this.enabled = true,
  });

  /// Current avatar image provider (e.g., from file or memory).
  final ImageProvider? currentImage;

  /// Current avatar URL (used when [currentImage] is null).
  final String? currentUrl;

  /// Initials fallback when no image is available.
  final String? initials;

  /// Called when the avatar or camera badge is tapped.
  final VoidCallback? onTap;

  /// Radius of the avatar circle.
  final double radius;

  /// Size of the camera badge.
  final double badgeSize;

  /// Whether the upload action is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayInitials = (initials ?? '?')
        .substring(0, initials != null && initials!.length >= 2 ? 2 : (initials?.length ?? 1))
        .toUpperCase();

    ImageProvider? imageProvider = currentImage;
    if (imageProvider == null && currentUrl != null && currentUrl!.isNotEmpty) {
      imageProvider = NetworkImage(currentUrl!);
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Stack(
        children: [
          // Avatar
          imageProvider != null
              ? CircleAvatar(
                  radius: radius,
                  backgroundImage: imageProvider,
                )
              : CircleAvatar(
                  radius: radius,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    displayInitials,
                    style: TextStyle(
                      fontSize: radius * 0.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
          // Camera badge
          if (enabled)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: badgeSize * 0.5,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

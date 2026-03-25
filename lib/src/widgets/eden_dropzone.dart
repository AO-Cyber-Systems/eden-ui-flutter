import 'package:flutter/material.dart';

/// Drag-and-drop file upload area.
///
/// Renders a dashed-border drop zone with icon and label. Since Flutter
/// doesn't have native drag-and-drop for files on mobile, this serves
/// as a tap-to-upload area with visual affordance. On web/desktop,
/// consumers can wrap this with a platform drag-drop handler.
///
/// ```dart
/// EdenDropzone(
///   label: 'Drop files here or tap to browse',
///   subLabel: 'PDF, PNG, JPG up to 10MB',
///   onTap: () => pickFiles(),
///   icon: Icons.cloud_upload_outlined,
/// )
/// ```
class EdenDropzone extends StatelessWidget {
  const EdenDropzone({
    super.key,
    this.onTap,
    this.label = 'Drop files here or tap to browse',
    this.subLabel,
    this.icon = Icons.cloud_upload_outlined,
    this.height = 160,
    this.enabled = true,
    this.isHighlighted = false,
  });

  final VoidCallback? onTap;
  final String label;
  final String? subLabel;
  final IconData icon;
  final double height;
  final bool enabled;

  /// Set true when a file is being dragged over the zone (web/desktop).
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isHighlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final bgColor = isHighlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.05)
        : theme.colorScheme.surfaceContainerLowest;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2 : 1,
            // Dashed border simulated via DashDecoration — using solid for now
            // as Flutter doesn't have a native dashed border.
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                subLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

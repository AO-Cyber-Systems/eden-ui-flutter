import 'package:flutter/material.dart';

/// A compact inline error banner for use inside content panes (chat
/// streams, list views, form footers).
///
/// Renders a rounded, error-tinted container with an icon, message, and
/// optional dismiss handle. Designed for the "transient feedback inside
/// a workflow" slot where a SnackBar is too disruptive — e.g. below a
/// message list and above the chat input bar.
///
/// Typically cleared when the user retries the failing action
/// successfully.
class EdenInlineErrorBanner extends StatelessWidget {
  const EdenInlineErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.warning_amber_rounded,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 12,
  });

  /// Message body shown to the user. Wraps as needed.
  final String message;

  /// Optional dismiss callback. When null, the close icon is hidden.
  final VoidCallback? onDismiss;

  /// Leading icon. Defaults to `Icons.warning_amber_rounded`.
  final IconData icon;

  /// Outer padding around the banner card.
  final EdgeInsets padding;

  /// Inner padding inside the banner card.
  final EdgeInsets contentPadding;

  /// Banner corner radius. Defaults to 12.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        padding: contentPadding,
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 16, color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

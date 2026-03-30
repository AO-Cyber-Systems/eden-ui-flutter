import 'package:flutter/material.dart';

/// Status banner variants.
enum EdenStatusBannerVariant { info, success, warning, danger, maintenance }

/// Full-width status/announcement banner.
///
/// Displayed at the top of a page or app to communicate system status,
/// maintenance notices, or important announcements. Supports dismiss.
///
/// ```dart
/// EdenStatusBanner(
///   message: 'System maintenance scheduled for tonight 10pm-2am.',
///   variant: EdenStatusBannerVariant.maintenance,
///   onDismiss: () => setState(() => showBanner = false),
/// )
/// ```
class EdenStatusBanner extends StatelessWidget {
  const EdenStatusBanner({
    super.key,
    required this.message,
    this.variant = EdenStatusBannerVariant.info,
    this.onDismiss,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String message;
  final EdenStatusBannerVariant variant;
  final VoidCallback? onDismiss;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolveColors(theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colors.background,
      child: Row(
        children: [
          Icon(icon ?? colors.defaultIcon, size: 20, color: colors.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null && actionLabel != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(
                foregroundColor: colors.foreground,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(actionLabel!),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 18, color: colors.foreground),
            ),
          ],
        ],
      ),
    );
  }

  _BannerColors _resolveColors(ThemeData theme) {
    switch (variant) {
      case EdenStatusBannerVariant.info:
        return _BannerColors(
          Colors.blue.shade50,
          Colors.blue.shade800,
          Icons.info_outline,
        );
      case EdenStatusBannerVariant.success:
        return _BannerColors(
          Colors.green.shade50,
          Colors.green.shade800,
          Icons.check_circle_outline,
        );
      case EdenStatusBannerVariant.warning:
        return _BannerColors(
          Colors.orange.shade50,
          Colors.orange.shade900,
          Icons.warning_amber_outlined,
        );
      case EdenStatusBannerVariant.danger:
        return _BannerColors(
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          Icons.error_outline,
        );
      case EdenStatusBannerVariant.maintenance:
        return _BannerColors(
          Colors.amber.shade50,
          Colors.amber.shade900,
          Icons.build_outlined,
        );
    }
  }
}

class _BannerColors {
  const _BannerColors(this.background, this.foreground, this.defaultIcon);
  final Color background;
  final Color foreground;
  final IconData defaultIcon;
}

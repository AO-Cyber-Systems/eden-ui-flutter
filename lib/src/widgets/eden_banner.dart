import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Banner variant types.
enum EdenBannerVariant { info, success, warning, danger }

/// Mirrors the eden_banner Rails component.
///
/// A full-width dismissible banner, typically shown at the top of a page.
class EdenBanner extends StatelessWidget {
  const EdenBanner({
    super.key,
    required this.message,
    this.variant = EdenBannerVariant.info,
    this.dismissible = true,
    this.onDismiss,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final EdenBannerVariant variant;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      color: colors.background,
      child: Row(
        children: [
          Icon(_resolveIcon(), size: 18, color: colors.foreground),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.foreground,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            action!,
          ] else if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          if (dismissible) ...[
            const SizedBox(width: EdenSpacing.space2),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 18, color: colors.foreground),
            ),
          ],
        ],
      ),
    );
  }

  IconData _resolveIcon() {
    switch (variant) {
      case EdenBannerVariant.info:
        return Icons.info_outline;
      case EdenBannerVariant.success:
        return Icons.check_circle_outline;
      case EdenBannerVariant.warning:
        return Icons.warning_amber_rounded;
      case EdenBannerVariant.danger:
        return Icons.error_outline;
    }
  }

  _BannerColors _resolveColors() {
    switch (variant) {
      case EdenBannerVariant.info:
        return _BannerColors(EdenColors.info, Colors.white);
      case EdenBannerVariant.success:
        return _BannerColors(EdenColors.success, Colors.white);
      case EdenBannerVariant.warning:
        return _BannerColors(EdenColors.warning, Colors.white);
      case EdenBannerVariant.danger:
        return _BannerColors(EdenColors.error, Colors.white);
    }
  }
}

class _BannerColors {
  const _BannerColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

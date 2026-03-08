import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Alert variant types.
enum EdenAlertVariant { info, success, warning, danger }

/// Mirrors the eden_alert Rails component.
class EdenAlert extends StatelessWidget {
  const EdenAlert({
    super.key,
    required this.message,
    this.title,
    this.variant = EdenAlertVariant.info,
    this.dismissible = false,
    this.onDismiss,
    this.icon,
  });

  final String message;
  final String? title;
  final EdenAlertVariant variant;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolveColors();
    final resolvedIcon = icon ?? _defaultIcon();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(resolvedIcon, size: 20, color: colors.foreground),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(title!, style: theme.textTheme.labelLarge?.copyWith(color: colors.foreground)),
                  ),
                Text(message, style: theme.textTheme.bodySmall?.copyWith(color: colors.foreground)),
              ],
            ),
          ),
          if (dismissible)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 18, color: colors.foreground),
              ),
            ),
        ],
      ),
    );
  }

  IconData _defaultIcon() {
    switch (variant) {
      case EdenAlertVariant.info:
        return Icons.info_outline;
      case EdenAlertVariant.success:
        return Icons.check_circle_outline;
      case EdenAlertVariant.warning:
        return Icons.warning_amber_rounded;
      case EdenAlertVariant.danger:
        return Icons.error_outline;
    }
  }

  _AlertColors _resolveColors() {
    switch (variant) {
      case EdenAlertVariant.info:
        return _AlertColors(EdenColors.infoBg, EdenColors.info.withValues(alpha: 0.2), EdenColors.info);
      case EdenAlertVariant.success:
        return _AlertColors(EdenColors.successBg, EdenColors.success.withValues(alpha: 0.2), EdenColors.success);
      case EdenAlertVariant.warning:
        return _AlertColors(EdenColors.warningBg, EdenColors.warning.withValues(alpha: 0.2), EdenColors.warning);
      case EdenAlertVariant.danger:
        return _AlertColors(EdenColors.errorBg, EdenColors.error.withValues(alpha: 0.2), EdenColors.error);
    }
  }
}

class _AlertColors {
  const _AlertColors(this.background, this.border, this.foreground);
  final Color background;
  final Color border;
  final Color foreground;
}

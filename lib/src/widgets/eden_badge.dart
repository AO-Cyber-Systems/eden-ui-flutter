import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Badge variant colors.
enum EdenBadgeVariant { primary, success, warning, danger, info, neutral }

/// Badge size presets.
enum EdenBadgeSize { sm, md, lg }

/// Mirrors the eden_badge Rails component.
class EdenBadge extends StatelessWidget {
  const EdenBadge({
    super.key,
    required this.label,
    this.variant = EdenBadgeVariant.primary,
    this.size = EdenBadgeSize.md,
    this.icon,
    this.onDismiss,
  });

  final String label;
  final EdenBadgeVariant variant;
  final EdenBadgeSize size;
  final IconData? icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolveColors(theme);
    final sizing = _resolveSizing();

    return Container(
      padding: sizing.padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: sizing.iconSize, color: colors.foreground),
            SizedBox(width: sizing.gap),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: sizing.fontSize,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: sizing.gap),
            Semantics(
              label: 'Remove $label',
              button: true,
              child: GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: sizing.iconSize, color: colors.foreground),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BadgeColors _resolveColors(ThemeData theme) {
    switch (variant) {
      case EdenBadgeVariant.primary:
        return _BadgeColors(
          theme.colorScheme.primary.withValues(alpha: 0.1),
          theme.colorScheme.primary.withValues(alpha: 0.2),
          theme.colorScheme.primary,
        );
      case EdenBadgeVariant.success:
        return _BadgeColors(EdenColors.successBg, EdenColors.success.withValues(alpha: 0.2), EdenColors.success);
      case EdenBadgeVariant.warning:
        return _BadgeColors(EdenColors.warningBg, EdenColors.warning.withValues(alpha: 0.2), EdenColors.warning);
      case EdenBadgeVariant.danger:
        return _BadgeColors(EdenColors.errorBg, EdenColors.error.withValues(alpha: 0.2), EdenColors.error);
      case EdenBadgeVariant.info:
        return _BadgeColors(EdenColors.infoBg, EdenColors.info.withValues(alpha: 0.2), EdenColors.info);
      case EdenBadgeVariant.neutral:
        final isDark = theme.brightness == Brightness.dark;
        return _BadgeColors(
          isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!,
          isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!,
        );
    }
  }

  _BadgeSizing _resolveSizing() {
    switch (size) {
      case EdenBadgeSize.sm:
        return _BadgeSizing(const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 11, 12, 4);
      case EdenBadgeSize.md:
        return _BadgeSizing(const EdgeInsets.symmetric(horizontal: 10, vertical: 3), 12, 14, 4);
      case EdenBadgeSize.lg:
        return _BadgeSizing(const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 13, 16, 6);
    }
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.border, this.foreground);
  final Color background;
  final Color border;
  final Color foreground;
}

class _BadgeSizing {
  const _BadgeSizing(this.padding, this.fontSize, this.iconSize, this.gap);
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double gap;
}

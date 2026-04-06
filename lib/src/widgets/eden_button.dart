import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Variant styles matching eden_button in the Rails component.
enum EdenButtonVariant { primary, secondary, danger, success, warning, ghost, dark }

/// Size presets for [EdenButton].
enum EdenButtonSize { xs, sm, md, lg, xl }

/// A button that mirrors the eden_button Rails component.
///
/// Supports solid + outline styles, pill shape, icon prefix/suffix, and loading state.
class EdenButton extends StatelessWidget {
  const EdenButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = EdenButtonVariant.primary,
    this.size = EdenButtonSize.md,
    this.outline = false,
    this.pill = false,
    this.disabled = false,
    this.loading = false,
    this.icon,
    this.trailingIcon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EdenButtonVariant variant;
  final EdenButtonSize size;
  final bool outline;
  final bool pill;
  final bool disabled;
  final bool loading;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _resolveColors(theme, isDark);
    final sizing = _resolveSizing();

    final borderRadius = pill ? EdenRadii.borderRadiusFull : EdenRadii.borderRadiusLg;

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: sizing.iconSize,
            height: sizing.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outline ? colors.foreground : colors.onForeground,
            ),
          ),
          SizedBox(width: sizing.gap),
        ] else if (icon != null) ...[
          Icon(icon, size: sizing.iconSize),
          SizedBox(width: sizing.gap),
        ],
        Text(label),
        if (trailingIcon != null) ...[
          SizedBox(width: sizing.gap),
          Icon(trailingIcon, size: sizing.iconSize),
        ],
      ],
    );

    if (outline) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: (disabled || loading) ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.foreground,
            side: BorderSide(color: disabled ? colors.foreground.withValues(alpha: 0.3) : colors.foreground),
            padding: sizing.padding,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            textStyle: sizing.textStyle,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (disabled || loading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.foreground,
          foregroundColor: colors.onForeground,
          disabledBackgroundColor: colors.foreground.withValues(alpha: 0.5),
          disabledForegroundColor: colors.onForeground.withValues(alpha: 0.5),
          elevation: 0,
          padding: sizing.padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: sizing.textStyle,
        ),
        child: child,
      ),
    );
  }

  _ButtonColors _resolveColors(ThemeData theme, bool isDark) {
    switch (variant) {
      case EdenButtonVariant.primary:
        return _ButtonColors(theme.colorScheme.primary, Colors.white);
      case EdenButtonVariant.secondary:
        return _ButtonColors(
          isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          isDark ? EdenColors.neutral[100]! : EdenColors.neutral[800]!,
        );
      case EdenButtonVariant.danger:
        return _ButtonColors(EdenColors.error, Colors.white);
      case EdenButtonVariant.success:
        return _ButtonColors(EdenColors.success, Colors.white);
      case EdenButtonVariant.warning:
        return _ButtonColors(EdenColors.warning, Colors.white);
      case EdenButtonVariant.ghost:
        return _ButtonColors(
          isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!,
          isDark ? EdenColors.neutral[200]! : EdenColors.neutral[700]!,
        );
      case EdenButtonVariant.dark:
        return _ButtonColors(
          isDark ? EdenColors.neutral[100]! : EdenColors.neutral[900]!,
          isDark ? EdenColors.neutral[900]! : Colors.white,
        );
    }
  }

  _ButtonSizing _resolveSizing() {
    switch (size) {
      case EdenButtonSize.xs:
        return _ButtonSizing(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          14, 4,
        );
      case EdenButtonSize.sm:
        return _ButtonSizing(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          16, 6,
        );
      case EdenButtonSize.md:
        return _ButtonSizing(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          18, 8,
        );
      case EdenButtonSize.lg:
        return _ButtonSizing(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          20, 8,
        );
      case EdenButtonSize.xl:
        return _ButtonSizing(
          const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          22, 10,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors(this.foreground, this.onForeground);
  final Color foreground;
  final Color onForeground;
}

class _ButtonSizing {
  const _ButtonSizing(this.padding, this.textStyle, this.iconSize, this.gap);
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double iconSize;
  final double gap;
}

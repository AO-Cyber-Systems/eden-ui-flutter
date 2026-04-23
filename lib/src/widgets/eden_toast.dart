import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Toast variant types.
enum EdenToastVariant { success, error, warning, info }

/// Mirrors the eden_toast Rails component.
///
/// Use [EdenToast.show] to display a toast via [ScaffoldMessenger].
class EdenToast {
  EdenToast._();

  static void show(
    BuildContext context, {
    required String message,
    EdenToastVariant variant = EdenToastVariant.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = _resolveColors(variant);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_resolveIcon(variant), size: 18, color: colors.foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: colors.background,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
        margin: const EdgeInsets.all(EdenSpacing.space4),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: colors.foreground,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static _ToastColors _resolveColors(EdenToastVariant variant) {
    switch (variant) {
      case EdenToastVariant.success:
        return const _ToastColors(Color(0xFF065F46), EdenColors.success);
      case EdenToastVariant.error:
        return const _ToastColors(Color(0xFF7F1D1D), EdenColors.error);
      case EdenToastVariant.warning:
        return const _ToastColors(Color(0xFF78350F), EdenColors.warning);
      case EdenToastVariant.info:
        return const _ToastColors(Color(0xFF1E3A8A), EdenColors.info);
    }
  }

  static IconData _resolveIcon(EdenToastVariant variant) {
    switch (variant) {
      case EdenToastVariant.success:
        return Icons.check_circle;
      case EdenToastVariant.error:
        return Icons.error;
      case EdenToastVariant.warning:
        return Icons.warning_amber_rounded;
      case EdenToastVariant.info:
        return Icons.info;
    }
  }
}

class _ToastColors {
  const _ToastColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

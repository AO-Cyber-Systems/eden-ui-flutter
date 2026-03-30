import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Confirmation dialog for destructive actions.
class EdenConfirmDialog {
  EdenConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _EdenConfirmDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }
}

class _EdenConfirmDialogContent extends StatelessWidget {
  const _EdenConfirmDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIcon =
        icon ?? (isDestructive ? Icons.warning_amber_rounded : null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (effectiveIcon != null) ...[
                    Icon(
                      effectiveIcon,
                      size: 22,
                      color:
                          isDestructive ? EdenColors.error : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: EdenSpacing.space3),
                  ],
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: EdenSpacing.space4),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[600],
                ),
              ),
              const SizedBox(height: EdenSpacing.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? EdenColors.neutral[300]
                          : EdenColors.neutral[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space5,
                        vertical: EdenSpacing.space3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: EdenRadii.borderRadiusLg,
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: EdenSpacing.space2),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? EdenColors.error
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space5,
                        vertical: EdenSpacing.space3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: EdenRadii.borderRadiusLg,
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

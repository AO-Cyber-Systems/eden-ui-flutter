import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../tokens/colors.dart';

/// A confirmation dialog for destructive delete actions.
///
/// Shows a warning with the entity name and red delete button.
class EdenDeleteConfirm extends StatelessWidget {
  const EdenDeleteConfirm({
    super.key,
    required this.entityName,
    required this.onConfirm,
    this.onCancel,
    this.title = 'Delete Confirmation',
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.loading = false,
  });

  /// The name of the entity being deleted (shown in warning text).
  final String entityName;

  /// Called when the delete button is tapped.
  final VoidCallback onConfirm;

  /// Called when cancel is tapped. If null, pops the dialog.
  final VoidCallback? onCancel;

  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final bool loading;

  /// Shows the delete confirmation as a dialog.
  static Future<bool?> show(
    BuildContext context, {
    required String entityName,
    String? title,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => EdenDeleteConfirm(
        entityName: entityName,
        title: title ?? 'Delete Confirmation',
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EdenColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: EdenColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(height: EdenSpacing.space4),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: EdenSpacing.space2),
              Text(
                'Are you sure you want to delete "$entityName"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: EdenSpacing.space6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : onCancel ?? () => Navigator.of(context).pop(),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: EdenSpacing.space3),
                  Expanded(
                    child: FilledButton(
                      onPressed: loading ? null : onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: EdenColors.error,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(confirmLabel),
                    ),
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

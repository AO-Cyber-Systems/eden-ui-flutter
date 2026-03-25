import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../tokens/colors.dart';

/// A generic create/edit/delete modal wrapping EdenModal conventions.
///
/// Provides a title, form content slot, and save/cancel/delete buttons.
class EdenCrudModal extends StatelessWidget {
  const EdenCrudModal({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.onDelete,
    this.isEdit = false,
    this.saveLabel = 'Save',
    this.deleteLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.loading = false,
  });

  /// Modal title (e.g., "Create Customer" or "Edit Customer").
  final String title;

  /// Form content to display in the modal body.
  final Widget child;

  /// Called when the save button is tapped.
  final VoidCallback onSave;

  /// Called when the delete button is tapped. Only shown when [isEdit] is true.
  final VoidCallback? onDelete;

  /// Whether this is an edit (vs create) modal. Controls delete button visibility.
  final bool isEdit;

  final String saveLabel;
  final String deleteLabel;
  final String cancelLabel;
  final bool loading;

  /// Shows the CRUD modal as a dialog.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    required VoidCallback onSave,
    VoidCallback? onDelete,
    bool isEdit = false,
    bool loading = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: !loading,
      builder: (_) => EdenCrudModal(
        title: title,
        onSave: onSave,
        onDelete: onDelete,
        isEdit: isEdit,
        loading: loading,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  GestureDetector(
                    onTap: loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EdenSpacing.space4),
              // Body
              child,
              const SizedBox(height: EdenSpacing.space6),
              // Actions
              Row(
                children: [
                  if (isEdit && onDelete != null)
                    TextButton(
                      onPressed: loading ? null : onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: EdenColors.error,
                      ),
                      child: Text(deleteLabel),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: loading ? null : onSave,
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(saveLabel),
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

import 'package:flutter/material.dart';

/// Floating action bar shown when items are selected for bulk operations.
///
/// Displays at the bottom of the screen with selected count, action buttons,
/// and a clear selection button.
///
/// ```dart
/// if (selectedIds.isNotEmpty)
///   EdenBulkActionBar(
///     selectedCount: selectedIds.length,
///     onClear: () => setState(() => selectedIds.clear()),
///     actions: [
///       EdenButton(label: 'Delete', variant: EdenButtonVariant.danger, onPressed: bulkDelete),
///       EdenButton(label: 'Archive', onPressed: bulkArchive),
///     ],
///   )
/// ```
class EdenBulkActionBar extends StatelessWidget {
  const EdenBulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.actions,
    this.label,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final List<Widget> actions;

  /// Custom label. Defaults to "{count} selected".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selection count
          GestureDetector(
            onTap: onClear,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label ?? '$selectedCount selected',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Actions
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            actions[i],
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_sync_indicator.dart';

class SyncQueueItem extends StatelessWidget {
  const SyncQueueItem({
    required this.operation,
    required this.isDark,
    required this.theme,
    this.onRetry,
  });

  final EdenSyncOperation operation;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (operation.errorMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    operation.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EdenColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (operation.status == EdenSyncOperationStatus.failed &&
              onRetry != null)
            Semantics(
              button: true,
              label: 'Retry ${operation.label}',
              child: GestureDetector(
                onTap: onRetry,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: EdenColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (operation.status) {
      case EdenSyncOperationStatus.pending:
        return Icon(
          Icons.schedule,
          size: 16,
          color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
        );
      case EdenSyncOperationStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(EdenColors.info),
          ),
        );
      case EdenSyncOperationStatus.completed:
        return const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: EdenColors.success,
        );
      case EdenSyncOperationStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 16,
          color: EdenColors.error,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// EdenStaleDataWarning
// ---------------------------------------------------------------------------

/// A banner warning the user that the displayed data may be stale.

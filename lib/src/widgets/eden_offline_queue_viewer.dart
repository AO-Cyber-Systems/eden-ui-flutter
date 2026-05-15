import 'package:flutter/material.dart';

import 'eden_badge.dart';
import 'eden_confirm_dialog.dart';
import 'eden_empty_state.dart';

/// Lifecycle status of a queued offline mutation.
enum EdenOfflineQueueItemStatus { pending, syncing, conflict, error }

/// One queued offline mutation row in an [EdenOfflineQueueViewer].
///
/// Library-level value type — does NOT carry transport / persistence
/// concerns. Caller owns the queue store (sqflite, hive, IndexedDB,
/// whatever) and translates its rows into this shape for display.
@immutable
class EdenOfflineQueueItem {
  /// Creates an offline queue item value object.
  const EdenOfflineQueueItem({
    required this.id,
    required this.actionType,
    required this.summary,
    required this.queuedAt,
    this.status = EdenOfflineQueueItemStatus.pending,
    this.payloadPreview,
    this.errorMessage,
    this.conflictDescription,
  });

  /// Stable identifier for this queued operation.
  final String id;

  /// Short action name, e.g. "Update Customer" or "Create Work Order".
  final String actionType;

  /// Human-readable one-line description of what's being mutated.
  final String summary;

  /// Wall-clock time the item was queued.
  final DateTime queuedAt;

  /// Lifecycle status — drives the status pill color/icon.
  final EdenOfflineQueueItemStatus status;

  /// Optional short JSON-ish payload preview for diagnostics.
  final String? payloadPreview;

  /// Populated when [status] is [EdenOfflineQueueItemStatus.error].
  final String? errorMessage;

  /// Populated when [status] is [EdenOfflineQueueItemStatus.conflict].
  final String? conflictDescription;
}

/// A list viewer for queued offline mutations.
///
/// Library-level concern: surface UI for queue items + expose retry,
/// discard, and resolve-conflict callbacks. The library does NOT own
/// persistence or replay — the caller does.
///
/// Used by trades field-crew app, medical home-visit nurses, fuel-truck
/// drivers, salon mobile services, any companion app with intermittent
/// connectivity.
class EdenOfflineQueueViewer extends StatelessWidget {
  /// Creates an offline-queue viewer.
  const EdenOfflineQueueViewer({
    super.key,
    required this.items,
    this.onRetry,
    this.onDiscard,
    this.onResolveConflict,
    this.now,
    this.emptyStateMessage = 'No pending changes',
  });

  /// The queued items to display.
  final List<EdenOfflineQueueItem> items;

  /// Invoked when the user taps Retry on a failed / error item.
  final ValueChanged<EdenOfflineQueueItem>? onRetry;

  /// Invoked when the user taps Discard (after confirm).
  final ValueChanged<EdenOfflineQueueItem>? onDiscard;

  /// Invoked when the user taps Resolve on a conflict item.
  final ValueChanged<EdenOfflineQueueItem>? onResolveConflict;

  /// Injectable clock — tests pass a frozen value so relative-time strings
  /// are deterministic; production callers omit this and the widget uses
  /// [DateTime.now].
  final DateTime? now;

  /// Text shown when [items] is empty.
  final String emptyStateMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EdenEmptyState(
        key: const ValueKey<String>('offline_queue_empty'),
        title: emptyStateMessage,
        icon: Icons.check_circle_outline,
      );
    }
    final clock = now ?? DateTime.now();
    return ListView.builder(
      key: const ValueKey<String>('offline_queue_list'),
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _QueueRow(
          key: ValueKey<String>('queue_row_${item.id}'),
          item: item,
          now: clock,
          onRetry: onRetry,
          onDiscard: onDiscard,
          onResolveConflict: onResolveConflict,
        );
      },
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    super.key,
    required this.item,
    required this.now,
    required this.onRetry,
    required this.onDiscard,
    required this.onResolveConflict,
  });

  final EdenOfflineQueueItem item;
  final DateTime now;
  final ValueChanged<EdenOfflineQueueItem>? onRetry;
  final ValueChanged<EdenOfflineQueueItem>? onDiscard;
  final ValueChanged<EdenOfflineQueueItem>? onResolveConflict;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_iconForAction(item.actionType),
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.actionType,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(status: item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (item.payloadPreview != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _truncate(item.payloadPreview!, 80),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(
                  _formatRelative(item.queuedAt, now),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (item.status == EdenOfflineQueueItemStatus.conflict &&
                    onResolveConflict != null)
                  TextButton(
                    key: ValueKey<String>('resolve_${item.id}'),
                    onPressed: () => onResolveConflict!(item),
                    child: const Text('Resolve'),
                  ),
                if ((item.status == EdenOfflineQueueItemStatus.error ||
                        item.status == EdenOfflineQueueItemStatus.pending) &&
                    onRetry != null)
                  TextButton(
                    key: ValueKey<String>('retry_${item.id}'),
                    onPressed: () => onRetry!(item),
                    child: const Text('Retry'),
                  ),
                if (onDiscard != null)
                  TextButton(
                    key: ValueKey<String>('discard_${item.id}'),
                    onPressed: () async {
                      final confirmed = await EdenConfirmDialog.show(
                        context,
                        title: 'Discard change?',
                        message:
                            'Discarding "${item.actionType}" cannot be undone.',
                        confirmLabel: 'Discard',
                        cancelLabel: 'Cancel',
                        isDestructive: true,
                      );
                      if (confirmed) onDiscard!(item);
                    },
                    child: const Text('Discard'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForAction(String action) {
    final l = action.toLowerCase();
    if (l.contains('create')) return Icons.add_circle_outline;
    if (l.contains('update')) return Icons.edit_outlined;
    if (l.contains('delete')) return Icons.delete_outline;
    return Icons.sync;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final EdenOfflineQueueItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, EdenBadgeVariant variant) = switch (status) {
      EdenOfflineQueueItemStatus.pending => ('Pending', EdenBadgeVariant.neutral),
      EdenOfflineQueueItemStatus.syncing => ('Syncing', EdenBadgeVariant.info),
      EdenOfflineQueueItemStatus.conflict =>
        ('Conflict', EdenBadgeVariant.warning),
      EdenOfflineQueueItemStatus.error => ('Error', EdenBadgeVariant.danger),
    };
    return EdenBadge(
      key: ValueKey<String>('status_pill_$label'),
      label: label,
      variant: variant,
      size: EdenBadgeSize.sm,
    );
  }
}

String _truncate(String s, int max) =>
    s.length <= max ? s : '${s.substring(0, max)}…';

String _formatRelative(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds <= 30) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds} sec ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  // Older — render as Jan 5 style.
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[then.month - 1]} ${then.day}';
}

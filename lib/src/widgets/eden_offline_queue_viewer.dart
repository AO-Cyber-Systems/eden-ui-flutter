import 'package:flutter/material.dart';

/// Lifecycle status of a queued offline mutation.
enum EdenOfflineQueueItemStatus { pending, syncing, conflict, error }

/// One queued offline mutation row.
@immutable
class EdenOfflineQueueItem {
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

  final String id;
  final String actionType;
  final String summary;
  final DateTime queuedAt;
  final EdenOfflineQueueItemStatus status;
  final String? payloadPreview;
  final String? errorMessage;
  final String? conflictDescription;
}

/// RED-phase stub for EdenOfflineQueueViewer.
class EdenOfflineQueueViewer extends StatelessWidget {
  const EdenOfflineQueueViewer({
    super.key,
    required this.items,
    this.onRetry,
    this.onDiscard,
    this.onResolveConflict,
    this.now,
    this.emptyStateMessage = 'No pending changes',
  });

  final List<EdenOfflineQueueItem> items;
  final ValueChanged<EdenOfflineQueueItem>? onRetry;
  final ValueChanged<EdenOfflineQueueItem>? onDiscard;
  final ValueChanged<EdenOfflineQueueItem>? onResolveConflict;
  final DateTime? now;
  final String emptyStateMessage;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

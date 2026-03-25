import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'sync_indicator/sync_indicator_details.dart';

// ---------------------------------------------------------------------------
// Enums & models
// ---------------------------------------------------------------------------

/// Sync connection status.
enum EdenSyncStatus {
  /// Device is connected and data is up to date.
  online,

  /// Device has no network connectivity.
  offline,

  /// A sync operation is currently in progress.
  syncing,

  /// The last sync attempt failed.
  error,

  /// There is a data conflict that needs manual resolution.
  conflict,
}

/// Which version to keep when resolving a sync conflict.
enum EdenConflictResolution {
  keepLocal,
  keepServer,
  merge,
}

/// Describes a single field-level conflict between local and server values.
class EdenConflictField {
  const EdenConflictField({
    required this.fieldName,
    required this.localValue,
    required this.serverValue,
  });

  final String fieldName;
  final String localValue;
  final String serverValue;
}

/// Data for a sync conflict card.
class EdenConflictData {
  const EdenConflictData({
    required this.id,
    required this.title,
    this.description,
    required this.fields,
    this.localTimestamp,
    this.serverTimestamp,
  });

  final String id;
  final String title;
  final String? description;
  final List<EdenConflictField> fields;
  final String? localTimestamp;
  final String? serverTimestamp;
}

/// A pending sync operation in the queue.
class EdenSyncOperation {
  const EdenSyncOperation({
    required this.id,
    required this.label,
    this.status = EdenSyncOperationStatus.pending,
    this.errorMessage,
  });

  final String id;
  final String label;
  final EdenSyncOperationStatus status;
  final String? errorMessage;
}

/// Status of an individual sync queue item.
enum EdenSyncOperationStatus {
  pending,
  syncing,
  completed,
  failed,
}

// ---------------------------------------------------------------------------
// EdenSyncStatusBar
// ---------------------------------------------------------------------------

/// A banner bar showing the current sync status with icon, message, and
/// optional retry action. Automatically fades out after a successful sync.
class EdenSyncStatusBar extends StatefulWidget {
  const EdenSyncStatusBar({
    super.key,
    required this.status,
    this.message,
    this.itemsSynced,
    this.totalItems,
    this.onRetry,
    this.onDismiss,
    this.autoDismissOnOnline = true,
    this.autoDismissDuration = const Duration(seconds: 3),
  });

  /// Current sync status.
  final EdenSyncStatus status;

  /// Optional override message. When null a default message is derived from
  /// [status].
  final String? message;

  /// Number of items already synced (shown during [EdenSyncStatus.syncing]).
  final int? itemsSynced;

  /// Total number of items to sync.
  final int? totalItems;

  /// Called when the user taps retry on an error banner.
  final VoidCallback? onRetry;

  /// Called when the banner is dismissed.
  final VoidCallback? onDismiss;

  /// Whether to auto-dismiss the bar when status returns to online.
  final bool autoDismissOnOnline;

  /// How long to wait before auto-dismissing after returning to online.
  final Duration autoDismissDuration;

  @override
  State<EdenSyncStatusBar> createState() => _EdenSyncStatusBarState();
}

class _EdenSyncStatusBarState extends State<EdenSyncStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..value = 1.0;
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant EdenSyncStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == EdenSyncStatus.online &&
        oldWidget.status != EdenSyncStatus.online &&
        widget.autoDismissOnOnline) {
      _scheduleAutoDismiss();
    }
    if (widget.status != EdenSyncStatus.online) {
      _dismissed = false;
      _fadeController.value = 1.0;
    }
  }

  void _scheduleAutoDismiss() {
    Future.delayed(widget.autoDismissDuration, () {
      if (!mounted) return;
      if (widget.status == EdenSyncStatus.online) {
        _fadeController.reverse().then((_) {
          if (mounted) {
            setState(() => _dismissed = true);
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _defaultMessage() {
    switch (widget.status) {
      case EdenSyncStatus.online:
        return 'All changes synced';
      case EdenSyncStatus.offline:
        return 'You are offline. Changes will sync when reconnected.';
      case EdenSyncStatus.syncing:
        if (widget.itemsSynced != null && widget.totalItems != null) {
          return 'Syncing ${widget.itemsSynced} of ${widget.totalItems}...';
        }
        return 'Syncing...';
      case EdenSyncStatus.error:
        return 'Sync failed. Please try again.';
      case EdenSyncStatus.conflict:
        return 'Sync conflict detected. Review required.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor;
    final Color fgColor;
    final IconData icon;

    switch (widget.status) {
      case EdenSyncStatus.online:
        bgColor = isDark
            ? EdenColors.success.withValues(alpha: 0.12)
            : EdenColors.successBg;
        fgColor = EdenColors.success;
        icon = Icons.cloud_done_outlined;
      case EdenSyncStatus.offline:
        bgColor = isDark
            ? EdenColors.warning.withValues(alpha: 0.12)
            : EdenColors.warningBg;
        fgColor = EdenColors.warning;
        icon = Icons.cloud_off_outlined;
      case EdenSyncStatus.syncing:
        bgColor = isDark
            ? EdenColors.info.withValues(alpha: 0.12)
            : EdenColors.infoBg;
        fgColor = EdenColors.info;
        icon = Icons.sync;
      case EdenSyncStatus.error:
        bgColor = isDark
            ? EdenColors.error.withValues(alpha: 0.12)
            : EdenColors.errorBg;
        fgColor = EdenColors.error;
        icon = Icons.error_outline;
      case EdenSyncStatus.conflict:
        bgColor = isDark
            ? EdenColors.warning.withValues(alpha: 0.12)
            : EdenColors.warningBg;
        fgColor = EdenColors.warning;
        icon = Icons.warning_amber_rounded;
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: EdenRadii.borderRadiusMd,
        ),
        child: Row(
          children: [
            widget.status == EdenSyncStatus.syncing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(fgColor),
                    ),
                  )
                : Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                widget.message ?? _defaultMessage(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ),
            if (widget.status == EdenSyncStatus.error &&
                widget.onRetry != null)
              TextButton(
                onPressed: widget.onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            if (widget.onDismiss != null &&
                widget.status != EdenSyncStatus.syncing)
              GestureDetector(
                onTap: () {
                  setState(() => _dismissed = true);
                  widget.onDismiss?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: EdenSpacing.space2),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: fgColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EdenSyncProgressIndicator
// ---------------------------------------------------------------------------

/// A progress indicator showing sync completion state.
class EdenSyncProgressIndicator extends StatelessWidget {
  const EdenSyncProgressIndicator({
    super.key,
    required this.itemsSynced,
    required this.totalItems,
    this.linear = false,
    this.label,
  });

  /// Number of items already synced.
  final int itemsSynced;

  /// Total number of items to sync.
  final int totalItems;

  /// Whether to use a linear bar instead of a circular indicator.
  final bool linear;

  /// Optional label override. Defaults to "X / Y synced".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = totalItems > 0 ? itemsSynced / totalItems : 0.0;
    final displayLabel = label ?? '$itemsSynced / $totalItems synced';

    if (linear) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: EdenRadii.borderRadiusFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? EdenColors.neutral[700]
                  : EdenColors.neutral[200],
              valueColor: AlwaysStoppedAnimation(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: EdenSpacing.space1),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? EdenColors.neutral[400]
                  : EdenColors.neutral[500],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: isDark
                    ? EdenColors.neutral[700]
                    : EdenColors.neutral[200],
                valueColor: AlwaysStoppedAnimation(
                  theme.colorScheme.primary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Text(
          displayLabel,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? EdenColors.neutral[300]
                : EdenColors.neutral[600],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// EdenConflictCard
// ---------------------------------------------------------------------------

/// A card showing a sync conflict with local vs server values and resolution
/// buttons.
class EdenConflictCard extends StatelessWidget {
  const EdenConflictCard({
    super.key,
    required this.conflict,
    this.onResolveConflict,
    this.onDismiss,
  });

  /// The conflict data to display.
  final EdenConflictData conflict;

  /// Called when the user picks a resolution.
  final void Function(String conflictId, EdenConflictResolution resolution)?
      onResolveConflict;

  /// Called when the user dismisses the card.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final surfaceColor =
        isDark ? EdenColors.neutral[850] : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: EdenColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            decoration: BoxDecoration(
              color: EdenColors.warning.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(EdenRadii.lg),
                topRight: Radius.circular(EdenRadii.lg),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: EdenColors.warning,
                ),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (conflict.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          conflict.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? EdenColors.neutral[400]
                                : EdenColors.neutral[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark
                          ? EdenColors.neutral[400]
                          : EdenColors.neutral[500],
                    ),
                  ),
              ],
            ),
          ),
          // Field comparison table
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              border: TableBorder.all(color: borderColor, width: 0.5),
              children: [
                // Table header
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark
                        ? EdenColors.neutral[800]
                        : EdenColors.neutral[50],
                  ),
                  children: [
                    _tableHeaderCell('Field', theme),
                    _tableHeaderCell(
                      'Local${conflict.localTimestamp != null ? ' (${conflict.localTimestamp})' : ''}',
                      theme,
                    ),
                    _tableHeaderCell(
                      'Server${conflict.serverTimestamp != null ? ' (${conflict.serverTimestamp})' : ''}',
                      theme,
                    ),
                  ],
                ),
                // Field rows
                for (final field in conflict.fields)
                  TableRow(
                    children: [
                      _tableCell(field.fieldName, theme, bold: true),
                      _tableCell(field.localValue, theme),
                      _tableCell(field.serverValue, theme),
                    ],
                  ),
              ],
            ),
          ),
          // Resolution buttons
          if (onResolveConflict != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EdenSpacing.space3,
                0,
                EdenSpacing.space3,
                EdenSpacing.space3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _resolveButton(
                    context,
                    'Keep Local',
                    Icons.phone_android,
                    EdenConflictResolution.keepLocal,
                  ),
                  const SizedBox(width: EdenSpacing.space2),
                  _resolveButton(
                    context,
                    'Keep Server',
                    Icons.cloud_outlined,
                    EdenConflictResolution.keepServer,
                  ),
                  const SizedBox(width: EdenSpacing.space2),
                  _resolveButton(
                    context,
                    'Merge',
                    Icons.merge_type,
                    EdenConflictResolution.merge,
                    primary: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _tableCell(String text, ThemeData theme, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _resolveButton(
    BuildContext context,
    String label,
    IconData icon,
    EdenConflictResolution resolution, {
    bool primary = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (primary) {
      return FilledButton.icon(
        onPressed: () => onResolveConflict?.call(conflict.id, resolution),
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => onResolveConflict?.call(conflict.id, resolution),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(
          color: isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EdenOfflineBadge
// ---------------------------------------------------------------------------

/// A small chip/badge indicating an item is available offline.
class EdenOfflineBadge extends StatelessWidget {
  const EdenOfflineBadge({
    super.key,
    this.label = 'Offline',
    this.available = true,
  });

  /// Display text.
  final String label;

  /// Whether the item is available offline (green) or not (neutral).
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    final IconData icon;

    if (available) {
      bg = isDark
          ? EdenColors.success.withValues(alpha: 0.12)
          : EdenColors.successBg;
      fg = EdenColors.success;
      icon = Icons.offline_pin_outlined;
    } else {
      bg = isDark
          ? EdenColors.neutral[700]!.withValues(alpha: 0.5)
          : EdenColors.neutral[100]!;
      fg = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
      icon = Icons.cloud_off_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EdenSyncQueue
// ---------------------------------------------------------------------------

/// A list showing pending sync operations and their individual statuses.
class EdenSyncQueue extends StatelessWidget {
  const EdenSyncQueue({
    super.key,
    required this.operations,
    this.onRetry,
  });

  /// The list of sync operations to display.
  final List<EdenSyncOperation> operations;

  /// Called with the operation id when the user retries a failed operation.
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (operations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Center(
          child: Text(
            'No pending operations',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? EdenColors.neutral[400]
                  : EdenColors.neutral[500],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < operations.length; i++) ...[
          SyncQueueItem(
            operation: operations[i],
            isDark: isDark,
            theme: theme,
            onRetry: onRetry != null
                ? () => onRetry!(operations[i].id)
                : null,
          ),
          if (i < operations.length - 1)
            Divider(
              height: 1,
              color: isDark
                  ? EdenColors.neutral[800]
                  : EdenColors.neutral[200],
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// EdenStaleDataWarning
// ---------------------------------------------------------------------------

/// A banner warning the user that the displayed data may be stale.
class EdenStaleDataWarning extends StatelessWidget {
  const EdenStaleDataWarning({
    super.key,
    this.lastSyncTime,
    this.onRefresh,
    this.onDismiss,
  });

  /// Human-readable last sync time (e.g. "15 min ago").
  final String? lastSyncTime;

  /// Called when the user taps refresh.
  final VoidCallback? onRefresh;

  /// Called when the user dismisses.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? EdenColors.warning.withValues(alpha: 0.10)
            : EdenColors.warningBg,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            size: 16,
            color: EdenColors.warning,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              lastSyncTime != null
                  ? 'Data may be stale. Last synced $lastSyncTime.'
                  : 'Data may be stale.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? EdenColors.neutral[300]
                    : EdenColors.neutral[700],
              ),
            ),
          ),
          if (onRefresh != null)
            GestureDetector(
              onTap: onRefresh,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh,
                  size: 16,
                  color: EdenColors.warning,
                ),
              ),
            ),
          if (onDismiss != null) ...[
            const SizedBox(width: EdenSpacing.space1),
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: EdenColors.warning.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

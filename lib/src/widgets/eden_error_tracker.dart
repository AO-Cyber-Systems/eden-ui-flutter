import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The resolution status of a tracked error.
enum EdenTrackedErrorStatus {
  /// Error is unresolved.
  unresolved,

  /// Error has been resolved.
  resolved,

  /// Error has been ignored.
  ignored,
}

/// A model representing a grouped error tracked in an error monitoring system.
class EdenTrackedError {
  /// Creates a tracked error model.
  const EdenTrackedError({
    required this.id,
    required this.errorClass,
    required this.message,
    this.occurrenceCount = 1,
    required this.firstSeen,
    required this.lastSeen,
    this.stackTracePreview,
    this.environment,
    this.status = EdenTrackedErrorStatus.unresolved,
  });

  /// Unique identifier for this error group.
  final String id;

  /// The error class or type name (e.g. "NullPointerException").
  final String errorClass;

  /// The error message.
  final String message;

  /// Number of times this error has occurred.
  final int occurrenceCount;

  /// When this error was first seen.
  final DateTime firstSeen;

  /// When this error was last seen.
  final DateTime lastSeen;

  /// First few lines of the stack trace.
  final String? stackTracePreview;

  /// The environment where the error was captured.
  final String? environment;

  /// The current resolution status.
  final EdenTrackedErrorStatus status;
}

/// A widget displaying a grouped error entry with class name, message,
/// occurrence count, timestamps, stack trace preview, and status controls.
///
/// ```dart
/// EdenErrorTracker(
///   error: EdenTrackedError(
///     id: 'err-1',
///     errorClass: 'TimeoutException',
///     message: 'Connection timed out after 30s',
///     occurrenceCount: 142,
///     firstSeen: DateTime(2026, 3, 1),
///     lastSeen: DateTime.now(),
///     stackTracePreview: 'at HttpClient.send (http_client.dart:42)\nat ApiService.fetch (api.dart:18)',
///     environment: 'production',
///   ),
///   onTap: () {},
///   onResolve: () {},
///   onIgnore: () {},
/// )
/// ```
class EdenErrorTracker extends StatefulWidget {
  /// Creates an Eden error tracker widget.
  const EdenErrorTracker({
    super.key,
    required this.error,
    this.onTap,
    this.onResolve,
    this.onIgnore,
  });

  /// The tracked error data to display.
  final EdenTrackedError error;

  /// Callback when the error entry is tapped.
  final VoidCallback? onTap;

  /// Callback when the resolve action is triggered.
  final VoidCallback? onResolve;

  /// Callback when the ignore action is triggered.
  final VoidCallback? onIgnore;

  @override
  State<EdenErrorTracker> createState() => _EdenErrorTrackerState();
}

class _EdenErrorTrackerState extends State<EdenErrorTracker> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final error = widget.error;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
                    : EdenColors.neutral[50])
                : (isDark ? EdenColors.neutral[900] : Colors.white),
            border: Border.all(
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
            borderRadius: EdenRadii.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: class + count + status
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EdenSpacing.space4,
                  EdenSpacing.space4,
                  EdenSpacing.space4,
                  EdenSpacing.space2,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report_rounded,
                      size: 18,
                      color: error.status == EdenTrackedErrorStatus.unresolved
                          ? EdenColors.error
                          : EdenColors.neutral[400],
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Expanded(
                      child: Text(
                        error.errorClass,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: error.status ==
                                  EdenTrackedErrorStatus.unresolved
                              ? null
                              : EdenColors.neutral[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    _OccurrenceCountBadge(
                      count: error.occurrenceCount,
                      isDark: isDark,
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    _StatusBadge(status: error.status),
                  ],
                ),
              ),

              // Message
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space4,
                ),
                child: Text(
                  error.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Timestamps + environment
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space4,
                  vertical: EdenSpacing.space2,
                ),
                child: Row(
                  children: [
                    _TimestampLabel(
                      label: 'First',
                      dateTime: error.firstSeen,
                    ),
                    const SizedBox(width: EdenSpacing.space4),
                    _TimestampLabel(
                      label: 'Last',
                      dateTime: error.lastSeen,
                    ),
                    if (error.environment != null) ...[
                      const Spacer(),
                      _EnvironmentTag(
                        environment: error.environment!,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),

              // Stack trace preview
              if (error.stackTracePreview != null)
                _StackTracePreview(
                  preview: error.stackTracePreview!,
                  isDark: isDark,
                ),

              // Actions
              if (error.status == EdenTrackedErrorStatus.unresolved)
                _ErrorActions(
                  onResolve: widget.onResolve,
                  onIgnore: widget.onIgnore,
                  isDark: isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OccurrenceCountBadge extends StatelessWidget {
  const _OccurrenceCountBadge({
    required this.count,
    required this.isDark,
  });

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayCount = count >= 10000
        ? '${(count / 1000).toStringAsFixed(1)}k'
        : count >= 1000
            ? '${(count / 1000).toStringAsFixed(1)}k'
            : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: EdenColors.error.withValues(alpha: 0.1),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.repeat_rounded,
            size: 10,
            color: EdenColors.error,
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            displayCount,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: EdenColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final EdenTrackedErrorStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      EdenTrackedErrorStatus.unresolved => (EdenColors.error, 'Unresolved'),
      EdenTrackedErrorStatus.resolved => (EdenColors.success, 'Resolved'),
      EdenTrackedErrorStatus.ignored => (EdenColors.neutral[500]!, 'Ignored'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TimestampLabel extends StatelessWidget {
  const _TimestampLabel({
    required this.label,
    required this.dateTime,
  });

  final String label;
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: EdenColors.neutral[400],
          ),
        ),
        Text(
          _formatRelative(dateTime),
          style: TextStyle(
            fontSize: 10,
            color: EdenColors.neutral[500],
          ),
        ),
      ],
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _EnvironmentTag extends StatelessWidget {
  const _EnvironmentTag({
    required this.environment,
    required this.isDark,
  });

  final String environment;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(
        environment,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: EdenColors.neutral[500],
        ),
      ),
    );
  }
}

class _StackTracePreview extends StatelessWidget {
  const _StackTracePreview({
    required this.preview,
    required this.isDark,
  });

  final String preview;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Show at most 3 lines
    final lines = preview.split('\n').take(3).join('\n');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
      ),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[950] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Text(
        lines,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.5,
          color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[600],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ErrorActions extends StatelessWidget {
  const _ErrorActions({
    this.onResolve,
    this.onIgnore,
    required this.isDark,
  });

  final VoidCallback? onResolve;
  final VoidCallback? onIgnore;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onIgnore != null)
            InkWell(
              onTap: onIgnore,
              borderRadius: EdenRadii.borderRadiusSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 14,
                      color: EdenColors.neutral[500],
                    ),
                    const SizedBox(width: EdenSpacing.space1),
                    Text(
                      'Ignore',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: EdenColors.neutral[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (onResolve != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            InkWell(
              onTap: onResolve,
              borderRadius: EdenRadii.borderRadiusSm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: EdenColors.success.withValues(alpha: 0.1),
                  border: Border.all(
                    color: EdenColors.success.withValues(alpha: 0.3),
                  ),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: EdenColors.success,
                    ),
                    SizedBox(width: EdenSpacing.space1),
                    Text(
                      'Resolve',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: EdenColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

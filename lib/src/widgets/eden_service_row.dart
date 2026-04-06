import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The operational status of a service or process.
enum EdenServiceStatus {
  /// Service is actively running.
  running,

  /// Service is stopped.
  stopped,

  /// Service encountered an error.
  error,

  /// Service has a warning condition.
  warning,
}

/// A row widget displaying a process or service with its current status,
/// version information, and contextual action buttons.
///
/// Designed for use in vertical lists with a bottom border separator.
///
/// ```dart
/// EdenServiceRow(
///   name: 'nginx',
///   description: 'Reverse proxy server',
///   status: EdenServiceStatus.running,
///   version: '1.25.3',
///   onStop: () => stopService('nginx'),
///   onRestart: () => restartService('nginx'),
/// )
/// ```
class EdenServiceRow extends StatelessWidget {
  /// Creates an Eden service row.
  const EdenServiceRow({
    super.key,
    required this.name,
    this.description,
    required this.status,
    this.version,
    this.onStart,
    this.onStop,
    this.onRestart,
    this.loading = false,
  });

  /// The name of the service or process.
  final String name;

  /// An optional description of the service.
  final String? description;

  /// The current operational status of the service.
  final EdenServiceStatus status;

  /// The version string to display as a badge.
  final String? version;

  /// Callback invoked when the start action is triggered.
  ///
  /// Only displayed when [status] is [EdenServiceStatus.stopped].
  final VoidCallback? onStart;

  /// Callback invoked when the stop action is triggered.
  ///
  /// Only displayed when [status] is [EdenServiceStatus.running].
  final VoidCallback? onStop;

  /// Callback invoked when the restart action is triggered.
  ///
  /// Only displayed when [status] is [EdenServiceStatus.running].
  final VoidCallback? onRestart;

  /// Whether the row is in a loading state.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? EdenColors.neutral[800]!
                : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          _StatusDot(status: status),
          SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: EdenSpacing.space1),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: EdenColors.neutral[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (version != null) ...[
            SizedBox(width: EdenSpacing.space2),
            _VersionBadge(version: version!, isDark: isDark),
          ],
          SizedBox(width: EdenSpacing.space3),
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: EdenColors.neutral[400],
              ),
            )
          else
            _ActionButtons(
              status: status,
              onStart: onStart,
              onStop: onStop,
              onRestart: onRestart,
            ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final EdenServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _StatusDotColors.forStatus(status);

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: status == EdenServiceStatus.running
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _StatusDotColors {
  static Color forStatus(EdenServiceStatus status) {
    switch (status) {
      case EdenServiceStatus.running:
        return EdenColors.success;
      case EdenServiceStatus.stopped:
        return EdenColors.neutral[400]!;
      case EdenServiceStatus.error:
        return EdenColors.error;
      case EdenServiceStatus.warning:
        return EdenColors.warning;
    }
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({
    required this.version,
    required this.isDark,
  });

  final String version;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? EdenColors.neutral[800]!
            : EdenColors.neutral[100]!,
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        version,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: EdenColors.neutral[500],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    this.onStart,
    this.onStop,
    this.onRestart,
  });

  final EdenServiceStatus status;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == EdenServiceStatus.stopped && onStart != null)
          _ActionButton(
            icon: Icons.play_arrow_rounded,
            color: EdenColors.success,
            tooltip: 'Start',
            onPressed: onStart!,
          ),
        if (status == EdenServiceStatus.running) ...[
          if (onStop != null)
            _ActionButton(
              icon: Icons.stop_rounded,
              color: EdenColors.error,
              tooltip: 'Stop',
              onPressed: onStop!,
            ),
          if (onRestart != null) ...[
            SizedBox(width: EdenSpacing.space1),
            _ActionButton(
              icon: Icons.refresh_rounded,
              color: EdenColors.warning,
              tooltip: 'Restart',
              onPressed: onRestart!,
            ),
          ],
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: EdenRadii.borderRadiusSm,
          child: Padding(
            padding: EdgeInsets.all(EdenSpacing.space1),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

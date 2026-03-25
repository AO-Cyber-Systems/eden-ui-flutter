import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A row widget displaying a network port listener with its associated
/// process, PID, user, and an optional kill action.
///
/// Port numbers are rendered in a prominent monospace font for quick scanning.
///
/// ```dart
/// EdenPortRow(
///   port: 8080,
///   process: 'node',
///   pid: '12345',
///   user: 'www-data',
///   onKill: () => killProcess(12345),
/// )
/// ```
class EdenPortRow extends StatelessWidget {
  /// Creates an Eden port row.
  const EdenPortRow({
    super.key,
    required this.port,
    required this.process,
    this.pid,
    this.user,
    this.onKill,
    this.loading = false,
  });

  /// The port number being listened on.
  final int port;

  /// The name of the process listening on this port.
  final String process;

  /// The process ID, if available.
  final String? pid;

  /// The user running the process, if available.
  final String? user;

  /// Callback invoked when the kill action is triggered.
  ///
  /// When null, the kill button is hidden.
  final VoidCallback? onKill;

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
          _PortNumber(port: port, isDark: isDark),
          SizedBox(width: EdenSpacing.space4),
          Expanded(
            child: Text(
              process,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pid != null) ...[
            SizedBox(width: EdenSpacing.space3),
            Text(
              pid!,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: EdenColors.neutral[500],
              ),
            ),
          ],
          if (user != null) ...[
            SizedBox(width: EdenSpacing.space3),
            Text(
              user!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: EdenColors.neutral[500],
              ),
            ),
          ],
          if (onKill != null) ...[
            SizedBox(width: EdenSpacing.space3),
            _KillButton(
              onKill: onKill!,
              loading: loading,
            ),
          ],
        ],
      ),
    );
  }
}

class _PortNumber extends StatelessWidget {
  const _PortNumber({
    required this.port,
    required this.isDark,
  });

  final int port;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 60),
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
        port.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: isDark
              ? EdenColors.neutral[100]!
              : EdenColors.neutral[800]!,
        ),
      ),
    );
  }
}

class _KillButton extends StatelessWidget {
  const _KillButton({
    required this.onKill,
    required this.loading,
  });

  final VoidCallback onKill;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: EdenColors.error,
        ),
      );
    }

    return Tooltip(
      message: 'Kill process',
      child: InkWell(
        onTap: onKill,
        borderRadius: EdenRadii.borderRadiusSm,
        child: Padding(
          padding: EdgeInsets.all(EdenSpacing.space1),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: EdenColors.error,
          ),
        ),
      ),
    );
  }
}

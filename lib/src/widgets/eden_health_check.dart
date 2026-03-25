import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The result status of a prerequisite or dependency check.
enum EdenHealthCheckStatus {
  /// Check passed successfully.
  pass,

  /// Check passed with warnings.
  warn,

  /// Check failed.
  fail,
}

/// A row widget displaying a prerequisite or dependency health check with
/// its status, optional fix hint, and install action.
///
/// ```dart
/// EdenHealthCheck(
///   name: 'Node.js',
///   category: 'Runtime',
///   status: EdenHealthCheckStatus.fail,
///   fixHint: 'brew install node',
///   onInstall: () => installNode(),
/// )
/// ```
class EdenHealthCheck extends StatelessWidget {
  /// Creates an Eden health check row.
  const EdenHealthCheck({
    super.key,
    required this.name,
    this.category,
    required this.status,
    this.fixHint,
    this.onInstall,
    this.installing = false,
  });

  /// The name of the prerequisite or dependency.
  final String name;

  /// An optional category grouping (e.g. 'Runtime', 'Database').
  final String? category;

  /// The current check status.
  final EdenHealthCheckStatus status;

  /// A command or hint for fixing a failed check, displayed as a code snippet.
  final String? fixHint;

  /// Callback invoked when the install action is triggered.
  ///
  /// When null, the install button is hidden.
  final VoidCallback? onInstall;

  /// Whether an installation is currently in progress.
  final bool installing;

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
          _StatusIcon(status: status),
          SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (category != null) ...[
                  SizedBox(height: EdenSpacing.space1),
                  Text(
                    category!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: EdenColors.neutral[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (fixHint != null) ...[
            SizedBox(width: EdenSpacing.space3),
            _FixHint(hint: fixHint!, isDark: isDark),
          ],
          if (onInstall != null) ...[
            SizedBox(width: EdenSpacing.space3),
            _InstallButton(
              onInstall: onInstall!,
              installing: installing,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final EdenHealthCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _StatusIconConfig.forStatus(status);

    return Icon(
      config.icon,
      size: 20,
      color: config.color,
    );
  }
}

class _StatusIconConfig {
  const _StatusIconConfig({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  static _StatusIconConfig forStatus(EdenHealthCheckStatus status) {
    switch (status) {
      case EdenHealthCheckStatus.pass:
        return _StatusIconConfig(
          icon: Icons.check_circle_rounded,
          color: EdenColors.success,
        );
      case EdenHealthCheckStatus.warn:
        return _StatusIconConfig(
          icon: Icons.warning_rounded,
          color: EdenColors.warning,
        );
      case EdenHealthCheckStatus.fail:
        return _StatusIconConfig(
          icon: Icons.cancel_rounded,
          color: EdenColors.error,
        );
    }
  }
}

class _FixHint extends StatelessWidget {
  const _FixHint({
    required this.hint,
    required this.isDark,
  });

  final String hint;
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
        hint,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark
              ? EdenColors.neutral[300]!
              : EdenColors.neutral[600]!,
        ),
      ),
    );
  }
}

class _InstallButton extends StatelessWidget {
  const _InstallButton({
    required this.onInstall,
    required this.installing,
  });

  final VoidCallback onInstall;
  final bool installing;

  @override
  Widget build(BuildContext context) {
    if (installing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: EdenColors.info,
        ),
      );
    }

    return TextButton.icon(
      onPressed: onInstall,
      icon: Icon(Icons.download_rounded, size: 16),
      label: const Text('Install'),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2,
          vertical: EdenSpacing.space1,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The status of a deployment environment.
enum EdenEnvironmentStatus {
  /// Environment is actively running.
  active,

  /// Environment is stopped.
  stopped,

  /// Environment is in a failed state.
  failed,
}

/// A card widget displaying deployment environment details with status,
/// deployment info, and contextual actions.
///
/// Shows the environment name, current status, last deployment details
/// (branch, SHA, timestamp, deployer), and action buttons for deploy,
/// rollback, stop, and open URL.
///
/// ```dart
/// EdenEnvironmentCard(
///   name: 'production',
///   status: EdenEnvironmentStatus.active,
///   lastDeployedBranch: 'main',
///   lastDeployedSha: 'a1b2c3d',
///   lastDeployedAt: DateTime.now(),
///   deployedBy: 'alice',
///   url: 'https://app.example.com',
///   onDeploy: () => deploy('production'),
///   onOpenUrl: () => openUrl('https://app.example.com'),
/// )
/// ```
class EdenEnvironmentCard extends StatefulWidget {
  /// Creates an environment card widget.
  const EdenEnvironmentCard({
    super.key,
    required this.name,
    required this.status,
    this.lastDeployedBranch,
    this.lastDeployedSha,
    this.lastDeployedAt,
    this.deployedBy,
    this.url,
    this.onDeploy,
    this.onRollback,
    this.onStop,
    this.onOpenUrl,
  });

  /// Environment name.
  final String name;

  /// Current environment status.
  final EdenEnvironmentStatus status;

  /// Branch of the last deployment.
  final String? lastDeployedBranch;

  /// Commit SHA of the last deployment.
  final String? lastDeployedSha;

  /// Timestamp of the last deployment.
  final DateTime? lastDeployedAt;

  /// Who performed the last deployment.
  final String? deployedBy;

  /// URL of the running environment.
  final String? url;

  /// Called when the deploy action is triggered.
  final VoidCallback? onDeploy;

  /// Called when the rollback action is triggered.
  final VoidCallback? onRollback;

  /// Called when the stop action is triggered.
  final VoidCallback? onStop;

  /// Called when the open URL action is triggered.
  final VoidCallback? onOpenUrl;

  @override
  State<EdenEnvironmentCard> createState() => _EdenEnvironmentCardState();
}

class _EdenEnvironmentCardState extends State<EdenEnvironmentCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(widget.status);

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[900] : EdenColors.neutral[50],
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, isDark, statusColor),
          const SizedBox(height: EdenSpacing.space3),
          _buildDeploymentInfo(theme, isDark),
          const SizedBox(height: EdenSpacing.space4),
          _buildActions(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color statusColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: widget.status == EdenEnvironmentStatus.active
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: EdenSpacing.space3),
        Expanded(
          child: Text(
            widget.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? EdenColors.neutral[100]
                  : EdenColors.neutral[900],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(theme, isDark, statusColor),
      ],
    );
  }

  Widget _buildStatusBadge(
    ThemeData theme,
    bool isDark,
    Color statusColor,
  ) {
    final label = switch (widget.status) {
      EdenEnvironmentStatus.active => 'Active',
      EdenEnvironmentStatus.stopped => 'Stopped',
      EdenEnvironmentStatus.failed => 'Failed',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeploymentInfo(ThemeData theme, bool isDark) {
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: EdenColors.neutral[500],
    );
    final iconColor = EdenColors.neutral[400]!;

    final hasDeployInfo = widget.lastDeployedBranch != null ||
        widget.lastDeployedSha != null ||
        widget.lastDeployedAt != null ||
        widget.deployedBy != null;

    if (!hasDeployInfo) {
      return Text(
        'No deployments yet',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: EdenColors.neutral[500],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.lastDeployedBranch != null)
            _buildInfoRow(
              Icons.alt_route,
              iconColor,
              widget.lastDeployedBranch!,
              metaStyle,
            ),
          if (widget.lastDeployedSha != null) ...[
            if (widget.lastDeployedBranch != null)
              const SizedBox(height: EdenSpacing.space1),
            _buildInfoRow(
              Icons.tag,
              iconColor,
              widget.lastDeployedSha!.length > 8
                  ? widget.lastDeployedSha!.substring(0, 8)
                  : widget.lastDeployedSha!,
              metaStyle?.copyWith(fontFamily: 'monospace'),
            ),
          ],
          if (widget.lastDeployedAt != null) ...[
            const SizedBox(height: EdenSpacing.space1),
            _buildInfoRow(
              Icons.schedule,
              iconColor,
              _formatDateTime(widget.lastDeployedAt!),
              metaStyle,
            ),
          ],
          if (widget.deployedBy != null) ...[
            const SizedBox(height: EdenSpacing.space1),
            _buildInfoRow(
              Icons.person_outline,
              iconColor,
              widget.deployedBy!,
              metaStyle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    Color iconColor,
    String text,
    TextStyle? textStyle,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space2,
      children: [
        if (widget.onDeploy != null)
          FilledButton.icon(
            onPressed: widget.onDeploy,
            icon: const Icon(Icons.rocket_launch, size: 16),
            label: const Text('Deploy'),
          ),
        if (widget.onRollback != null)
          OutlinedButton.icon(
            onPressed: widget.onRollback,
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Rollback'),
          ),
        if (widget.onStop != null &&
            widget.status == EdenEnvironmentStatus.active)
          OutlinedButton.icon(
            onPressed: widget.onStop,
            icon: const Icon(Icons.stop, size: 16, color: EdenColors.error),
            label: const Text(
              'Stop',
              style: TextStyle(color: EdenColors.error),
            ),
          ),
        if (widget.onOpenUrl != null && widget.url != null)
          OutlinedButton.icon(
            onPressed: widget.onOpenUrl,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open'),
          ),
      ],
    );
  }

  Color _statusColor(EdenEnvironmentStatus status) {
    switch (status) {
      case EdenEnvironmentStatus.active:
        return EdenColors.success;
      case EdenEnvironmentStatus.stopped:
        return EdenColors.neutral[400]!;
      case EdenEnvironmentStatus.failed:
        return EdenColors.error;
    }
  }

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute';
  }
}

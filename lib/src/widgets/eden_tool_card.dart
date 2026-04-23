import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A card widget for browsing and managing tools or agents.
///
/// Displays tool metadata, capabilities, and provides install/configure/remove
/// actions.
class EdenToolCard extends StatelessWidget {
  /// Creates a tool card widget.
  const EdenToolCard({
    super.key,
    required this.name,
    this.description,
    this.version,
    this.provider,
    this.icon,
    this.installed = false,
    this.capabilities = const [],
    this.onInstall,
    this.onConfigure,
    this.onRemove,
    this.loading = false,
  });

  /// The tool name.
  final String name;

  /// A description of the tool.
  final String? description;

  /// The tool version string.
  final String? version;

  /// The provider or author of the tool.
  final String? provider;

  /// An icon representing the tool.
  final IconData? icon;

  /// Whether the tool is currently installed.
  final bool installed;

  /// A list of capability labels for this tool.
  final List<String> capabilities;

  /// Called to install the tool.
  final VoidCallback? onInstall;

  /// Called to configure the tool.
  final VoidCallback? onConfigure;

  /// Called to remove the tool.
  final VoidCallback? onRemove;

  /// Whether an action is currently in progress.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        children: [
          _buildTopRow(theme, isDark),
          if (description != null) ...[
            const SizedBox(height: EdenSpacing.space3),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EdenColors.neutral[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (capabilities.isNotEmpty) ...[
            const SizedBox(height: EdenSpacing.space3),
            _buildCapabilities(theme, isDark),
          ],
          const SizedBox(height: EdenSpacing.space4),
          _buildActions(theme),
        ],
      ),
    );
  }

  Widget _buildTopRow(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: EdenRadii.borderRadiusMd,
          ),
          child: Icon(
            icon ?? Icons.extension,
            size: 22,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: EdenSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (version != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: EdenSpacing.space1),
                      child: Text(
                        'v$version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: EdenColors.neutral[400],
                        ),
                      ),
                    ),
                ],
              ),
              if (provider != null)
                Text(
                  provider!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EdenColors.neutral[500],
                  ),
                ),
            ],
          ),
        ),
        _buildStatusBadge(theme, isDark),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme, bool isDark) {
    if (installed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: EdenColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: EdenColors.success),
            const SizedBox(width: 4),
            Text(
              'Installed',
              style: theme.textTheme.labelSmall?.copyWith(
                color: EdenColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Not installed',
        style: theme.textTheme.labelSmall?.copyWith(
          color: EdenColors.neutral[500],
        ),
      ),
    );
  }

  Widget _buildCapabilities(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: EdenSpacing.space1,
      runSpacing: EdenSpacing.space1,
      children: capabilities.map((cap) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cap,
            style: theme.textTheme.labelSmall?.copyWith(
              color: EdenColors.neutral[600],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(ThemeData theme) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!installed) {
      return Row(
        children: [
          if (onInstall != null)
            FilledButton.icon(
              onPressed: onInstall,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Install'),
            ),
        ],
      );
    }

    return Row(
      children: [
        if (onConfigure != null)
          OutlinedButton.icon(
            onPressed: onConfigure,
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Configure'),
          ),
        if (onRemove != null) ...[
          const SizedBox(width: EdenSpacing.space2),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 16, color: EdenColors.error),
            label: const Text(
              'Remove',
              style: TextStyle(color: EdenColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// The type of package or tool.
enum EdenPackageType {
  /// A Homebrew formula.
  formula,

  /// A Homebrew cask.
  cask,

  /// A mise (rtx) managed tool.
  mise,

  /// An npm package.
  npm,

  /// A plugin.
  plugin,
}

/// A row widget displaying an installable package or tool with version info
/// and action buttons.
class EdenPackageRow extends StatelessWidget {
  /// Creates a package row widget.
  const EdenPackageRow({
    super.key,
    required this.name,
    this.description,
    this.currentVersion,
    this.availableVersion,
    this.type,
    this.pinned = false,
    this.outdated = false,
    this.onInstall,
    this.onUpgrade,
    this.onUninstall,
    this.loading = false,
  });

  /// The package name.
  final String name;

  /// A short description of the package.
  final String? description;

  /// The currently installed version, or null if not installed.
  final String? currentVersion;

  /// The latest available version.
  final String? availableVersion;

  /// The package type.
  final EdenPackageType? type;

  /// Whether the package is pinned to its current version.
  final bool pinned;

  /// Whether an update is available.
  final bool outdated;

  /// Called to install the package.
  final VoidCallback? onInstall;

  /// Called to upgrade the package.
  final VoidCallback? onUpgrade;

  /// Called to uninstall the package.
  final VoidCallback? onUninstall;

  /// Whether an action is currently in progress.
  final bool loading;

  Color _typeBadgeColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case EdenPackageType.formula:
        return EdenColors.info;
      case EdenPackageType.cask:
        return Colors.purple;
      case EdenPackageType.mise:
        return EdenColors.success;
      case EdenPackageType.npm:
        return EdenColors.warning;
      case EdenPackageType.plugin:
        return theme.colorScheme.primary;
      case null:
        return EdenColors.neutral[400]!;
    }
  }

  String _typeLabel() {
    switch (type) {
      case EdenPackageType.formula:
        return 'formula';
      case EdenPackageType.cask:
        return 'cask';
      case EdenPackageType.mise:
        return 'mise';
      case EdenPackageType.npm:
        return 'npm';
      case EdenPackageType.plugin:
        return 'plugin';
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: EdenColors.neutral[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (type != null)
            Padding(
              padding: const EdgeInsets.only(left: EdenSpacing.space2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _typeBadgeColor(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _typeLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _typeBadgeColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (pinned)
            Padding(
              padding: const EdgeInsets.only(left: EdenSpacing.space2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: EdenColors.neutral[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 12,
                      color: EdenColors.neutral[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'pinned',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: EdenColors.neutral[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: EdenSpacing.space3),
            child: _buildVersionDisplay(theme),
          ),
          Padding(
            padding: const EdgeInsets.only(left: EdenSpacing.space2),
            child: _buildActions(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionDisplay(ThemeData theme) {
    if (currentVersion == null && availableVersion == null) {
      return const SizedBox.shrink();
    }

    if (outdated && currentVersion != null && availableVersion != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: EdenColors.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EdenColors.warning.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            currentVersion!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EdenColors.neutral[500],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 12,
              color: EdenColors.warning,
            ),
          ),
          Text(
            availableVersion!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      currentVersion ?? availableVersion ?? '',
      style: theme.textTheme.bodySmall?.copyWith(
        color: EdenColors.neutral[500],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    if (loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final buttons = <Widget>[];

    if (currentVersion == null && onInstall != null) {
      buttons.add(
        TextButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Install'),
        ),
      );
    }

    if (outdated && onUpgrade != null) {
      buttons.add(
        TextButton.icon(
          onPressed: onUpgrade,
          icon: const Icon(Icons.upgrade, size: 16),
          label: const Text('Upgrade'),
        ),
      );
    }

    if (currentVersion != null && onUninstall != null) {
      buttons.add(
        TextButton.icon(
          onPressed: onUninstall,
          icon: const Icon(Icons.delete_outline, size: 16, color: EdenColors.error),
          label: const Text(
            'Uninstall',
            style: TextStyle(color: EdenColors.error),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

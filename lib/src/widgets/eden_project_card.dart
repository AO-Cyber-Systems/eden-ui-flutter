import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Status of a DevFlow project.
enum EdenProjectStatus {
  /// Project is currently running.
  running,

  /// Project is stopped.
  stopped,

  /// Project directory is missing or inaccessible.
  missing,
}

/// A project overview card for DevFlow projects.
///
/// Displays project name, path, framework badge, DevFlow status,
/// and quick-action buttons for terminal, editor, finder, and logs.
class EdenProjectCard extends StatelessWidget {
  /// Creates an Eden project card.
  const EdenProjectCard({
    super.key,
    required this.name,
    required this.path,
    this.framework,
    this.status = EdenProjectStatus.stopped,
    this.hasDevflow = false,
    this.onOpenTerminal,
    this.onOpenEditor,
    this.onOpenFinder,
    this.onOpenLogs,
    this.onTap,
  });

  /// The project name displayed as the heading.
  final String name;

  /// The filesystem path to the project.
  final String path;

  /// Optional framework identifier (e.g. "Rails", "Next", "Go").
  final String? framework;

  /// Current status of the project.
  final EdenProjectStatus status;

  /// Whether the project has DevFlow initialized.
  final bool hasDevflow;

  /// Called when the terminal action button is pressed.
  final VoidCallback? onOpenTerminal;

  /// Called when the editor action button is pressed.
  final VoidCallback? onOpenEditor;

  /// Called when the finder action button is pressed.
  final VoidCallback? onOpenFinder;

  /// Called when the logs action button is pressed.
  final VoidCallback? onOpenLogs;

  /// Called when the card itself is tapped.
  final VoidCallback? onTap;

  static const _frameworkColorMap = <String, Color Function()>{
    'Rails': _errorColor,
    'Ruby': _errorColor,
    'Node': _successColor,
    'Next': _successColor,
    'Python': _warningColor,
    'Django': _warningColor,
    'Flask': _warningColor,
    'Go': _infoColor,
    'Elixir': _infoColor,
  };

  static Color _errorColor() => EdenColors.error;
  static Color _successColor() => EdenColors.success;
  static Color _warningColor() => EdenColors.warning;
  static Color _infoColor() => EdenColors.info;

  Color _statusDotColor() {
    switch (status) {
      case EdenProjectStatus.running:
        return EdenColors.success;
      case EdenProjectStatus.stopped:
        return EdenColors.neutral[400]!;
      case EdenProjectStatus.missing:
        return EdenColors.error;
    }
  }

  Color _frameworkBadgeColor() {
    if (framework == null) return EdenColors.info;
    final getter = _frameworkColorMap[framework!];
    return getter != null ? getter() : EdenColors.info;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final pathColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: EdenRadii.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: EdenRadii.borderRadiusLg,
          child: Padding(
            padding: EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: status dot, name, framework badge, devflow badge
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusDotColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (framework != null) ...[
                      SizedBox(width: EdenSpacing.space2),
                      _FrameworkBadge(
                        label: framework!,
                        color: _frameworkBadgeColor(),
                      ),
                    ],
                    if (hasDevflow) ...[
                      SizedBox(width: EdenSpacing.space2),
                      _DevflowBadge(isDark: isDark),
                    ],
                  ],
                ),

                SizedBox(height: EdenSpacing.space2),

                // Path row
                Text(
                  path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: pathColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),

                SizedBox(height: EdenSpacing.space3),

                // Bottom row: quick action icon buttons
                Row(
                  children: [
                    _ActionIconButton(
                      icon: Icons.terminal,
                      tooltip: 'Open Terminal',
                      onPressed: onOpenTerminal,
                      isDark: isDark,
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    _ActionIconButton(
                      icon: Icons.code,
                      tooltip: 'Open Editor',
                      onPressed: onOpenEditor,
                      isDark: isDark,
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    _ActionIconButton(
                      icon: Icons.folder_open,
                      tooltip: 'Open Finder',
                      onPressed: onOpenFinder,
                      isDark: isDark,
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    _ActionIconButton(
                      icon: Icons.article_outlined,
                      tooltip: 'Open Logs',
                      onPressed: onOpenLogs,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameworkBadge extends StatelessWidget {
  const _FrameworkBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }
}

class _DevflowBadge extends StatelessWidget {
  const _DevflowBadge({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = EdenColors.info;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space1,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        'DF',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final hoverColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final iconColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Material(
          color: Colors.transparent,
          borderRadius: EdenRadii.borderRadiusSm,
          child: InkWell(
            onTap: onPressed,
            borderRadius: EdenRadii.borderRadiusSm,
            hoverColor: hoverColor,
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: onPressed != null ? iconColor : iconColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The rollout strategy for a feature flag.
enum EdenFeatureFlagStrategy {
  /// Rolling out to a percentage of users.
  percentage,

  /// Enabled for a specific list of users.
  userList,

  /// Enabled based on environment.
  environment,
}

/// A model representing a feature flag configuration.
class EdenFeatureFlag {
  /// Creates a feature flag model.
  const EdenFeatureFlag({
    required this.name,
    required this.isEnabled,
    required this.strategy,
    this.strategyDescription,
    this.environments = const [],
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  /// The flag name / key.
  final String name;

  /// Whether the flag is currently enabled.
  final bool isEnabled;

  /// The rollout strategy.
  final EdenFeatureFlagStrategy strategy;

  /// A human-readable description of the strategy configuration.
  final String? strategyDescription;

  /// The list of environments this flag targets.
  final List<String> environments;

  /// When the flag was last modified.
  final DateTime? lastModifiedAt;

  /// Who last modified the flag.
  final String? lastModifiedBy;
}

/// A row widget displaying a feature flag with toggle, strategy info,
/// environment badges, and last-modified metadata.
///
/// ```dart
/// EdenFeatureFlagRow(
///   flag: EdenFeatureFlag(
///     name: 'dark-mode-v2',
///     isEnabled: true,
///     strategy: EdenFeatureFlagStrategy.percentage,
///     strategyDescription: '25% of users',
///     environments: ['staging', 'production'],
///   ),
///   onToggle: (enabled) {},
///   onTap: () {},
/// )
/// ```
class EdenFeatureFlagRow extends StatefulWidget {
  /// Creates an Eden feature flag row.
  const EdenFeatureFlagRow({
    super.key,
    required this.flag,
    this.onToggle,
    this.onTap,
  });

  /// The feature flag data to display.
  final EdenFeatureFlag flag;

  /// Callback when the toggle is switched.
  final ValueChanged<bool>? onToggle;

  /// Callback when the row is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenFeatureFlagRow> createState() => _EdenFeatureFlagRowState();
}

class _EdenFeatureFlagRowState extends State<EdenFeatureFlagRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flag = widget.flag;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
                    : EdenColors.neutral[50])
                : null,
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
              // Toggle
              SizedBox(
                width: 40,
                height: 24,
                child: Switch.adaptive(
                  value: flag.isEnabled,
                  onChanged: widget.onToggle,
                  activeThumbColor: EdenColors.success,
                ),
              ),
              const SizedBox(width: EdenSpacing.space3),

              // Name + strategy + environments
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          flag.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: EdenSpacing.space2),
                        _StrategyChip(strategy: flag.strategy, isDark: isDark),
                      ],
                    ),
                    if (flag.strategyDescription != null) ...[
                      const SizedBox(height: EdenSpacing.space1),
                      Text(
                        flag.strategyDescription!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: EdenColors.neutral[500],
                        ),
                      ),
                    ],
                    if (flag.environments.isNotEmpty) ...[
                      const SizedBox(height: EdenSpacing.space2),
                      Wrap(
                        spacing: EdenSpacing.space1,
                        runSpacing: EdenSpacing.space1,
                        children: flag.environments.map((env) {
                          return _EnvironmentBadge(
                            environment: env,
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Last modified
              if (flag.lastModifiedAt != null || flag.lastModifiedBy != null)
                _LastModifiedInfo(
                  lastModifiedAt: flag.lastModifiedAt,
                  lastModifiedBy: flag.lastModifiedBy,
                  isDark: isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategyChip extends StatelessWidget {
  const _StrategyChip({required this.strategy, required this.isDark});

  final EdenFeatureFlagStrategy strategy;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (strategy) {
      EdenFeatureFlagStrategy.percentage => (Icons.pie_chart_rounded, '%'),
      EdenFeatureFlagStrategy.userList => (Icons.people_rounded, 'Users'),
      EdenFeatureFlagStrategy.environment => (Icons.dns_rounded, 'Env'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: EdenColors.neutral[500],
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: EdenColors.neutral[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentBadge extends StatelessWidget {
  const _EnvironmentBadge({
    required this.environment,
    required this.isDark,
  });

  final String environment;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = switch (environment.toLowerCase()) {
      'production' || 'prod' => EdenColors.red[400]!,
      'staging' || 'stage' => EdenColors.warning,
      'development' || 'dev' => EdenColors.info,
      _ => EdenColors.neutral[500]!,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(
        environment,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _LastModifiedInfo extends StatelessWidget {
  const _LastModifiedInfo({
    this.lastModifiedAt,
    this.lastModifiedBy,
    required this.isDark,
  });

  final DateTime? lastModifiedAt;
  final String? lastModifiedBy;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lastModifiedBy != null)
          Text(
            lastModifiedBy!,
            style: TextStyle(
              fontSize: 11,
              color: EdenColors.neutral[500],
            ),
          ),
        if (lastModifiedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatDate(lastModifiedAt!),
            style: TextStyle(
              fontSize: 10,
              color: EdenColors.neutral[400],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

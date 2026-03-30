import 'package:flutter/material.dart';

/// Urgency/priority level badge with icon and color coding.
///
/// Displays urgency levels (low, medium, high, critical) with appropriate
/// colors and optional icons for high/critical levels.
///
/// ```dart
/// EdenUrgencyBadge(urgency: 'high')
/// EdenUrgencyBadge(urgency: 'critical')
/// EdenUrgencyBadge(urgency: 'low', fontSize: 11)
/// ```
class EdenUrgencyBadge extends StatelessWidget {
  const EdenUrgencyBadge({
    super.key,
    required this.urgency,
    this.fontSize,
  });

  final String urgency;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(config.icon, size: 14, color: config.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            config.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  _UrgencyConfig _getConfig(ThemeData theme) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return _UrgencyConfig(
          label: 'Low',
          backgroundColor: Colors.blue.withValues(alpha: 0.15),
          textColor: Colors.blue.shade800,
        );
      case 'medium':
        return _UrgencyConfig(
          label: 'Medium',
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          textColor: Colors.amber.shade800,
        );
      case 'high':
        return _UrgencyConfig(
          label: 'High',
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          textColor: Colors.orange.shade800,
          icon: Icons.priority_high,
        );
      case 'critical':
        return _UrgencyConfig(
          label: 'Critical',
          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
          textColor: theme.colorScheme.error,
          icon: Icons.warning_rounded,
        );
      default:
        return _UrgencyConfig(
          label: urgency,
          backgroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          textColor: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _UrgencyConfig {
  const _UrgencyConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
}

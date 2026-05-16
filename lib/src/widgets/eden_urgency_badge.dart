import 'package:flutter/material.dart';

/// Cross-vertical urgency-level pill badge.
///
/// Renders a small rounded pill displaying the urgency level with appropriate
/// color coding and optional icon. Recognises four canonical urgency strings:
///
/// - `low` → blue, no icon, label "Low".
/// - `medium` → amber, no icon, label "Medium".
/// - `high` → orange, `Icons.priority_high`, label "High".
/// - `critical` → theme `colorScheme.error`, `Icons.warning_rounded`, label
///   "Critical".
///
/// Any other input string is rendered verbatim as the label on the
/// `theme.colorScheme.onSurfaceVariant` tone (graceful unknown fallback).
///
/// Cross-vertical examples:
///
/// - Trades: work-order priority, dispatch urgency, callback urgency.
/// - Medical: patient triage levels.
/// - Legal: case priority (P0/P1/P2/P3 maps to critical/high/medium/low).
/// - Government: incident response urgency.
/// - Retail: loss-prevention alert priority.
///
/// Donor: `trades-flutter/lib/shared/widgets/urgency_badge.dart`.
class EdenUrgencyBadge extends StatelessWidget {
  const EdenUrgencyBadge({
    super.key,
    required this.urgency,
    this.fontSize,
  });

  /// Urgency level string. Canonical values are `low`, `medium`, `high`, and
  /// `critical`; any other value renders verbatim with the neutral
  /// onSurfaceVariant tone.
  final String urgency;

  /// Optional font-size override. When null the label inherits the size of
  /// `theme.textTheme.labelSmall`.
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
          Flexible(
            child: Text(
              config.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: config.textColor,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _UrgencyConfig _getConfig(ThemeData theme) {
    switch (urgency) {
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

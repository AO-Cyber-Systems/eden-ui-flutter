import 'package:flutter/material.dart';

/// Severity level for classification badges.
enum EdenSeverityLevel {
  safe('Safe', Color(0xFF22C55E), Icons.check_circle_outline),
  scoped('Scoped', Color(0xFF3B82F6), Icons.shield_outlined),
  review('Review', Color(0xFFF59E0B), Icons.rate_review_outlined),
  destructive('Destructive', Color(0xFFEF4444), Icons.warning_amber_rounded);

  const EdenSeverityLevel(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// Compact color-coded severity badge with icon, tooltip, and optional label.
///
/// Four built-in levels: safe (green), scoped (blue), review (amber),
/// destructive (red). Supports compact mode (icon-only) and full mode
/// (icon + label). Tap shows tooltip with [description].
///
/// ```dart
/// EdenSeverityBadge(level: EdenSeverityLevel.safe)
/// EdenSeverityBadge(level: EdenSeverityLevel.destructive, compact: true)
/// EdenSeverityBadge(
///   level: EdenSeverityLevel.review,
///   description: 'Affects shared resources, needs review',
/// )
/// ```
class EdenSeverityBadge extends StatelessWidget {
  const EdenSeverityBadge({
    super.key,
    required this.level,
    this.compact = false,
    this.description,
    this.customLabel,
    this.customColor,
    this.customIcon,
  });

  /// The severity level determining color, icon, and default label.
  final EdenSeverityLevel level;

  /// When true, shows only the icon without the label.
  final bool compact;

  /// Optional tooltip description shown on long-press/hover.
  final String? description;

  /// Override the default label for this level.
  final String? customLabel;

  /// Override the default color for this level.
  final Color? customColor;

  /// Override the default icon for this level.
  final IconData? customIcon;

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? level.color;
    final icon = customIcon ?? level.icon;
    final label = customLabel ?? level.label;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );

    if (description != null) {
      return Tooltip(message: description!, child: badge);
    }

    return badge;
  }
}

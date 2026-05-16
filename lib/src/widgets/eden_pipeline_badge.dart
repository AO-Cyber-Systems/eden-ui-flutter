import 'package:flutter/material.dart';

/// Cross-vertical pipeline-stage outlined pill badge.
///
/// Renders an outlined pill displaying a stage label with an icon, using
/// case-insensitive matching against five canonical stages plus aliases:
///
/// - `draft` → grey, `Icons.edit_outlined`, label "Draft".
/// - `sent` → blue, `Icons.send_outlined`, label "Sent".
/// - `won` (alias `accepted`) → green, `Icons.check_circle_outline`, label "Won".
/// - `lost` (alias `rejected`) → red, `Icons.cancel_outlined`, label "Lost".
/// - `expired` → orange, `Icons.schedule_outlined`, label "Expired".
///
/// Any other input renders the label "Unknown" with `Icons.help_outline` on the
/// neutral grey tone (graceful unknown fallback).
///
/// Cross-vertical mapping (informational; not enforced):
/// - Trades bidding: draft / sent / won / lost / expired.
/// - Salon membership: draft / sent / accepted / rejected / expired.
/// - Legal cases: draft / filed / won / lost / withdrawn (caller maps
///   "withdrawn" → "expired" if desired).
/// - Retail leads: draft / sent / converted ("won") / dropped ("lost") /
///   expired.
///
/// Donor: `trades-flutter/lib/shared/widgets/pipeline_badge.dart`.
class EdenPipelineBadge extends StatelessWidget {
  const EdenPipelineBadge({
    super.key,
    required this.stage,
  });

  /// Pipeline-stage string. Case-insensitive; aliases supported. See class doc.
  final String stage;

  static _StageStyle _styleForStage(String stage) {
    return switch (stage.toLowerCase()) {
      'draft' => const _StageStyle(
          color: Colors.grey,
          icon: Icons.edit_outlined,
          label: 'Draft',
        ),
      'sent' => const _StageStyle(
          color: Colors.blue,
          icon: Icons.send_outlined,
          label: 'Sent',
        ),
      'won' || 'accepted' => const _StageStyle(
          color: Colors.green,
          icon: Icons.check_circle_outline,
          label: 'Won',
        ),
      'lost' || 'rejected' => const _StageStyle(
          color: Colors.red,
          icon: Icons.cancel_outlined,
          label: 'Lost',
        ),
      'expired' => const _StageStyle(
          color: Colors.orange,
          icon: Icons.schedule_outlined,
          label: 'Expired',
        ),
      _ => const _StageStyle(
          color: Colors.grey,
          icon: Icons.help_outline,
          label: 'Unknown',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleForStage(stage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              style.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: style.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageStyle {
  const _StageStyle({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;
}

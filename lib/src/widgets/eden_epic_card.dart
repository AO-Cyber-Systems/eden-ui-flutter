import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Health status of an epic or initiative.
enum EdenEpicHealth {
  /// On track — all milestones proceeding as expected.
  onTrack,

  /// At risk — one or more issues may cause a delay.
  atRisk,

  /// Needs attention — significant blockers or delays.
  needsAttention,

  /// Completed — all work is done.
  completed,
}

/// A color-labeled tag on an epic.
class EdenEpicLabel {
  /// Creates an epic label.
  const EdenEpicLabel({
    required this.name,
    required this.color,
  });

  /// Display name.
  final String name;

  /// Label color.
  final Color color;
}

/// A card displaying an epic or initiative with progress, health, labels, and dates.
///
/// Shows a progress bar with child count, health status badge, date range,
/// and colored label pills.
class EdenEpicCard extends StatefulWidget {
  /// Creates an epic card.
  const EdenEpicCard({
    super.key,
    required this.title,
    this.description,
    this.childCount = 0,
    this.completedCount = 0,
    this.startDate,
    this.endDate,
    this.labels = const [],
    this.healthStatus = EdenEpicHealth.onTrack,
    this.onTap,
  });

  /// Title of the epic.
  final String title;

  /// Optional description.
  final String? description;

  /// Total number of child issues / stories.
  final int childCount;

  /// How many children are completed.
  final int completedCount;

  /// Start date of the epic.
  final DateTime? startDate;

  /// Target end date of the epic.
  final DateTime? endDate;

  /// Color-labeled tags.
  final List<EdenEpicLabel> labels;

  /// Overall health status.
  final EdenEpicHealth healthStatus;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenEpicCard> createState() => _EdenEpicCardState();
}

class _EdenEpicCardState extends State<EdenEpicCard> {
  // ---------------------------------------------------------------------------
  // Health helpers
  // ---------------------------------------------------------------------------

  Color _healthColor() {
    switch (widget.healthStatus) {
      case EdenEpicHealth.onTrack:
        return EdenColors.success;
      case EdenEpicHealth.atRisk:
        return EdenColors.warning;
      case EdenEpicHealth.needsAttention:
        return EdenColors.error;
      case EdenEpicHealth.completed:
        return EdenColors.info;
    }
  }

  String _healthLabel() {
    switch (widget.healthStatus) {
      case EdenEpicHealth.onTrack:
        return 'On Track';
      case EdenEpicHealth.atRisk:
        return 'At Risk';
      case EdenEpicHealth.needsAttention:
        return 'Needs Attention';
      case EdenEpicHealth.completed:
        return 'Completed';
    }
  }

  IconData _healthIcon() {
    switch (widget.healthStatus) {
      case EdenEpicHealth.onTrack:
        return Icons.check_circle_outline;
      case EdenEpicHealth.atRisk:
        return Icons.warning_amber_rounded;
      case EdenEpicHealth.needsAttention:
        return Icons.error_outline;
      case EdenEpicHealth.completed:
        return Icons.verified_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final healthColor = _healthColor();

    final progressFraction = widget.childCount > 0
        ? widget.completedCount / widget.childCount
        : 0.0;

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
          onTap: widget.onTap,
          borderRadius: EdenRadii.borderRadiusLg,
          child: Padding(
            padding: EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + health badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    _HealthBadge(
                      label: _healthLabel(),
                      icon: _healthIcon(),
                      color: healthColor,
                    ),
                  ],
                ),

                // Description
                if (widget.description != null) ...[
                  SizedBox(height: EdenSpacing.space2),
                  Text(
                    widget.description!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: mutedColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: EdenSpacing.space3),

                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: EdenRadii.borderRadiusFull,
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? EdenColors.neutral[700]
                              : EdenColors.neutral[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(healthColor),
                        ),
                      ),
                    ),
                    SizedBox(width: EdenSpacing.space2),
                    Text(
                      '${widget.completedCount} of ${widget.childCount} issues',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: mutedColor),
                    ),
                  ],
                ),

                // Date range
                if (widget.startDate != null || widget.endDate != null) ...[
                  SizedBox(height: EdenSpacing.space3),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: mutedColor),
                      SizedBox(width: EdenSpacing.space1),
                      Text(
                        [
                          if (widget.startDate != null)
                            _formatDate(widget.startDate!),
                          if (widget.endDate != null)
                            _formatDate(widget.endDate!),
                        ].join(' — '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: mutedColor),
                      ),
                    ],
                  ),
                ],

                // Labels
                if (widget.labels.isNotEmpty) ...[
                  SizedBox(height: EdenSpacing.space3),
                  Wrap(
                    spacing: EdenSpacing.space1,
                    runSpacing: EdenSpacing.space1,
                    children: widget.labels.map((label) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: EdenSpacing.space2,
                          vertical: EdenSpacing.space1 / 2,
                        ),
                        decoration: BoxDecoration(
                          color: label.color.withValues(alpha: 0.12),
                          borderRadius: EdenRadii.borderRadiusFull,
                        ),
                        child: Text(
                          label.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: label.color,
                            height: 1.2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: EdenSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

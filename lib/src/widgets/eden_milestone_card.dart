import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The state of a milestone.
enum EdenMilestoneState {
  /// Milestone is open and active.
  open,

  /// Milestone is closed.
  closed,
}

/// A card displaying milestone progress, due date, and issue counts.
///
/// Shows a progress bar based on closed vs total issues, due date with overdue
/// warning, and percentage complete.
class EdenMilestoneCard extends StatefulWidget {
  /// Creates a milestone card widget.
  const EdenMilestoneCard({
    super.key,
    required this.title,
    this.description,
    this.dueDate,
    this.openCount = 0,
    this.closedCount = 0,
    this.state = EdenMilestoneState.open,
    this.onTap,
  });

  /// The milestone title.
  final String title;

  /// An optional description.
  final String? description;

  /// The due date (null if no due date set).
  final DateTime? dueDate;

  /// Number of open issues.
  final int openCount;

  /// Number of closed issues.
  final int closedCount;

  /// The milestone state.
  final EdenMilestoneState state;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenMilestoneCard> createState() => _EdenMilestoneCardState();
}

class _EdenMilestoneCardState extends State<EdenMilestoneCard> {
  int get _total => widget.openCount + widget.closedCount;

  double get _progress => _total > 0 ? widget.closedCount / _total : 0.0;

  int get _percentComplete => (_progress * 100).round();

  bool get _isOverdue {
    if (widget.dueDate == null) return false;
    return DateTime.now().isAfter(widget.dueDate!) &&
        widget.state == EdenMilestoneState.open;
  }

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
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row with state badge
                _buildTitleRow(theme, isDark),
                if (widget.description != null) ...[
                  const SizedBox(height: EdenSpacing.space2),
                  Text(
                    widget.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: EdenSpacing.space3),

                // Progress bar
                _buildProgressBar(isDark),
                const SizedBox(height: EdenSpacing.space3),

                // Stats row: percentage, counts, due date
                _buildStatsRow(theme, isDark, mutedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(ThemeData theme, bool isDark) {
    final isClosed = widget.state == EdenMilestoneState.closed;

    return Row(
      children: [
        Icon(
          isClosed ? Icons.check_circle : Icons.flag,
          size: 18,
          color: isClosed ? EdenColors.purple : EdenColors.success,
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isClosed)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: EdenColors.purple.withValues(alpha: 0.12),
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              'Closed',
              style: theme.textTheme.labelSmall?.copyWith(
                color: EdenColors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final trackColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
    const fillColor = EdenColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(EdenRadii.full),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Track
                Container(
                  width: double.infinity,
                  color: trackColor,
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(color: fillColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark, Color mutedColor) {
    return Row(
      children: [
        // Percentage
        Text(
          '$_percentComplete% complete',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: EdenColors.success,
          ),
        ),
        const SizedBox(width: EdenSpacing.space4),

        // Open / closed counts
        const Icon(Icons.radio_button_checked, size: 14, color: EdenColors.success),
        const SizedBox(width: 2),
        Text(
          '${widget.openCount} open',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        const SizedBox(width: EdenSpacing.space3),
        const Icon(Icons.check_circle, size: 14, color: EdenColors.purple),
        const SizedBox(width: 2),
        Text(
          '${widget.closedCount} closed',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),

        const Spacer(),

        // Due date
        if (widget.dueDate != null) ...[
          Icon(
            Icons.calendar_today,
            size: 14,
            color: _isOverdue ? EdenColors.error : mutedColor,
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            _isOverdue
                ? 'Past due ${_formatDate(widget.dueDate!)}'
                : 'Due ${_formatDate(widget.dueDate!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _isOverdue ? EdenColors.error : mutedColor,
              fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

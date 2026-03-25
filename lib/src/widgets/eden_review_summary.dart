import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Verdict a reviewer can leave on a pull/merge request.
enum EdenReviewVerdict { approved, changesRequested, commented, dismissed }

/// Data model for a review summary event.
class EdenReviewSummaryData {
  const EdenReviewSummaryData({
    required this.reviewerName,
    required this.reviewerInitial,
    required this.verdict,
    required this.timestamp,
    this.summaryBody,
    this.inlineCommentCount = 0,
  });

  final String reviewerName;
  final String reviewerInitial;
  final EdenReviewVerdict verdict;
  final String timestamp;
  final String? summaryBody;
  final int inlineCommentCount;
}

/// A review summary card with verdict-colored left border, icon, label,
/// summary body, and expandable inline-comment count.
class EdenReviewSummary extends StatefulWidget {
  const EdenReviewSummary({
    super.key,
    required this.data,
    this.commentWidgets,
    this.onViewComments,
  });

  final EdenReviewSummaryData data;

  /// Optional list of widgets rendered when the inline-comment section is
  /// expanded. When null the count is still shown but expansion is disabled.
  final List<Widget>? commentWidgets;

  /// Called when the user taps "View comments".
  final VoidCallback? onViewComments;

  @override
  State<EdenReviewSummary> createState() => _EdenReviewSummaryState();
}

class _EdenReviewSummaryState extends State<EdenReviewSummary> {
  bool _commentsExpanded = false;

  // ---------------------------------------------------------------------------
  // Verdict visuals
  // ---------------------------------------------------------------------------

  static const _verdictLabels = {
    EdenReviewVerdict.approved: 'Approved',
    EdenReviewVerdict.changesRequested: 'Changes requested',
    EdenReviewVerdict.commented: 'Commented',
    EdenReviewVerdict.dismissed: 'Dismissed',
  };

  static const _verdictIcons = {
    EdenReviewVerdict.approved: Icons.check_circle_outline,
    EdenReviewVerdict.changesRequested: Icons.error_outline,
    EdenReviewVerdict.commented: Icons.chat_bubble_outline,
    EdenReviewVerdict.dismissed: Icons.remove_circle_outline,
  };

  Color _verdictColor(EdenReviewVerdict verdict) {
    switch (verdict) {
      case EdenReviewVerdict.approved:
        return EdenColors.emerald[600]!;
      case EdenReviewVerdict.changesRequested:
        return EdenColors.red[600]!;
      case EdenReviewVerdict.commented:
        return EdenColors.blue[600]!;
      case EdenReviewVerdict.dismissed:
        return EdenColors.neutral[500]!;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final review = widget.data;

    final verdictColor = _verdictColor(review.verdict);
    final surfaceColor = isDark
        ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
        : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border.all(color: borderColor),
            borderRadius: EdenRadii.borderRadiusLg,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Verdict-colored left border
                Container(width: 4, color: verdictColor),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(EdenSpacing.space4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(theme, isDark, review, verdictColor),
                        if (review.summaryBody != null &&
                            review.summaryBody!.isNotEmpty) ...[
                          const SizedBox(height: EdenSpacing.space3),
                          _buildBody(theme, review),
                        ],
                        if (review.inlineCommentCount > 0) ...[
                          const SizedBox(height: EdenSpacing.space3),
                          _buildCommentCount(theme, isDark, review),
                        ],
                        if (_commentsExpanded &&
                            widget.commentWidgets != null) ...[
                          const SizedBox(height: EdenSpacing.space3),
                          ...widget.commentWidgets!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    EdenReviewSummaryData review,
    Color verdictColor,
  ) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 14,
          backgroundColor: verdictColor.withValues(alpha: 0.15),
          child: Text(
            review.reviewerInitial,
            style: theme.textTheme.labelSmall?.copyWith(
              color: verdictColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),

        // Reviewer name
        Text(
          review.reviewerName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),

        // Verdict chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: verdictColor.withValues(alpha: 0.12),
            borderRadius: EdenRadii.borderRadiusFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _verdictIcons[review.verdict],
                size: 14,
                color: verdictColor,
              ),
              const SizedBox(width: 4),
              Text(
                _verdictLabels[review.verdict]!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: verdictColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Timestamp
        Text(
          review.timestamp,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody(ThemeData theme, EdenReviewSummaryData review) {
    return Text(
      review.summaryBody!,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Comment count
  // ---------------------------------------------------------------------------

  Widget _buildCommentCount(
    ThemeData theme,
    bool isDark,
    EdenReviewSummaryData review,
  ) {
    final canExpand = widget.commentWidgets != null;
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return GestureDetector(
      onTap: () {
        if (canExpand) {
          setState(() => _commentsExpanded = !_commentsExpanded);
        }
        widget.onViewComments?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.comment_outlined, size: 14, color: muted),
          const SizedBox(width: 4),
          Text(
            '${review.inlineCommentCount} inline comment${review.inlineCommentCount == 1 ? '' : 's'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (canExpand) ...[
            const SizedBox(width: 2),
            Icon(
              _commentsExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}

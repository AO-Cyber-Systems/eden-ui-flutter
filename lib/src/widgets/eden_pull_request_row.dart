import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The state of a pull request.
enum EdenPrState {
  /// Pull request is open and accepting changes.
  open,

  /// Pull request has been closed without merging.
  closed,

  /// Pull request has been merged into the base branch.
  merged,

  /// Pull request is a draft and not ready for review.
  draft,
}

/// The review status of a pull request.
enum EdenPrReviewStatus {
  /// Awaiting review.
  pending,

  /// All required reviews approved.
  approved,

  /// One or more reviewers requested changes.
  changesRequested,
}

/// The CI status of a pull request.
enum EdenPrCiStatus {
  /// All checks passed.
  passed,

  /// One or more checks failed.
  failed,

  /// Checks are currently running.
  running,

  /// Checks have not yet started.
  pending,
}

/// A label attached to a pull request.
class EdenPrLabel {
  /// Creates a pull request label.
  const EdenPrLabel({
    required this.name,
    required this.color,
  });

  /// The display name of the label.
  final String name;

  /// The color of the label.
  final Color color;
}

/// A compact row widget for displaying a pull request in a list.
///
/// Shows the PR number, title, state icon, branch info, CI status,
/// review status, conflict indicator, comment count, and labels.
///
/// ```dart
/// EdenPullRequestRow(
///   number: 42,
///   title: 'Add dark mode support',
///   state: EdenPrState.open,
///   authorName: 'Jane',
///   authorInitial: 'J',
///   headBranch: 'feat/dark-mode',
///   baseBranch: 'main',
///   labels: [EdenPrLabel(name: 'enhancement', color: Colors.blue)],
///   reviewStatus: EdenPrReviewStatus.approved,
///   ciStatus: EdenPrCiStatus.passed,
///   hasConflicts: false,
///   commentCount: 3,
///   createdAt: DateTime.now(),
///   onTap: () {},
/// )
/// ```
class EdenPullRequestRow extends StatefulWidget {
  /// Creates an Eden pull request row.
  const EdenPullRequestRow({
    super.key,
    required this.number,
    required this.title,
    required this.state,
    required this.authorName,
    required this.authorInitial,
    required this.headBranch,
    required this.baseBranch,
    this.labels = const [],
    this.reviewStatus = EdenPrReviewStatus.pending,
    this.ciStatus = EdenPrCiStatus.pending,
    this.hasConflicts = false,
    this.commentCount = 0,
    required this.createdAt,
    this.onTap,
  });

  /// The pull request number.
  final int number;

  /// The pull request title.
  final String title;

  /// The current state of the pull request.
  final EdenPrState state;

  /// The name of the author.
  final String authorName;

  /// A single character initial for the author avatar.
  final String authorInitial;

  /// The source branch name.
  final String headBranch;

  /// The target branch name.
  final String baseBranch;

  /// Labels attached to this pull request.
  final List<EdenPrLabel> labels;

  /// The review status of this pull request.
  final EdenPrReviewStatus reviewStatus;

  /// The CI status of this pull request.
  final EdenPrCiStatus ciStatus;

  /// Whether this pull request has merge conflicts.
  final bool hasConflicts;

  /// The number of comments on this pull request.
  final int commentCount;

  /// When this pull request was created.
  final DateTime createdAt;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenPullRequestRow> createState() => _EdenPullRequestRowState();
}

class _EdenPullRequestRowState extends State<EdenPullRequestRow> {
  Color _stateColor() {
    switch (widget.state) {
      case EdenPrState.open:
        return EdenColors.success;
      case EdenPrState.merged:
        return EdenColors.purple[500]!;
      case EdenPrState.closed:
        return EdenColors.error;
      case EdenPrState.draft:
        return EdenColors.neutral[400]!;
    }
  }

  IconData _stateIcon() {
    switch (widget.state) {
      case EdenPrState.open:
        return Icons.adjust;
      case EdenPrState.merged:
        return Icons.merge_type;
      case EdenPrState.closed:
        return Icons.cancel_outlined;
      case EdenPrState.draft:
        return Icons.radio_button_unchecked;
    }
  }

  IconData _reviewIcon() {
    switch (widget.reviewStatus) {
      case EdenPrReviewStatus.pending:
        return Icons.access_time;
      case EdenPrReviewStatus.approved:
        return Icons.check_circle_outline;
      case EdenPrReviewStatus.changesRequested:
        return Icons.highlight_off;
    }
  }

  Color _reviewColor() {
    switch (widget.reviewStatus) {
      case EdenPrReviewStatus.pending:
        return EdenColors.neutral[400]!;
      case EdenPrReviewStatus.approved:
        return EdenColors.success;
      case EdenPrReviewStatus.changesRequested:
        return EdenColors.error;
    }
  }

  Color _ciDotColor() {
    switch (widget.ciStatus) {
      case EdenPrCiStatus.passed:
        return EdenColors.success;
      case EdenPrCiStatus.failed:
        return EdenColors.error;
      case EdenPrCiStatus.running:
        return EdenColors.warning;
      case EdenPrCiStatus.pending:
        return EdenColors.neutral[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
    final subtextColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row: state icon + title + PR number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        _stateIcon(),
                        size: 18,
                        color: _stateColor(),
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Text(
                      '#${widget.number}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtextColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: EdenSpacing.space2),

                // Labels row
                if (widget.labels.isNotEmpty) ...[
                  Wrap(
                    spacing: EdenSpacing.space1,
                    runSpacing: EdenSpacing.space1,
                    children: widget.labels
                        .map((label) => _LabelPill(label: label))
                        .toList(),
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                ],

                // Metadata row: branch info, CI, review, conflicts, comments
                Row(
                  children: [
                    // Branch info
                    Icon(
                      Icons.account_tree_outlined,
                      size: 13,
                      color: subtextColor,
                    ),
                    const SizedBox(width: EdenSpacing.space1),
                    Flexible(
                      child: Text(
                        '${widget.headBranch} \u2192 ${widget.baseBranch}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: subtextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: EdenSpacing.space3),

                    // CI status dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ciDotColor(),
                      ),
                    ),

                    const SizedBox(width: EdenSpacing.space2),

                    // Review status icon
                    Icon(
                      _reviewIcon(),
                      size: 14,
                      color: _reviewColor(),
                    ),

                    // Conflict warning
                    if (widget.hasConflicts) ...[
                      const SizedBox(width: EdenSpacing.space2),
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: EdenColors.warning,
                      ),
                    ],

                    // Comment count
                    if (widget.commentCount > 0) ...[
                      const SizedBox(width: EdenSpacing.space2),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 13,
                        color: subtextColor,
                      ),
                      const SizedBox(width: EdenSpacing.space1 / 2),
                      Text(
                        '${widget.commentCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: subtextColor,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Author
                    _AuthorChip(
                      initial: widget.authorInitial,
                      name: widget.authorName,
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

class _LabelPill extends StatelessWidget {
  const _LabelPill({required this.label});

  final EdenPrLabel label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: label.color.withValues(alpha: 0.15),
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(
          color: label.color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: label.color,
          height: 1.2,
        ),
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  const _AuthorChip({
    required this.initial,
    required this.name,
    required this.isDark,
  });

  final String initial;
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final textColor =
        isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

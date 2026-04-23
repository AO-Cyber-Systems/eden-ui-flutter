import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The review status of a reviewer.
enum EdenReviewerStatus {
  /// Review has been requested but not yet started.
  pending,

  /// Reviewer approved the pull request.
  approved,

  /// Reviewer requested changes.
  changesRequested,

  /// Reviewer left comments without explicit approval or rejection.
  commented,
}

/// A reviewer on a pull request.
class EdenReviewer {
  /// Creates a reviewer model.
  const EdenReviewer({
    required this.name,
    required this.avatarInitial,
    this.reviewStatus = EdenReviewerStatus.pending,
  });

  /// The reviewer display name.
  final String name;

  /// A single character initial for the avatar.
  final String avatarInitial;

  /// The current review status.
  final EdenReviewerStatus reviewStatus;
}

/// A list widget displaying pull request reviewers with their review status.
///
/// Each reviewer row shows an avatar circle, display name, and a status
/// icon indicating their review state. A "Request review" button appears
/// at the bottom.
///
/// ```dart
/// EdenReviewerList(
///   reviewers: [
///     EdenReviewer(name: 'Alice', avatarInitial: 'A', reviewStatus: EdenReviewerStatus.approved),
///     EdenReviewer(name: 'Bob', avatarInitial: 'B', reviewStatus: EdenReviewerStatus.pending),
///   ],
///   onReviewerTap: (reviewer) {},
///   onRequestReview: () {},
/// )
/// ```
class EdenReviewerList extends StatefulWidget {
  /// Creates an Eden reviewer list.
  const EdenReviewerList({
    super.key,
    required this.reviewers,
    this.onReviewerTap,
    this.onRequestReview,
  });

  /// The list of reviewers to display.
  final List<EdenReviewer> reviewers;

  /// Called when a reviewer row is tapped.
  final ValueChanged<EdenReviewer>? onReviewerTap;

  /// Called when the "Request review" button is pressed.
  final VoidCallback? onRequestReview;

  @override
  State<EdenReviewerList> createState() => _EdenReviewerListState();
}

class _EdenReviewerListState extends State<EdenReviewerList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            child: Text(
              'Reviewers',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Divider(color: borderColor, height: 1),

          // Reviewer rows
          ...widget.reviewers.map((reviewer) => _ReviewerRow(
                reviewer: reviewer,
                onTap: widget.onReviewerTap != null
                    ? () => widget.onReviewerTap!(reviewer)
                    : null,
                isDark: isDark,
              )),

          // Request review button
          if (widget.onRequestReview != null) ...[
            Divider(color: borderColor, height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onRequestReview,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(EdenRadii.lg),
                  bottomRight: Radius.circular(EdenRadii.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space4,
                    vertical: EdenSpacing.space3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add_outlined,
                        size: 16,
                        color: EdenColors.info,
                      ),
                      const SizedBox(width: EdenSpacing.space2),
                      Text(
                        'Request review',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: EdenColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewerRow extends StatelessWidget {
  const _ReviewerRow({
    required this.reviewer,
    required this.isDark,
    this.onTap,
  });

  final EdenReviewer reviewer;
  final bool isDark;
  final VoidCallback? onTap;

  IconData _statusIcon() {
    switch (reviewer.reviewStatus) {
      case EdenReviewerStatus.pending:
        return Icons.access_time;
      case EdenReviewerStatus.approved:
        return Icons.check_circle_outline;
      case EdenReviewerStatus.changesRequested:
        return Icons.cancel_outlined;
      case EdenReviewerStatus.commented:
        return Icons.chat_bubble_outline;
    }
  }

  Color _statusColor() {
    switch (reviewer.reviewStatus) {
      case EdenReviewerStatus.pending:
        return EdenColors.neutral[400]!;
      case EdenReviewerStatus.approved:
        return EdenColors.success;
      case EdenReviewerStatus.changesRequested:
        return EdenColors.error;
      case EdenReviewerStatus.commented:
        return EdenColors.info;
    }
  }

  String _statusLabel() {
    switch (reviewer.reviewStatus) {
      case EdenReviewerStatus.pending:
        return 'Pending';
      case EdenReviewerStatus.approved:
        return 'Approved';
      case EdenReviewerStatus.changesRequested:
        return 'Changes requested';
      case EdenReviewerStatus.commented:
        return 'Commented';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
    final avatarBgColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final avatarTextColor =
        isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: avatarBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    reviewer.avatarInitial,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: avatarTextColor,
                    ),
                  ),
                ),

                const SizedBox(width: EdenSpacing.space3),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reviewer.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: EdenSpacing.space1 / 2),
                      Text(
                        _statusLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _statusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status icon
                Icon(
                  _statusIcon(),
                  size: 18,
                  color: _statusColor(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

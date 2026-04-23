import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'pull_request_detail/pr_detail_sections.dart';

/// The tab sections available in the pull request detail view.
enum EdenPrDetailTab {
  /// The conversation and timeline view.
  conversation,

  /// The list of commits in this pull request.
  commits,

  /// The files changed diff view.
  filesChanged,

  /// The CI checks and status view.
  checks,
}

/// The state of a pull request for the detail view.
enum EdenPrDetailState {
  /// Pull request is open.
  open,

  /// Pull request has been closed without merging.
  closed,

  /// Pull request has been merged.
  merged,

  /// Pull request is a draft.
  draft,
}

/// A reviewer on a pull request.
class EdenPrDetailReviewer {
  /// Creates a reviewer.
  const EdenPrDetailReviewer({
    required this.name,
    required this.initial,
    this.approved = false,
  });

  /// The reviewer display name.
  final String name;

  /// A single character initial for the avatar.
  final String initial;

  /// Whether this reviewer has approved.
  final bool approved;
}

/// An assignee on a pull request.
class EdenPrDetailAssignee {
  /// Creates an assignee.
  const EdenPrDetailAssignee({
    required this.name,
    required this.initial,
  });

  /// The assignee display name.
  final String name;

  /// A single character initial for the avatar.
  final String initial;
}

/// A label on a pull request detail.
class EdenPrDetailLabel {
  /// Creates a label.
  const EdenPrDetailLabel({
    required this.name,
    required this.color,
  });

  /// The display name.
  final String name;

  /// The label color.
  final Color color;
}

/// A linked issue reference.
class EdenPrLinkedIssue {
  /// Creates a linked issue.
  const EdenPrLinkedIssue({
    required this.number,
    required this.title,
    this.closed = false,
  });

  /// The issue number.
  final int number;

  /// The issue title.
  final String title;

  /// Whether this issue is closed.
  final bool closed;
}

/// A full-detail view for a single pull request.
///
/// Displays a header with state badge, title, and branch info; a body
/// text area; tab-like section navigation; and a metadata sidebar with
/// reviewers, assignees, labels, milestone, and linked issues.
///
/// ```dart
/// EdenPullRequestDetail(
///   number: 42,
///   title: 'Add dark mode support',
///   state: EdenPrDetailState.open,
///   authorName: 'Jane',
///   authorInitial: 'J',
///   headBranch: 'feat/dark-mode',
///   baseBranch: 'main',
///   body: 'This PR adds dark mode theming throughout the app.',
///   commitsCount: 5,
///   filesChangedCount: 12,
///   additions: 340,
///   deletions: 80,
///   activeTab: EdenPrDetailTab.conversation,
///   onTabChanged: (tab) {},
/// )
/// ```
class EdenPullRequestDetail extends StatefulWidget {
  /// Creates an Eden pull request detail view.
  const EdenPullRequestDetail({
    super.key,
    required this.number,
    required this.title,
    required this.state,
    required this.authorName,
    required this.authorInitial,
    required this.headBranch,
    required this.baseBranch,
    this.body,
    this.reviewers = const [],
    this.assignees = const [],
    this.labels = const [],
    this.milestone,
    this.linkedIssues = const [],
    this.commitsCount = 0,
    this.filesChangedCount = 0,
    this.additions = 0,
    this.deletions = 0,
    this.activeTab = EdenPrDetailTab.conversation,
    this.onTabChanged,
    this.onReviewerTap,
  });

  /// The pull request number.
  final int number;

  /// The pull request title.
  final String title;

  /// The current state of this pull request.
  final EdenPrDetailState state;

  /// The author display name.
  final String authorName;

  /// A single character initial for the author avatar.
  final String authorInitial;

  /// The source branch name.
  final String headBranch;

  /// The target branch name.
  final String baseBranch;

  /// The body / description text (supports plain text).
  final String? body;

  /// Reviewers assigned to this pull request.
  final List<EdenPrDetailReviewer> reviewers;

  /// Assignees for this pull request.
  final List<EdenPrDetailAssignee> assignees;

  /// Labels attached to this pull request.
  final List<EdenPrDetailLabel> labels;

  /// The milestone name, if any.
  final String? milestone;

  /// Issues linked to this pull request.
  final List<EdenPrLinkedIssue> linkedIssues;

  /// Number of commits in this pull request.
  final int commitsCount;

  /// Number of files changed.
  final int filesChangedCount;

  /// Total lines added.
  final int additions;

  /// Total lines deleted.
  final int deletions;

  /// The currently active tab.
  final EdenPrDetailTab activeTab;

  /// Called when the user selects a different tab.
  final ValueChanged<EdenPrDetailTab>? onTabChanged;

  /// Called when a reviewer avatar/name is tapped.
  final ValueChanged<EdenPrDetailReviewer>? onReviewerTap;

  @override
  State<EdenPullRequestDetail> createState() => _EdenPullRequestDetailState();
}

class _EdenPullRequestDetailState extends State<EdenPullRequestDetail> {
  Color _stateColor() {
    switch (widget.state) {
      case EdenPrDetailState.open:
        return EdenColors.success;
      case EdenPrDetailState.merged:
        return EdenColors.purple[500]!;
      case EdenPrDetailState.closed:
        return EdenColors.error;
      case EdenPrDetailState.draft:
        return EdenColors.neutral[400]!;
    }
  }

  String _stateLabel() {
    switch (widget.state) {
      case EdenPrDetailState.open:
        return 'Open';
      case EdenPrDetailState.merged:
        return 'Merged';
      case EdenPrDetailState.closed:
        return 'Closed';
      case EdenPrDetailState.draft:
        return 'Draft';
    }
  }

  IconData _stateIcon() {
    switch (widget.state) {
      case EdenPrDetailState.open:
        return Icons.adjust;
      case EdenPrDetailState.merged:
        return Icons.merge_type;
      case EdenPrDetailState.closed:
        return Icons.cancel_outlined;
      case EdenPrDetailState.draft:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final subtextColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

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
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // State badge + PR number
                Row(
                  children: [
                    PrStateBadge(
                      icon: _stateIcon(),
                      label: _stateLabel(),
                      color: _stateColor(),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Text(
                      '#${widget.number}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtextColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    // +/- changes summary
                    ChangesSummary(
                      additions: widget.additions,
                      deletions: widget.deletions,
                    ),
                  ],
                ),

                const SizedBox(height: EdenSpacing.space2),

                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: EdenSpacing.space2),

                // Branch info
                Row(
                  children: [
                    Icon(
                      Icons.account_tree_outlined,
                      size: 14,
                      color: subtextColor,
                    ),
                    const SizedBox(width: EdenSpacing.space1),
                    BranchChip(
                      name: widget.headBranch,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space1,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: subtextColor,
                      ),
                    ),
                    BranchChip(
                      name: widget.baseBranch,
                      isDark: isDark,
                    ),
                    const SizedBox(width: EdenSpacing.space3),
                    Text(
                      widget.authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: EdenPrDetailTab.values.map((tab) {
                return PrTabButton(
                  tab: tab,
                  isActive: widget.activeTab == tab,
                  commitsCount: widget.commitsCount,
                  filesChangedCount: widget.filesChangedCount,
                  onTap: () => widget.onTabChanged?.call(tab),
                  isDark: isDark,
                );
              }).toList(),
            ),
          ),

          // Body + sidebar row
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Body area
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(EdenSpacing.space3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? EdenColors.neutral[850]!
                          : Colors.white,
                      border: Border.all(color: borderColor),
                      borderRadius: EdenRadii.borderRadiusMd,
                    ),
                    child: Text(
                      widget.body ?? 'No description provided.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.body != null
                            ? null
                            : subtextColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: EdenSpacing.space4),

                // Metadata sidebar
                Expanded(
                  flex: 1,
                  child: MetadataSidebar(
                    reviewers: widget.reviewers,
                    assignees: widget.assignees,
                    labels: widget.labels,
                    milestone: widget.milestone,
                    linkedIssues: widget.linkedIssues,
                    onReviewerTap: widget.onReviewerTap,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


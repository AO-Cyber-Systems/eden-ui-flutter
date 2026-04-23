import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_pull_request_detail.dart';

class PrStateBadge extends StatelessWidget {
  const PrStateBadge({super.key, 
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ChangesSummary extends StatelessWidget {
  const ChangesSummary({super.key, 
    required this.additions,
    required this.deletions,
  });

  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+$additions',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: EdenColors.success,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          '-$deletions',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: EdenColors.error,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class BranchChip extends StatelessWidget {
  const BranchChip({super.key, 
    required this.name,
    required this.isDark,
  });

  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? EdenColors.blue[900]!.withValues(alpha: 0.4)
            : EdenColors.blue[50]!,
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
          color: isDark ? EdenColors.blue[300]! : EdenColors.blue[700]!,
        ),
      ),
    );
  }
}

class PrTabButton extends StatelessWidget {
  const PrTabButton({super.key, 
    required this.tab,
    required this.isActive,
    required this.commitsCount,
    required this.filesChangedCount,
    required this.onTap,
    required this.isDark,
  });

  final EdenPrDetailTab tab;
  final bool isActive;
  final int commitsCount;
  final int filesChangedCount;
  final VoidCallback onTap;
  final bool isDark;

  String _label() {
    switch (tab) {
      case EdenPrDetailTab.conversation:
        return 'Conversation';
      case EdenPrDetailTab.commits:
        return 'Commits ($commitsCount)';
      case EdenPrDetailTab.filesChanged:
        return 'Files ($filesChangedCount)';
      case EdenPrDetailTab.checks:
        return 'Checks';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : EdenColors.neutral[900]!;
    final inactiveColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Semantics(
      button: true,
      label: _label(),
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            _label(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class MetadataSidebar extends StatelessWidget {
  const MetadataSidebar({super.key, 
    required this.reviewers,
    required this.assignees,
    required this.labels,
    required this.milestone,
    required this.linkedIssues,
    required this.onReviewerTap,
    required this.isDark,
  });

  final List<EdenPrDetailReviewer> reviewers;
  final List<EdenPrDetailAssignee> assignees;
  final List<EdenPrDetailLabel> labels;
  final String? milestone;
  final List<EdenPrLinkedIssue> linkedIssues;
  final ValueChanged<EdenPrDetailReviewer>? onReviewerTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionLabelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!,
      letterSpacing: 0.5,
    );
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reviewers
        if (reviewers.isNotEmpty) ...[
          Text('REVIEWERS', style: sectionLabelStyle),
          const SizedBox(height: EdenSpacing.space2),
          ...reviewers.map((r) => ReviewerRow(
                reviewer: r,
                onTap: onReviewerTap != null
                    ? () => onReviewerTap!(r)
                    : null,
                isDark: isDark,
              )),
          const SizedBox(height: EdenSpacing.space3),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: EdenSpacing.space3),
        ],

        // Assignees
        if (assignees.isNotEmpty) ...[
          Text('ASSIGNEES', style: sectionLabelStyle),
          const SizedBox(height: EdenSpacing.space2),
          ...assignees.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
                child: Row(
                  children: [
                    PrAvatarCircle(initial: a.initial, isDark: isDark),
                    const SizedBox(width: EdenSpacing.space2),
                    Expanded(
                      child: Text(
                        a.name,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: EdenSpacing.space3),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: EdenSpacing.space3),
        ],

        // Labels
        if (labels.isNotEmpty) ...[
          Text('LABELS', style: sectionLabelStyle),
          const SizedBox(height: EdenSpacing.space2),
          Wrap(
            spacing: EdenSpacing.space1,
            runSpacing: EdenSpacing.space1,
            children: labels.map((l) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space1 / 2,
                ),
                decoration: BoxDecoration(
                  color: l.color.withValues(alpha: 0.15),
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Text(
                  l.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: l.color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: EdenSpacing.space3),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: EdenSpacing.space3),
        ],

        // Milestone
        if (milestone != null) ...[
          Text('MILESTONE', style: sectionLabelStyle),
          const SizedBox(height: EdenSpacing.space2),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 14,
                color: isDark
                    ? EdenColors.neutral[400]!
                    : EdenColors.neutral[500]!,
              ),
              const SizedBox(width: EdenSpacing.space1),
              Expanded(
                child: Text(
                  milestone!,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space3),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: EdenSpacing.space3),
        ],

        // Linked issues
        if (linkedIssues.isNotEmpty) ...[
          Text('LINKED ISSUES', style: sectionLabelStyle),
          const SizedBox(height: EdenSpacing.space2),
          ...linkedIssues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
                child: Row(
                  children: [
                    Icon(
                      issue.closed
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: issue.closed
                          ? EdenColors.purple[500]!
                          : EdenColors.success,
                    ),
                    const SizedBox(width: EdenSpacing.space1),
                    Expanded(
                      child: Text(
                        '#${issue.number} ${issue.title}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

class ReviewerRow extends StatelessWidget {
  const ReviewerRow({super.key, 
    required this.reviewer,
    required this.isDark,
    this.onTap,
  });

  final EdenPrDetailReviewer reviewer;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
      child: Semantics(
        button: onTap != null,
        label: 'Reviewer: ${reviewer.name}',
        child: InkWell(
          onTap: onTap,
          borderRadius: EdenRadii.borderRadiusSm,
          child: Row(
            children: [
              PrAvatarCircle(initial: reviewer.initial, isDark: isDark),
              const SizedBox(width: EdenSpacing.space2),
              Expanded(
                child: Text(
                  reviewer.name,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                reviewer.approved
                    ? Icons.check_circle_outline
                    : Icons.access_time,
                size: 14,
                color: reviewer.approved
                    ? EdenColors.success
                    : EdenColors.neutral[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrAvatarCircle extends StatelessWidget {
  const PrAvatarCircle({super.key, 
    required this.initial,
    required this.isDark,
  });

  final String initial;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final textColor =
        isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;

    return Container(
      width: 20,
      height: 20,
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
    );
  }
}

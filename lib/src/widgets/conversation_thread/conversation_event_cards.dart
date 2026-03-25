import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_conversation_thread.dart';
import 'conversation_shared.dart';

class CommentContent extends StatelessWidget {
  const CommentContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final surfaceColor = isDark
        ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
        : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author header
        Row(
          children: [
            Text(
              event.actorName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              'commented',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              event.timestamp,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),

        // Body card
        if (event.body != null && event.body!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EdenSpacing.space4),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: borderColor),
              borderRadius: EdenRadii.borderRadiusLg,
            ),
            child: Text(
              event.body!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

class LabelChangeContent extends StatelessWidget {
  const LabelChangeContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final action = event.metadata['action'] as String? ?? 'added';
    final labels =
        (event.metadata['labels'] as List<dynamic>?) ?? <dynamic>[];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: EdenSpacing.space1,
        runSpacing: EdenSpacing.space1,
        children: [
          Text(
            event.actorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '$action label${labels.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          for (final label in labels) LabelPill(label: label, isDark: isDark),
          Text(
            event.timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class AssignmentContent extends StatelessWidget {
  const AssignmentContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final action = event.metadata['action'] as String? ?? 'assigned';
    final assigneeName =
        event.metadata['assigneeName'] as String? ?? 'someone';
    final assigneeInitial =
        event.metadata['assigneeInitial'] as String? ?? assigneeName[0];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        children: [
          Text(
            event.actorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            action,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 8,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              assigneeInitial,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            assigneeName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            event.timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class StatusChangeContent extends StatelessWidget {
  const StatusChangeContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final status = event.metadata['status'] as String? ?? 'closed';
    final isClosed = status == 'closed';
    final statusColor =
        isClosed ? EdenColors.purple[500]! : EdenColors.emerald[500]!;
    final statusIcon = isClosed
        ? Icons.cancel_outlined
        : Icons.check_circle_outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(
            event.actorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$status this',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const Spacer(),
          Text(
            event.timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class CommitRefContent extends StatelessWidget {
  const CommitRefContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final commits =
        (event.metadata['commits'] as List<dynamic>?) ?? <dynamic>[];
    final commitCount = commits.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                event.actorName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'pushed $commitCount commit${commitCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const Spacer(),
              Text(
                event.timestamp,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),

          // Show abbreviated SHAs
          if (commits.isNotEmpty) ...[
            const SizedBox(height: EdenSpacing.space1),
            for (final commit in commits)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CommitLine(
                  commit: commit as Map<String, dynamic>,
                  isDark: isDark,
                  theme: theme,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class CommitLine extends StatelessWidget {
  const CommitLine({
    required this.commit,
    required this.isDark,
    required this.theme,
  });

  final Map<String, dynamic> commit;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final sha = (commit['sha'] as String? ?? '').length >= 7
        ? (commit['sha'] as String).substring(0, 7)
        : commit['sha'] as String? ?? '';
    final message = commit['message'] as String? ?? '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isDark
                ? EdenColors.neutral[700]!.withValues(alpha: 0.6)
                : EdenColors.neutral[100]!,
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Text(
            sha,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class CrossRefContent extends StatelessWidget {
  const CrossRefContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final refNumber = event.metadata['refNumber'] as String? ?? '';
    final refTitle = event.metadata['refTitle'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        children: [
          Text(
            event.actorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'referenced this in',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(width: 4),
          Text(
            '#$refNumber',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (refTitle.isNotEmpty) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                refTitle,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(width: EdenSpacing.space2),
          Text(
            event.timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class ReviewSummaryContent extends StatelessWidget {
  const ReviewSummaryContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final verdict = event.metadata['verdict'] as String? ?? 'commented';
    final summaryBody = event.metadata['summaryBody'] as String? ?? '';
    final inlineCount =
        event.metadata['inlineCommentCount'] as int? ?? 0;

    final verdictColor = _verdictToColor(verdict);
    final verdictLabel = _verdictToLabel(verdict);
    final verdictIcon = _verdictToIcon(verdict);

    final surfaceColor = isDark
        ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
        : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header line
        Row(
          children: [
            Text(
              event.actorName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: verdictColor.withValues(alpha: 0.12),
                borderRadius: EdenRadii.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(verdictIcon, size: 12, color: verdictColor),
                  const SizedBox(width: 3),
                  Text(
                    verdictLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: verdictColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              event.timestamp,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),

        // Body
        if (summaryBody.isNotEmpty) ...[
          const SizedBox(height: EdenSpacing.space2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EdenSpacing.space3),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                left: BorderSide(color: verdictColor, width: 3),
                top: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
              borderRadius: EdenRadii.borderRadiusMd,
            ),
            child: Text(
              summaryBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],

        // Inline comment count
        if (inlineCount > 0) ...[
          const SizedBox(height: EdenSpacing.space1),
          Text(
            '$inlineCount inline comment${inlineCount == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }

  static Color _verdictToColor(String verdict) {
    switch (verdict) {
      case 'approved':
        return EdenColors.emerald[600]!;
      case 'changesRequested':
        return EdenColors.red[600]!;
      case 'commented':
        return EdenColors.blue[600]!;
      case 'dismissed':
        return EdenColors.neutral[500]!;
      default:
        return EdenColors.neutral[500]!;
    }
  }

  static String _verdictToLabel(String verdict) {
    switch (verdict) {
      case 'approved':
        return 'Approved';
      case 'changesRequested':
        return 'Changes requested';
      case 'commented':
        return 'Commented';
      case 'dismissed':
        return 'Dismissed';
      default:
        return verdict;
    }
  }

  static IconData _verdictToIcon(String verdict) {
    switch (verdict) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'changesRequested':
        return Icons.error_outline;
      case 'commented':
        return Icons.chat_bubble_outline;
      case 'dismissed':
        return Icons.remove_circle_outline;
      default:
        return Icons.circle;
    }
  }
}

class MergeContent extends StatelessWidget {
  const MergeContent({
    required this.event,
    required this.isDark,
    required this.theme,
  });

  final EdenConversationEvent event;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final commitSha = event.metadata['commitSha'] as String? ?? '';
    final baseBranch = event.metadata['baseBranch'] as String? ?? 'main';
    final shortSha =
        commitSha.length >= 7 ? commitSha.substring(0, 7) : commitSha;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Row(
        children: [
          Icon(Icons.merge, size: 16, color: EdenColors.purple[500]),
          const SizedBox(width: 4),
          Text(
            event.actorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'merged commit',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(width: 4),
          if (shortSha.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isDark
                    ? EdenColors.neutral[700]!.withValues(alpha: 0.6)
                    : EdenColors.neutral[100]!,
                borderRadius: EdenRadii.borderRadiusSm,
              ),
              child: Text(
                shortSha,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: EdenColors.purple[500],
                ),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            'into',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark
                  ? EdenColors.neutral[700]!.withValues(alpha: 0.6)
                  : EdenColors.neutral[100]!,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              baseBranch,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            event.timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

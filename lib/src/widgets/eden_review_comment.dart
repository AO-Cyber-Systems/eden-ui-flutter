import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single review comment (or reply) on a code review.
class EdenReviewCommentData {
  const EdenReviewCommentData({
    required this.id,
    required this.authorName,
    required this.authorInitial,
    required this.body,
    required this.timestamp,
    this.filePath,
    this.startLine,
    this.endLine,
    this.isResolved = false,
    this.replies = const [],
    this.reactionCounts = const {},
  });

  final String id;
  final String authorName;
  final String authorInitial;
  final String body;
  final String timestamp;
  final String? filePath;
  final int? startLine;
  final int? endLine;
  final bool isResolved;
  final List<EdenReviewCommentData> replies;
  final Map<String, int> reactionCounts;
}

/// A code-review comment with author header, body, file reference, resolve
/// toggle, threaded replies, and reaction summary.
class EdenReviewComment extends StatefulWidget {
  const EdenReviewComment({
    super.key,
    required this.data,
    this.onResolve,
    this.onReply,
    this.onReactionTap,
    this.onFileReferenceTap,
  });

  final EdenReviewCommentData data;

  /// Called when the resolve / unresolve toggle is pressed.
  final ValueChanged<bool>? onResolve;

  /// Called when the user taps the Reply button.
  final VoidCallback? onReply;

  /// Called when a reaction emoji chip is tapped.
  final ValueChanged<String>? onReactionTap;

  /// Called when the file-path + line-range reference is tapped.
  final VoidCallback? onFileReferenceTap;

  @override
  State<EdenReviewComment> createState() => _EdenReviewCommentState();
}

class _EdenReviewCommentState extends State<EdenReviewComment> {
  bool _repliesExpanded = true;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final comment = widget.data;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(theme, isDark, comment),

              // File reference
              if (comment.filePath != null)
                _buildFileReference(theme, isDark, comment),

              // Body
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space4,
                  vertical: EdenSpacing.space3,
                ),
                child: Text(
                  comment.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),

              // Reactions
              if (comment.reactionCounts.isNotEmpty)
                _buildReactions(theme, isDark, comment),

              // Actions row
              _buildActions(theme, isDark, comment),
            ],
          ),
        ),

        // Reply thread
        if (comment.replies.isNotEmpty) _buildReplyThread(theme, isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    EdenReviewCommentData comment,
  ) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EdenSpacing.space4,
        EdenSpacing.space3,
        EdenSpacing.space4,
        0,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              comment.authorInitial,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),

          // Name
          Text(
            comment.authorName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),

          // Timestamp
          Text(
            comment.timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),

          const Spacer(),

          // Resolved badge
          if (comment.isResolved)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space2,
                vertical: EdenSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: EdenColors.emerald.withValues(alpha: 0.12),
                borderRadius: EdenRadii.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: EdenColors.emerald[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: EdenColors.emerald[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // File reference
  // ---------------------------------------------------------------------------

  Widget _buildFileReference(
    ThemeData theme,
    bool isDark,
    EdenReviewCommentData comment,
  ) {
    final lineRange = _formatLineRange(comment);
    final refText = lineRange != null
        ? '${comment.filePath}$lineRange'
        : comment.filePath!;

    return GestureDetector(
      onTap: widget.onFileReferenceTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EdenSpacing.space4,
          EdenSpacing.space2,
          EdenSpacing.space4,
          0,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? EdenColors.neutral[700]!.withValues(alpha: 0.6)
                : EdenColors.neutral[100]!,
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  refText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatLineRange(EdenReviewCommentData comment) {
    if (comment.startLine == null) return null;
    if (comment.endLine != null && comment.endLine != comment.startLine) {
      return ':${comment.startLine}-${comment.endLine}';
    }
    return ':${comment.startLine}';
  }

  // ---------------------------------------------------------------------------
  // Reactions
  // ---------------------------------------------------------------------------

  Widget _buildReactions(
    ThemeData theme,
    bool isDark,
    EdenReviewCommentData comment,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      child: Wrap(
        spacing: EdenSpacing.space1,
        runSpacing: EdenSpacing.space1,
        children: comment.reactionCounts.entries.map((entry) {
          return GestureDetector(
            onTap: widget.onReactionTap != null
                ? () => widget.onReactionTap!(entry.key)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? EdenColors.neutral[700]!.withValues(alpha: 0.6)
                    : EdenColors.neutral[100]!,
                borderRadius: EdenRadii.borderRadiusFull,
                border: Border.all(
                  color: isDark
                      ? EdenColors.neutral[600]!
                      : EdenColors.neutral[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text(
                    '${entry.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? EdenColors.neutral[300]
                          : EdenColors.neutral[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Widget _buildActions(
    ThemeData theme,
    bool isDark,
    EdenReviewCommentData comment,
  ) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EdenSpacing.space3,
        EdenSpacing.space2,
        EdenSpacing.space3,
        EdenSpacing.space3,
      ),
      child: Row(
        children: [
          // Reply button
          _ActionButton(
            icon: Icons.reply,
            label: 'Reply',
            color: muted,
            onTap: widget.onReply,
          ),
          const SizedBox(width: EdenSpacing.space3),

          // Resolve / unresolve toggle
          _ActionButton(
            icon: comment.isResolved
                ? Icons.refresh
                : Icons.check_circle_outline,
            label: comment.isResolved ? 'Unresolve' : 'Resolve',
            color: comment.isResolved ? muted : EdenColors.emerald[600]!,
            onTap: widget.onResolve != null
                ? () => widget.onResolve!(!comment.isResolved)
                : null,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reply thread
  // ---------------------------------------------------------------------------

  Widget _buildReplyThread(ThemeData theme, bool isDark) {
    final timelineColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Padding(
      padding: const EdgeInsets.only(left: EdenSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          if (widget.data.replies.length > 1)
            GestureDetector(
              onTap: () => setState(() => _repliesExpanded = !_repliesExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _repliesExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _repliesExpanded
                          ? 'Hide replies'
                          : '${widget.data.replies.length} replies',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_repliesExpanded)
            ...widget.data.replies.map((reply) {
              return Padding(
                padding: const EdgeInsets.only(top: EdenSpacing.space2),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Vertical connector
                      Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: timelineColor,
                          borderRadius: EdenRadii.borderRadiusFull,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space3),

                      // Reply content
                      Expanded(
                        child: _ReplyBubble(
                          reply: reply,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// =============================================================================
// Private helpers
// =============================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({
    required this.reply,
    required this.isDark,
    required this.theme,
  });

  final EdenReviewCommentData reply;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author + timestamp
        Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                reply.authorInitial,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              reply.authorName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              reply.timestamp,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space1),

        // Body
        Text(
          reply.body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

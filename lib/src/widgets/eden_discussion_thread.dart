import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A discussion post model (Q&A style).
class EdenDiscussion {
  /// Creates a discussion model.
  const EdenDiscussion({
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorInitial,
    required this.createdAt,
    this.category,
    this.upvoteCount = 0,
    this.answerCount = 0,
  });

  /// Discussion title.
  final String title;

  /// Discussion body text.
  final String body;

  /// Author display name.
  final String authorName;

  /// Author initial for the avatar.
  final String authorInitial;

  /// Creation date string.
  final String createdAt;

  /// Optional category label (e.g. "Q&A", "Ideas", "General").
  final String? category;

  /// Number of upvotes on the original post.
  final int upvoteCount;

  /// Number of answers/replies.
  final int answerCount;
}

/// A reply to a discussion thread.
class EdenDiscussionReply {
  /// Creates a discussion reply model.
  const EdenDiscussionReply({
    required this.id,
    required this.body,
    required this.authorName,
    required this.authorInitial,
    required this.createdAt,
    this.isAcceptedAnswer = false,
    this.upvoteCount = 0,
  });

  /// Unique identifier for this reply.
  final String id;

  /// Reply body text.
  final String body;

  /// Author display name.
  final String authorName;

  /// Author initial for the avatar.
  final String authorInitial;

  /// Creation date string.
  final String createdAt;

  /// Whether this reply is the accepted answer.
  final bool isAcceptedAnswer;

  /// Number of upvotes on this reply.
  final int upvoteCount;
}

/// A Q&A discussion thread with original post, upvotes, and replies.
///
/// Displays the original discussion post with title, body, author, and category
/// badge, followed by a list of replies. Accepted answers are highlighted with
/// a green left border and checkmark.
class EdenDiscussionThread extends StatefulWidget {
  /// Creates an Eden discussion thread.
  const EdenDiscussionThread({
    super.key,
    required this.discussion,
    this.replies = const [],
    this.onUpvote,
    this.onReply,
    this.onAcceptAnswer,
  });

  /// The original discussion post.
  final EdenDiscussion discussion;

  /// List of replies to the discussion.
  final List<EdenDiscussionReply> replies;

  /// Called when the upvote button on the original post is pressed.
  final VoidCallback? onUpvote;

  /// Called when the reply button is pressed.
  final VoidCallback? onReply;

  /// Called when a reply is accepted as the answer, with the reply id.
  final ValueChanged<String>? onAcceptAnswer;

  @override
  State<EdenDiscussionThread> createState() => _EdenDiscussionThreadState();
}

class _EdenDiscussionThreadState extends State<EdenDiscussionThread> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Original post
        _buildOriginalPost(theme, isDark, borderColor),
        const SizedBox(height: EdenSpacing.space3),

        // Reply count + reply button
        _buildReplyHeader(theme, isDark),
        const SizedBox(height: EdenSpacing.space2),

        // Replies
        for (int i = 0; i < widget.replies.length; i++) ...[
          if (i > 0) const SizedBox(height: EdenSpacing.space2),
          _ReplyCard(
            reply: widget.replies[i],
            isDark: isDark,
            borderColor: borderColor,
            onAcceptAnswer: widget.onAcceptAnswer != null
                ? () => widget.onAcceptAnswer!(widget.replies[i].id)
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildOriginalPost(
    ThemeData theme,
    bool isDark,
    Color borderColor,
  ) {
    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category badge + title
            if (widget.discussion.category != null) ...[
              _CategoryBadge(category: widget.discussion.category!),
              const SizedBox(height: EdenSpacing.space2),
            ],
            Text(
              widget.discussion.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: EdenSpacing.space3),

            // Body
            Text(
              widget.discussion.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: EdenSpacing.space4),

            // Author row + upvote
            Row(
              children: [
                // Upvote button
                _UpvoteButton(
                  count: widget.discussion.upvoteCount,
                  isDark: isDark,
                  onTap: widget.onUpvote,
                ),
                const Spacer(),
                // Author
                _AuthorRow(
                  name: widget.discussion.authorName,
                  initial: widget.discussion.authorInitial,
                  date: widget.discussion.createdAt,
                  isDark: isDark,
                  mutedText: mutedText,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyHeader(ThemeData theme, bool isDark) {
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final count = widget.replies.length;

    return Row(
      children: [
        Icon(Icons.forum_outlined, size: 18, color: mutedText),
        const SizedBox(width: EdenSpacing.space2),
        Text(
          '$count ${count == 1 ? 'Reply' : 'Replies'}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (widget.onReply != null)
          SizedBox(
            height: 32,
            child: Material(
              color: EdenColors.info.withValues(alpha: 0.12),
              borderRadius: EdenRadii.borderRadiusSm,
              child: InkWell(
                onTap: widget.onReply,
                borderRadius: EdenRadii.borderRadiusSm,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.reply, size: 14, color: EdenColors.info),
                      SizedBox(width: EdenSpacing.space1),
                      Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EdenColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.reply,
    required this.isDark,
    required this.borderColor,
    this.onAcceptAnswer,
  });

  final EdenDiscussionReply reply;
  final bool isDark;
  final Color borderColor;
  final VoidCallback? onAcceptAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    final isAccepted = reply.isAcceptedAnswer;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(
          color: isAccepted ? EdenColors.success.withValues(alpha: 0.5) : borderColor,
        ),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green left border for accepted answer
          if (isAccepted)
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: EdenColors.success,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(EdenRadii.md),
                  bottomLeft: Radius.circular(EdenRadii.md),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accepted answer indicator
                  if (isAccepted) ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: EdenColors.success),
                        SizedBox(width: EdenSpacing.space1),
                        Text(
                          'Accepted Answer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: EdenColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EdenSpacing.space2),
                  ],

                  // Body
                  Text(
                    reply.body,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: EdenSpacing.space3),

                  // Footer: upvote, accept button, author
                  Row(
                    children: [
                      _UpvoteButton(
                        count: reply.upvoteCount,
                        isDark: isDark,
                        onTap: null,
                      ),
                      if (!isAccepted && onAcceptAnswer != null) ...[
                        const SizedBox(width: EdenSpacing.space2),
                        SizedBox(
                          height: 28,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: EdenRadii.borderRadiusSm,
                            child: InkWell(
                              onTap: onAcceptAnswer,
                              borderRadius: EdenRadii.borderRadiusSm,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: EdenSpacing.space2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: mutedText,
                                    ),
                                    const SizedBox(width: EdenSpacing.space1),
                                    Text(
                                      'Accept',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: mutedText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _AuthorRow(
                        name: reply.authorName,
                        initial: reply.authorInitial,
                        date: reply.createdAt,
                        isDark: isDark,
                        mutedText: mutedText,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpvoteButton extends StatelessWidget {
  const _UpvoteButton({
    required this.count,
    required this.isDark,
    this.onTap,
  });

  final int count;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final textColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return SizedBox(
      height: 28,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: EdenRadii.borderRadiusSm,
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: EdenRadii.borderRadiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, size: 14, color: textColor),
                const SizedBox(width: EdenSpacing.space1),
                Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.name,
    required this.initial,
    required this.date,
    required this.isDark,
    required this.mutedText,
    required this.theme,
  });

  final String name;
  final String initial;
  final String date;
  final bool isDark;
  final Color mutedText;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final avatarBg =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: mutedText,
              ),
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Text(
          date,
          style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  Color _categoryColor() {
    switch (category.toLowerCase()) {
      case 'q&a':
        return EdenColors.info;
      case 'ideas':
        return EdenColors.purple[500]!;
      case 'announcements':
        return EdenColors.warning;
      case 'show and tell':
        return EdenColors.success;
      default:
        return EdenColors.neutral[500]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

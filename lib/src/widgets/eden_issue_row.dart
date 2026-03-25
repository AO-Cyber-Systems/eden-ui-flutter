import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The state of an issue.
enum EdenIssueState {
  /// Issue is open.
  open,

  /// Issue is closed.
  closed,
}

/// A label model with a name and color.
class EdenIssueLabel {
  /// Creates a label.
  const EdenIssueLabel({
    required this.name,
    required this.color,
  });

  /// The label display name.
  final String name;

  /// The label background color.
  final Color color;
}

/// A compact row displaying a single issue entry.
///
/// Shows open/closed state icon, title, inline labels, assignee avatars,
/// comment count, and milestone info.
class EdenIssueRow extends StatefulWidget {
  /// Creates an issue row widget.
  const EdenIssueRow({
    super.key,
    required this.number,
    required this.title,
    required this.state,
    required this.createdAt,
    this.labels = const [],
    this.assigneeInitials = const [],
    this.commentCount = 0,
    this.milestone,
    this.onTap,
  });

  /// The issue number.
  final int number;

  /// The issue title.
  final String title;

  /// The current state of the issue.
  final EdenIssueState state;

  /// When the issue was created.
  final DateTime createdAt;

  /// Labels applied to this issue.
  final List<EdenIssueLabel> labels;

  /// List of initials for assigned users.
  final List<String> assigneeInitials;

  /// Number of comments on the issue.
  final int commentCount;

  /// Optional milestone name.
  final String? milestone;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenIssueRow> createState() => _EdenIssueRowState();
}

class _EdenIssueRowState extends State<EdenIssueRow> {
  String get _relativeTime {
    final now = DateTime.now();
    final diff = now.difference(widget.createdAt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final mo = diff.inDays ~/ 30;
      return '$mo month${mo == 1 ? '' : 's'} ago';
    }
    final y = diff.inDays ~/ 365;
    return '$y year${y == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // State icon
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _buildStateIcon(),
                  ),
                  const SizedBox(width: EdenSpacing.space3),

                  // Title + labels + metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row with inline labels
                        _buildTitleRow(theme),
                        const SizedBox(height: EdenSpacing.space1),
                        // Metadata row
                        _buildMetadataRow(theme, mutedColor),
                      ],
                    ),
                  ),

                  // Right side: assignee avatars
                  if (widget.assigneeInitials.isNotEmpty) ...[
                    const SizedBox(width: EdenSpacing.space3),
                    _buildAssigneeAvatars(isDark),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    if (widget.state == EdenIssueState.open) {
      return const Icon(
        Icons.radio_button_checked,
        size: 18,
        color: EdenColors.success,
      );
    }
    return const Icon(
      Icons.check_circle,
      size: 18,
      color: EdenColors.purple,
    );
  }

  Widget _buildTitleRow(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space1,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        ...widget.labels.map((label) => _InlineLabel(label: label)),
      ],
    );
  }

  Widget _buildMetadataRow(ThemeData theme, Color mutedColor) {
    return Row(
      children: [
        Text(
          '#${widget.number}',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Text(
          'opened $_relativeTime',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        if (widget.milestone != null) ...[
          const SizedBox(width: EdenSpacing.space3),
          Icon(Icons.flag_outlined, size: 14, color: mutedColor),
          const SizedBox(width: 2),
          Text(
            widget.milestone!,
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        ],
        if (widget.commentCount > 0) ...[
          const SizedBox(width: EdenSpacing.space3),
          Icon(Icons.chat_bubble_outline, size: 14, color: mutedColor),
          const SizedBox(width: 2),
          Text(
            '${widget.commentCount}',
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        ],
      ],
    );
  }

  Widget _buildAssigneeAvatars(bool isDark) {
    final bgColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final fgColor = isDark ? EdenColors.neutral[200]! : EdenColors.neutral[700]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.assigneeInitials.take(3).map((initial) {
        return Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial.isNotEmpty ? initial[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InlineLabel extends StatelessWidget {
  const _InlineLabel({required this.label});

  final EdenIssueLabel label;

  @override
  Widget build(BuildContext context) {
    final textColor =
        label.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: label.color,
        borderRadius: BorderRadius.circular(EdenRadii.full),
      ),
      child: Text(
        label.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The state of an issue for the detail view.
enum EdenIssueDetailState {
  /// Issue is open.
  open,

  /// Issue is closed.
  closed,
}

/// A linked pull request summary.
class EdenLinkedPR {
  /// Creates a linked PR model.
  const EdenLinkedPR({
    required this.number,
    required this.title,
    this.isMerged = false,
  });

  /// The PR number.
  final int number;

  /// The PR title.
  final String title;

  /// Whether the PR has been merged.
  final bool isMerged;
}

/// A label with name and color for the detail view.
class EdenIssueDetailLabel {
  /// Creates a label.
  const EdenIssueDetailLabel({
    required this.name,
    required this.color,
  });

  /// The label name.
  final String name;

  /// The label color.
  final Color color;
}

/// A detailed view of a single issue.
///
/// Shows issue title, rendered body, state badge, and a metadata sidebar
/// with labels, assignees, milestone, and linked PRs.
class EdenIssueDetail extends StatefulWidget {
  /// Creates an issue detail widget.
  const EdenIssueDetail({
    super.key,
    required this.number,
    required this.title,
    required this.state,
    required this.author,
    required this.createdAt,
    this.body,
    this.labels = const [],
    this.assignees = const [],
    this.milestone,
    this.linkedPRs = const [],
    this.onLabelTap,
    this.onAssigneeTap,
    this.onMilestoneTap,
    this.onLinkedPRTap,
  });

  /// The issue number.
  final int number;

  /// The issue title.
  final String title;

  /// The current state.
  final EdenIssueDetailState state;

  /// The issue author name.
  final String author;

  /// When the issue was created.
  final DateTime createdAt;

  /// Optional body widget (consumer handles markdown rendering).
  final Widget? body;

  /// Labels on this issue.
  final List<EdenIssueDetailLabel> labels;

  /// Assignee names.
  final List<String> assignees;

  /// Milestone name.
  final String? milestone;

  /// Linked pull requests.
  final List<EdenLinkedPR> linkedPRs;

  /// Called when a label is tapped.
  final ValueChanged<EdenIssueDetailLabel>? onLabelTap;

  /// Called when an assignee is tapped.
  final ValueChanged<String>? onAssigneeTap;

  /// Called when the milestone is tapped.
  final VoidCallback? onMilestoneTap;

  /// Called when a linked PR is tapped.
  final ValueChanged<EdenLinkedPR>? onLinkedPRTap;

  @override
  State<EdenIssueDetail> createState() => _EdenIssueDetailState();
}

class _EdenIssueDetailState extends State<EdenIssueDetail> {
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
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with state badge
            _buildHeader(theme, isDark),
            const SizedBox(height: EdenSpacing.space2),

            // Author + time
            _buildAuthorLine(theme, mutedColor),
            const SizedBox(height: EdenSpacing.space4),

            // Main content + sidebar
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Body
                  Expanded(
                    flex: 3,
                    child: widget.body ??
                        Text(
                          'No description provided.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  ),
                  const SizedBox(width: EdenSpacing.space5),

                  // Metadata sidebar
                  SizedBox(
                    width: 220,
                    child: _buildSidebar(theme, isDark, mutedColor, borderColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '${widget.title} #${widget.number}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space3),
        _buildStateBadge(theme),
      ],
    );
  }

  Widget _buildStateBadge(ThemeData theme) {
    final isOpen = widget.state == EdenIssueDetailState.open;
    final color = isOpen ? EdenColors.success : EdenColors.purple;
    final label = isOpen ? 'Open' : 'Closed';
    final icon = isOpen ? Icons.radio_button_checked : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EdenRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorLine(ThemeData theme, Color mutedColor) {
    return Text(
      '${widget.author} opened this issue on '
      '${_formatDate(widget.createdAt)}',
      style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
    );
  }

  Widget _buildSidebar(
    ThemeData theme,
    bool isDark,
    Color mutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Labels
        _buildSidebarSection(
          theme: theme,
          title: 'Labels',
          mutedColor: mutedColor,
          borderColor: borderColor,
          child: widget.labels.isEmpty
              ? Text('None', style: TextStyle(fontSize: 13, color: mutedColor))
              : Wrap(
                  spacing: EdenSpacing.space1,
                  runSpacing: EdenSpacing.space1,
                  children: widget.labels.map((label) {
                    final textColor = label.color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onLabelTap != null
                            ? () => widget.onLabelTap!(label)
                            : null,
                        borderRadius: BorderRadius.circular(EdenRadii.full),
                        child: Container(
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
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: EdenSpacing.space3),

        // Assignees
        _buildSidebarSection(
          theme: theme,
          title: 'Assignees',
          mutedColor: mutedColor,
          borderColor: borderColor,
          child: widget.assignees.isEmpty
              ? Text('None', style: TextStyle(fontSize: 13, color: mutedColor))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: widget.assignees.map((name) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onAssigneeTap != null
                              ? () => widget.onAssigneeTap!(name)
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MiniAvatar(initial: name, isDark: isDark),
                              const SizedBox(width: EdenSpacing.space2),
                              Text(
                                name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: EdenSpacing.space3),

        // Milestone
        _buildSidebarSection(
          theme: theme,
          title: 'Milestone',
          mutedColor: mutedColor,
          borderColor: borderColor,
          child: widget.milestone == null
              ? Text('None', style: TextStyle(fontSize: 13, color: mutedColor))
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onMilestoneTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined, size: 14, color: mutedColor),
                        const SizedBox(width: EdenSpacing.space1),
                        Text(
                          widget.milestone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: EdenSpacing.space3),

        // Linked PRs
        if (widget.linkedPRs.isNotEmpty)
          _buildSidebarSection(
            theme: theme,
            title: 'Linked Pull Requests',
            mutedColor: mutedColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: widget.linkedPRs.map((pr) {
                final prColor =
                    pr.isMerged ? EdenColors.purple : EdenColors.success;
                return Padding(
                  padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onLinkedPRTap != null
                          ? () => widget.onLinkedPRTap!(pr)
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pr.isMerged
                                ? Icons.merge
                                : Icons.call_merge,
                            size: 14,
                            color: prColor,
                          ),
                          const SizedBox(width: EdenSpacing.space1),
                          Flexible(
                            child: Text(
                              '#${pr.number} ${pr.title}',
                              style: theme.textTheme.bodySmall?.copyWith(
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
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarSection({
    required ThemeData theme,
    required String title,
    required Color mutedColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        child,
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

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.initial,
    required this.isDark,
  });

  final String initial;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final fgColor = isDark ? EdenColors.neutral[200]! : EdenColors.neutral[700]!;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.isNotEmpty ? initial[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}

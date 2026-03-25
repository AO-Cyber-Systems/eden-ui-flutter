import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Enums & models
// ---------------------------------------------------------------------------

/// The type of an activity feed entry.
enum EdenActivityType {
  comment,
  statusChange,
  assignment,
  upload,
  approval,
  system,
}

/// A single activity entry in the feed.
class EdenActivity {
  const EdenActivity({
    required this.id,
    required this.type,
    required this.actorName,
    this.actorAvatarInitial,
    required this.timestamp,
    required this.title,
    this.body,
    this.metadata = const {},
  });

  /// Unique identifier.
  final String id;

  /// Activity type determines icon and color.
  final EdenActivityType type;

  /// Name of the person who performed the action.
  final String actorName;

  /// Optional single-character initial for the avatar. Defaults to first
  /// letter of [actorName].
  final String? actorAvatarInitial;

  /// When this activity occurred.
  final DateTime timestamp;

  /// Short summary line (e.g. "Approved the document").
  final String title;

  /// Optional rich body text. Supports @mentions (words prefixed with @).
  final String? body;

  /// Arbitrary metadata map for extensions.
  final Map<String, String> metadata;
}

/// Callback when a @mention is tapped.
typedef MentionTapCallback = void Function(String mention);

// ---------------------------------------------------------------------------
// EdenActivityFeed
// ---------------------------------------------------------------------------

/// A rich activity feed / timeline widget with date grouping, type filters,
/// pagination, and collapsible system event batches.
class EdenActivityFeed extends StatefulWidget {
  const EdenActivityFeed({
    super.key,
    required this.activities,
    this.onActivityTap,
    this.onMentionTap,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.useRelativeTime = true,
    this.emptyMessage = 'No activity yet.',
    this.systemBatchThreshold = 3,
  });

  /// All activities to display.
  final List<EdenActivity> activities;

  /// Called when a feed item is tapped.
  final ValueChanged<EdenActivity>? onActivityTap;

  /// Called when a @mention in a body is tapped.
  final MentionTapCallback? onMentionTap;

  /// Called when the user requests more data.
  final VoidCallback? onLoadMore;

  /// Whether there are more items to load.
  final bool hasMore;

  /// Whether a load-more request is currently in flight.
  final bool isLoadingMore;

  /// Show relative timestamps ("2h ago") vs absolute ("Mar 20, 3:15 PM").
  final bool useRelativeTime;

  /// Message shown when there are no activities.
  final String emptyMessage;

  /// Number of consecutive system events that triggers batching.
  final int systemBatchThreshold;

  @override
  State<EdenActivityFeed> createState() => _EdenActivityFeedState();
}

class _EdenActivityFeedState extends State<EdenActivityFeed> {
  final Set<EdenActivityType> _activeFilters = {};
  final Set<String> _expandedBatches = {};

  List<EdenActivity> get _filteredActivities {
    if (_activeFilters.isEmpty) return widget.activities;
    return widget.activities
        .where((a) => _activeFilters.contains(a.type))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Date grouping helpers
  // ---------------------------------------------------------------------------

  static String _dateGroupLabel(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return _weekdayName(date.weekday);

    return _formatDate(date);
  }

  static String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _relativeTime(DateTime timestamp, DateTime now) {
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(timestamp);
  }

  static String _absoluteTime(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  // ---------------------------------------------------------------------------
  // Activity type visuals
  // ---------------------------------------------------------------------------

  static IconData _iconForType(EdenActivityType type) {
    switch (type) {
      case EdenActivityType.comment:
        return Icons.chat_bubble_outline;
      case EdenActivityType.statusChange:
        return Icons.swap_horiz;
      case EdenActivityType.assignment:
        return Icons.person_add_alt_1_outlined;
      case EdenActivityType.upload:
        return Icons.upload_file_outlined;
      case EdenActivityType.approval:
        return Icons.thumb_up_alt_outlined;
      case EdenActivityType.system:
        return Icons.settings_outlined;
    }
  }

  static Color _colorForType(EdenActivityType type) {
    switch (type) {
      case EdenActivityType.comment:
        return EdenColors.blue;
      case EdenActivityType.statusChange:
        return EdenColors.purple;
      case EdenActivityType.assignment:
        return EdenColors.emerald;
      case EdenActivityType.upload:
        return EdenColors.gold;
      case EdenActivityType.approval:
        return EdenColors.emerald[600]!;
      case EdenActivityType.system:
        return EdenColors.slate;
    }
  }

  static String _typeLabel(EdenActivityType type) {
    switch (type) {
      case EdenActivityType.comment:
        return 'Comments';
      case EdenActivityType.statusChange:
        return 'Status';
      case EdenActivityType.assignment:
        return 'Assignments';
      case EdenActivityType.upload:
        return 'Uploads';
      case EdenActivityType.approval:
        return 'Approvals';
      case EdenActivityType.system:
        return 'System';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activities = _filteredActivities;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final feedBody = activities.isEmpty
            ? _buildEmptyState(theme, isDark)
            : _buildFeed(activities, theme, isDark, shrinkWrap: !hasBoundedHeight);
        final wrappedBody = hasBoundedHeight
            ? Expanded(child: feedBody)
            : feedBody;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Filter chips
            _buildFilterChips(theme, isDark),
            const SizedBox(height: EdenSpacing.space3),
            // Feed body
            wrappedBody,
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
      child: Row(
        children: [
          for (final type in EdenActivityType.values) ...[
            _FilterChip(
              label: _typeLabel(type),
              color: _colorForType(type),
              selected: _activeFilters.contains(type),
              isDark: isDark,
              onTap: () {
                setState(() {
                  if (_activeFilters.contains(type)) {
                    _activeFilters.remove(type);
                  } else {
                    _activeFilters.add(type);
                  }
                });
              },
            ),
            const SizedBox(width: EdenSpacing.space2),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: isDark ? EdenColors.neutral[600] : EdenColors.neutral[300],
          ),
          const SizedBox(height: EdenSpacing.space3),
          Text(
            widget.emptyMessage,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? EdenColors.neutral[400]
                  : EdenColors.neutral[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(
    List<EdenActivity> activities,
    ThemeData theme,
    bool isDark, {
    bool shrinkWrap = false,
  }) {
    final now = DateTime.now();
    final children = <Widget>[];
    String? lastGroup;

    // Build items, grouping by date and batching system events.
    int i = 0;
    while (i < activities.length) {
      final activity = activities[i];

      // Date separator
      final groupLabel = _dateGroupLabel(activity.timestamp, now);
      if (groupLabel != lastGroup) {
        lastGroup = groupLabel;
        children.add(_DateSeparator(label: groupLabel, isDark: isDark));
      }

      // Batch consecutive system events
      if (activity.type == EdenActivityType.system) {
        int batchEnd = i + 1;
        while (batchEnd < activities.length &&
            activities[batchEnd].type == EdenActivityType.system &&
            _dateGroupLabel(activities[batchEnd].timestamp, now) ==
                groupLabel) {
          batchEnd++;
        }
        final batchSize = batchEnd - i;

        if (batchSize >= widget.systemBatchThreshold) {
          final batch = activities.sublist(i, batchEnd);
          final batchId = '${batch.first.id}_batch';
          final expanded = _expandedBatches.contains(batchId);

          children.add(
            _SystemBatch(
              activities: batch,
              expanded: expanded,
              isDark: isDark,
              theme: theme,
              useRelativeTime: widget.useRelativeTime,
              onToggle: () {
                setState(() {
                  if (expanded) {
                    _expandedBatches.remove(batchId);
                  } else {
                    _expandedBatches.add(batchId);
                  }
                });
              },
              onActivityTap: widget.onActivityTap,
              onMentionTap: widget.onMentionTap,
            ),
          );
          i = batchEnd;
          continue;
        }
      }

      children.add(
        _ActivityItem(
          activity: activity,
          isDark: isDark,
          theme: theme,
          useRelativeTime: widget.useRelativeTime,
          onTap: widget.onActivityTap != null
              ? () => widget.onActivityTap!(activity)
              : null,
          onMentionTap: widget.onMentionTap,
        ),
      );
      i++;
    }

    // Load more button
    if (widget.hasMore) {
      children.add(
        _LoadMoreButton(
          isLoading: widget.isLoadingMore,
          onTap: widget.onLoadMore,
          isDark: isDark,
          theme: theme,
        ),
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? color.withValues(alpha: 0.15)
        : (isDark
            ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
            : EdenColors.neutral[100]!);
    final fg = selected
        ? color
        : (isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: EdenRadii.borderRadiusFull,
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date separator
// ---------------------------------------------------------------------------

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({
    required this.label,
    required this.isDark,
  });

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color =
        isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!;
    final lineColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space3),
      child: Row(
        children: [
          Expanded(child: Divider(color: lineColor, height: 1)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(child: Divider(color: lineColor, height: 1)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity item
// ---------------------------------------------------------------------------

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.activity,
    required this.isDark,
    required this.theme,
    required this.useRelativeTime,
    this.onTap,
    this.onMentionTap,
  });

  final EdenActivity activity;
  final bool isDark;
  final ThemeData theme;
  final bool useRelativeTime;
  final VoidCallback? onTap;
  final MentionTapCallback? onMentionTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = _EdenActivityFeedState._colorForType(activity.type);
    final typeIcon = _EdenActivityFeedState._iconForType(activity.type);
    final now = DateTime.now();

    final timeText = useRelativeTime
        ? _EdenActivityFeedState._relativeTime(activity.timestamp, now)
        : _EdenActivityFeedState._absoluteTime(activity.timestamp);

    return InkWell(
      onTap: onTap,
      borderRadius: EdenRadii.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _Avatar(
              initial: activity.actorAvatarInitial ??
                  (activity.actorName.isNotEmpty
                      ? activity.actorName[0]
                      : '?'),
              color: typeColor,
              isDark: isDark,
            ),
            const SizedBox(width: EdenSpacing.space3),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, size: 14, color: typeColor),
                      const SizedBox(width: EdenSpacing.space1),
                      Expanded(
                        child: RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: activity.actorName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: activity.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? EdenColors.neutral[300]
                                      : EdenColors.neutral[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? EdenColors.neutral[500]
                          : EdenColors.neutral[400],
                    ),
                  ),
                  if (activity.body != null && activity.body!.isNotEmpty) ...[
                    const SizedBox(height: EdenSpacing.space2),
                    _RichBody(
                      text: activity.body!,
                      isDark: isDark,
                      theme: theme,
                      onMentionTap: onMentionTap,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.color,
    required this.isDark,
  });

  final String initial;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rich body with @mention highlighting
// ---------------------------------------------------------------------------

class _RichBody extends StatelessWidget {
  const _RichBody({
    required this.text,
    required this.isDark,
    required this.theme,
    this.onMentionTap,
  });

  final String text;
  final bool isDark;
  final ThemeData theme;
  final MentionTapCallback? onMentionTap;

  @override
  Widget build(BuildContext context) {
    final spans = _parseBody();

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Text.rich(
        TextSpan(children: spans),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
          height: 1.5,
        ),
      ),
    );
  }

  /// Parse body text and highlight @mentions and links.
  List<InlineSpan> _parseBody() {
    final mentionPattern = RegExp(r'@[\w.]+');
    final combined = RegExp(r'(@[\w.]+)|(https?://\S+)');

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in combined.allMatches(text)) {
      // Plain text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final value = match.group(0)!;
      if (mentionPattern.hasMatch(value) && value.startsWith('@')) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: onMentionTap != null
                  ? () => onMentionTap!(value.substring(1))
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // Link
        spans.add(
          TextSpan(
            text: value,
            style: TextStyle(
              color: EdenColors.info,
              decoration: TextDecoration.underline,
              decorationColor: EdenColors.info.withValues(alpha: 0.5),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    // Trailing plain text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }
}

// ---------------------------------------------------------------------------
// System event batch
// ---------------------------------------------------------------------------

class _SystemBatch extends StatelessWidget {
  const _SystemBatch({
    required this.activities,
    required this.expanded,
    required this.isDark,
    required this.theme,
    required this.useRelativeTime,
    required this.onToggle,
    this.onActivityTap,
    this.onMentionTap,
  });

  final List<EdenActivity> activities;
  final bool expanded;
  final bool isDark;
  final ThemeData theme;
  final bool useRelativeTime;
  final VoidCallback onToggle;
  final ValueChanged<EdenActivity>? onActivityTap;
  final MentionTapCallback? onMentionTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsed summary
        InkWell(
          onTap: onToggle,
          borderRadius: EdenRadii.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
              vertical: EdenSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
                  : EdenColors.neutral[100],
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 14,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: Text(
                    '${activities.length} system events',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? EdenColors.neutral[300]
                          : EdenColors.neutral[600],
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ],
            ),
          ),
        ),
        // Expanded items
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(
              left: EdenSpacing.space4,
              top: EdenSpacing.space1,
            ),
            child: Column(
              children: [
                for (final activity in activities)
                  _ActivityItem(
                    activity: activity,
                    isDark: isDark,
                    theme: theme,
                    useRelativeTime: useRelativeTime,
                    onTap: onActivityTap != null
                        ? () => onActivityTap!(activity)
                        : null,
                    onMentionTap: onMentionTap,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Load more button
// ---------------------------------------------------------------------------

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.isLoading,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  final bool isLoading;
  final VoidCallback? onTap;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space4),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space6,
                    vertical: EdenSpacing.space2,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? EdenColors.neutral[600]!
                        : EdenColors.neutral[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: EdenRadii.borderRadiusMd,
                  ),
                ),
                child: Text(
                  'Load more',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
      ),
    );
  }
}

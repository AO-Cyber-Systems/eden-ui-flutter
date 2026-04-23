import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'conversation_thread/conversation_event_cards.dart';
import 'conversation_thread/conversation_shared.dart';

enum EdenConversationEventType {
  comment,
  labelChange,
  assignmentChange,
  statusChange,
  commitRef,
  crossRef,
  reviewSummary,
  merge,
}

/// A single event in a conversation timeline.
class EdenConversationEvent {
  const EdenConversationEvent({
    required this.id,
    required this.type,
    required this.actorName,
    required this.actorInitial,
    required this.timestamp,
    this.body,
    this.metadata = const {},
  });

  final String id;
  final EdenConversationEventType type;
  final String actorName;
  final String actorInitial;
  final String timestamp;

  /// Body text for comments or additional detail.
  final String? body;

  /// Arbitrary metadata bag used by each event type:
  /// - labelChange: `labels` (`List<Map<String,String>>` with `name` / `color`)
  ///   `action` ("added" | "removed")
  /// - assignmentChange: `assigneeName`, `assigneeInitial`,
  ///   `action` ("assigned" | "unassigned")
  /// - statusChange: `status` ("closed" | "reopened")
  /// - commitRef: `commits` (`List<Map<String,String>>` with `sha` / `message`)
  /// - crossRef: `refNumber`, `refTitle`
  /// - reviewSummary: `verdict` ("approved"|"changesRequested"|"commented"|"dismissed"),
  ///   `summaryBody`, `inlineCommentCount`
  /// - merge: `commitSha`, `baseBranch`
  final Map<String, dynamic> metadata;
}

/// Renders a list of [EdenConversationEvent] items as a vertical timeline.
///
/// Comment events are rendered with full avatar + body, while compact events
/// (label, assignment, status, commit, cross-ref, merge) are rendered as
/// single-line items. Consecutive compact events share a connector line and
/// are visually grouped.
class EdenConversationThread extends StatefulWidget {
  const EdenConversationThread({
    super.key,
    required this.events,
    this.onEventTap,
    this.reviewSummaryBuilder,
  });

  final List<EdenConversationEvent> events;

  /// Called when any event row is tapped.
  final ValueChanged<EdenConversationEvent>? onEventTap;

  /// Optional builder for reviewSummary events. When null a default inline
  /// rendering is used.
  final Widget Function(EdenConversationEvent event)? reviewSummaryBuilder;

  @override
  State<EdenConversationThread> createState() => _EdenConversationThreadState();
}

class _EdenConversationThreadState extends State<EdenConversationThread> {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isCompact(EdenConversationEventType type) {
    switch (type) {
      case EdenConversationEventType.comment:
      case EdenConversationEventType.reviewSummary:
        return false;
      case EdenConversationEventType.labelChange:
      case EdenConversationEventType.assignmentChange:
      case EdenConversationEventType.statusChange:
      case EdenConversationEventType.commitRef:
      case EdenConversationEventType.crossRef:
      case EdenConversationEventType.merge:
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timelineColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final events = widget.events;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < events.length; i++)
          _buildEventRow(
            theme: theme,
            isDark: isDark,
            timelineColor: timelineColor,
            event: events[i],
            isLast: i == events.length - 1,
          ),
      ],
    );
  }

  Widget _buildEventRow({
    required ThemeData theme,
    required bool isDark,
    required Color timelineColor,
    required EdenConversationEvent event,
    required bool isLast,
  }) {
    final isCompact = _isCompact(event.type);

    return GestureDetector(
      onTap: widget.onEventTap != null
          ? () => widget.onEventTap!(event)
          : null,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline gutter
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  // Dot or avatar
                  if (isCompact)
                    CompactDot(
                      eventType: event.type,
                      isDark: isDark,
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        event.actorInitial,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Connector line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: timelineColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: EdenSpacing.space3),

            // Event content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : EdenSpacing.space4,
                ),
                child: _buildEventContent(
                  theme: theme,
                  isDark: isDark,
                  event: event,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Event content dispatcher
  // ---------------------------------------------------------------------------

  Widget _buildEventContent({
    required ThemeData theme,
    required bool isDark,
    required EdenConversationEvent event,
  }) {
    switch (event.type) {
      case EdenConversationEventType.comment:
        return CommentContent(event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.labelChange:
        return LabelChangeContent(event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.assignmentChange:
        return AssignmentContent(event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.statusChange:
        return StatusChangeContent(
            event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.commitRef:
        return CommitRefContent(event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.crossRef:
        return CrossRefContent(event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.reviewSummary:
        if (widget.reviewSummaryBuilder != null) {
          return widget.reviewSummaryBuilder!(event);
        }
        return ReviewSummaryContent(
            event: event, isDark: isDark, theme: theme);
      case EdenConversationEventType.merge:
        return MergeContent(event: event, isDark: isDark, theme: theme);
    }
  }
}

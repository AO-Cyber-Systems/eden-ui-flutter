import 'package:flutter/material.dart';

import '../eden_badge.dart';
import '../eden_input.dart';
import '../eden_spinner.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'eden_support_panel_config.dart';
import 'support_panel_models.dart';

/// Shows a single ticket's details plus a scrollable comment thread.
///
/// The comment input is pinned at the bottom outside the scrollable area so it
/// stays visible while the thread scrolls.
class EdenTicketDetailView extends StatefulWidget {
  const EdenTicketDetailView({
    super.key,
    required this.ticket,
    required this.config,
    required this.onBack,
  });

  final SupportTicket ticket;
  final EdenSupportPanelConfig config;
  final VoidCallback onBack;

  @override
  State<EdenTicketDetailView> createState() => _EdenTicketDetailViewState();
}

class _EdenTicketDetailViewState extends State<EdenTicketDetailView> {
  List<SupportComment> _comments = [];
  bool _isLoading = false;
  String? _error;

  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  String? _commentError;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (widget.config.listComments == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final comments = await widget.config.listComments!(widget.ticket.id);
      // Sort ascending by date
      final sorted = List<SupportComment>.from(comments)
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return aDate.compareTo(bDate);
        });
      setState(() {
        _comments = sorted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (widget.config.addComment == null) return;
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
      _commentError = null;
    });
    try {
      final comment = await widget.config.addComment!(
        ticketId: widget.ticket.id,
        body: body,
      );
      _commentController.clear();
      setState(() {
        _comments = [..._comments, comment];
        _isSubmittingComment = false;
      });
      // Scroll to bottom after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      // Preserve comment text — only update error
      setState(() {
        _commentError = e.toString();
        _isSubmittingComment = false;
      });
    }
  }

  EdenBadgeVariant _statusVariant(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return EdenBadgeVariant.primary;
      case SupportTicketStatus.inProgress:
        return EdenBadgeVariant.warning;
      case SupportTicketStatus.resolved:
        return EdenBadgeVariant.success;
      case SupportTicketStatus.closed:
        return EdenBadgeVariant.neutral;
      case SupportTicketStatus.waiting:
        return EdenBadgeVariant.info;
    }
  }

  String _statusLabel(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return 'Open';
      case SupportTicketStatus.inProgress:
        return 'In Progress';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
      case SupportTicketStatus.waiting:
        return 'Waiting';
    }
  }

  EdenBadgeVariant _priorityVariant(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.urgent:
        return EdenBadgeVariant.danger;
      case SupportTicketPriority.high:
        return EdenBadgeVariant.warning;
      case SupportTicketPriority.normal:
      case SupportTicketPriority.low:
        return EdenBadgeVariant.neutral;
    }
  }

  String _priorityLabel(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.urgent:
        return 'Urgent';
      case SupportTicketPriority.high:
        return 'High';
      case SupportTicketPriority.normal:
        return 'Normal';
      case SupportTicketPriority.low:
        return 'Low';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticket = widget.ticket;
    final canComment = widget.config.addComment != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EdenSpacing.space4,
            EdenSpacing.space3,
            EdenSpacing.space4,
            EdenSpacing.space2,
          ),
          child: Semantics(
            button: true,
            label: 'Back to ticket list',
            child: GestureDetector(
              onTap: widget.onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: EdenSpacing.space2),
                  Text(
                    'Back',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Ticket header + comment list (scrollable)
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
            ),
            children: [
              // Subject
              Text(
                ticket.subject,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: EdenSpacing.space2),

              // Status + priority row
              Row(
                children: [
                  EdenBadge(
                    label: _statusLabel(ticket.status),
                    variant: _statusVariant(ticket.status),
                    size: EdenBadgeSize.sm,
                  ),
                  const SizedBox(width: EdenSpacing.space2),
                  EdenBadge(
                    label: _priorityLabel(ticket.priority),
                    variant: _priorityVariant(ticket.priority),
                    size: EdenBadgeSize.sm,
                  ),
                ],
              ),

              if (ticket.description != null &&
                  ticket.description!.isNotEmpty) ...[
                const SizedBox(height: EdenSpacing.space3),
                Text(
                  ticket.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],

              if (ticket.createdAt != null) ...[
                const SizedBox(height: EdenSpacing.space2),
                Text(
                  'Created ${_formatDate(ticket.createdAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: EdenSpacing.space3),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: EdenSpacing.space2),

              // Comments section header
              Text(
                'Comments',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: EdenSpacing.space2),

              // Comment list body
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(EdenSpacing.space4),
                    child: EdenSpinner(),
                  ),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 13),
                )
              else if (_comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: EdenSpacing.space3,
                  ),
                  child: Text(
                    'No comments yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._comments.asMap().entries.map((entry) {
                  final i = entry.key;
                  final comment = entry.value;
                  final isEven = i % 2 == 0;
                  final bg = isEven
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.colorScheme.surface;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
                    child: Container(
                      padding: const EdgeInsets.all(EdenSpacing.space3),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: EdenRadii.borderRadiusMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.body,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (comment.createdAt != null) ...[
                            const SizedBox(height: EdenSpacing.space1),
                            Text(
                              _formatDate(comment.createdAt!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              // Bottom padding for the comment input
              const SizedBox(height: EdenSpacing.space4),
            ],
          ),
        ),

        // Comment error
        if (_commentError != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space1,
            ),
            child: Text(
              _commentError!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ),

        // Pinned comment input at the bottom
        if (canComment)
          Container(
            padding: const EdgeInsets.fromLTRB(
              EdenSpacing.space4,
              EdenSpacing.space2,
              EdenSpacing.space2,
              EdenSpacing.space3,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: EdenInput(
                    controller: _commentController,
                    hint: 'Add a comment...',
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: EdenSpacing.space2),
                Semantics(
                  button: true,
                  label: 'Send comment',
                  child: IconButton(
                    onPressed: _isSubmittingComment ? null : _submitComment,
                    icon: _isSubmittingComment
                        ? const EdenSpinner(size: EdenSpinnerSize.sm)
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

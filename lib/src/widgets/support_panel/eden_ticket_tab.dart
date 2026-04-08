import 'package:flutter/material.dart';

import '../eden_badge.dart';
import '../eden_button.dart';
import '../eden_empty_state.dart';
import '../eden_input.dart';
import '../eden_select.dart';
import '../eden_spinner.dart';
import '../../tokens/spacing.dart';
import 'eden_support_panel_config.dart';
import 'eden_ticket_detail_view.dart';
import 'support_panel_models.dart';

/// Full ticket list + create-form widget for the Support tab.
class EdenTicketTab extends StatefulWidget {
  const EdenTicketTab({super.key, required this.config});

  final EdenSupportPanelConfig config;

  @override
  State<EdenTicketTab> createState() => _EdenTicketTabState();
}

class _EdenTicketTabState extends State<EdenTicketTab> {
  // List state
  List<SupportTicket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  // Navigation stack (drill into ticket detail)
  final List<Widget> _viewStack = [];

  // Create form state
  bool _showCreateForm = false;
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _description = TextEditingController();
  SupportTicketPriority _priority = SupportTicketPriority.normal;
  bool _isSubmitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    if (widget.config.listTickets == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tickets = await widget.config.listTickets!();
      // Sort newest first as a safety net (server should return sorted)
      final sorted = List<SupportTicket>.from(tickets)
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
      setState(() {
        _tickets = sorted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (widget.config.createTicket == null) return;
    final subject = _subject.text.trim();
    if (subject.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });
    try {
      await widget.config.createTicket!(
        subject: subject,
        description: _description.text.trim(),
        priority: _priority,
      );
      // Success: clear form, go back to list, reload
      _subject.clear();
      _description.clear();
      setState(() {
        _priority = SupportTicketPriority.normal;
        _isSubmitting = false;
        _showCreateForm = false;
      });
      await _loadTickets();
    } catch (e) {
      // Preserve form input — only update error and submitting flag
      setState(() {
        _formError = e.toString();
        _isSubmitting = false;
      });
    }
  }

  void _openTicket(SupportTicket ticket) {
    setState(() {
      _viewStack.add(
        EdenTicketDetailView(
          ticket: ticket,
          config: widget.config,
          onBack: () => setState(() => _viewStack.removeLast()),
        ),
      );
    });
  }

  EdenBadgeVariant _statusVariant(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return EdenBadgeVariant.primary; // blue
      case SupportTicketStatus.inProgress:
        return EdenBadgeVariant.warning; // amber
      case SupportTicketStatus.resolved:
        return EdenBadgeVariant.success; // green
      case SupportTicketStatus.closed:
        return EdenBadgeVariant.neutral; // gray
      case SupportTicketStatus.waiting:
        return EdenBadgeVariant.info; // orange-ish
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

  Color? _priorityDotColor(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.urgent:
        return Colors.red;
      case SupportTicketPriority.high:
        return Colors.orange;
      case SupportTicketPriority.normal:
      case SupportTicketPriority.low:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drill-down: show the topmost stacked view
    if (_viewStack.isNotEmpty) {
      return _viewStack.last;
    }

    if (_showCreateForm) {
      return _buildCreateForm(context);
    }

    return _buildTicketList(context);
  }

  Widget _buildCreateForm(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = !_isSubmitting && _subject.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back / cancel row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EdenSpacing.space4,
            EdenSpacing.space3,
            EdenSpacing.space4,
            EdenSpacing.space2,
          ),
          child: Semantics(
            button: true,
            label: 'Cancel and go back',
            child: GestureDetector(
              onTap: () => setState(() {
                _showCreateForm = false;
                _formError = null;
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: EdenSpacing.space2),
                  Text(
                    'Cancel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New Ticket',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: EdenSpacing.space4),
                EdenInput(
                  label: 'Subject',
                  hint: 'Describe your issue briefly',
                  controller: _subject,
                  onChanged: (_) => setState(() {}), // refresh canSubmit
                ),
                const SizedBox(height: EdenSpacing.space3),
                EdenInput(
                  label: 'Description',
                  hint: 'Provide more detail (optional)',
                  controller: _description,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: EdenSpacing.space3),
                EdenSelect<SupportTicketPriority>(
                  label: 'Priority',
                  value: _priority,
                  options: SupportTicketPriority.values
                      .map(
                        (p) => EdenSelectOption<SupportTicketPriority>(
                          value: p,
                          label: _priorityLabel(p),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
                if (_formError != null) ...[
                  const SizedBox(height: EdenSpacing.space3),
                  Text(
                    _formError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: EdenSpacing.space4),
                EdenButton(
                  label: 'Submit Ticket',
                  onPressed: canSubmit ? _submitTicket : null,
                  variant: EdenButtonVariant.primary,
                  disabled: !canSubmit,
                  loading: _isSubmitting,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _priorityLabel(SupportTicketPriority p) {
    switch (p) {
      case SupportTicketPriority.low:
        return 'Low';
      case SupportTicketPriority.normal:
        return 'Normal';
      case SupportTicketPriority.high:
        return 'High';
      case SupportTicketPriority.urgent:
        return 'Urgent';
    }
  }

  Widget _buildTicketList(BuildContext context) {
    final theme = Theme.of(context);
    final canCreate = widget.config.createTicket != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EdenSpacing.space4,
            EdenSpacing.space3,
            EdenSpacing.space2,
            EdenSpacing.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tickets',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (canCreate)
                Semantics(
                  button: true,
                  label: 'New ticket',
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _showCreateForm = true;
                      _formError = null;
                    }),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Ticket'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space2,
                        vertical: EdenSpacing.space1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildListBody(context, theme),
        ),
      ],
    );
  }

  Widget _buildListBody(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: EdenSpinner());
    }

    if (_error != null) {
      return EdenEmptyState(
        title: 'Could not load tickets',
        description: _error,
        icon: Icons.error_outline,
        actionLabel: 'Retry',
        onAction: _loadTickets,
      );
    }

    if (_tickets.isEmpty) {
      return EdenEmptyState(
        title: 'No tickets yet',
        description: 'Create a ticket to get support from our team.',
        icon: Icons.confirmation_number_outlined,
        actionLabel: widget.config.createTicket != null ? 'New Ticket' : null,
        onAction: widget.config.createTicket != null
            ? () => setState(() => _showCreateForm = true)
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: EdenSpacing.space4),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final dotColor = _priorityDotColor(ticket.priority);
          return Semantics(
            button: true,
            label: 'View ticket: ${ticket.subject}',
            child: InkWell(
              onTap: () => _openTicket(ticket),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space4,
                  vertical: EdenSpacing.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority dot
                    if (dotColor != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          right: EdenSpacing.space2,
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 16), // placeholder to align
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.subject,
                            style: theme.textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: EdenSpacing.space1),
                          Row(
                            children: [
                              EdenBadge(
                                label: _statusLabel(ticket.status),
                                variant: _statusVariant(ticket.status),
                                size: EdenBadgeSize.sm,
                              ),
                              if (ticket.createdAt != null) ...[
                                const SizedBox(width: EdenSpacing.space2),
                                Text(
                                  _formatDate(ticket.createdAt!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'approval_queue/approval_filter_bar.dart';
import 'approval_queue/approval_card.dart';

/// Status of an approval item.
enum EdenApprovalStatus {
  /// Awaiting a decision.
  pending,

  /// Approved by reviewer.
  approved,

  /// Rejected by reviewer.
  rejected,

  /// Reviewer requested changes before re-submission.
  changesRequested,
}

/// Priority level for an approval item.
enum EdenApprovalPriority {
  /// Low priority.
  low,

  /// Normal priority.
  normal,

  /// High priority — surfaces higher in the queue.
  high,

  /// Urgent — requires immediate attention.
  urgent,
}

/// Represents a single item in an approval workflow queue.
class EdenApprovalItem {
  /// Creates an approval item.
  const EdenApprovalItem({
    required this.id,
    required this.title,
    required this.submittedBy,
    required this.submittedAt,
    this.subtitle,
    this.description,
    this.avatarInitial,
    this.status = EdenApprovalStatus.pending,
    this.priority = EdenApprovalPriority.normal,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String submittedBy;
  final String? avatarInitial;
  final DateTime submittedAt;
  final EdenApprovalStatus status;
  final EdenApprovalPriority priority;
  final Map<String, String> metadata;
}

/// An approval workflow queue widget that displays pending items as cards
/// with approve, reject, and request-changes actions.
///
/// Supports batch operations, filtering by status/priority/submitter,
/// and displays summary statistics.
class EdenApprovalQueue extends StatefulWidget {
  /// Creates an Eden approval queue.
  const EdenApprovalQueue({
    super.key,
    required this.items,
    this.onApprove,
    this.onReject,
    this.onRequestChanges,
    this.onItemTap,
    this.enableBatchActions = true,
    this.showFilters = true,
    this.showStats = true,
    this.emptyStateMessage = 'No items match the current filters.',
    this.emptyStateIcon = Icons.inbox_outlined,
  });

  final List<EdenApprovalItem> items;
  final ValueChanged<List<String>>? onApprove;
  final void Function(List<String> ids, String comment)? onReject;
  final void Function(List<String> ids, String comment)? onRequestChanges;
  final ValueChanged<EdenApprovalItem>? onItemTap;
  final bool enableBatchActions;
  final bool showFilters;
  final bool showStats;
  final String emptyStateMessage;
  final IconData emptyStateIcon;

  @override
  State<EdenApprovalQueue> createState() => _EdenApprovalQueueState();
}

class _EdenApprovalQueueState extends State<EdenApprovalQueue> {
  EdenApprovalStatus? _statusFilter;
  EdenApprovalPriority? _priorityFilter;
  String? _submitterFilter;
  final Set<String> _selectedIds = {};

  List<EdenApprovalItem> get _filteredItems {
    return widget.items.where((item) {
      if (_statusFilter != null && item.status != _statusFilter) return false;
      if (_priorityFilter != null && item.priority != _priorityFilter) return false;
      if (_submitterFilter != null && item.submittedBy != _submitterFilter) return false;
      return true;
    }).toList();
  }

  List<String> get _uniqueSubmitters {
    return widget.items.map((i) => i.submittedBy).toSet().toList()..sort();
  }

  int _countByStatus(EdenApprovalStatus status) =>
      widget.items.where((i) => i.status == status).length;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      final filtered = _filteredItems;
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(filtered.map((i) => i.id));
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  Future<void> _handleApprove(List<String> ids) async {
    widget.onApprove?.call(ids);
    _clearSelection();
  }

  Future<void> _handleRejectOrChanges({
    required List<String> ids,
    required bool isReject,
  }) async {
    final comment = await _showCommentDialog(
      context: context,
      title: isReject ? 'Reject' : 'Request Changes',
      actionLabel: isReject ? 'Reject' : 'Request Changes',
      isDestructive: isReject,
    );
    if (comment == null) return;

    if (isReject) {
      widget.onReject?.call(ids, comment);
    } else {
      widget.onRequestChanges?.call(ids, comment);
    }
    _clearSelection();
  }

  Future<String?> _showCommentDialog({
    required BuildContext context,
    required String title,
    required String actionLabel,
    bool isDestructive = false,
  }) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(EdenSpacing.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: EdenSpacing.space4),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    filled: true,
                    fillColor: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
                    border: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusLg,
                      borderSide: BorderSide(color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusLg,
                      borderSide: BorderSide(color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: EdenSpacing.space5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
                        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space5, vertical: EdenSpacing.space3),
                        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        Navigator.of(dialogContext).pop(text.isEmpty ? '(no comment)' : text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? EdenColors.error : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space5, vertical: EdenSpacing.space3),
                        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
                      ),
                      child: Text(actionLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final listContent = filtered.isEmpty
            ? EmptyState(message: widget.emptyStateMessage, icon: widget.emptyStateIcon, isDark: isDark)
            : ListView.separated(
                shrinkWrap: !hasBoundedHeight,
                physics: !hasBoundedHeight ? const NeverScrollableScrollPhysics() : null,
                padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: EdenSpacing.space3),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return ApprovalCard(
                    item: item,
                    isDark: isDark,
                    theme: theme,
                    isSelected: _selectedIds.contains(item.id),
                    showCheckbox: widget.enableBatchActions,
                    onToggleSelect: () => _toggleSelection(item.id),
                    onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
                    onApprove: widget.onApprove != null ? () => _handleApprove([item.id]) : null,
                    onReject: widget.onReject != null ? () => _handleRejectOrChanges(ids: [item.id], isReject: true) : null,
                    onRequestChanges: widget.onRequestChanges != null ? () => _handleRejectOrChanges(ids: [item.id], isReject: false) : null,
                  );
                },
              );
        final wrappedList = hasBoundedHeight ? Expanded(child: listContent) : listContent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.showStats)
              SummaryStatsRow(
                pending: _countByStatus(EdenApprovalStatus.pending),
                approved: _countByStatus(EdenApprovalStatus.approved),
                rejected: _countByStatus(EdenApprovalStatus.rejected),
                changesRequested: _countByStatus(EdenApprovalStatus.changesRequested),
                isDark: isDark,
              ),
            if (widget.showStats) const SizedBox(height: EdenSpacing.space3),
            if (widget.showFilters)
              FilterBar(
                statusFilter: _statusFilter,
                priorityFilter: _priorityFilter,
                submitterFilter: _submitterFilter,
                submitters: _uniqueSubmitters,
                isDark: isDark,
                theme: theme,
                onStatusChanged: (v) => setState(() => _statusFilter = v),
                onPriorityChanged: (v) => setState(() => _priorityFilter = v),
                onSubmitterChanged: (v) => setState(() => _submitterFilter = v),
              ),
            if (widget.showFilters) const SizedBox(height: EdenSpacing.space3),
            if (widget.enableBatchActions && _selectedIds.isNotEmpty)
              BatchActionBar(
                selectedCount: _selectedIds.length,
                isDark: isDark,
                theme: theme,
                onApprove: () => _handleApprove(_selectedIds.toList()),
                onReject: () => _handleRejectOrChanges(ids: _selectedIds.toList(), isReject: true),
                onRequestChanges: () => _handleRejectOrChanges(ids: _selectedIds.toList(), isReject: false),
                onClear: _clearSelection,
              ),
            if (widget.enableBatchActions && _selectedIds.isNotEmpty) const SizedBox(height: EdenSpacing.space2),
            if (widget.enableBatchActions && filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                child: GestureDetector(
                  onTap: _selectAll,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _selectedIds.length == filtered.length && filtered.isNotEmpty,
                            tristate: true,
                            onChanged: (_) => _selectAll(),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: EdenSpacing.space2),
                        Text(
                          'Select all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.enableBatchActions && filtered.isNotEmpty) const SizedBox(height: EdenSpacing.space2),
            wrappedList,
          ],
        );
      },
    );
  }
}

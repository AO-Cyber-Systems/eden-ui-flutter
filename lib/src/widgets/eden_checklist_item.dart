import 'package:flutter/material.dart';

/// A checkable task tile with assignee and due date metadata.
///
/// Used in checklist/task views. Calls [onToggle] when the checkbox
/// is tapped. Shows overdue styling when the due date has passed and
/// the task is not yet complete. Supports required flag and description.
///
/// ```dart
/// EdenChecklistItem(
///   title: 'Install ductwork',
///   isCompleted: false,
///   onToggle: (completed) => updateTask(completed),
///   isRequired: true,
///   assignedTo: 'Mike S.',
///   dueDate: DateTime(2026, 3, 28),
/// )
/// ```
class EdenChecklistItem extends StatelessWidget {
  const EdenChecklistItem({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.onToggle,
    this.isRequired = false,
    this.assignedTo,
    this.dueDate,
    this.description,
    this.enabled = true,
  });

  final String title;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;
  final bool isRequired;
  final String? assignedTo;
  final DateTime? dueDate;
  final String? description;
  final bool enabled;

  bool get _isOverdue =>
      !isCompleted && dueDate != null && DateTime.now().isAfter(dueDate!);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return 'Overdue ${-diff}d';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueColor = theme.colorScheme.error;
    final completedColor =
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    final activeColor = theme.colorScheme.onSurface;

    final textColor = isCompleted
        ? completedColor
        : _isOverdue
            ? overdueColor
            : activeColor;

    return InkWell(
      onTap: enabled ? () => onToggle(!isCompleted) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isCompleted,
                onChanged: enabled ? (v) => onToggle(v ?? false) : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            fontWeight: isRequired && !isCompleted
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isRequired && !isCompleted)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (assignedTo != null || dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (assignedTo != null) ...[
                          Icon(Icons.person_outline,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            assignedTo!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (assignedTo != null && dueDate != null)
                          const SizedBox(width: 10),
                        if (dueDate != null) ...[
                          Icon(
                            _isOverdue
                                ? Icons.warning_amber_outlined
                                : Icons.calendar_today_outlined,
                            size: 13,
                            color: _isOverdue
                                ? overdueColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(dueDate!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _isOverdue
                                  ? overdueColor
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  _isOverdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
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

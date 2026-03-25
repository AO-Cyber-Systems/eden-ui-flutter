import 'package:flutter/material.dart';

/// A checkable task tile with assignee and due date metadata.
///
/// Used in checklist/task views. Calls [onToggle] when the checkbox
/// is tapped. Shows overdue styling when the due date has passed and
/// the task is not yet complete. Supports required flag, description,
/// blocked/N-A states, and an optional trailing widget.
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
    this.isBlocked = false,
    this.isNa = false,
    this.assignedTo,
    this.dueDate,
    this.description,
    this.blockedReason,
    this.naReason,
    this.enabled = true,
    this.onLongPress,
    this.trailing,
  });

  final String title;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;
  final bool isRequired;

  /// Whether this task is blocked (renders a lock icon instead of checkbox).
  final bool isBlocked;

  /// Whether this task is not applicable (renders a dash icon instead of checkbox).
  final bool isNa;

  final String? assignedTo;
  final DateTime? dueDate;
  final String? description;

  /// Reason this task is blocked (e.g. "PO #1234").
  final String? blockedReason;

  /// Reason this task was marked N/A.
  final String? naReason;

  final bool enabled;
  final VoidCallback? onLongPress;

  /// Widget displayed after the title row (e.g. a PO badge or spinner).
  final Widget? trailing;

  bool get _isOverdue =>
      !isCompleted && !isNa && dueDate != null && DateTime.now().isAfter(dueDate!);

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

    final textColor = isCompleted || isNa
        ? completedColor
        : isBlocked
            ? overdueColor
            : _isOverdue
                ? overdueColor
                : activeColor;

    return InkWell(
      onTap: enabled && !isBlocked && !isNa
          ? () => onToggle(!isCompleted)
          : null,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon / checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _buildLeadingIcon(context),
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
                            fontWeight: isRequired && !isCompleted && !isNa
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isRequired && !isCompleted && !isNa)
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
                      if (trailing != null) ...[
                        const SizedBox(width: 6),
                        trailing!,
                      ],
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
                  // Metadata row
                  if (assignedTo != null ||
                      dueDate != null ||
                      blockedReason != null ||
                      naReason != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (assignedTo != null)
                          _MetaLabel(
                            icon: Icons.person_outline,
                            label: assignedTo!,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        if (dueDate != null)
                          _MetaLabel(
                            icon: _isOverdue
                                ? Icons.warning_amber_outlined
                                : Icons.calendar_today_outlined,
                            label: _formatDate(dueDate!),
                            color: _isOverdue
                                ? overdueColor
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        if (blockedReason != null)
                          _MetaLabel(
                            icon: Icons.lock_outline,
                            label: blockedReason!,
                            color: theme.colorScheme.error,
                          ),
                        if (naReason != null)
                          _MetaLabel(
                            icon: Icons.info_outline,
                            label: naReason!,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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

  Widget _buildLeadingIcon(BuildContext context) {
    final theme = Theme.of(context);

    if (isBlocked) {
      return Icon(Icons.lock, size: 20, color: theme.colorScheme.error);
    }

    if (isNa) {
      return Icon(Icons.remove_circle_outline,
          size: 20, color: theme.colorScheme.onSurfaceVariant);
    }

    return SizedBox(
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
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({
    required this.icon,
    required this.label,
    required this.color,
    this.fontWeight,
  });

  final IconData icon;
  final String label;
  final Color color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}

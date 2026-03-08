import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Priority level for kanban cards.
enum EdenKanbanPriority { high, medium, low }

/// Color theme for kanban columns.
enum EdenKanbanColumnColor { primary, success, warning, danger, neutral }

/// A tag on a kanban card.
class EdenKanbanTag {
  const EdenKanbanTag({required this.label, this.color});
  final String label;
  final Color? color;
}

/// A single card within a kanban column.
class EdenKanbanCard extends StatelessWidget {
  const EdenKanbanCard({
    super.key,
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
    this.assigneeInitials = const [],
    this.tags = const [],
    this.onTap,
  });

  final String title;
  final String? description;
  final EdenKanbanPriority? priority;
  final String? dueDate;
  final List<String> assigneeInitials;
  final List<EdenKanbanTag> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EdenSpacing.space3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (priority != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _priorityColor(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (tag.color ?? EdenColors.info).withValues(alpha: 0.1),
                    borderRadius: EdenRadii.borderRadiusFull,
                  ),
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tag.color ?? EdenColors.info,
                    ),
                  ),
                )).toList(),
              ),
            ],
            if (assigneeInitials.isNotEmpty || dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (assigneeInitials.isNotEmpty)
                    SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          for (int i = 0; i < assigneeInitials.length && i < 3; i++)
                            Transform.translate(
                              offset: Offset(-6.0 * i, 0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                child: Text(
                                  assigneeInitials[i],
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  if (dueDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          dueDate!,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _priorityColor() {
    switch (priority!) {
      case EdenKanbanPriority.high:
        return EdenColors.error;
      case EdenKanbanPriority.medium:
        return EdenColors.warning;
      case EdenKanbanPriority.low:
        return EdenColors.success;
    }
  }
}

/// A column in a kanban board.
class EdenKanbanColumn extends StatelessWidget {
  const EdenKanbanColumn({
    super.key,
    required this.title,
    this.count,
    this.color = EdenKanbanColumnColor.neutral,
    this.children = const [],
    this.width = 280,
  });

  final String title;
  final int? count;
  final EdenKanbanColumnColor color;
  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = _resolveColor(theme);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color bar
          Container(height: 4, color: accentColor),
          // Header
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                ),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.labelLarge),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                      borderRadius: EdenRadii.borderRadiusFull,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(EdenSpacing.space3, 0, EdenSpacing.space3, EdenSpacing.space3),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(ThemeData theme) {
    switch (color) {
      case EdenKanbanColumnColor.primary:
        return theme.colorScheme.primary;
      case EdenKanbanColumnColor.success:
        return EdenColors.success;
      case EdenKanbanColumnColor.warning:
        return EdenColors.warning;
      case EdenKanbanColumnColor.danger:
        return EdenColors.error;
      case EdenKanbanColumnColor.neutral:
        return EdenColors.neutral[400]!;
    }
  }
}

/// Horizontal scrollable kanban board.
class EdenKanbanBoard extends StatelessWidget {
  const EdenKanbanBoard({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: EdenSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: EdenSpacing.space4),
            children[i],
          ],
        ],
      ),
    );
  }
}

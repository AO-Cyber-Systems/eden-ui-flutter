import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A single task item data.
class EdenTaskItemData {
  EdenTaskItemData({
    required this.title,
    this.subtitle,
    this.completed = false,
    this.onChanged,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  bool completed;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final Widget? trailing;
}

/// Mirrors the eden_task_list / eden_task_item Rails components.
class EdenTaskList extends StatelessWidget {
  const EdenTaskList({
    super.key,
    required this.tasks,
    this.title,
  });

  final List<EdenTaskItemData> tasks;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(title!, style: theme.textTheme.titleSmall),
          const SizedBox(height: EdenSpacing.space3),
        ],
        ...tasks.asMap().entries.map((entry) {
          final i = entry.key;
          final task = entry.value;
          return Column(
            children: [
              if (i > 0) Divider(height: 1, color: theme.colorScheme.outlineVariant),
              _EdenTaskItem(data: task),
            ],
          );
        }),
      ],
    );
  }
}

class _EdenTaskItem extends StatelessWidget {
  const _EdenTaskItem({required this.data});
  final EdenTaskItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: data.completed,
              onChanged: data.onChanged != null ? (v) => data.onChanged!(v ?? false) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              activeColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: data.completed ? TextDecoration.lineThrough : null,
                    color: data.completed ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
                if (data.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (data.trailing != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            data.trailing!,
          ],
        ],
      ),
    );

    if (data.onTap != null) {
      return InkWell(onTap: data.onTap, child: content);
    }
    return content;
  }
}
